# Import all models here so that:
# 1. Alembic's env.py can do ``from app.models import Base`` and see every table.
# 2. SQLAlchemy relationship resolution works at import time.

from app.models.base import Base
from app.models.user import User
from app.models.daily_log import DailyLog
from app.models.meal import Meal
from app.models.behavior_pattern import UserBehaviorPattern
from app.models.push_log import PushNotificationLog
from app.models.sos_session import SosSession
from app.models.ai_interaction import AIInteraction

__all__ = [
    "Base",
    "User",
    "DailyLog",
    "Meal",
    "UserBehaviorPattern",
    "PushNotificationLog",
    "SosSession",
    "AIInteraction",
]
