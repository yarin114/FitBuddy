import logging

import firebase_admin
from firebase_admin import auth, credentials

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_app: firebase_admin.App | None = None


def initialize_firebase() -> None:
    """
    Initialize the Firebase Admin SDK using the service-account JSON file
    specified in settings.  Must be called once during application startup
    (inside the FastAPI lifespan handler).

    If the credentials file is missing the SDK is skipped and FCM push
    notifications will be unavailable, but all other API features continue
    to work normally.  This allows local development without a Firebase
    service account.
    """
    global _app
    if _app is not None:
        logger.warning("Firebase Admin SDK already initialised — skipping.")
        return

    import os
    settings = get_settings()
    path = settings.firebase_credentials_path

    if not os.path.exists(path):
        logger.warning(
            "Firebase service-account file not found at %r — "
            "FCM push notifications disabled.  "
            "Add the file and restart to enable push.",
            path,
        )
        return

    cred = credentials.Certificate(path)
    _app = firebase_admin.initialize_app(cred)
    logger.info("Firebase Admin SDK initialised.")


def verify_firebase_token(id_token: str) -> dict:
    """
    Verify a Firebase ID token and return the decoded JWT claims.

    Raises ``firebase_admin.auth.InvalidIdTokenError`` (and subclasses) on
    any verification failure — callers should catch these and raise HTTP 401.
    """
    return auth.verify_id_token(id_token)
