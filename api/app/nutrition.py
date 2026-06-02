"""
MacroForge nutrition calculation module.

Pure functions only — no database, no FastAPI imports. Everything here is
deterministic math that turns a user's body stats + goal into daily targets.
This is the cold-start seed; the future Adaptive Targeting Engine (design doc
Section 21) will later override these using observed weight/intake data.

All inputs are metric. Conversion from imperial happens in the Flutter layer.
"""

from datetime import date

# ─────────────────────────────────────────────────────────────────────────────
# Tunable constants. When advanced diet protocols arrive post-grad, most of
# the per-protocol variation is swapping these values, not rewriting the math.
# ─────────────────────────────────────────────────────────────────────────────

ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,        # little/no exercise
    "light": 1.375,          # light exercise 1-3 days/week
    "moderate": 1.55,        # moderate exercise 3-5 days/week
    "active": 1.725,         # hard exercise 6-7 days/week
    "very_active": 1.9,      # very hard exercise + physical job
}

# Goal -> calorie adjustment as a multiplier on TDEE.
GOAL_CALORIE_ADJUSTMENT = {
    "cut": 0.80,        # -20%
    "maintain": 1.0,
    "bulk": 1.10,       # +10%
}

# Protein target in grams per kg of bodyweight, per goal.
# Higher on a cut to preserve lean mass in a deficit.
PROTEIN_G_PER_KG = {
    "cut": 2.2,
    "maintain": 1.8,
    "bulk": 2.0,
}

# Fat as a fraction of total calories.
FAT_FRACTION_OF_CALORIES = 0.25

# Calories per gram of each macronutrient.
KCAL_PER_G_PROTEIN = 4
KCAL_PER_G_CARB = 4
KCAL_PER_G_FAT = 9

# Safety floor: carbs can't go below this even if protein+fat eat the budget.
MIN_CARB_G = 30


def calculate_age(birthdate: date, on_date: date | None = None) -> int:
    """Whole-year age derived from birthdate. Avoids storing a drifting age."""
    today = on_date or date.today()
    age = today.year - birthdate.year
    # subtract a year if this year's birthday hasn't happened yet
    if (today.month, today.day) < (birthdate.month, birthdate.day):
        age -= 1
    return age


def calculate_bmr(sex: str, weight_kg: float, height_cm: float, age: int) -> float:
    """
    Basal Metabolic Rate via Mifflin-St Jeor.
    Male:   10*kg + 6.25*cm - 5*age + 5
    Female: 10*kg + 6.25*cm - 5*age - 161
    """
    base = 10 * weight_kg + 6.25 * height_cm - 5 * age
    if sex == "male":
        return base + 5
    elif sex == "female":
        return base - 161
    else:
        # neutral offset for unspecified: midpoint of the male/female constants
        return base - 78


def calculate_tdee(bmr: float, activity_level: str) -> float:
    """Total Daily Energy Expenditure = BMR * activity multiplier."""
    multiplier = ACTIVITY_MULTIPLIERS[activity_level]
    return bmr * multiplier


def calculate_target_calories(tdee: float, goal: str) -> int:
    """Apply the goal adjustment to TDEE and round to a whole calorie."""
    return round(tdee * GOAL_CALORIE_ADJUSTMENT[goal])


def calculate_macros(target_calories: int, weight_kg: float, goal: str) -> dict:
    """
    Split calories into macro grams in priority order:
      1. Protein anchored to bodyweight (g/kg by goal)
      2. Fat as a fixed fraction of total calories
      3. Carbs absorb whatever calories remain (with a safety floor)
    Returns whole-gram values. target_calories remains the source of truth;
    macro grams are derived and may sum to within a few kcal of it.
    """
    protein_g = round(PROTEIN_G_PER_KG[goal] * weight_kg)
    fat_g = round((target_calories * FAT_FRACTION_OF_CALORIES) / KCAL_PER_G_FAT)

    protein_kcal = protein_g * KCAL_PER_G_PROTEIN
    fat_kcal = fat_g * KCAL_PER_G_FAT
    remaining_kcal = target_calories - protein_kcal - fat_kcal
    carbs_g = round(remaining_kcal / KCAL_PER_G_CARB)

    # safety floor on carbs
    if carbs_g < MIN_CARB_G:
        carbs_g = MIN_CARB_G

    return {
        "protein_g": protein_g,
        "carbs_g": carbs_g,
        "fat_g": fat_g,
    }


def calculate_targets(
    sex: str,
    birthdate: date,
    weight_kg: float,
    height_cm: float,
    activity_level: str,
    goal: str,
    on_date: date | None = None,
) -> dict:
    """
    End-to-end: from raw profile inputs to the full target set.
    This is the single function the endpoint layer calls.
    """
    age = calculate_age(birthdate, on_date)
    bmr = calculate_bmr(sex, weight_kg, height_cm, age)
    tdee = calculate_tdee(bmr, activity_level)
    target_calories = calculate_target_calories(tdee, goal)
    macros = calculate_macros(target_calories, weight_kg, goal)

    return {
        "bmr": round(bmr),
        "tdee": round(tdee),
        "target_calories": target_calories,
        "target_protein_g": macros["protein_g"],
        "target_carbs_g": macros["carbs_g"],
        "target_fat_g": macros["fat_g"],
    }