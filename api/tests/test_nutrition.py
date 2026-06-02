"""
Tests for the nutrition calculation module.
Run with: pytest   (from the api/ directory)
"""

from datetime import date
import pytest

from app.nutrition import (
    calculate_age,
    calculate_bmr,
    calculate_tdee,
    calculate_target_calories,
    calculate_macros,
    calculate_targets,
    KCAL_PER_G_PROTEIN,
    KCAL_PER_G_CARB,
    KCAL_PER_G_FAT,
    MIN_CARB_G,
)


# ── Age ───────────────────────────────────────────────────────────────────────
def test_age_before_birthday_this_year():
    # born Dec 31, evaluated mid-year -> hasn't had birthday yet
    age = calculate_age(date(1996, 12, 31), on_date=date(2026, 6, 1))
    assert age == 29

def test_age_after_birthday_this_year():
    age = calculate_age(date(1996, 1, 1), on_date=date(2026, 6, 1))
    assert age == 30

def test_age_on_exact_birthday():
    age = calculate_age(date(1996, 6, 1), on_date=date(2026, 6, 1))
    assert age == 30


# ── BMR (Mifflin-St Jeor) ──────────────────────────────────────────────────────
def test_bmr_canonical_male():
    # 80kg, 180cm, age 30, male: 10*80 + 6.25*180 - 5*30 + 5 = 1780
    assert calculate_bmr("male", 80, 180, 30) == 1780

def test_bmr_female_offset():
    # same body, female: 1780 - 5 - 161 = ... base = 800+1125-150 = 1775; -161 = 1614
    assert calculate_bmr("female", 80, 180, 30) == 1614

def test_bmr_male_female_difference_is_166():
    m = calculate_bmr("male", 70, 170, 25)
    f = calculate_bmr("female", 70, 170, 25)
    assert m - f == 166  # (+5) - (-161)


# ── TDEE / activity multipliers ────────────────────────────────────────────────
def test_tdee_moderate():
    # BMR 1780 * 1.55 = 2759
    assert round(calculate_tdee(1780, "moderate")) == 2759

def test_activity_multipliers_are_monotonic():
    levels = ["sedentary", "light", "moderate", "active", "very_active"]
    tdees = [calculate_tdee(1780, lv) for lv in levels]
    assert tdees == sorted(tdees)  # strictly increasing


# ── Goal calorie adjustment ────────────────────────────────────────────────────
def test_cut_is_below_maintain_below_bulk():
    tdee = 2759
    cut = calculate_target_calories(tdee, "cut")
    maintain = calculate_target_calories(tdee, "maintain")
    bulk = calculate_target_calories(tdee, "bulk")
    assert cut < maintain < bulk

def test_maintain_equals_tdee():
    assert calculate_target_calories(2759, "maintain") == 2759


# ── Macros ──────────────────────────────────────────────────────────────────────
def test_protein_higher_on_cut_than_maintain():
    cut = calculate_macros(2000, 80, "cut")
    maintain = calculate_macros(2000, 80, "maintain")
    assert cut["protein_g"] > maintain["protein_g"]

def test_carbs_floor_enforced():
    # tiny calorie target with heavy person -> protein+fat would eat everything
    macros = calculate_macros(800, 120, "cut")
    assert macros["carbs_g"] >= MIN_CARB_G

def test_macros_sum_close_to_target():
    target = 2759
    macros = calculate_macros(target, 80, "maintain")
    total = (
        macros["protein_g"] * KCAL_PER_G_PROTEIN
        + macros["carbs_g"] * KCAL_PER_G_CARB
        + macros["fat_g"] * KCAL_PER_G_FAT
    )
    # rounding to whole grams means it won't be exact, but must be very close
    assert abs(total - target) <= 9


# ── End-to-end canonical case ──────────────────────────────────────────────────
def test_canonical_full_targets():
    """
    Hand-verifiable: male, 80kg, 180cm, age 30, moderate, maintain.
    BMR = 1780, TDEE = 1780*1.55 = 2759, maintain so calories = 2759.
    protein = 1.8 * 80 = 144g
    fat = 25% of 2759 / 9 = 689.75/9 = 76.6 -> 77g
    """
    targets = calculate_targets(
        sex="male",
        birthdate=date(1996, 1, 1),
        weight_kg=80,
        height_cm=180,
        activity_level="moderate",
        goal="maintain",
        on_date=date(2026, 6, 1),
    )
    assert targets["bmr"] == 1780
    assert targets["tdee"] == 2759
    assert targets["target_calories"] == 2759
    assert targets["target_protein_g"] == 144
    assert targets["target_fat_g"] == 77

def test_targets_dict_has_all_keys():
    targets = calculate_targets(
        sex="female",
        birthdate=date(2000, 5, 15),
        weight_kg=65,
        height_cm=165,
        activity_level="light",
        goal="cut",
        on_date=date(2026, 6, 1),
    )
    for key in ["bmr", "tdee", "target_calories",
                "target_protein_g", "target_carbs_g", "target_fat_g"]:
        assert key in targets
        assert targets[key] > 0