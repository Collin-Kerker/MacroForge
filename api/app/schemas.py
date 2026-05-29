from datetime import datetime
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