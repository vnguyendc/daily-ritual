-- User integrations table for OAuth token storage (Whoop, Strava, etc.)
CREATE TABLE IF NOT EXISTS user_integrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service TEXT NOT NULL CHECK (service IN ('whoop', 'strava', 'apple_health')),
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMPTZ,
    external_user_id TEXT,
    last_sync_at TIMESTAMPTZ,
    connected_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, service)
);

-- Indexes
CREATE INDEX idx_user_integrations_user_id ON user_integrations(user_id);
CREATE INDEX idx_user_integrations_service ON user_integrations(service);
CREATE INDEX idx_user_integrations_external_user ON user_integrations(service, external_user_id);

-- RLS policies
ALTER TABLE user_integrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own integrations"
    ON user_integrations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own integrations"
    ON user_integrations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own integrations"
    ON user_integrations FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own integrations"
    ON user_integrations FOR DELETE
    USING (auth.uid() = user_id);

-- Service role bypass for backend operations
CREATE POLICY "Service role full access to integrations"
    ON user_integrations FOR ALL
    USING (auth.role() = 'service_role');
