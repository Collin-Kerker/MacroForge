"""
MacroForge nutrition calculation module.

Pure functions only — no database, no FastAPI imports. Turns a user's body
stats + destination goal into daily targets. This is the cold-start seed; the
future Adaptive Targeting Engine (design doc Section 21) will later override
these using observed weight/intake data.

GOAL MODEL (destination-based):
  The user states where they want to end up and how fast:
    - current_weight_kg  (where they are)
    - goal_weight_kg     (where they want to be)
    - rate_kg_per_week   (how fast; magnitude, always >= 0)
  Direction is INFERRED:  goal < current = cut, goal > current = bulk,
  goal == current = recomp/maintain.
  The rate converts to a calorie offset via energy balance (~7700 kcal/kg).

  For the recomp case (goal == current), the user also chooses a protein
  level via a slider (PROTEIN_G_PER_KG range), since calories are at
  maintenance and protein is the lever that matters.

All inputs are metric. Imperial conversion happens in the Flutter layer.
"""

from datetime import date

# ─────────────────────────────────────────────────────────────────────────────
# Tunable constants.
# ─────────────────────────────────────────────────────────────────────────────

ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}

# Energy balance: kcal equivalent of 1 kg of bodyweight change.
KCAL_PER_KG = 7700

# Safe rate bounds (kg/week), by direction. Rates outside these get clamped.
MAX_LOSS_RATE_KG_WK = 1.0
MIN_LOSS_RATE_KG_WK = 0.25
MAX_GAIN_RATE_KG_WK = 0.5
MIN_GAIN_RATE_KG_WK = 0.1

# Default protein (g/kg bodyweight) for directional goals (cut/bulk).
# Cut runs higher to preserve lean mass in a deficit.
PROTEIN_G_PER_KG_CUT = 2.2
PROTEIN_G_PER_KG_BULK = 2.0

# Recomp protein slider range (g/kg). User picks within this; label snaps to band.
RECOMP_PROTEIN_MIN = 1.8
RECOMP_PROTEIN_MAX = 3.0
RECOMP_PROTEIN_DEFAULT = 2.4

# Fat as a fraction of total calories.
FAT_FRACTION_OF_CALORIES = 0.25

KCAL_PER_G_PROTEIN = 4
KCAL_PER_G_CARB = 4
KCAL_PER_G_FAT = 9

MIN_CARB_G = 30

# Safety: never set target calories below this absolute floor or below BMR.
ABSOLUTE_MIN_CALORIES = 1200


def calculate_age(birthdate: date, on_date: date | None = None) -> int:
    today = on_date or date.today()
    age = today.year - birthdate.year
    if (today.month, today.day) < (birthdate.month, birthdate.day):
        age -= 1
    return age


def calculate_bmr(sex: str, weight_kg: float, height_cm: float, age: int) -> float:
    base = 10 * weight_kg + 6.25 * height_cm - 5 * age
    if sex == "male":
        return base + 5
    elif sex == "female":
        return base - 161
    else:
        return base - 78


def calculate_tdee(bmr: float, activity_level: str) -> float:
    return bmr * ACTIVITY_MULTIPLIERS[activity_level]


def infer_direction(current_weight_kg: float, goal_weight_kg: float) -> str:
    """cut | bulk | recomp, inferred from the two weights."""
    if goal_weight_kg < current_weight_kg:
        return "cut"
    elif goal_weight_kg > current_weight_kg:
        return "bulk"
    else:
        return "recomp"


def clamp_rate(rate_kg_per_week: float, direction: str) -> float:
    """Clamp a (magnitude) rate into the safe band for its direction."""
    r = abs(rate_kg_per_week)
    if direction == "cut":
        return max(MIN_LOSS_RATE_KG_WK, min(MAX_LOSS_RATE_KG_WK, r))
    elif direction == "bulk":
        return max(MIN_GAIN_RATE_KG_WK, min(MAX_GAIN_RATE_KG_WK, r))
    else:  # recomp
        return 0.0


