from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Recipe, User
from app.schemas import RecipeSummary, RecipeDetail
from app.routers.auth import get_current_user

router = APIRouter(prefix="/recipes", tags=["recipes"])


@router.get("", response_model=list[RecipeSummary])
def list_recipes(
    meal_type: str | None = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    stmt = select(Recipe)
    if meal_type:
        stmt = stmt.where(Recipe.meal_type == meal_type)
    stmt = stmt.order_by(Recipe.name)
    return db.execute(stmt).scalars().all()


@router.get("/{recipe_id}", response_model=RecipeDetail)
def get_recipe(
    recipe_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    recipe = db.get(Recipe, recipe_id)
    if recipe is None:
        raise HTTPException(404, "Recipe not found")
    return recipe