from __future__ import annotations

from datetime import date, datetime
from typing import TYPE_CHECKING, List, Optional
from uuid import UUID, uuid4

from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.ai_interaction import AIInteraction
    from app.models.behavior_pattern import UserBehaviorPattern
    from app.models.daily_log import DailyLog
    from app.models.meal import Meal
    from app.models.push_log import PushNotificationLog
    from app.models.sos_session import SosSession


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    supabase_uid: Mapped[str] = mapped_column(
        String(128), unique=True, nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(String(320), unique=True, nullable=False)

    # Physical profile — populated during onboarding
    date_of_birth: Mapped[Optional[date]] = mapped_column(nullable=True)
    gender: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    weight_kg: Mapped[Optional[float]] = mapped_column(nullable=True)
    height_cm: Mapped[Optional[float]] = mapped_column(nullable=True)
    goal_weight_kg: Mapped[Optional[float]] = mapped_column(nullable=True)
    activity_level: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True
    )  # sedentary | light | moderate | active | very_active
    goal: Mapped[Optional[str]] = mapped_column(
        String(20), nullable=True
    )  # lose_weight | maintain | gain_muscle
    onboarding_completed: Mapped[bool] = mapped_column(
        nullable=False, default=False, server_default="false"
    )

    # Daily macro targets — calculated once on onboarding, re-calculated on profile update
    daily_calorie_target: Mapped[Optional[int]] = mapped_column(nullable=True)
    daily_protein_g: Mapped[Optional[int]] = mapped_column(nullable=True)
    daily_carbs_g: Mapped[Optional[int]] = mapped_column(nullable=True)
    daily_fat_g: Mapped[Optional[int]] = mapped_column(nullable=True)

    # Localisation — ISO 639-1: en | he
    preferred_language: Mapped[str] = mapped_column(
        String(5), nullable=False, default="en", server_default="en"
    )

    # Device / notification
    fcm_token: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False, default="UTC")

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # ── Relationships ────────────────────────────────────────────────────────
    daily_logs: Mapped[List[DailyLog]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="select"
    )
    meals: Mapped[List[Meal]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="select"
    )
    sos_sessions: Mapped[List[SosSession]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="select"
    )
    push_logs: Mapped[List[PushNotificationLog]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="select"
    )
    ai_interactions: Mapped[List[AIInteraction]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="select"
    )
    behavior_patterns: Mapped[List[UserBehaviorPattern]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="select"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"
