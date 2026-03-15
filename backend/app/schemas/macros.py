from datetime import date
from uuid import UUID

from pydantic import BaseModel


class MacroBudget(BaseModel):
    """
    The remaining macro budget for a user on a given day.
    Computed by macro_service and passed into the LLM agent as context.
    """

    log_date: date
    calories_target: int
    calories_consumed: int
    calories_remaining: int

    protein_target_g: int
    protein_consumed_g: int
    protein_remaining_g: int

    carbs_target_g: int
    carbs_consumed_g: int
    carbs_remaining_g: int

    fat_target_g: int
    fat_consumed_g: int
    fat_remaining_g: int


class DailyLogResponse(BaseModel):
    """Outbound representation of a daily log row."""

    id: UUID
    log_date: date
    budget: MacroBudget

    model_config = {"from_attributes": True}
