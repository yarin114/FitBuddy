"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-03-15 11:48:28

Creates all tables from scratch using the current SQLAlchemy models.
Includes Supabase-based auth (supabase_uid on users table).
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers
revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users ─────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("supabase_uid", sa.String(128), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("email", sa.String(320), nullable=False),
        sa.Column("date_of_birth", sa.Date(), nullable=True),
        sa.Column("gender", sa.String(20), nullable=True),
        sa.Column("weight_kg", sa.Float(), nullable=True),
        sa.Column("height_cm", sa.Float(), nullable=True),
        sa.Column("goal_weight_kg", sa.Float(), nullable=True),
        sa.Column("activity_level", sa.String(20), nullable=True),
        sa.Column("daily_calorie_target", sa.Integer(), nullable=True),
        sa.Column("daily_protein_g", sa.Integer(), nullable=True),
        sa.Column("daily_carbs_g", sa.Integer(), nullable=True),
        sa.Column("daily_fat_g", sa.Integer(), nullable=True),
        sa.Column("fcm_token", sa.String(512), nullable=True),
        sa.Column("timezone", sa.String(64), nullable=False, server_default="UTC"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("supabase_uid"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_supabase_uid", "users", ["supabase_uid"], unique=True)

    # ── daily_logs ────────────────────────────────────────────────────────────
    op.create_table(
        "daily_logs",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("log_date", sa.Date(), nullable=False),
        sa.Column("total_calories", sa.Integer(), nullable=True),
        sa.Column("total_protein_g", sa.Float(), nullable=True),
        sa.Column("total_carbs_g", sa.Float(), nullable=True),
        sa.Column("total_fat_g", sa.Float(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "log_date", name="uq_daily_log_user_date"),
    )

    # ── meals ─────────────────────────────────────────────────────────────────
    op.create_table(
        "meals",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("daily_log_id", sa.UUID(), nullable=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("calories", sa.Integer(), nullable=False),
        sa.Column("protein_g", sa.Float(), nullable=True),
        sa.Column("carbs_g", sa.Float(), nullable=True),
        sa.Column("fat_g", sa.Float(), nullable=True),
        sa.Column("meal_type", sa.String(20), nullable=True),
        sa.Column("logged_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["daily_log_id"], ["daily_logs.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_meals_user_logged_at", "meals", ["user_id", "logged_at"])

    # ── sos_sessions ──────────────────────────────────────────────────────────
    op.create_table(
        "sos_sessions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("trigger_type", sa.String(50), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("outcome", sa.String(50), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── push_notification_logs ────────────────────────────────────────────────
    op.create_table(
        "push_notification_logs",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("trigger_reason", sa.String(50), nullable=False),
        sa.Column("title", sa.String(128), nullable=False),
        sa.Column("body", sa.String(512), nullable=False),
        sa.Column("suggested_craving", sa.String(255), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("fcm_message_id", sa.String(255), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_push_logs_user_sent_at",
        "push_notification_logs",
        ["user_id", "sent_at"],
    )

    # ── ai_interactions ───────────────────────────────────────────────────────
    op.create_table(
        "ai_interactions",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("interaction_type", sa.String(50), nullable=False),
        sa.Column("prompt_tokens", sa.Integer(), nullable=True),
        sa.Column("completion_tokens", sa.Integer(), nullable=True),
        sa.Column("latency_ms", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── user_behavior_patterns ────────────────────────────────────────────────
    op.create_table(
        "user_behavior_patterns",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("pattern_type", sa.String(50), nullable=False),
        sa.Column("detected_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("metadata", sa.JSON(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("user_behavior_patterns")
    op.drop_table("ai_interactions")
    op.drop_index("ix_push_logs_user_sent_at", table_name="push_notification_logs")
    op.drop_table("push_notification_logs")
    op.drop_table("sos_sessions")
    op.drop_index("ix_meals_user_logged_at", table_name="meals")
    op.drop_table("meals")
    op.drop_table("daily_logs")
    op.drop_index("ix_users_supabase_uid", table_name="users")
    op.drop_table("users")
