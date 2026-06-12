"""
MacroForge meal solver.

Given a user's macro targets, a meal structure (ordered list of slot types),
and a pool of recipes, pick one recipe + serving size per slot so the day's
totals land as close to target as possible. Integer programming via PuLP.

Pure module: no DB, no FastAPI. The endpoint layer passes in plain recipe
dicts and reads back a plain result dict.

The meal_structure parameter is the forward-compatible seam: today the endpoint
passes a fixed default like ["breakfast","lunch","dinner","snack"], but the
future drag-and-drop planner will pass arbitrary structures and this function
won't need to change.
"""

import pulp

# Serving multipliers the solver may choose (keeps results edible).
SERVING_SIZES = [1.0, 1.5, 2.0]

# Objective weights: how much each macro's deviation "costs". Protein is the
# priority macro for this app, so missing it is penalized hardest. Calories
# next. Carbs/fat are the flex macros.
WEIGHT_PROTEIN = 4.0
WEIGHT_KCAL = 1.0
WEIGHT_CARBS = 0.5
WEIGHT_FAT = 0.5


def solve_day(
    target_kcal: int,
    target_protein: int,
    target_carbs: int,
    target_fat: int,
    meal_structure: list[str],          # e.g. ["breakfast","lunch","dinner","snack"]
    recipes: list[dict],                # each: id,name,meal_type,kcal,protein,carbs,fat
    optional_slots: set[str] | None = None,   # slot types that may be left empty
    exclude_recipe_ids: set | None = None,    # for "regenerate" variety
):
    """
    Returns a dict:
      {
        "feasible": bool,
        "slots": [ {"slot": str, "recipe_id", "name", "servings", per-slot macros} ],
        "totals": {kcal,protein,carbs,fat},
        "targets": {...},
        "deviation": {kcal,protein,carbs,fat},   # signed: total - target
      }
    """
    optional_slots = optional_slots or set()
    exclude_recipe_ids = exclude_recipe_ids or set()

    # Index recipes by meal_type, dropping excluded ones.
    by_type: dict[str, list[dict]] = {}
    for r in recipes:
        if r["id"] in exclude_recipe_ids:
            continue
        by_type.setdefault(r["meal_type"], []).append(r)

    prob = pulp.LpProblem("meal_day", pulp.LpMinimize)

    # Decision vars: x[(slot_index, recipe_id, serving)] in {0,1}
    x = {}
    for si, slot_type in enumerate(meal_structure):
        for r in by_type.get(slot_type, []):
            for s in SERVING_SIZES:
                x[(si, r["id"], s)] = pulp.LpVariable(
                    f"x_{si}_{r['id']}_{str(s).replace('.','_')}", cat="Binary"
                )

    # Constraint: each required slot picks exactly one; optional slots <= one.
    for si, slot_type in enumerate(meal_structure):
        slot_vars = [x[(si, r["id"], s)] for r in by_type.get(slot_type, []) for s in SERVING_SIZES]
        if not slot_vars:
            # no recipes available for this slot type
            if slot_type not in optional_slots:
                return {"feasible": False, "reason": f"No recipes for slot '{slot_type}'"}
            continue
        if slot_type in optional_slots:
            prob += pulp.lpSum(slot_vars) <= 1
        else:
            prob += pulp.lpSum(slot_vars) == 1

    # Helper: total of a macro across all chosen (var * recipe_macro * serving)
    def macro_total(key):
        terms = []
        for si, slot_type in enumerate(meal_structure):
            for r in by_type.get(slot_type, []):
                for s in SERVING_SIZES:
                    terms.append(x[(si, r["id"], s)] * (r[key] * s))
        return pulp.lpSum(terms)

    total_kcal = macro_total("kcal")
    total_protein = macro_total("protein")
    total_carbs = macro_total("carbs")
    total_fat = macro_total("fat")

    # Deviation vars (over/under) for each macro, >= 0. dev = over + under.
    def dev_pair(name):
        over = pulp.LpVariable(f"over_{name}", lowBound=0)
        under = pulp.LpVariable(f"under_{name}", lowBound=0)
        return over, under

    o_k, u_k = dev_pair("kcal")
    o_p, u_p = dev_pair("protein")
    o_c, u_c = dev_pair("carbs")
    o_f, u_f = dev_pair("fat")

    # total - target = over - under  (linearizes absolute deviation)
    prob += total_kcal - target_kcal == o_k - u_k
    prob += total_protein - target_protein == o_p - u_p
    prob += total_carbs - target_carbs == o_c - u_c
    prob += total_fat - target_fat == o_f - u_f

    # Objective: minimize weighted absolute deviation.
    # Protein under-shoot penalized extra (don't want to under-deliver protein).
    prob += (
        WEIGHT_KCAL * (o_k + u_k)
        + WEIGHT_PROTEIN * (o_p + 1.5 * u_p)   # under-protein hurts more than over
        + WEIGHT_CARBS * (o_c + u_c)
        + WEIGHT_FAT * (o_f + u_f)
    )

    prob.solve(pulp.PULP_CBC_CMD(msg=0))

    if pulp.LpStatus[prob.status] != "Optimal":
        return {"feasible": False, "reason": pulp.LpStatus[prob.status]}

    # Read back the chosen recipes.
    chosen = []
    tot = {"kcal": 0.0, "protein": 0.0, "carbs": 0.0, "fat": 0.0}
    rec_by_id = {r["id"]: r for r in recipes}
    for (si, rid, s), var in x.items():
        if var.value() and var.value() > 0.5:
            r = rec_by_id[rid]
            slot_macros = {
                "kcal": round(r["kcal"] * s),
                "protein": round(r["protein"] * s),
                "carbs": round(r["carbs"] * s),
                "fat": round(r["fat"] * s),
            }
            chosen.append({
                "slot_index": si,
                "slot": meal_structure[si],
                "recipe_id": rid,
                "name": r["name"],
                "servings": s,
                **slot_macros,
            })
            for k in tot:
                tot[k] += slot_macros[k]

    chosen.sort(key=lambda c: c["slot_index"])
    tot = {k: round(v) for k, v in tot.items()}

    return {
        "feasible": True,
        "slots": chosen,
        "totals": tot,
        "targets": {
            "kcal": target_kcal, "protein": target_protein,
            "carbs": target_carbs, "fat": target_fat,
        },
        "deviation": {
            "kcal": tot["kcal"] - target_kcal,
            "protein": tot["protein"] - target_protein,
            "carbs": tot["carbs"] - target_carbs,
            "fat": tot["fat"] - target_fat,
        },
    }


