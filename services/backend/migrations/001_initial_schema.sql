-- LumeraAI Initial Schema

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT UNIQUE NOT NULL,
    name            TEXT NOT NULL,
    password_hash   TEXT NOT NULL,
    is_blind        BOOLEAN NOT NULL DEFAULT FALSE,
    is_low_vision   BOOLEAN NOT NULL DEFAULT FALSE,
    prefers_haptic_only BOOLEAN NOT NULL DEFAULT FALSE,
    haptic_intensity TEXT NOT NULL DEFAULT 'medium',
    audio_volume    DOUBLE PRECISION NOT NULL DEFAULT 0.9,
    voice_feedback  BOOLEAN NOT NULL DEFAULT TRUE,
    preferred_language TEXT NOT NULL DEFAULT 'en-US',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Routes
CREATE TABLE routes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                TEXT NOT NULL,
    description         TEXT NOT NULL DEFAULT '',
    environment         TEXT NOT NULL,
    segments            JSONB NOT NULL DEFAULT '[]',
    total_distance_m    DOUBLE PRECISION NOT NULL DEFAULT 0,
    complexity_rating   TEXT NOT NULL DEFAULT 'beginner-safe',
    tags                TEXT[] NOT NULL DEFAULT '{}',
    known_hazard_notes  TEXT[] NOT NULL DEFAULT '{}',
    validation_status   TEXT NOT NULL DEFAULT 'pending',
    created_by          UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sessions
CREATE TABLE sessions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id),
    route_id                UUID NOT NULL REFERENCES routes(id),
    run_mode                TEXT NOT NULL,
    started_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at                TIMESTAMPTZ,
    state                   TEXT NOT NULL DEFAULT 'ACTIVE_RUN',
    lap_count               INT NOT NULL DEFAULT 0,
    total_distance_m        DOUBLE PRECISION NOT NULL DEFAULT 0,
    average_pace_mps        DOUBLE PRECISION NOT NULL DEFAULT 0,
    average_heart_rate_bpm  INT,
    max_heart_rate_bpm      INT
);

CREATE INDEX idx_sessions_user ON sessions(user_id);

-- Guidance Events
CREATE TABLE guidance_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES sessions(id),
    timestamp       TIMESTAMPTZ NOT NULL,
    semantic_type   TEXT NOT NULL,
    priority        INT NOT NULL,
    trigger_reason  TEXT NOT NULL DEFAULT '',
    lat             DOUBLE PRECISION,
    lon             DOUBLE PRECISION
);

CREATE INDEX idx_guidance_session ON guidance_events(session_id);

-- Hazard Events
CREATE TABLE hazard_events (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES sessions(id),
    timestamp       TIMESTAMPTZ NOT NULL,
    hazard_type     TEXT NOT NULL,
    severity        TEXT NOT NULL,
    distance_m      DOUBLE PRECISION NOT NULL,
    bearing         DOUBLE PRECISION NOT NULL,
    resolved        BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at     TIMESTAMPTZ
);

CREATE INDEX idx_hazard_session ON hazard_events(session_id);

-- Emergency Events
CREATE TABLE emergency_events (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES sessions(id),
    user_id             UUID NOT NULL REFERENCES users(id),
    triggered_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    trigger_source      TEXT NOT NULL,
    last_known_lat      DOUBLE PRECISION,
    last_known_lon      DOUBLE PRECISION,
    resolved_at         TIMESTAMPTZ,
    checkin_at          TIMESTAMPTZ
);

-- Session Feedback
CREATE TABLE session_feedback (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id              UUID NOT NULL REFERENCES sessions(id),
    user_id                 UUID NOT NULL REFERENCES users(id),
    submitted_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    overall_rating          SMALLINT NOT NULL CHECK (overall_rating BETWEEN 1 AND 5),
    guidance_accuracy       SMALLINT NOT NULL CHECK (guidance_accuracy BETWEEN 1 AND 5),
    haptic_clarity          SMALLINT NOT NULL CHECK (haptic_clarity BETWEEN 1 AND 5),
    free_text_comment       TEXT,
    false_alerts_reported   INT NOT NULL DEFAULT 0,
    missed_alerts_reported  INT NOT NULL DEFAULT 0
);
