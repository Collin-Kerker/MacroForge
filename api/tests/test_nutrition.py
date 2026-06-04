"""
Tests for the destination-based nutrition calculation module.
Run with: pytest   (from the api/ directory)
"""
from datetime import date
import pytest

from app.nutrition import (
    calculate_age,
    calculate_bmr,
    calculate_tdee,
    infer_direction,
    clamp_rate,
    calculate_target_calories,
    fastest_safe_rate,
    calculate_macros,
    resolve_protein_g_per_kg,
    calculate_targets,
    KCAL_PER_G_PROTEIN,
    KCAL_PER_G_CARB,
    KCAL_PER_G_FAT,
    KCAL_PER_KG,
    MIN_CARB_G,
    MAX_LOSS_RATE_KG_WK,
    RECOMP_PROTEIN_MIN,
    RECOMP_PROTEIN_MAX,
    RECOMP_PROTEIN_DEFAULT,
    PROTEIN_G_PER_KG_CUT,
    PROTEIN_G_PER_KG_BULK,
    ABSOLUTE_MIN_CALORIES,
)


# ── Age ───────────────────────────────────────────────────────────────────────
def test_age_before_birthday_this_year():
    assert calculate_age(date(1996, 12, 31), on_date=date(2026, 6, 1)) == 29

def test_age_after_birthday_this_year():
    assert calculate_age(date(1996, 1, 1), on_date=date(2026, 6, 1)) == 30

def test_age_on_exact_birthday():
    assert calculate_age(date(1996, 6, 1), on_date=date(2026, 6, 1)) == 30


# ── BMR (Mifflin-St Jeor) ──────────────────────────────────────────────────────
def test_bmr_canonical_male():
    assert calculate_bmr("male", 80, 180, 30) == 1780

def test_bmr_female_offset():
    assert calculate_bmr("female", 80, 180, 30) == 1614

def test_bmr_male_female_difference_is_166():
    m = calculate_bmr("male", 70, 170, 25)
    f = calculate_bmr("female", 70, 170, 25)
    assert m - f == 166


# ── TDEE ──────────────────────────────────────────────────────────────────────
def test_tdee_moderate():
    assert round(calculate_tdee(1780, "moderate")) == 2759

def test_activity_multipliers_monotonic():
    levels = ["sedentary", "light", "moderate", "active", "very_active"]
    tdees = [calculate_tdee(1780, lv) for lv in levels]
    assert tdees == sorted(tdees)


# ── Direction inference ────────────────────────────────────────────────────────
def test_direction_cut():
    assert infer_direction(80, 75) == "cut"

def test_direction_bulk():
    assert infer_direction(80, 85) == "bulk"

def test_direction_recomp_equal_weights():
    assert infer_direction(80, 80) == "recomp"


# ── Rate clamping ──────────────────────────────────────────────────────────────
def test_clamp_excessive_loss_rate():
    # asking 2.0 kg/wk loss clamps to max 1.0
    assert clamp_rate(2.0, "cut") == MAX_LOSS_RATE_KG_WK

def test_clamp_tiny_loss_rate_up_to_min():
    assert clamp_rate(0.05, "cut") == 0.25

def test_clamp_gain_rate_bounded():
    assert clamp_rate(2.0, "bulk") == 0.5

def test_clamp_recomp_is_zero():
    assert clamp_rate(0.5, "recomp") == 0.0


# ── Calorie offset from rate ───────────────────────────────────────────────────
def test_cut_calories_below_tdee():
    # 0.5 kg/wk loss => 550 kcal/day deficit. tdee 2759 -> ~2209
    cals, hit = calculate_target_calories(2759, 1780, "cut", 0.5)
    assert cals == round(2759 - (0.5 * KCAL_PER_KG / 7))
    assert hit is False

def test_bulk_calories_above_tdee():
    cals, hit = calculate_target_calories(2759, 1780, "bulk", 0.25)
    assert cals == round(2759 + (0.25 * KCAL_PER_KG / 7))

def test_recomp_calories_equal_tdee():
    cals, hit = calculate_target_calories(2759, 1780, "recomp", 0.0)
    assert cals == 2759

def test_calorie_floor_enforced():
    # small person, huge deficit -> floor kicks in
    cals, hit = calculate_target_calories(1500, 1400, "cut", 1.0)
    assert cals == 1400  # bmr is the floor (above absolute min 1200)
    assert hit is True

def test_floor_is_absolute_min_when_bmr_lower():
    cals, hit = calculate_target_calories(1300, 1100, "cut", 1.0)
    assert cals == ABSOLUTE_MIN_CALORIES
    assert hit is True