# Day keys in display/solve order. Matches schemas.DAYS.
WEEK_DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

# Slot types that may be left empty if no recipe exists / isn't needed to hit
# targets. (dessert has no recipes yet, so it's skippable rather than fatal.)
OPTIONAL_SLOT_TYPES = {"snack", "dessert"}


def _empty_day(target_kcal, target_protein, target_carbs, target_fat):
    """A day with no slots — feasible, zero macros."""
    return {
        "feasible": True,
        "empty": True,
        "slots": [],
        "totals": {"kcal": 0, "protein": 0, "carbs": 0, "fat": 0},
        "targets": {"kcal": target_kcal, "protein": target_protein,
                    "carbs": target_carbs, "fat": target_fat},
        "deviation": {"kcal": -target_kcal, "protein": -target_protein,
                      "carbs": -target_carbs, "fat": -target_fat},
    }


def solve_week(target_kcal, target_protein, target_carbs, target_fat,
               structure, recipes, exclude_recipe_ids=None):
    """
    Solve all seven days against a structure dict {"mon": [...slots...], ...}.

    Cross-day variety: each day excludes the recipes used on the previous TWO
    days. With a small recipe pool (7-8 per meal type) and a deterministic
    optimizer, a 1-day look-back makes the solver ping-pong between its two
    best days; a 2-day look-back forces a ~3-day rotation and uses more of the
    library. As the recipe library grows, variety widens automatically.

    Feasibility ladder per day: try excluding the last 2 days; if infeasible,
    fall back to excluding just the last day; if still infeasible, solve with
    no exclusions. A valid day always wins over strict variety.

    Empty days (no slots) are returned as feasible zero-macro days and reset
    the variety streak.

    Returns:
      {
        "days": {"mon": <solve_day result>, ...},   # one entry per WEEK_DAYS
        "week_totals": {"kcal","protein","carbs","fat"},  # sum of feasible days
      }
    """
    days_out = {}
    seed = set(exclude_recipe_ids) if exclude_recipe_ids else set()
    recent = [seed, seed] if seed else []

    for day in WEEK_DAYS:
        slots = structure.get(day, [])

        if not slots:
            days_out[day] = _empty_day(target_kcal, target_protein,
                                       target_carbs, target_fat)
            recent = []  # an empty day breaks the streak
            continue

        optional = {s for s in slots if s in OPTIONAL_SLOT_TYPES}
        exclude2 = set().union(*recent[-2:]) if recent else set()

        result = solve_day(
            target_kcal, target_protein, target_carbs, target_fat,
            slots, recipes, optional_slots=optional, exclude_recipe_ids=exclude2,
        )

        # Relax to 1-day look-back if 2-day made the day infeasible.
        if not result["feasible"] and recent:
            result = solve_day(
                target_kcal, target_protein, target_carbs, target_fat,
                slots, recipes, optional_slots=optional,
                exclude_recipe_ids=recent[-1],
            )

        # Last resort: no exclusions at all.
        if not result["feasible"]:
            result = solve_day(
                target_kcal, target_protein, target_carbs, target_fat,
                slots, recipes, optional_slots=optional,
            )

        days_out[day] = result
        recent.append({s["recipe_id"] for s in result.get("slots", [])}
                      if result["feasible"] else set())

    week_totals = {"kcal": 0, "protein": 0, "carbs": 0, "fat": 0}
    for d in days_out.values():
        if d.get("feasible") and d.get("totals"):
            for k in week_totals:
                week_totals[k] += d["totals"][k]

    return {"days": days_out, "week_totals": week_totals}