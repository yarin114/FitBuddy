from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


# ── Ingredient sub-schema ─────────────────────────────────────────────────────

class Ingredient(BaseModel):
    name: str = Field(..., min_length=1)
    grams: float = Field(..., gt=0)
    calories: int = Field(..., ge=0)
    protein_g: float = Field(..., ge=0)
    carbs_g: float = Field(..., ge=0)
    fat_g: float = Field(..., ge=0)


# ── Inbound ───────────────────────────────────────────────────────────────────

class MealGenerateRequest(BaseModel):
    """
    What the Flutter client sends to POST /api/v1/meals/generate.
    Phase 1: text-only cravings (photo_scan deferred to Phase 2).
    """

    craving_input: str = Field(
        ...,
        min_length=2,
        max_length=500,
        description="Free-text craving, e.g. 'I want something with chicken and pasta'",
    )


class MealLogManualRequest(BaseModel):
    """Client manually logs a meal they ate (not AI-generated)."""

    name: str = Field(..., min_length=1, max_length=255)
    ingredients: List[Ingredient]
    instructions: str = Field(default="")
    total_calories: int = Field(..., ge=0)
    total_protein_g: int = Field(..., ge=0)
    total_carbs_g: int = Field(..., ge=0)
    total_fat_g: int = Field(..., ge=0)


class MealLogTextRequest(BaseModel):
    """Client logs a meal using plain-text description; AI parses the macros."""

    text: str = Field(
        ...,
        min_length=2,
        max_length=500,
        description='Free-text description, e.g. "2 eggs and 100g chicken breast"',
    )


# ── Outbound ──────────────────────────────────────────────────────────────────

class MealResponse(BaseModel):
    id: UUID
    name: str
    ingredients: List[Ingredient]
    instructions: str
    total_calories: int
    total_protein_g: int
    total_carbs_g: int
    total_fat_g: int
    craving_input: Optional[str]
    source: str
    logged_at: datetime

    model_config = {"from_attributes": True}
