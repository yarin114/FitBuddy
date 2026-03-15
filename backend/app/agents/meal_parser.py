"""
Meal Parser Agent
──────────────────
Parses a free-text meal description (e.g. "2 eggs and 100g chicken breast")
into structured macronutrient data using Claude Tool Use.

Tool Use guarantees a structurally valid JSON response — the model is
literally forced to call submit_meal or we raise MealParserError.
"""

import logging
import time
from pathlib import Path

import anthropic

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_PROMPT_PATH = Path(__file__).parent / "prompts" / "meal_parser_v1.txt"
_SYSTEM_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

_SUBMIT_MEAL_TOOL: dict = {
    "name": "submit_meal",
    "description": (
        "Submit the parsed meal with its estimated macronutrients. "
        "You MUST call this tool with realistic values based on standard nutritional data."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "meal_name": {
                "type": "string",
                "description": "Short, clean name for the meal (3-6 words max).",
            },
            "calories": {
                "type": "integer",
                "minimum": 0,
                "description": "Total calories (kcal), rounded to nearest 5.",
            },
            "protein_g": {
                "type": "integer",
                "minimum": 0,
                "description": "Total protein in grams.",
            },
            "carbs_g": {
                "type": "integer",
                "minimum": 0,
                "description": "Total carbohydrates in grams.",
            },
            "fat_g": {
                "type": "integer",
                "minimum": 0,
                "description": "Total fat in grams.",
            },
        },
        "required": ["meal_name", "calories", "protein_g", "carbs_g", "fat_g"],
    },
}


class MealParserError(Exception):
    """Raised when the LLM fails to parse the meal description."""


async def parse_meal_text(text: str) -> dict:
    """
    Parse a free-text meal description and return structured macro data.

    Returns a dict: {meal_name, calories, protein_g, carbs_g, fat_g}.
    Raises MealParserError on any LLM or validation failure.
    """
    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

    t0 = time.monotonic()
    try:
        response = await client.messages.create(
            model=settings.llm_model,
            max_tokens=256,
            system=_SYSTEM_PROMPT,
            tools=[_SUBMIT_MEAL_TOOL],
            tool_choice={"type": "tool", "name": "submit_meal"},
            messages=[
                {
                    "role": "user",
                    "content": f'Estimate the macros for: "{text}"',
                }
            ],
        )
    except anthropic.APIStatusError as exc:
        logger.error("meal_parser: Anthropic API error: %s", exc)
        raise MealParserError(f"AI service error ({exc.status_code}). Please try again.") from exc
    except anthropic.APIConnectionError as exc:
        logger.error("meal_parser: Anthropic connection error: %s", exc)
        raise MealParserError("AI service unreachable. Please try again.") from exc

    latency_ms = int((time.monotonic() - t0) * 1000)
    logger.info(
        "meal_parser: parsed in %d ms | tokens in=%d out=%d",
        latency_ms,
        response.usage.input_tokens,
        response.usage.output_tokens,
    )

    tool_block = next(
        (b for b in response.content if b.type == "tool_use"),
        None,
    )
    if tool_block is None:
        logger.error("meal_parser: model did not call submit_meal")
        raise MealParserError("Could not parse your meal. Please try again.")

    raw: dict = tool_block.input
    return {
        "meal_name": str(raw["meal_name"]),
        "calories":  int(raw["calories"]),
        "protein_g": int(raw["protein_g"]),
        "carbs_g":   int(raw["carbs_g"]),
        "fat_g":     int(raw["fat_g"]),
    }
