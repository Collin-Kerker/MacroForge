"""Tests for the meal solver. Run with pytest from api/."""
import pytest
from app.solver import solve_day, SERVING_SIZES

# Small fixed recipe pool for deterministic testing.
RECIPES = [
    {"id": 1, "name": "Big Breakfast", "meal_type": "breakfast", "kcal": 400, "protein": 30, "carbs": 40, "fat": 12},
    {"id": 2, "name": "Light Breakfast", "meal_type": "breakfast", "kcal": 200, "protein": 15, "carbs": 20, "fat": 6},
    {"id": 3, "name": "Big Lunch", "meal_type": "lunch", "kcal": 600, "protein": 45, "carbs": 50, "fat": 20},
    {"id": 4, "name": "Light Lunch", "meal_type": "lunch", "kcal": 300, "protein": 25, "carbs": 20, "fat": 10},
    {"id": 5, "name": "Big Dinner", "meal_type": "dinner", "kcal": 700, "protein": 50, "carbs": 60, "fat": 25},
    {"id": 6, "name": "Light Dinner", "meal_type": "dinner", "kcal": 400, "protein": 35, "carbs": 30, "fat": 12},
    {"id": 7, "name": "Protein Snack", "meal_type": "snack", "kcal": 200, "protein": 25, "carbs": 10, "fat": 5},
    {"id": 8, "name": "Carb Snack", "meal_type": "snack", "kcal": 250, "protein": 5, "carbs": 40, "fat": 8},
]


def test_feasible_basic():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    assert res["feasible"]
    assert len(res["slots"]) == 3


def test_one_recipe_per_required_slot():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    slots_used = [s["slot"] for s in res["slots"]]
    assert sorted(slots_used) == ["breakfast", "dinner", "lunch"]


def test_slots_match_their_meal_type():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    by_id = {r["id"]: r for r in RECIPES}
    for s in res["slots"]:
        assert by_id[s["recipe_id"]]["meal_type"] == s["slot"]


def test_servings_are_allowed_sizes():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    for s in res["slots"]:
        assert s["servings"] in SERVING_SIZES


def test_optional_snack_can_be_omitted():
    # Tiny target reachable without a snack -> snack should be skippable.
    res = solve_day(900, 70, 70, 28, ["breakfast", "lunch", "dinner", "snack"],
                    RECIPES, optional_slots={"snack"})
    assert res["feasible"]
    # required slots always present
    required = [s for s in res["slots"] if s["slot"] != "snack"]
    assert len(required) == 3


def test_totals_match_sum_of_slots():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    summed = {"kcal": 0, "protein": 0, "carbs": 0, "fat": 0}
    for s in res["slots"]:
        for k in summed:
            summed[k] += s[k]
    assert res["totals"] == summed


def test_deviation_is_signed_correctly():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    for k in ["kcal", "protein", "carbs", "fat"]:
        assert res["deviation"][k] == res["totals"][k] - res["targets"][k]


def test_exclude_changes_result():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    used = {s["recipe_id"] for s in res["slots"]}
    res2 = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"],
                     RECIPES, exclude_recipe_ids=used)
    used2 = {s["recipe_id"] for s in res2["slots"]}
    # none of the originally-used recipes should reappear
    assert used.isdisjoint(used2)


def test_infeasible_when_no_recipes_for_required_slot():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dessert"], RECIPES)
    assert res["feasible"] is False


def test_protein_priority_hits_protein_close():
    # Solver weights protein heavily; it should land protein near target.
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    assert abs(res["deviation"]["protein"]) <= 20


def test_lands_reasonably_close_overall():
    res = solve_day(1700, 130, 130, 50, ["breakfast", "lunch", "dinner"], RECIPES)
    # calories within ~10% of a feasible target
    assert abs(res["deviation"]["kcal"]) <= 200