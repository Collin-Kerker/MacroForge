from datetime import datetime, date
from uuid import UUID
from pydantic import BaseModel, EmailStr, ConfigDict


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
    log_date: date | None = None   # defaults to today if not given


class FoodLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    food_item_id: int
    log_date: date
    grams: float
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