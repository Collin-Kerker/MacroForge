from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import ProfileUpdate, ProfileResponse
from app.routers.auth import get_current_user
from app.nutrition import calculate_targets

router = APIRouter(prefix="/profile", tags=["profile"])

VALID_SEX = {"male", "female", "unspecified"}
VALID_ACTIVITY = {"sedentary", "light", "moderate", "active", "very_active"}


def _build_response(user: User) -> ProfileResponse:
    complete = user.birthdate is not None and user.target_calories is not None
    return ProfileResponse(
        sex=user.sex,
        birthdate=user.birthdate,
        height_cm=float(user.height_cm) if user.height_cm is not None else None,
        current_weight_kg=float(user.current_weight_kg) if user.current_weight_kg is not None else None,
        goal_weight_kg=float(user.goal_weight_kg) if user.goal_weight_kg is not None else None,
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
    if payload.sex not in VALID_SEX:
        raise HTTPException(400, f"sex must be one of {sorted(VALID_SEX)}")
    if payload.activity_level not in VALID_ACTIVITY:
        raise HTTPException(400, f"activity_level must be one of {sorted(VALID_ACTIVITY)}")
    if payload.height_cm <= 0 or payload.current_weight_kg <= 0 or payload.goal_weight_kg <= 0:
        raise HTTPException(400, "height and weights must be positive")

    result = calculate_targets(
        sex=payload.sex,
        birthdate=payload.birthdate,
        current_weight_kg=float(payload.current_weight_kg),
        goal_weight_kg=float(payload.goal_weight_kg),
        height_cm=float(payload.height_cm),
        activity_level=payload.activity_level,
        rate_kg_per_week=float(payload.rate_kg_per_week),
        recomp_protein_g_per_kg=payload.recomp_protein_g_per_kg,
    )

    # save inputs
    current_user.sex = payload.sex
    current_user.birthdate = payload.birthdate
    current_user.height_cm = payload.height_cm
    current_user.current_weight_kg = payload.current_weight_kg
    current_user.goal_weight_kg = payload.goal_weight_kg
    current_user.activity_level = payload.activity_level
    current_user.activity_level = payload.activity_level
    current_user.prep_cadence = payload.prep_cadence
    current_user.prep_day = payload.prep_day
    current_user.goal = result["direction"]  # inferred cut/bulk/recomp
    # store the signed rate: negative for cut, positive for bulk, 0 recomp
    signed_rate = result["clamped_rate_kg_per_week"]
    if result["direction"] == "cut":
        signed_rate = -signed_rate
    current_user.goal_rate_kg_per_week = signed_rate

    # save computed targets
    current_user.target_calories = result["target_calories"]
    current_user.target_protein_g = result["target_protein_g"]
    current_user.target_carbs_g = result["target_carbs_g"]
    current_user.target_fat_g = result["target_fat_g"]
    current_user.target_source = "formula"

    db.commit()
    db.refresh(current_user)

    response = _build_response(current_user)
    response.hit_calorie_floor = result["hit_calorie_floor"]
    response.fastest_safe_rate_kg_per_week = result["fastest_safe_rate_kg_per_week"]
    return response