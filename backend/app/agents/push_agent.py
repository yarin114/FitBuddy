"""
Push Notification Agent
────────────────────────
Generates hyper-personalised FCM push notification copy using
Claude 3.5 Sonnet via Tool Use.

Tool Use guarantees strict JSON output — the model cannot respond with
plain text. Same pattern as macro_engine.py.

Output schema:
    {
        "title": str,               # ≤65 chars — push headline
        "body":  str,               # ≤200 chars — push body copy
        "suggested_craving": str,   # optional — only for overeating_risk
    }
"""

import logging
import time
from datetime import datetime
from pathlib import Path
from typing import Any

import anthropic

from app.core.config import get_settings

logger   = logging.getLogger(__name__)
settings = get_settings()

# ── Load versioned system prompt ──────────────────────────────────────────────
_PROMPT_PATH: Path  = Path(__file__).parent / "prompts" / "push_coach_v1.txt"
_SYSTEM_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# ── Tool schema — the JSON contract the model must fill ───────────────────────
_NOTIFICATION_TOOL: dict = {
    "name": "submit_notification",
    "description": (
        "Submit the generated push notification. "
        "You MUST call this tool — never respond with plain text. "
        "For overeating_risk triggers you MUST include suggested_craving."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "title": {
                "type": "string",
                "description": (
                    "Push notification headline. "
                    "Max 65 characters. Action-oriented and warm."
                ),
                "maxLength": 65,
            },
            "body": {
                "type": "string",
                "description": (
                    "Push notification body. "
                    "Max 200 characters. Names a specific food suggestion "
                    "and one micro-motivation."
                ),
                "maxLength": 200,
            },
            "suggested_craving": {
                "type": "string",
                "description": (
                    "A short craving string passed to the Macro Engine so the app "
                    "can immediately surface a rescue recipe. "
                    "Required ONLY for overeating_risk trigger. "
                    "Example: 'greek yogurt with cucumber' or 'cottage cheese with celery'."
                ),
            },
        },
        "required": ["title", "body"],
    },
}


class PushAgentError(Exception):
    """Raised when the LLM fails to generate a valid push notification."""


async def generate_push_message(
    user_name: str,
    trigger_reason: str,
    calories_remaining: int,
    last_meal_at: datetime | None,
    current_time: datetime,
) -> dict[str, Any]:
    """
    Call Claude 3.5 Sonnet and return a validated push notification dict.

    Returns:
        {
            "title": str,
            "body":  str,
            "suggested_craving": str | None,   # None when not an overeating_risk
        }

    Raises:
        PushAgentError on LLM or validation failure.
    """
    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    user_message = _build_user_message(
        user_name, trigger_reason, calories_remaining, last_meal_at, current_time
    )

    logger.debug(
        "push_agent: calling LLM | trigger=%s user=%s", trigger_reason, user_name
    )

    t0 = time.monotonic()
    try:
        response = await client.messages.create(
            model=settings.llm_model,
            max_tokens=300,
            system=_SYSTEM_PROMPT,
            tools=[_NOTIFICATION_TOOL],
            # Force the model to populate the tool — cannot produce free text.
            tool_choice={"type": "tool", "name": "submit_notification"},
            messages=[{"role": "user", "content": user_message}],
        )
    except anthropic.APIStatusError as exc:
        logger.error("push_agent: Anthropic API error: %s", exc)
        raise PushAgentError(f"LLM API error: {exc.status_code}") from exc
    except anthropic.APIConnectionError as exc:
        logger.error("push_agent: Anthropic connection error: %s", exc)
        raise PushAgentError("LLM unreachable.") from exc

    latency_ms = int((time.monotonic() - t0) * 1000)
    logger.info(
        "push_agent: responded in %d ms | tokens in=%d out=%d",
        latency_ms,
        response.usage.input_tokens,
        response.usage.output_tokens,
    )

    # ── Extract tool call ──────────────────────────────────────────────────
    tool_block = next(
        (b for b in response.content if b.type == "tool_use"),
        None,
    )
    if tool_block is None:
        raise PushAgentError("Model did not call submit_notification tool.")

    raw: dict = tool_block.input

    # ── Field validation ──────────────────────────────────────────────────
    if not raw.get("title") or not raw.get("body"):
        raise PushAgentError(f"Notification missing required fields: {raw}")

    if len(raw["title"]) > 65:
        logger.warning("push_agent: title too long (%d chars) — truncating", len(raw["title"]))
        raw["title"] = raw["title"][:65]

    if len(raw["body"]) > 200:
        logger.warning("push_agent: body too long (%d chars) — truncating", len(raw["body"]))
        raw["body"] = raw["body"][:200]

    return {
        "title":              raw["title"],
        "body":               raw["body"],
        "suggested_craving":  raw.get("suggested_craving"),
        # Caller metadata
        "_meta": {
            "input_tokens":   response.usage.input_tokens,
            "output_tokens":  response.usage.output_tokens,
            "latency_ms":     latency_ms,
            "prompt_version": "push_coach_v1",
        },
    }


# ── Private helpers ───────────────────────────────────────────────────────────

def _build_user_message(
    user_name: str,
    trigger_reason: str,
    calories_remaining: int,
    last_meal_at: datetime | None,
    current_time: datetime,
) -> str:
    hours_since_meal: str
    if last_meal_at is None:
        hours_since_meal = "null (no meals logged today)"
    else:
        delta_hours = (current_time - last_meal_at).total_seconds() / 3600
        hours_since_meal = f"{delta_hours:.1f}"

    return (
        f"user_name: {user_name}\n"
        f"trigger_reason: {trigger_reason}\n"
        f"calories_remaining: {calories_remaining} kcal\n"
        f"hours_since_meal: {hours_since_meal}\n"
        f"current_hour: {current_time.hour}\n\n"
        "Generate a personalised push notification for this user. "
        "Call submit_notification with your answer."
    )
