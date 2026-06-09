from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Recipe, User
from app.schemas import SolveRequest, SolveResponse
from app.routers.auth import get_current_user
from app.solver import solve_day

router = APIRouter(prefix="/solve", tags=["solve"])

# The fixed default meal structure. The future drag-and-drop planner will
# replace this with a user-defined structure; the solver already accepts it.
DEFAULT_STRUCTURE = ["breakfast", "lunch", "dinner", "snack"]


@router.post("", response_model=SolveResponse)
def solve(
    payload: SolveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Need the user's computed targets.
    if current_user.target_calories is None:
        raise HTTPException(400, "Complete your profile first to generate a day.")

    # Load all recipes, convert to the plain dicts the solver expects.
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

    structure = ["breakfast", "lunch", "dinner"]
    optional = set()
    if payload.include_snack:
        structure.append("snack")
        optional = {"snack"}

    result = solve_day(
        target_kcal=current_user.target_calories,
        target_protein=current_user.target_protein_g,
        target_carbs=current_user.target_carbs_g,
        target_fat=current_user.target_fat_g,
        meal_structure=structure,
        recipes=recipes,
        optional_slots=optional,
        exclude_recipe_ids={str(rid) for rid in payload.exclude_recipe_ids},
    )

    if not result["feasible"]:
        return SolveResponse(feasible=False, reason=result.get("reason"))

    return SolveResponse(
        feasible=True,
        slots=result["slots"],
        totals=result["totals"],
        targets=result["targets"],
        deviation=result["deviation"],
    )