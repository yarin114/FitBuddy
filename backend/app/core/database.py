from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import get_settings

settings = get_settings()

# pool_pre_ping=True: SQLAlchemy will test the connection on checkout and
# transparently reconnect if the server closed it (e.g. after idle timeout).
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,       # SQL logging in dev; False in production
    pool_pre_ping=True,
    pool_size=10,              # baseline connections kept alive
    max_overflow=20,           # extra connections allowed under load
)

# expire_on_commit=False: keeps ORM objects usable after commit inside
# async routes (avoids lazy-load errors when returning Pydantic schemas).
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)
