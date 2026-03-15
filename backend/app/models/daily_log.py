from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING, List, Optional
from uuid import UUID, uuid4

from sqlalchemy import Date, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.meal import Meal
    from app.models.user import User


class DailyLog(Base):
    """
    One row per user per calendar day.  Serves as the macro budget ledger.

    calories_remaining / macros_remaining are intentionally NOT stored here —
    they are derived at the service layer from (User.daily_*_target - consumed)
    to avoid drift when the user updates their targets mid-day.
    """

    __tablename__ = "daily_logs"
    __table_args__ = (
        UniqueConstraint("user_id", "log_date", name="uq_daily_logs_user_date"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    log_date: Mapped[date] = mapped_column(Date, nullable=False)

    # Running totals — incremented every time a meal is logged
    calories_consumed: Mapped[int] = mapped_column(nullable=False, default=0)
    protein_consumed_g: Mapped[int] = mapped_column(nullable=False, default=0)
    carbs_consumed_g: Mapped[int] = mapped_column(nullable=False, default=0)
    fat_consumed_g: Mapped[int] = mapped_column(nullable=False, default=0)

    # Used by the push daemon to detect "black hole" windows
    last_meal_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # ── Relationships ────────────────────────────────────────────────────────
    user: Mapped[User] = relationship(back_populates="daily_logs")
    meals: Mapped[List[Meal]] = relationship(
        back_populates="daily_log", cascade="all, delete-orphan", lazy="select"
    )

    def __repr__(self) -> str:
        return f"<DailyLog user={self.user_id} date={self.log_date}>"
