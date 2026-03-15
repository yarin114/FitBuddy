from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Database ──────────────────────────────────────────────────────────────
    database_url: str  # must use postgresql+asyncpg:// scheme

    # ── Firebase ──────────────────────────────────────────────────────────────
    firebase_credentials_path: str

    # ── Anthropic ─────────────────────────────────────────────────────────────
    anthropic_api_key: str
    llm_model: str = "claude-3-5-sonnet-20241022"

    # ── App ───────────────────────────────────────────────────────────────────
    app_name: str = "FitBuddy API"
    debug: bool = False

    # ── Workers ───────────────────────────────────────────────────────────────
    push_worker_interval_minutes: int = 15
    skip_risk_threshold_hours: int = 5
    push_cooldown_hours: int = 3


@lru_cache
def get_settings() -> Settings:
    """
    Return a cached Settings instance.
    Use ``get_settings.cache_clear()`` in tests to force reloading from env.
    """
    return Settings()
