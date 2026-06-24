"""
Prep-plan builder for MacroForge.

Pure, no DB. Turns a generated week into either:
  - a consolidated BATCH prep session (group by recipe, sum servings,
    order by prep category so make-ahead items come first), or
  - a ROLLING per-day cook list.

Honest scope (Collin, Jun 16): we do NOT decompose free-text recipe steps
into merged tasks. We group by RECIPE and order recipes by a coarse prep
category inferred from the recipe name + main ingredients. Heuristic, but
useful and never silently wrong about steps.
"""

# Prep categories in cook-and-store-first order. Lower sort_rank = prep earlier.
# proteins/grains batch-cook and keep; fresh/assembly happen last.
PREP_CATEGORIES = [
    ("protein", 0),   # cook proteins first (longest, keep well)
    ("grain", 1),     # grains/starches batch-cook, keep well
    ("roast_veg", 2), # roasted/cooked veg, keeps a few days
    ("assembly", 3),  # fresh assembly, salads, wraps — do last / day-of
]

# keyword -> category. Checked in order; first hit wins.
_CATEGORY_KEYWORDS = [
    ("protein", ["chicken", "beef", "salmon", "tuna", "pork", "turkey", "shrimp",
                 "tofu", "egg", "meatball", "steak", "fish"]),
    ("grain",   ["rice", "quinoa", "oats", "oat", "pasta", "bagel", "bread",
                 "potato", "sweet potato", "noodle"]),
    ("roast_veg", ["broccoli", "green bean", "zucchini", "pepper", "stir-fry",
                   "stir fry", "veggie", "vegetable", "curry", "soup", "peppers"]),
    ("assembly", ["salad", "wrap", "bowl", "toast", "yogurt", "parfait", "plate",
                  "snack", "shake", "smoothie", "cups", "sticks", "trail mix",
                  "rice cakes", "almonds", "fruit", "hummus", "cheese", "honey",
                  "peanut butter", "pancake"]),
]

def categorize(recipe_name, ingredients=None):
    """Infer a coarse prep category from recipe name (+ optional ingredients)."""
    text = recipe_name.lower()
    if ingredients:
        text += " " + " ".join(
            (i.get("item", "") if isinstance(i, dict) else str(i)).lower()
            for i in ingredients
        )
    # Strong no-cook FORM words mean the dish is assembled fresh / day-of,
    # even if it contains a protein or grain ingredient. These win first so
    # "Avocado Toast with Egg" and "Turkey & Hummus Wrap" don't get filed as
    # cook-ahead proteins. (Name-only signal — judged on the dish form.)
    STRONG_ASSEMBLY = ["toast", "wrap", "bagel", "sandwich", "cups", "lettuce",
                       "plate", "parfait", "shake", "smoothie", "trail mix",
                       "rice cakes", "salad"]
    # match strong-assembly words against the NAME only (form, not ingredients)
    nm = recipe_name.lower()
    if any(w in nm for w in STRONG_ASSEMBLY):
        return "assembly"
    # proteins/grains/roast_veg are about CONTENT and should win over the
    # weaker "assembly" form-words (bowl) when a real protein/grain is present.
    for cat in ("protein", "grain", "roast_veg"):
        kws = dict(_CATEGORY_KEYWORDS)[cat]
        if any(kw in text for kw in kws):
            return cat
    # otherwise it's assembly/snack
    return "assembly"

_CAT_RANK = dict(PREP_CATEGORIES)
_CAT_LABEL = {
    "protein": "Proteins",
    "grain": "Grains & starches",
    "roast_veg": "Cooked vegetables",
    "assembly": "Fresh & assembly",
}

def build_batch_prep(week_days):
    """
    week_days: dict like generated_plan week['days'] ->
        {dayname: {"slots": [{recipe_id, name, servings, ...}], ...}}
    Returns ordered list of groups:
        [{"category","label","items":[{recipe_id,name,total_servings,category}]}]
    """
    # group by recipe_id, sum servings
    by_recipe = {}
    for day in week_days.values():
        for slot in day.get("slots", []):
            rid = slot.get("recipe_id")
            if not rid:
                continue
            if rid not in by_recipe:
                by_recipe[rid] = {
                    "recipe_id": rid,
                    "name": slot.get("name", "Recipe"),
                    "total_servings": 0.0,
                    "ingredients": slot.get("ingredients"),  # usually absent in week JSON
                }
            by_recipe[rid]["total_servings"] += slot.get("servings", 1.0) or 1.0

    # categorize + sort
    items = []
    for r in by_recipe.values():
        cat = categorize(r["name"], r.get("ingredients"))
        items.append({
            "recipe_id": r["recipe_id"],
            "name": r["name"],
            "total_servings": round(r["total_servings"], 2),
            "category": cat,
        })
    items.sort(key=lambda x: (_CAT_RANK[x["category"]], x["name"].lower()))

    # group into ordered category sections (only non-empty)
    groups = []
    for cat, _ in PREP_CATEGORIES:
        cat_items = [i for i in items if i["category"] == cat]
        if cat_items:
            groups.append({"category": cat, "label": _CAT_LABEL[cat], "items": cat_items})
    return groups

def build_rolling_prep(week_days, day_order):
    """Per-day cook list: each day's meals as-is, in week order."""
    out = []
    for dayname in day_order:
        day = week_days.get(dayname)
        if not day:
            continue
        slots = day.get("slots", [])
        out.append({
            "day": dayname,
            "meals": [
                {"recipe_id": s.get("recipe_id"), "name": s.get("name", "Recipe"),
                 "servings": s.get("servings", 1.0), "slot": s.get("slot", "")}
                for s in slots
            ],
        })
    return out