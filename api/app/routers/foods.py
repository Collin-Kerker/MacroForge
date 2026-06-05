from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import FoodItem, User
from app.schemas import FoodItemResponse
from app.routers.auth import get_current_user

router = APIRouter(prefix="/foods", tags=["foods"])


@router.get("/search", response_model=list[FoodItemResponse])
def search_foods(
    q: str = Query(..., min_length=2, description="Search text"),
    limit: int = Query(20, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    term = q.strip().lower()

    # Only return foods that actually have calorie data
    base = select(FoodItem).where(FoodItem.kcal_per_100g.isnot(None))

    # Rank: exact-ish prefix matches first, then any substring match.
    # ILIKE is case-insensitive contains.
    stmt = (
        base.where(FoodItem.description.ilike(f"%{term}%"))
        .order_by(
            # foods whose description STARTS with the term rank first
            func.lower(FoodItem.description).like(f"{term}%").desc(),
            func.length(FoodItem.description),  # shorter = more generic = better
        )
        .limit(limit)
    )

    results = db.execute(stmt).scalars().all()
    return results


@router.get("/{food_id}", response_model=FoodItemResponse)
def get_food(
    food_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    food = db.get(FoodItem, food_id)
    if food is None:
        from fastapi import HTTPException
        raise HTTPException(404, "Food not found")
    return food