from sqlalchemy import MetaData
from sqlalchemy.orm import AsyncAttrs, DeclarativeBase

# Alembic-friendly naming conventions so auto-generated constraint names are
# deterministic and portable across databases.
NAMING_CONVENTION: dict[str, str] = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(AsyncAttrs, DeclarativeBase):
    """
    Shared declarative base for all ORM models.

    AsyncAttrs allows lazy-loaded relationships to be awaited in async
    contexts (e.g. ``await user.awaitable_attrs.daily_logs``).
    """

    metadata = MetaData(naming_convention=NAMING_CONVENTION)
