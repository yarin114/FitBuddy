"""
Notification Service
──────────────────────
Thin wrapper around Firebase Admin SDK's FCM messaging.
Keeps Firebase-specific calls isolated from business logic.
"""

import logging

from firebase_admin import messaging

logger = logging.getLogger(__name__)


async def send_push(fcm_token: str, title: str, body: str, data: dict | None = None) -> None:
    """
    Send a Firebase Cloud Messaging push notification to a single device.

    ``data`` is an optional dict of string key-value pairs for deep-linking
    (e.g. {"meal_id": "...", "screen": "recipe"}).
    """
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        token=fcm_token,
    )
    try:
        # messaging.send() is synchronous — acceptable here because it's
        # only called from background workers, never inside an async request path.
        response = messaging.send(message)
        logger.info("FCM message sent: %s", response)
    except messaging.UnregisteredError:
        logger.warning("FCM token unregistered (device uninstalled app): %s", fcm_token)
    except Exception as exc:
        logger.error("FCM send failed: %s", exc)
        raise
