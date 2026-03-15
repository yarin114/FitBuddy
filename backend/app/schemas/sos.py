from datetime import datetime
from typing import List, Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str
    timestamp: datetime


class SosSessionResponse(BaseModel):
    id: UUID
    started_at: datetime
    ended_at: Optional[datetime]
    messages: List[ChatMessage]
    outcome: Optional[str]

    model_config = {"from_attributes": True}
