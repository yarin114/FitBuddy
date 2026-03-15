from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.daily_log import DailyLog
    from app.models.user import User


class Meal(Base):
    """
    An individual meal record — either AI-generated or manually entered.

    ``ingredients`` stores a JSONB array:
    [{"name": str, "grams": float, "calories": int,
      "protein": float, "carbs": float, "fat": float}, ...]
    """

    __tablename__ = "meals"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    daily_log_id: Mapped[Optional[UUID]] = mapped_column(
        ForeignKey("daily_logs.id", ondelete="SET NULL"), nullable=True, index=True
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    ingredients: Mapped[list] = mapped_column(JSONB, nullable=False)
    instructions: Mapped[str] = mapped_column(Text, nullable=False)

    # Macro totals — denormalised for fast read access and push-daemon queries
    total_calories: Mapped[int] = mapped_column(nullable=False)
    total_protein_g: Mapped[int] = mapped_column(nullable=False)
    total_carbs_g: Mapped[int] = mapped_column(nullable=False)
    total_fat_g: Mapped[int] = mapped_column(nullable=False)

    craving_input: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(
        String(20), nullable=False, default="ai_generated"
    )  # manual | ai_generated

    logged_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # ── Relationships ────────────────────────────────────────────────────────
    user: Mapped[User] = relationship(back_populates="meals")
    daily_log: Mapped[Optional[DailyLog]] = relationship(back_populates="meals")

    def __repr__(self) -> str:
        return f"<Meal id={self.id} name={self.name!r} calories={self.total_calories}>"
