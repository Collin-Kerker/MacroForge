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

    # extras the UI can show
    hit_calorie_floor: bool = False
    fastest_safe_rate_kg_per_week: float | None = None

    profile_complete: bool = False


# ── Profile response (GET /profile) ──────────────────────────
class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    # inputs
    sex: str | None = None
    birthdate: date | None = None
    height_cm: float | None = None
    current_weight_kg: float | None = None
    activity_level: str | None = None
    goal: str | None = None
    goal_rate_kg_per_week: float | None = None

    # computed targets
    target_calories: int | None = None
    target_protein_g: int | None = None
    target_carbs_g: int | None = None
    target_fat_g: int | None = None
    target_source: str = "formula"

    # convenience: is the profile complete enough to have targets?
    profile_complete: bool = False