# ── Fastest safe rate ──────────────────────────────────────────────────────────
def test_fastest_safe_rate_reasonable():
    r = fastest_safe_rate(2759, 1780)
    assert 0 < r <= MAX_LOSS_RATE_KG_WK


# ── Protein resolution ─────────────────────────────────────────────────────────
def test_protein_cut_is_constant():
    assert resolve_protein_g_per_kg("cut") == PROTEIN_G_PER_KG_CUT

def test_protein_bulk_is_constant():
    assert resolve_protein_g_per_kg("bulk") == PROTEIN_G_PER_KG_BULK

def test_protein_recomp_uses_slider_value():
    assert resolve_protein_g_per_kg("recomp", 2.6) == 2.6

def test_protein_recomp_default_when_none():
    assert resolve_protein_g_per_kg("recomp", None) == RECOMP_PROTEIN_DEFAULT

def test_protein_recomp_clamped_high():
    assert resolve_protein_g_per_kg("recomp", 5.0) == RECOMP_PROTEIN_MAX

def test_protein_recomp_clamped_low():
    assert resolve_protein_g_per_kg("recomp", 0.5) == RECOMP_PROTEIN_MIN


# ── Macros ──────────────────────────────────────────────────────────────────────
def test_carbs_floor_enforced():
    macros = calculate_macros(800, 120, 2.2)
    assert macros["carbs_g"] >= MIN_CARB_G

def test_macros_sum_close_to_target():
    target = 2759
    macros = calculate_macros(target, 80, 1.8)
    total = (macros["protein_g"] * KCAL_PER_G_PROTEIN
             + macros["carbs_g"] * KCAL_PER_G_CARB
             + macros["fat_g"] * KCAL_PER_G_FAT)
    assert abs(total - target) <= 9

def test_higher_protein_gives_more_protein_grams():
    low = calculate_macros(2200, 80, 1.8)
    high = calculate_macros(2200, 80, 3.0)
    assert high["protein_g"] > low["protein_g"]


# ── End-to-end canonical cases ─────────────────────────────────────────────────
def test_canonical_cut_half_kg_per_week():
    """
    Male, 80kg current, 75kg goal, 180cm, age 30, moderate, 0.5 kg/wk loss.
    BMR 1780, TDEE 2759. Deficit = 0.5*7700/7 = 550/day. Target = 2209.
    Direction inferred = cut. Protein = 2.2*80 = 176g.
    """
    t = calculate_targets(
        sex="male", birthdate=date(1996, 1, 1),
        current_weight_kg=80, goal_weight_kg=75, height_cm=180,
        activity_level="moderate", rate_kg_per_week=0.5,
        on_date=date(2026, 6, 1),
    )
    assert t["bmr"] == 1780
    assert t["tdee"] == 2759
    assert t["direction"] == "cut"
    assert t["target_calories"] == 2209
    assert t["target_protein_g"] == 176

def test_canonical_recomp_default_protein():
    """
    Male, 80kg current == 80kg goal -> recomp. Maintenance calories 2759.
    Default recomp protein 2.4 * 80 = 192g.
    """
    t = calculate_targets(
        sex="male", birthdate=date(1996, 1, 1),
        current_weight_kg=80, goal_weight_kg=80, height_cm=180,
        activity_level="moderate", rate_kg_per_week=0.0,
        on_date=date(2026, 6, 1),
    )
    assert t["direction"] == "recomp"
    assert t["target_calories"] == 2759
    assert t["target_protein_g"] == 192  # 2.4 * 80

def test_canonical_recomp_high_protein_slider():
    """Recomp with slider pushed to 3.0 g/kg -> 240g protein."""
    t = calculate_targets(
        sex="male", birthdate=date(1996, 1, 1),
        current_weight_kg=80, goal_weight_kg=80, height_cm=180,
        activity_level="moderate", rate_kg_per_week=0.0,
        recomp_protein_g_per_kg=3.0,
        on_date=date(2026, 6, 1),
    )
    assert t["target_protein_g"] == 240

def test_targets_dict_has_all_keys():
    t = calculate_targets(
        sex="female", birthdate=date(2000, 5, 15),
        current_weight_kg=65, goal_weight_kg=60, height_cm=165,
        activity_level="light", rate_kg_per_week=0.5,
        on_date=date(2026, 6, 1),
    )
    for key in ["bmr", "tdee", "direction", "clamped_rate_kg_per_week",
                "hit_calorie_floor", "fastest_safe_rate_kg_per_week",
                "target_calories", "target_protein_g", "target_carbs_g",
                "target_fat_g", "protein_g_per_kg_used"]:
        assert key in t