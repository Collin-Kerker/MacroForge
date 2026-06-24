from sqlalchemy import select
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import MealPlan, User
from app.routers.auth import get_current_user
from fastapi import APIRouter, Depends, HTTPException
from app.models import MealPlan, GeneratedPlan, Recipe, User
from app.schemas import (
    MealPlanResponse, MealPlanUpdate, GeneratedPlanResponse, DAYS,
)
from app.solver import solve_week
from app.grocery import build_grocery_list
from app.prep import build_batch_prep, build_rolling_prep

router = APIRouter(prefix="/meal-plan", tags=["meal-plan"])

# default week: breakfast, lunch, dinner every day
def _default_structure():
    return {day: ["breakfast", "lunch", "dinner"] for day in DAYS}


@router.get("", response_model=MealPlanResponse)
def get_meal_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    plan = db.execute(
        select(MealPlan).where(MealPlan.user_id == current_user.id)
    ).scalar_one_or_none()

    if plan is None:
        # lazily create a default plan on first access
        plan = MealPlan(user_id=current_user.id, structure=_default_structure())
        db.add(plan)
        db.commit()
        db.refresh(plan)

    return MealPlanResponse(structure=plan.structure)


@router.put("", response_model=MealPlanResponse)
def update_meal_plan(
    payload: MealPlanUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    plan = db.execute(
        select(MealPlan).where(MealPlan.user_id == current_user.id)
    ).scalar_one_or_none()

    if plan is None:
        plan = MealPlan(user_id=current_user.id, structure=payload.structure)
        db.add(plan)
    else:
        plan.structure = payload.structure

    db.commit()
    db.refresh(plan)
    return MealPlanResponse(structure=plan.structure)


@router.post("/generate", response_model=GeneratedPlanResponse)
def generate_week(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.target_calories is None:
        raise HTTPException(400, "Complete your profile first to generate a week.")

    # Load the user's saved structure (lazily create default if none yet).
    plan = db.execute(
        select(MealPlan).where(MealPlan.user_id == current_user.id)
    ).scalar_one_or_none()
    if plan is None:
        plan = MealPlan(user_id=current_user.id, structure=_default_structure())
        db.add(plan)
        db.commit()
        db.refresh(plan)

    # Load recipe pool as plain dicts for the solver.
    recipes_db = db.execute(select(Recipe)).scalars().all()
    recipes = [
        {
            "id": str(r.id),
            "name": r.name,
            "meal_type": r.meal_type,
            "kcal": r.kcal_per_serving,
            "protein": r.protein_g_per_serving,
            "carbs": r.carbs_g_per_serving,
            "fat": r.fat_g_per_serving,
        }
        for r in recipes_db
    ]


    prior = db.execute(
        select(GeneratedPlan).where(GeneratedPlan.user_id == current_user.id)
    ).scalar_one_or_none()
    exclude_ids = set()
    if prior is not None:
        for day in prior.week.get("days", {}).values():
            for slot in day.get("slots", []):
                if slot.get("recipe_id"):
                    exclude_ids.add(slot["recipe_id"])

    week = solve_week(
        target_kcal=current_user.target_calories,
        target_protein=current_user.target_protein_g,
        target_carbs=current_user.target_carbs_g,
        target_fat=current_user.target_fat_g,
        structure=plan.structure,
        recipes=recipes,
        exclude_recipe_ids=exclude_ids,
    )


    # Persist (overwrite any prior generated plan for this user).
    gen = db.execute(
        select(GeneratedPlan).where(GeneratedPlan.user_id == current_user.id)
    ).scalar_one_or_none()
    if gen is None:
        gen = GeneratedPlan(user_id=current_user.id, week=week)
        db.add(gen)
    else:
        gen.week = week
    db.commit()
    db.refresh(gen)

    return GeneratedPlanResponse(week=gen.week, generated_at=gen.generated_at)


@router.get("/generated", response_model=GeneratedPlanResponse)
def get_generated_week(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    gen = db.execute(
        select(GeneratedPlan).where(GeneratedPlan.user_id == current_user.id)
    ).scalar_one_or_none()
    if gen is None:
        raise HTTPException(404, "No generated week yet. Generate one first.")
    return GeneratedPlanResponse(week=gen.week, generated_at=gen.generated_at)


@router.get("/grocery-list")
def get_grocery_list(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Need a generated week to shop for.
    gen = db.execute(
        select(GeneratedPlan).where(GeneratedPlan.user_id == current_user.id)
    ).scalar_one_or_none()
    if gen is None:
        raise HTTPException(404, "Generate a week first to build a grocery list.")

    # The saved week stores recipe IDs per slot, not ingredients. Pull every
    # recipe used in the week, then look up its ingredients.
    recipe_ids = set()
    for day in gen.week.get("days", {}).values():
        for slot in day.get("slots", []):
            if slot.get("recipe_id"):
                recipe_ids.add(slot["recipe_id"])

    if not recipe_ids:
        return {"sections": []}

    recipes = db.execute(
        select(Recipe).where(Recipe.id.in_(recipe_ids))
    ).scalars().all()
    ingredients_by_recipe = {str(r.id): r.ingredients for r in recipes}

    # Build the (item, amount, servings) list across the whole week, scaling
    # each recipe's ingredients by the servings the solver chose for that slot.
    items = []
    for day in gen.week.get("days", {}).values():
        for slot in day.get("slots", []):
            rid = slot.get("recipe_id")
            servings = slot.get("servings", 1.0)
            for ing in ingredients_by_recipe.get(rid, []):
                items.append((ing["item"], ing["amount"], servings))

    sections = build_grocery_list(items)
    return {"sections": sections}


WEEK_ORDER = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]


@router.get("/prep-plan")
def get_prep_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    gen = db.execute(
        select(GeneratedPlan).where(GeneratedPlan.user_id == current_user.id)
    ).scalar_one_or_none()
    if gen is None:
        raise HTTPException(404, "Generate a week first to build a prep plan.")

    days = gen.week.get("days", {})
    cadence = current_user.prep_cadence or "batch"

    if cadence == "batch":
        return {
            "cadence": "batch",
            "prep_day": current_user.prep_day,
            "groups": build_batch_prep(days),
        }
    else:
        return {
            "cadence": "rolling",
            "days": build_rolling_prep(days, WEEK_ORDER),
        }