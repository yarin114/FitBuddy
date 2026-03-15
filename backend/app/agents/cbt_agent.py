"""
CBT Agent — Real-Time Streaming
────────────────────────────────
Uses Anthropic Claude 3.5 Sonnet with async streaming to deliver token-by-token
responses over a WebSocket connection.

Design decisions:
- `client.messages.stream()` (AsyncMessageStreamManager) gives us text chunks
  as they are generated, which we forward over the WS immediately.
- The full conversation history is passed on every turn so Claude maintains
  continuity without server-side session memory beyond the DB transcript.
- A typing sentinel ("__DONE__") is sent as the final WebSocket message so
  the Flutter client knows when to stop the typing indicator.
"""

import logging
import time
from pathlib import Path
from typing import AsyncIterator

import anthropic

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_PROMPT_PATH = Path(__file__).parent / "prompts" / "cbt_v1.txt"
_SYSTEM_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# Sentinel string sent as the final WS message to signal stream end
STREAM_DONE_SENTINEL = "__DONE__"

# Max conversation turns kept in context to avoid exceeding token limits.
# Oldest turns are trimmed first (sliding window).
_MAX_HISTORY_TURNS = 20


class CBTAgentError(Exception):
    """Raised when the LLM call fails unrecoverably."""


async def stream_response(
    messages: list[dict],
    user_name: str,
) -> AsyncIterator[str]:
    """
    Yield text chunks from Claude 3.5 Sonnet as they are generated.

    ``messages`` is the full conversation history in Anthropic format:
    [{"role": "user"|"assistant", "content": str}, ...]

    The caller (WebSocket route) is responsible for sending each chunk
    over the WebSocket and appending the completed response to the DB transcript.

    Yields:
        str  — individual text chunks (may be single characters or short phrases)
        After the last chunk, yields STREAM_DONE_SENTINEL exactly once.

    Raises:
        CBTAgentError — on API failure (caller should close WS gracefully)
    """
    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

    # Slide the context window to stay within token budget
    windowed = _apply_window(messages)

    # Inject user name into system prompt for personalisation
    system = _SYSTEM_PROMPT.replace("{user_name}", user_name)

    logger.debug(
        "cbt_agent: streaming response | turns=%d user=%s",
        len(windowed),
        user_name,
    )

    t0 = time.monotonic()
    try:
        async with client.messages.stream(
            model=settings.llm_model,
            max_tokens=600,   # CBT responses should be concise
            system=system,
            messages=windowed,
        ) as stream:
            async for text_chunk in stream.text_stream:
                yield text_chunk

        # Final usage logging
        final_msg = await stream.get_final_message()
        latency_ms = int((time.monotonic() - t0) * 1000)
        logger.info(
            "cbt_agent: stream complete | latency=%dms tokens_in=%d tokens_out=%d",
            latency_ms,
            final_msg.usage.input_tokens,
            final_msg.usage.output_tokens,
        )

    except anthropic.APIStatusError as exc:
        logger.error("cbt_agent: API error %s: %s", exc.status_code, exc.message)
        raise CBTAgentError(f"AI service error ({exc.status_code}).") from exc
    except anthropic.APIConnectionError as exc:
        logger.error("cbt_agent: connection error: %s", exc)
        raise CBTAgentError("AI service is unreachable. Please try again.") from exc

    yield STREAM_DONE_SENTINEL


def build_opening_message() -> str:
    """
    Return the hard-coded opening message for a new SOS session.
    This is sent immediately on WS connect before any user input,
    matching the opening defined in the system prompt.
    """
    return (
        "Hey, I'm here. I can tell this moment is hard. "
        "Take a breath — you reached out, and that already takes courage. 💙 "
        "What's going on right now?"
    )


# ── Private helpers ───────────────────────────────────────────────────────────

def _apply_window(messages: list[dict]) -> list[dict]:
    """
    Keep only the last _MAX_HISTORY_TURNS turns.
    Always preserves the first user message (session context anchor).
    Ensures the windowed list starts with a user turn (Anthropic requirement).
    """
    if len(messages) <= _MAX_HISTORY_TURNS:
        return messages

    trimmed = messages[-_MAX_HISTORY_TURNS:]
    # Anthropic requires the first message to have role "user"
    while trimmed and trimmed[0]["role"] != "user":
        trimmed = trimmed[1:]
    return trimmed
