from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class UserBehaviorPattern(Base):
    """
    Aggregated risk scores per (user, hour_of_day, day_of_week) slot.

    Re-computed weekly by the behavior_analyzer worker.
    Consumed by the push_worker to decide whether to fire a proactive notification.
    """

    __tablename__ = "user_behavior_patterns"
    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "hour_of_day",
            "day_of_week",
            name="uq_behavior_user_hour_day",
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    hour_of_day: Mapped[int] = mapped_column(nullable=False)   # 0 – 23
    day_of_week: Mapped[int] = mapped_column(nullable=False)   # 0 (Mon) – 6 (Sun)

    avg_meals_logged: Mapped[float] = mapped_column(nullable=False, default=0.0)
    overeating_risk_score: Mapped[float] = mapped_column(
        nullable=False, default=0.0
    )  # 0.0 – 1.0
    skip_risk_score: Mapped[float] = mapped_column(
        nullable=False, default=0.0
    )  # 0.0 – 1.0

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # ── Relationships ────────────────────────────────────────────────────────
    user: Mapped[User] = relationship(back_populates="behavior_patterns")

    def __repr__(self) -> str:
        return (
            f"<BehaviorPattern user={self.user_id} "
            f"h={self.hour_of_day} d={self.day_of_week} "
            f"skip={self.skip_risk_score:.2f}>"
        )
