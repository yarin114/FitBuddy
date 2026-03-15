"""
SOS WebSocket Route
────────────────────
WS  wss://<host>/api/v1/sos/ws?token=<firebase_id_token>
GET /api/v1/sos/sessions              — paginated session history
GET /api/v1/sos/sessions/{session_id} — single session transcript

WebSocket protocol (JSON messages):
  Client → Server: {"content": "I just got home and went straight to the fridge"}
  Server → Client: {"type": "chunk",    "content": "I hear you..."}   (streaming)
  Server → Client: {"type": "done"}                                   (turn complete)
  Server → Client: {"type": "error",    "content": "..."}             (fatal error)

Authentication:
  WS endpoints cannot use FastAPI's Depends(HTTPBearer) because the browser WS
  API does not support custom headers.  Instead, the Firebase ID token is passed
  as a query parameter and verified before the handshake is accepted.
  This is the standard pattern for WS auth in FastAPI.
"""

import logging
from typing import List
from uuid import UUID

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect, status
from sqlalchemy import select

from app.agents.cbt_agent import (
    STREAM_DONE_SENTINEL,
    CBTAgentError,
    build_opening_message,
    stream_response,
)
from app.core.database import AsyncSessionLocal
from app.core.firebase_admin import verify_firebase_token
from app.models.sos_session import SosSession
from app.models.user import User
from app.schemas.sos import SosSessionResponse
from app.services.sos_service import (
    append_message,
    close_session,
    create_session,
)

logger = logging.getLogger(__name__)
router = APIRouter()


# ── WebSocket endpoint ────────────────────────────────────────────────────────

@router.websocket("/ws")
async def sos_websocket(
    websocket: WebSocket,
    token: str = Query(..., description="Firebase ID token for authentication"),
) -> None:
    """
    Persistent WebSocket connection for the real-time CBT intervention module.

    Lifecycle:
    1. Verify Firebase token → resolve User → accept connection
    2. Open SOS session in DB → send opening message
    3. Loop: receive user message → stream AI response chunk-by-chunk → persist both
    4. On disconnect or "I'm okay" signal → close session with outcome
    """
    # ── Step 1: authenticate BEFORE accepting the connection ─────────────────
    async with AsyncSessionLocal() as db:
        user = await _authenticate_ws(websocket, token, db)
        if user is None:
            return  # connection already closed with 4001 inside helper

        await websocket.accept()
        logger.info("SOS WS accepted: user=%s", user.id)

        # ── Step 2: open session and send opening message ─────────────────────
        session = await create_session(db, user.id)
        opening = build_opening_message()

        await websocket.send_json({"type": "chunk", "content": opening})
        await websocket.send_json({"type": "done"})

        # Persist assistant opening turn
        await append_message(db, session, role="assistant", content=opening)

        # Build the Anthropic-format history list (starts empty, grows each turn)
        history: list[dict] = [{"role": "assistant", "content": opening}]

        # ── Step 3: main conversation loop ────────────────────────────────────
        outcome = "abandoned"
        try:
            while True:
                # Receive user message (text or JSON)
                raw = await websocket.receive_text()
                user_content = _parse_client_message(raw)

                # Special client signal to gracefully end the session
                if user_content.strip().lower() in ("__ok__", "i'm okay", "i am okay"):
                    outcome = "resolved"
                    await websocket.send_json({
                        "type": "chunk",
                        "content": (
                            "I'm really proud of you for reaching out and working through that. "
                            "You're stronger than the craving. 💪 I'll be here whenever you need me."
                        ),
                    })
                    await websocket.send_json({"type": "done"})
                    break

                # Append user turn to history and DB
                history.append({"role": "user", "content": user_content})
                await append_message(db, session, role="user", content=user_content)

                # Stream AI response
                assistant_response = await _stream_and_forward(
                    websocket=websocket,
                    history=history,
                    user_name=user.name,
                    db=db,
                    session=session,
                )

                if assistant_response is None:
                    # CBTAgentError was already sent to client as error frame
                    outcome = "error"
                    break

                # Append completed assistant turn to history
                history.append({"role": "assistant", "content": assistant_response})

        except WebSocketDisconnect:
            logger.info("SOS WS disconnected: user=%s session=%s", user.id, session.id)
            outcome = "abandoned"

        except Exception as exc:
            logger.exception("SOS WS unexpected error: %s", exc)
            try:
                await websocket.send_json({
                    "type": "error",
                    "content": "Something went wrong. Please try again.",
                })
            except Exception:
                pass
            outcome = "error"

        finally:
            await close_session(db, session, outcome=outcome)
            logger.info("SOS session finalised: id=%s outcome=%s", session.id, outcome)


