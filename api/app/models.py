import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, Date, Numeric, Integer
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    hashed_password = Column(String, nullable=False)

    sex = Column(String, nullable=True)
    birthdate = Column(Date, nullable=True)
    height_cm = Column(Numeric(5, 1), nullable=True)
    current_weight_kg = Column(Numeric(5, 2), nullable=True)
    goal_weight_kg = Column(Numeric(5, 2), nullable=True)
    activity_level = Column(String, nullable=True)
    goal = Column(String, nullable=True)
    goal_rate_kg_per_week = Column(Numeric(4, 2), nullable=True)

    target_calories = Column(Integer, nullable=True)
    target_protein_g = Column(Integer, nullable=True)
    target_carbs_g = Column(Integer, nullable=True)
    target_fat_g = Column(Integer, nullable=True)
    target_source = Column(String, nullable=False, default="formula")

    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    token = Column(String, unique=True, nullable=False, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

class FoodItem(Base):
    __tablename__ = "food_items"

    id = Column(Integer, primary_key=True)  # USDA fdc_id
    description = Column(String, nullable=False, index=True)
    data_type = Column(String, nullable=True)
    food_category_id = Column(Integer, nullable=True)

    # macros per 100g (USDA's standard basis)
    kcal_per_100g = Column(Numeric(8, 2), nullable=True)
    protein_per_100g = Column(Numeric(8, 2), nullable=True)
    carbs_per_100g = Column(Numeric(8, 2), nullable=True)
    fat_per_100g = Column(Numeric(8, 2), nullable=True)