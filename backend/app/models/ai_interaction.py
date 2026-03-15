from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING, Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.user import User


class AIInteraction(Base):
    """
    Audit log for every LLM API call made on behalf of a user.

    Used for cost tracking, latency monitoring, and prompt version analysis.
    ``prompt_version`` maps to a file in ``app/agents/prompts/``.
    """

    __tablename__ = "ai_interactions"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    module: Mapped[str] = mapped_column(
        String(30), nullable=False
    )  # macro_engine | push_agent | cbt_agent

    prompt_version: Mapped[str] = mapped_column(
        String(30), nullable=False
    )  # e.g. "macro_v1" — matches filename in agents/prompts/

    input_tokens: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    output_tokens: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    latency_ms: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # ── Relationships ────────────────────────────────────────────────────────
    user: Mapped[User] = relationship(back_populates="ai_interactions")

    def __repr__(self) -> str:
        return (
            f"<AIInteraction module={self.module!r} "
            f"tokens_in={self.input_tokens} tokens_out={self.output_tokens}>"
        )
