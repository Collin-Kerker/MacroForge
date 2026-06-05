from datetime import date as date_type
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import FoodItem, FoodLog, User
from app.schemas import FoodLogCreate, FoodLogResponse, DayLogResponse
from app.routers.auth import get_current_user

router = APIRouter(prefix="/logs", tags=["logs"])


@router.post("", response_model=FoodLogResponse, status_code=201)
def create_log(
    payload: FoodLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.grams <= 0:
        raise HTTPException(400, "grams must be positive")

    food = db.get(FoodItem, payload.food_item_id)
    if food is None:
        raise HTTPException(404, "Food not found")
    if food.kcal_per_100g is None:
        raise HTTPException(400, "This food has no nutrition data")

    factor = float(payload.grams) / 100.0  # macros are per 100g
    entry = FoodLog(
        user_id=current_user.id,
        food_item_id=food.id,
        log_date=payload.log_date or date_type.today(),
        grams=payload.grams,
        description=food.description,
        kcal=round(float(food.kcal_per_100g) * factor, 1),
        protein_g=round(float(food.protein_per_100g or 0) * factor, 1),
        carbs_g=round(float(food.carbs_per_100g or 0) * factor, 1),
        fat_g=round(float(food.fat_per_100g or 0) * factor, 1),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("", response_model=DayLogResponse)
def get_day_log(
    log_date: date_type | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    day = log_date or date_type.today()
    stmt = (
        select(FoodLog)
        .where(FoodLog.user_id == current_user.id, FoodLog.log_date == day)
        .order_by(FoodLog.created_at)
    )
    entries = db.execute(stmt).scalars().all()

    return DayLogResponse(
        log_date=day,
        entries=entries,
        total_kcal=round(sum(float(e.kcal) for e in entries), 1),
        total_protein_g=round(sum(float(e.protein_g) for e in entries), 1),
        total_carbs_g=round(sum(float(e.carbs_g) for e in entries), 1),
        total_fat_g=round(sum(float(e.fat_g) for e in entries), 1),
    )


@router.delete("/{log_id}", status_code=204)
def delete_log(
    log_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    entry = db.get(FoodLog, log_id)
    if entry is None or entry.user_id != current_user.id:
        raise HTTPException(404, "Log entry not found")
    db.delete(entry)
    db.commit()
    return None