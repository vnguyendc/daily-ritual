-- Enhanced insights: new types, trigger context, and summary column

-- Drop existing constraint and add expanded one
ALTER TABLE ai_insights DROP CONSTRAINT IF EXISTS ai_insights_insight_type_check;
ALTER TABLE ai_insights ADD CONSTRAINT ai_insights_insight_type_check
    CHECK (insight_type IN (
        'morning', 'evening', 'weekly', 'competition_prep', 'pattern_analysis',
        'post_workout', 'post_meal', 'daily_nutrition', 'weekly_comprehensive'
    ));

-- Store the data that triggered the insight (workout ID, meal ID, etc.)
ALTER TABLE ai_insights ADD COLUMN IF NOT EXISTS trigger_context JSONB;

-- Short 1-line preview for list views
ALTER TABLE ai_insights ADD COLUMN IF NOT EXISTS summary TEXT;
