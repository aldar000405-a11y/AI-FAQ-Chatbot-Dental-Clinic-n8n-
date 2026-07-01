-- Database setup for the AI FAQ Chatbot workflows
-- Run this once in your Postgres provider (e.g. Neon, Supabase, Railway, or any Postgres instance)
-- Tested against the exact queries used in telegram-faq-chatbot.json and daily-report-digest.json

-- 1. Conversation memory (last 8 messages per patient)
CREATE TABLE chat_sessions (
    id          SERIAL PRIMARY KEY,
    session_id  TEXT NOT NULL,        -- Telegram chat_id
    role        TEXT NOT NULL,        -- 'user' or 'assistant'
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_chat_sessions_session_id ON chat_sessions (session_id, created_at DESC);

-- 2. Escalated / unanswered questions (for human triage + daily report)
CREATE TABLE unanswered_questions (
    id          SERIAL PRIMARY KEY,
    session_id  TEXT NOT NULL,
    question    TEXT NOT NULL,
    reason      TEXT NOT NULL,        -- 'medical_risk' | 'off_topic' | 'no_faq_match'
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. System / AI failures (for IT alerting + daily report)
CREATE TABLE ai_errors (
    id            SERIAL PRIMARY KEY,
    session_id    TEXT,
    error_message TEXT NOT NULL,
    raw_payload   TEXT,               -- JSON.stringify of the failing payload, for debugging
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Token usage + cost tracking (for the daily quota check + cost reporting)
CREATE TABLE user_token_usage (
    id                SERIAL PRIMARY KEY,
    session_id        TEXT NOT NULL,
    model             TEXT NOT NULL,
    prompt_tokens     INTEGER NOT NULL DEFAULT 0,
    completion_tokens INTEGER NOT NULL DEFAULT 0,
    total_tokens      INTEGER NOT NULL DEFAULT 0,
    cost_usd          NUMERIC(10,6) NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_user_token_usage_session_date ON user_token_usage (session_id, created_at);
