"""add goal and onboarding_completed to users

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-15

Adds:
  - users.goal              VARCHAR(20) nullable
  - users.onboarding_completed BOOLEAN NOT NULL DEFAULT false
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("goal", sa.String(20), nullable=True))
    op.add_column(
        "users",
        sa.Column(
            "onboarding_completed",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )


def downgrade() -> None:
    op.drop_column("users", "onboarding_completed")
    op.drop_column("users", "goal")
