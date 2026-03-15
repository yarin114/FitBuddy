"""
SOS Service
────────────
Manages the lifecycle of SOS sessions in the database:
- create, append messages, close with outcome.

All functions are pure DB operations — no HTTP or WebSocket logic.
"""

import logging
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.sos_session import SosSession

logger = logging.getLogger(__name__)


async def create_session(db: AsyncSession, user_id: UUID) -> SosSession:
    """Open a new SOS session and persist it immediately."""
    session = SosSession(
        user_id=user_id,
        messages=[],
        outcome=None,
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    logger.info("SOS session opened: id=%s user=%s", session.id, user_id)
    return session


async def append_message(
    db: AsyncSession,
    session: SosSession,
    role: str,
    content: str,
) -> None:
    """
    Append a single message turn to the session transcript.

    ``role`` must be "user" or "assistant".
    Writes to DB immediately so the transcript is never lost on WS disconnect.
    """
    turn = {
        "role": role,
        "content": content,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    # JSONB lists must be reassigned (not mutated) to trigger SQLAlchemy change detection
    session.messages = session.messages + [turn]
    await db.commit()


async def close_session(
    db: AsyncSession,
    session: SosSession,
    outcome: str,
) -> None:
    """
    Mark the session as closed with a final outcome.

    outcome: "resolved" | "abandoned" | "escalated" | "error"
    """
    session.ended_at = datetime.now(timezone.utc)
    session.outcome = outcome
    await db.commit()
    logger.info(
        "SOS session closed: id=%s outcome=%s turns=%d",
        session.id,
        outcome,
        len(session.messages),
    )


async def get_session(
    db: AsyncSession,
    session_id: UUID,
    user_id: UUID,
) -> SosSession | None:
    """Fetch a session by ID, scoped to the owning user."""
    result = await db.execute(
        select(SosSession).where(
            SosSession.id == session_id,
            SosSession.user_id == user_id,
        )
    )
    return result.scalar_one_or_none()
