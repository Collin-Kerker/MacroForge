from datetime import datetime, date
from uuid import UUID
from pydantic import BaseModel, EmailStr, ConfigDict, field_validator
from typing import Any


# ── Request schemas (data coming IN) ──────────────────────────
class UserRegister(BaseModel):
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


# ── Response schemas (data going OUT) ─────────────────────────
class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    created_at: datetime


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


# ── Internal: decoded token contents ──────────────────────────
class TokenData(BaseModel):
    user_id: str | None = None


# ── Profile request (PUT /profile body) ──────────────────────
class ProfileUpdate(BaseModel):
    sex: str
    birthdate: date
    height_cm: float
    current_weight_kg: float
    goal_weight_kg: float
    activity_level: str
    rate_kg_per_week: float = 0.0
    recomp_protein_g_per_kg: float | None = None
    prep_cadence: str = "batch"
    prep_day: int = 6


class PrepUpdate(BaseModel):
    prep_cadence: str
    prep_day: int


# ── Profile response (GET /profile) ──────────────────────────
class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    sex: str | None = None
    birthdate: date | None = None
    height_cm: float | None = None
    current_weight_kg: float | None = None
    goal_weight_kg: float | None = None
    activity_level: str | None = None
    goal: str | None = None
    goal_rate_kg_per_week: float | None = None

    target_calories: int | None = None
    target_protein_g: int | None = None
    target_carbs_g: int | None = None
    target_fat_g: int | None = None
    target_source: str = "formula"

    hit_calorie_floor: bool = False
    fastest_safe_rate_kg_per_week: float | None = None

    profile_complete: bool = False

    prep_cadence: str | None = None
    prep_day: int | None = None


class FoodItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    description: str
    kcal_per_100g: float | None = None
    protein_per_100g: float | None = None
    carbs_per_100g: float | None = None
    fat_per_100g: float | None = None


# ── Food Log schemas ──────────────────────────
class FoodLogCreate(BaseModel):
    food_item_id: int
    grams: float
    log_date: date | None = None


class FoodLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    food_item_id: int | None = None
    recipe_id: UUID | None = None
    source: str = "usda"
    log_date: date
    grams: float | None = None
    description: str
    kcal: float
    protein_g: float
    carbs_g: float
    fat_g: float


class DayLogResponse(BaseModel):
    log_date: date
    entries: list[FoodLogResponse]
    total_kcal: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float


class RecipeSummary(BaseModel):
    """Lightweight version for the browse list."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None = None
    meal_type: str | None = None
    prep_minutes: int | None = None
    kcal_per_serving: int
    protein_g_per_serving: int
    carbs_g_per_serving: int
    fat_g_per_serving: int


class RecipeDetail(BaseModel):
    """Full version for the recipe detail view."""
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None = None
    meal_type: str | None = None
    servings: int
    prep_minutes: int | None = None
    ingredients: Any
    steps: Any
    kcal_per_serving: int
    protein_g_per_serving: int
    carbs_g_per_serving: int
    fat_g_per_serving: int


class SolveRequest(BaseModel):
    include_snack: bool = True
    exclude_recipe_ids: list[UUID] = []   # for "regenerate" variety


class SolvedSlot(BaseModel):
    slot: str
    recipe_id: UUID
    name: str
    servings: float
    kcal: int
    protein: int
    carbs: int
    fat: int


class SolveResponse(BaseModel):
    feasible: bool
    reason: str | None = None
    slots: list[SolvedSlot] = []
    totals: dict | None = None
    targets: dict | None = None
    deviation: dict | None = None


class SolveRequest(BaseModel):
    include_snack: bool = True
    exclude_recipe_ids: list[UUID] = []
    meal_structure: list[str] | None = None   # if set, overrides the default structure


# valid meal-type slots a user can place in a day
VALID_MEAL_TYPES = {"breakfast", "lunch", "dinner", "snack", "dessert"}
DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]


class MealPlanResponse(BaseModel):
    structure: dict   # {"mon": [...], ...}


class MealPlanUpdate(BaseModel):
    structure: dict

    @field_validator("structure")
    @classmethod
    def validate_structure(cls, v):
        # must have all 7 days, each a list of valid meal types
        for day in DAYS:
            if day not in v:
                raise ValueError(f"Missing day: {day}")
            if not isinstance(v[day], list):
                raise ValueError(f"{day} must be a list of meal types")
            for slot in v[day]:
                if slot not in VALID_MEAL_TYPES:
                    raise ValueError(f"Invalid meal type '{slot}' in {day}")
            if len(v[day]) > 8:
                raise ValueError(f"{day} has too many slots (max 8)")
        # reject unexpected keys
        for key in v:
            if key not in DAYS:
                raise ValueError(f"Unexpected day key: {key}")
        return v
    

class GeneratedPlanResponse(BaseModel):
    week: dict                 # {"days": {...}, "week_totals": {...}}
    generated_at: datetime | None = None


class DayRegenRequest(BaseModel):
    structure: list[str] | None = None


class SlotLockRequest(BaseModel):
    slot_index: int
    locked: bool


class CookRequest(BaseModel):
    slot_index: int