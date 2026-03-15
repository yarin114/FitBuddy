from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class SosSession(Base):
    """
    A single real-time CBT intervention session.

    ``messages`` is a JSONB array of conversation turns:
    [{"role": "user"|"assistant", "content": str, "timestamp": ISO-8601}, ...]

    The full transcript is persisted for future personalisation and to allow
    the behaviour analyser to identify recurring emotional eating triggers.
    """

    __tablename__ = "sos_sessions"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    ended_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    messages: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)

    outcome: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True
    )  # resolved | abandoned | escalated

    # ── Relationships ────────────────────────────────────────────────────────
    user: Mapped[User] = relationship(back_populates="sos_sessions")

    def __repr__(self) -> str:
        return f"<SosSession id={self.id} user={self.user_id} outcome={self.outcome!r}>"
