-- Add planned_notes to daily_entries for training plan notes
ALTER TABLE daily_entries
ADD COLUMN IF NOT EXISTS planned_notes TEXT;


