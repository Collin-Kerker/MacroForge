from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import MealPlan, User
from app.schemas import MealPlanResponse, MealPlanUpdate, DAYS
from app.routers.auth import get_current_user

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