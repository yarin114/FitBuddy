import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.database import engine
from app.core.firebase_admin import initialize_firebase
from app.workers.scheduler import register_jobs, scheduler

settings = get_settings()

logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # ── Startup ───────────────────────────────────────────────────────────────
    logger.info("FitBuddy API starting up...")

    initialize_firebase()

    register_jobs()
    scheduler.start()
    logger.info("APScheduler started with %d jobs.", len(scheduler.get_jobs()))

    yield

    # ── Shutdown ──────────────────────────────────────────────────────────────
    logger.info("FitBuddy API shutting down...")

    scheduler.shutdown(wait=False)
    logger.info("APScheduler stopped.")

    await engine.dispose()
    logger.info("Database engine disposed.")


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    # Disable interactive docs in production to reduce attack surface
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────────────────────
# Tighten allow_origins to your Flutter app's domain before going to production.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
# Imported after app creation to prevent circular imports at module load time.
from app.api.v1 import auth, macros, meals, notifications, sos, users  # noqa: E402

app.include_router(auth.router,          prefix="/api/v1/auth",          tags=["Auth"])
app.include_router(users.router,         prefix="/api/v1/users",         tags=["Users"])
app.include_router(macros.router,        prefix="/api/v1/macros",        tags=["Macros"])
app.include_router(meals.router,         prefix="/api/v1/meals",         tags=["Meals"])
app.include_router(sos.router,           prefix="/api/v1/sos",           tags=["SOS"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["Notifications"])


@app.get("/health", tags=["Health"])
async def health_check() -> dict:
    return {"status": "ok", "service": settings.app_name, "version": "0.1.0"}
