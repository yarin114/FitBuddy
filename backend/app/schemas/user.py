from datetime import date, datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


# ── Inbound ───────────────────────────────────────────────────────────────────

class UserOnboardRequest(BaseModel):
    """Sent by the client after Firebase sign-up to create the DB profile."""

    name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr
    date_of_birth: Optional[date] = None
    gender: Optional[str] = Field(None, pattern="^(male|female|other)$")
    weight_kg: Optional[float] = Field(None, gt=0, le=500)
    height_cm: Optional[float] = Field(None, gt=0, le=300)
    goal_weight_kg: Optional[float] = Field(None, gt=0, le=500)
    activity_level: Optional[str] = Field(
        None, pattern="^(sedentary|light|moderate|active)$"
    )
    timezone: str = Field(default="UTC", max_length=64)


class UserUpdateRequest(BaseModel):
    """Partial profile update — all fields optional."""

    name: Optional[str] = Field(None, min_length=1, max_length=255)
    weight_kg: Optional[float] = Field(None, gt=0, le=500)
    goal_weight_kg: Optional[float] = Field(None, gt=0, le=500)
    activity_level: Optional[str] = Field(
        None, pattern="^(sedentary|light|moderate|active)$"
    )
    fcm_token: Optional[str] = Field(None, max_length=512)
    timezone: Optional[str] = Field(None, max_length=64)


# ── Outbound ──────────────────────────────────────────────────────────────────

class MacroTargets(BaseModel):
    daily_calorie_target: Optional[int]
    daily_protein_g: Optional[int]
    daily_carbs_g: Optional[int]
    daily_fat_g: Optional[int]


class UserResponse(BaseModel):
    id: UUID
    firebase_uid: str
    name: str
    email: str
    date_of_birth: Optional[date]
    gender: Optional[str]
    weight_kg: Optional[float]
    height_cm: Optional[float]
    goal_weight_kg: Optional[float]
    activity_level: Optional[str]
    timezone: str
    macro_targets: MacroTargets
    created_at: datetime

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm(cls, user) -> "UserResponse":
        return cls(
            id=user.id,
            firebase_uid=user.firebase_uid,
            name=user.name,
            email=user.email,
            date_of_birth=user.date_of_birth,
            gender=user.gender,
            weight_kg=user.weight_kg,
            height_cm=user.height_cm,
            goal_weight_kg=user.goal_weight_kg,
            activity_level=user.activity_level,
            timezone=user.timezone,
            macro_targets=MacroTargets(
                daily_calorie_target=user.daily_calorie_target,
                daily_protein_g=user.daily_protein_g,
                daily_carbs_g=user.daily_carbs_g,
                daily_fat_g=user.daily_fat_g,
            ),
            created_at=user.created_at,
        )
