from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import ProfileUpdate, ProfileResponse
from app.routers.auth import get_current_user
from app.nutrition import calculate_targets

router = APIRouter(prefix="/profile", tags=["profile"])

VALID_SEX = {"male", "female", "unspecified"}
VALID_ACTIVITY = {"sedentary", "light", "moderate", "active", "very_active"}
VALID_GOAL = {"cut", "maintain", "bulk"}

# Default goal rate (kg/week) per goal — captured for the future adaptive engine
DEFAULT_GOAL_RATE = {"cut": -0.5, "maintain": 0.0, "bulk": 0.25}


def _build_response(user: User) -> ProfileResponse:
    complete = user.birthdate is not None and user.target_calories is not None
    return ProfileResponse(
        sex=user.sex,
        birthdate=user.birthdate,
        height_cm=float(user.height_cm) if user.height_cm is not None else None,
        current_weight_kg=float(user.current_weight_kg) if user.current_weight_kg is not None else None,
        activity_level=user.activity_level,
        goal=user.goal,
        goal_rate_kg_per_week=float(user.goal_rate_kg_per_week) if user.goal_rate_kg_per_week is not None else None,
        target_calories=user.target_calories,
        target_protein_g=user.target_protein_g,
        target_carbs_g=user.target_carbs_g,
        target_fat_g=user.target_fat_g,
        target_source=user.target_source or "formula",
        profile_complete=complete,
    )


@router.get("", response_model=ProfileResponse)
def get_profile(current_user: User = Depends(get_current_user)):
    return _build_response(current_user)


@router.put("", response_model=ProfileResponse)
def update_profile(
    payload: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # validate enums
    if payload.sex not in VALID_SEX:
        raise HTTPException(400, f"sex must be one of {sorted(VALID_SEX)}")
    if payload.activity_level not in VALID_ACTIVITY:
        raise HTTPException(400, f"activity_level must be one of {sorted(VALID_ACTIVITY)}")
    if payload.goal not in VALID_GOAL:
        raise HTTPException(400, f"goal must be one of {sorted(VALID_GOAL)}")
    if payload.height_cm <= 0 or payload.current_weight_kg <= 0:
        raise HTTPException(400, "height and weight must be positive")

    # save the inputs
    current_user.sex = payload.sex
    current_user.birthdate = payload.birthdate
    current_user.height_cm = payload.height_cm
    current_user.current_weight_kg = payload.current_weight_kg
    current_user.activity_level = payload.activity_level
    current_user.goal = payload.goal
    current_user.goal_rate_kg_per_week = DEFAULT_GOAL_RATE[payload.goal]

    # recompute targets (formula source)
    targets = calculate_targets(
        sex=payload.sex,
        birthdate=payload.birthdate,
        weight_kg=float(payload.current_weight_kg),
        height_cm=float(payload.height_cm),
        activity_level=payload.activity_level,
        goal=payload.goal,
    )
    current_user.target_calories = targets["target_calories"]
    current_user.target_protein_g = targets["target_protein_g"]
    current_user.target_carbs_g = targets["target_carbs_g"]
    current_user.target_fat_g = targets["target_fat_g"]
    current_user.target_source = "formula"

    db.commit()
    db.refresh(current_user)
    return _build_response(current_user)