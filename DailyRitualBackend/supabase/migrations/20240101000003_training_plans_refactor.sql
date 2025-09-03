-- Training plans and reflections refactor

-- 1) Create training_plans (multi per day)
CREATE TABLE IF NOT EXISTS training_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  sequence INTEGER DEFAULT 1, -- ordering when multiple plans exist
  type TEXT CHECK (type IN ('strength','cardio','skills','competition','rest','cross_training','recovery')) NOT NULL,
  start_time TIME,
  intensity TEXT CHECK (intensity IN ('light','moderate','hard','very_hard')),
  duration_minutes INTEGER,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date, sequence)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_training_plans_user_date ON training_plans(user_id, date DESC);

-- Enable RLS and policies
ALTER TABLE training_plans ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'training_plans' AND policyname = 'tp_select_own'
  ) THEN
    CREATE POLICY tp_select_own ON training_plans FOR SELECT USING (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'training_plans' AND policyname = 'tp_insert_own'
  ) THEN
    CREATE POLICY tp_insert_own ON training_plans FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'training_plans' AND policyname = 'tp_update_own'
  ) THEN
    CREATE POLICY tp_update_own ON training_plans FOR UPDATE USING (user_id = auth.uid());
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'training_plans' AND policyname = 'tp_delete_own'
  ) THEN
    CREATE POLICY tp_delete_own ON training_plans FOR DELETE USING (user_id = auth.uid());
  END IF;
END$$;

-- 2) Tie workout_reflections to training_plans and simplify columns
ALTER TABLE workout_reflections
  ADD COLUMN IF NOT EXISTS training_plan_id UUID REFERENCES training_plans(id) ON DELETE SET NULL;

-- Drop extraneous columns if they exist (keeping simple reflection fields)
ALTER TABLE workout_reflections
  DROP COLUMN IF EXISTS strain_score,
  DROP COLUMN IF EXISTS recovery_score,
  DROP COLUMN IF EXISTS sleep_performance,
  DROP COLUMN IF EXISTS hrv,
  DROP COLUMN IF EXISTS resting_hr,
  DROP COLUMN IF EXISTS max_hr,
  DROP COLUMN IF EXISTS average_hr,
  DROP COLUMN IF EXISTS calories_burned,
  DROP COLUMN IF EXISTS duration_minutes,
  DROP COLUMN IF EXISTS workout_type,
  DROP COLUMN IF EXISTS workout_intensity,
  DROP COLUMN IF EXISTS strava_activity_id,
  DROP COLUMN IF EXISTS apple_workout_id,
  DROP COLUMN IF EXISTS whoop_activity_id;

-- Ensure core reflection fields are present with constraints
ALTER TABLE workout_reflections
  ALTER COLUMN training_feeling DROP DEFAULT,
  ALTER COLUMN training_feeling TYPE INTEGER,
  ALTER COLUMN what_went_well DROP DEFAULT,
  ALTER COLUMN what_to_improve DROP DEFAULT,
  ALTER COLUMN energy_level TYPE INTEGER,
  ALTER COLUMN focus_level TYPE INTEGER;

-- Add simple bounds (Postgres CHECKs)
ALTER TABLE workout_reflections
  ADD CONSTRAINT wr_training_feeling_ck CHECK (training_feeling IS NULL OR (training_feeling >= 1 AND training_feeling <= 5)),
  ADD CONSTRAINT wr_energy_level_ck CHECK (energy_level IS NULL OR (energy_level >= 1 AND energy_level <= 5)),
  ADD CONSTRAINT wr_focus_level_ck CHECK (focus_level IS NULL OR (focus_level >= 1 AND focus_level <= 5));

CREATE INDEX IF NOT EXISTS idx_wr_user_date ON workout_reflections(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_wr_training_plan ON workout_reflections(training_plan_id);

-- 3) Remove competitions and competition_prep_entries (simplified V1)
DROP TABLE IF EXISTS competition_prep_entries CASCADE;
DROP TABLE IF EXISTS competitions CASCADE;


