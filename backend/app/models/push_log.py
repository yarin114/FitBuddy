from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.meal import Meal
    from app.models.user import User


class PushNotificationLog(Base):
    """
    Audit trail of every push notification sent by the proactive coach daemon.

    ``opened_at`` is set via a deep-link callback from the Flutter client,
    allowing us to measure engagement and tune the push frequency.
    """

    __tablename__ = "push_notification_logs"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    trigger_reason: Mapped[str] = mapped_column(
        String(50), nullable=False
    )  # skip_risk | overeating_risk | end_of_day_gap

    message_body: Mapped[str] = mapped_column(Text, nullable=False)

    # Optional: the recipe that was pre-loaded alongside this push notification
    meal_id: Mapped[Optional[UUID]] = mapped_column(
        ForeignKey("meals.id", ondelete="SET NULL"), nullable=True
    )

    sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    opened_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ── Relationships ────────────────────────────────────────────────────────
    user: Mapped[User] = relationship(back_populates="push_logs")
    meal: Mapped[Optional[Meal]] = relationship(lazy="select")

    def __repr__(self) -> str:
        return f"<PushLog user={self.user_id} reason={self.trigger_reason!r} sent={self.sent_at}>"
