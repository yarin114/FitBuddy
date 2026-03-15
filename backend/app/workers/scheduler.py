import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger

from app.core.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Single scheduler instance — started/stopped inside the FastAPI lifespan.
scheduler = AsyncIOScheduler(timezone="UTC")


def register_jobs() -> None:
    """
    Register all background jobs.
    Called once during application startup before ``scheduler.start()``.
    Jobs are imported here (not at module level) to avoid circular imports
    at the time the scheduler module itself is loaded.
    """
    from app.workers.behavior_analyzer import run as behavior_run
    from app.workers.push_worker import run as push_run

    scheduler.add_job(
        push_run,
        trigger=IntervalTrigger(minutes=settings.push_worker_interval_minutes),
        id="push_worker",
        name="Proactive Push Coach Daemon",
        replace_existing=True,
        misfire_grace_time=60,   # allow up to 60 s late if the event loop was busy
    )

    scheduler.add_job(
        behavior_run,
        trigger=CronTrigger(day_of_week="sun", hour=2, minute=0, timezone="UTC"),
        id="behavior_analyzer",
        name="Weekly Behavior Pattern Analyzer",
        replace_existing=True,
    )

    logger.info(
        "Registered %d APScheduler jobs: %s",
        len(scheduler.get_jobs()),
        [j.id for j in scheduler.get_jobs()],
    )
