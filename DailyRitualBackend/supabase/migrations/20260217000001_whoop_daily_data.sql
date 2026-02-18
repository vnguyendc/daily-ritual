-- Cache table for daily Whoop biometric data (recovery, sleep, strain)
CREATE TABLE IF NOT EXISTS whoop_daily_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    recovery_score REAL,
    recovery_zone TEXT CHECK (recovery_zone IN ('green', 'yellow', 'red')),
    sleep_performance REAL,
    sleep_duration_minutes INT,
    sleep_efficiency REAL,
    sleep_stages JSONB,
    respiratory_rate REAL,
    skin_temp_delta REAL,
    hrv REAL,
    resting_hr INT,
    strain_score REAL,
    raw_recovery_json JSONB,
    raw_sleep_json JSONB,
    raw_cycle_json JSONB,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX idx_whoop_daily_data_user_date ON whoop_daily_data(user_id, date DESC);

ALTER TABLE whoop_daily_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own whoop data"
    ON whoop_daily_data FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role full access to whoop data"
    ON whoop_daily_data FOR ALL USING (auth.role() = 'service_role');
