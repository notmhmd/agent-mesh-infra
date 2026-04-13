-- Minimal schema for Agent Mesh (extend in migrations later)
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGSERIAL PRIMARY KEY,
    source TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS execution_events (
    id BIGSERIAL PRIMARY KEY,
    intent_id TEXT,
    trace_id TEXT,
    status TEXT NOT NULL,
    detail JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_execution_events_created_at ON execution_events (created_at DESC);

-- LLM strategist output (read by signal/risk layers; never written by execution gateway)
CREATE TABLE IF NOT EXISTS market_intelligence (
    id BIGSERIAL PRIMARY KEY,
    regime VARCHAR(64) NOT NULL,
    sentiment_score DECIMAL(8, 4) NOT NULL,
    regime_multiplier DECIMAL(6, 3) NOT NULL,
    summary TEXT,
    source VARCHAR(32) NOT NULL DEFAULT 'LLM',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_market_intelligence_created_at ON market_intelligence (created_at DESC);