def calculate_target_calories(
    tdee: float,
    bmr: float,
    direction: str,
    rate_kg_per_week: float,
) -> tuple[int, bool]:
    """
    Apply the rate-derived calorie offset to TDEE.
    Returns (target_calories, hit_floor) where hit_floor is True if the
    safety floor had to override the requested rate.
    """
    daily_offset = (rate_kg_per_week * KCAL_PER_KG) / 7  # kcal/day

    if direction == "cut":
        target = tdee - daily_offset
    elif direction == "bulk":
        target = tdee + daily_offset
    else:  # recomp -> maintenance
        target = tdee

    floor = max(ABSOLUTE_MIN_CALORIES, bmr)
    hit_floor = False
    if target < floor:
        target = floor
        hit_floor = True

    return round(target), hit_floor


def fastest_safe_rate(tdee: float, bmr: float) -> float:
    """
    For a cut, the fastest rate that doesn't breach the calorie floor.
    Used to tell the user 'the fastest safe rate for you is X'.
    """
    floor = max(ABSOLUTE_MIN_CALORIES, bmr)
    max_daily_deficit = tdee - floor
    if max_daily_deficit <= 0:
        return 0.0
    rate = (max_daily_deficit * 7) / KCAL_PER_KG
    return min(rate, MAX_LOSS_RATE_KG_WK)


def calculate_macros(
    target_calories: int,
    weight_kg: float,
    protein_g_per_kg: float,
) -> dict:
    """
    Split calories into macro grams:
      1. Protein = protein_g_per_kg * bodyweight
      2. Fat = fixed fraction of calories
      3. Carbs absorb the remainder (with a floor)
    """
    protein_g = round(protein_g_per_kg * weight_kg)
    fat_g = round((target_calories * FAT_FRACTION_OF_CALORIES) / KCAL_PER_G_FAT)

    protein_kcal = protein_g * KCAL_PER_G_PROTEIN
    fat_kcal = fat_g * KCAL_PER_G_FAT
    remaining_kcal = target_calories - protein_kcal - fat_kcal
    carbs_g = round(remaining_kcal / KCAL_PER_G_CARB)

    if carbs_g < MIN_CARB_G:
        carbs_g = MIN_CARB_G

    return {"protein_g": protein_g, "carbs_g": carbs_g, "fat_g": fat_g}


def resolve_protein_g_per_kg(
    direction: str,
    recomp_protein_g_per_kg: float | None = None,
) -> float:
    """
    Pick the protein g/kg for the goal:
      - cut/bulk: auto-set from constants
      - recomp:   use the user's slider value (clamped), default if None
    """
    if direction == "cut":
        return PROTEIN_G_PER_KG_CUT
    elif direction == "bulk":
        return PROTEIN_G_PER_KG_BULK
    else:  # recomp
        val = recomp_protein_g_per_kg if recomp_protein_g_per_kg is not None else RECOMP_PROTEIN_DEFAULT
        return max(RECOMP_PROTEIN_MIN, min(RECOMP_PROTEIN_MAX, val))


def calculate_targets(
    sex: str,
    birthdate: date,
    current_weight_kg: float,
    goal_weight_kg: float,
    height_cm: float,
    activity_level: str,
    rate_kg_per_week: float,
    recomp_protein_g_per_kg: float | None = None,
    on_date: date | None = None,
) -> dict:
    """
    End-to-end: raw destination-based inputs -> full target set.
    The single function the endpoint layer calls.
    """
    age = calculate_age(birthdate, on_date)
    bmr = calculate_bmr(sex, current_weight_kg, height_cm, age)
    tdee = calculate_tdee(bmr, activity_level)

    direction = infer_direction(current_weight_kg, goal_weight_kg)
    clamped_rate = clamp_rate(rate_kg_per_week, direction)

    target_calories, hit_floor = calculate_target_calories(tdee, bmr, direction, clamped_rate)

    protein_g_per_kg = resolve_protein_g_per_kg(direction, recomp_protein_g_per_kg)
    macros = calculate_macros(target_calories, current_weight_kg, protein_g_per_kg)

    return {
        "bmr": round(bmr),
        "tdee": round(tdee),
        "direction": direction,
        "clamped_rate_kg_per_week": clamped_rate,
        "hit_calorie_floor": hit_floor,
        "fastest_safe_rate_kg_per_week": round(fastest_safe_rate(tdee, bmr), 2),
        "target_calories": target_calories,
        "target_protein_g": macros["protein_g"],
        "target_carbs_g": macros["carbs_g"],
        "target_fat_g": macros["fat_g"],
        "protein_g_per_kg_used": protein_g_per_kg,
    }