# ── REST endpoints for session history ───────────────────────────────────────

@router.get("/sessions", response_model=List[SosSessionResponse])
async def list_sessions(
    token: str = Query(...),
    limit: int = Query(default=10, ge=1, le=50),
    offset: int = Query(default=0, ge=0),
) -> List[SosSessionResponse]:
    """Return paginated SOS session history for the authenticated user."""
    async with AsyncSessionLocal() as db:
        user = await _get_user_from_token(token, db)
        result = await db.execute(
            select(SosSession)
            .where(SosSession.user_id == user.id)
            .order_by(SosSession.started_at.desc())
            .limit(limit)
            .offset(offset)
        )
        sessions = result.scalars().all()
        return [SosSessionResponse.model_validate(s) for s in sessions]


@router.get("/sessions/{session_id}", response_model=SosSessionResponse)
async def get_session_transcript(
    session_id: UUID,
    token: str = Query(...),
) -> SosSessionResponse:
    """Return a single session transcript (for review / analytics)."""
    from fastapi import HTTPException
    async with AsyncSessionLocal() as db:
        user = await _get_user_from_token(token, db)
        result = await db.execute(
            select(SosSession).where(
                SosSession.id == session_id,
                SosSession.user_id == user.id,
            )
        )
        session = result.scalar_one_or_none()
        if session is None:
            raise HTTPException(status_code=404, detail="Session not found.")
        return SosSessionResponse.model_validate(session)


# ── Private helpers ───────────────────────────────────────────────────────────

async def _authenticate_ws(
    websocket: WebSocket,
    token: str,
    db,
) -> User | None:
    """
    Verify the Firebase token and resolve the User row.
    Closes the WS with a 4001/4004 code and returns None on failure.
    """
    try:
        decoded = verify_firebase_token(token)
        firebase_uid: str = decoded["uid"]
    except Exception:
        await websocket.close(code=4001, reason="Invalid or expired token.")
        return None

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if user is None:
        await websocket.close(code=4004, reason="User profile not found.")
        return None

    return user


async def _get_user_from_token(token: str, db) -> User:
    """Used by the REST endpoints that also rely on token-based auth."""
    from fastapi import HTTPException
    try:
        decoded = verify_firebase_token(token)
        firebase_uid = decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token.")

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found.")
    return user


async def _stream_and_forward(
    websocket: WebSocket,
    history: list[dict],
    user_name: str,
    db,
    session: SosSession,
) -> str | None:
    """
    Stream the CBT agent response chunk-by-chunk over the WebSocket.

    Returns the complete assembled response string on success,
    or None if a CBTAgentError occurred (error frame already sent to client).
    """
    full_response: list[str] = []

    try:
        async for chunk in stream_response(history, user_name):
            if chunk == STREAM_DONE_SENTINEL:
                await websocket.send_json({"type": "done"})
                break
            await websocket.send_json({"type": "chunk", "content": chunk})
            full_response.append(chunk)

    except CBTAgentError as exc:
        logger.error("SOS stream error: %s", exc)
        try:
            await websocket.send_json({"type": "error", "content": str(exc)})
        except Exception:
            pass
        return None

    assembled = "".join(full_response)

    # Persist completed assistant turn to DB
    if assembled:
        await append_message(db, session, role="assistant", content=assembled)

    return assembled


def _parse_client_message(raw: str) -> str:
    """
    Accept either plain text or a JSON envelope: {"content": "..."}.
    Returns the plain-text content string.
    """
    import json
    try:
        data = json.loads(raw)
        return str(data.get("content", raw))
    except (json.JSONDecodeError, TypeError):
        return raw
