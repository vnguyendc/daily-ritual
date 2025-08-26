-- Row Level Security (RLS) Policies for Daily Ritual
-- Ensures users can only access their own data

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE competition_prep_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;

-- Quotes table is public (read-only for all authenticated users)
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Daily entries policies
CREATE POLICY "Users can view own daily entries" ON daily_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily entries" ON daily_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily entries" ON daily_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own daily entries" ON daily_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Workout reflections policies
CREATE POLICY "Users can view own workout reflections" ON workout_reflections
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout reflections" ON workout_reflections
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout reflections" ON workout_reflections
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout reflections" ON workout_reflections
    FOR DELETE USING (auth.uid() = user_id);

-- Journal entries policies
CREATE POLICY "Users can view own journal entries" ON journal_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own journal entries" ON journal_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journal entries" ON journal_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own journal entries" ON journal_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Competitions policies
CREATE POLICY "Users can view own competitions" ON competitions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own competitions" ON competitions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own competitions" ON competitions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own competitions" ON competitions
    FOR DELETE USING (auth.uid() = user_id);

-- Competition prep entries policies
CREATE POLICY "Users can view own competition prep entries" ON competition_prep_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own competition prep entries" ON competition_prep_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own competition prep entries" ON competition_prep_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own competition prep entries" ON competition_prep_entries
    FOR DELETE USING (auth.uid() = user_id);

-- AI insights policies
CREATE POLICY "Users can view own AI insights" ON ai_insights
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own AI insights" ON ai_insights
    FOR UPDATE USING (auth.uid() = user_id);

-- AI insights can only be inserted by service role (Edge Functions)
CREATE POLICY "Service role can insert AI insights" ON ai_insights
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- User streaks policies
CREATE POLICY "Users can view own streaks" ON user_streaks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streaks" ON user_streaks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks" ON user_streaks
    FOR UPDATE USING (auth.uid() = user_id);

-- Quotes policies (public read access for authenticated users)
CREATE POLICY "Authenticated users can view quotes" ON quotes
    FOR SELECT USING (auth.role() = 'authenticated');

-- Functions to handle user creation and streak initialization
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Initialize user streaks when a new user is created
    INSERT INTO public.user_streaks (user_id, streak_type, current_streak, longest_streak, last_completed_date)
    VALUES 
        (NEW.id, 'morning_ritual', 0, 0, NULL),
        (NEW.id, 'workout_reflection', 0, 0, NULL),
        (NEW.id, 'evening_reflection', 0, 0, NULL),
        (NEW.id, 'daily_complete', 0, 0, NULL);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to initialize streaks for new users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update streaks
CREATE OR REPLACE FUNCTION public.update_user_streak(
    p_user_id UUID,
    p_streak_type TEXT,
    p_completed_date DATE DEFAULT CURRENT_DATE
)
RETURNS VOID AS $$
DECLARE
    current_streak_record RECORD;
    new_streak INTEGER;
BEGIN
    -- Get current streak info
    SELECT current_streak, longest_streak, last_completed_date
    INTO current_streak_record
    FROM user_streaks
    WHERE user_id = p_user_id AND streak_type = p_streak_type;
    
    -- If no record exists, create it
    IF NOT FOUND THEN
        INSERT INTO user_streaks (user_id, streak_type, current_streak, longest_streak, last_completed_date)
        VALUES (p_user_id, p_streak_type, 1, 1, p_completed_date);
        RETURN;
    END IF;
    
    -- Calculate new streak
    IF current_streak_record.last_completed_date IS NULL THEN
        new_streak := 1;
    ELSIF current_streak_record.last_completed_date = p_completed_date THEN
        -- Same day, no change
        RETURN;
    ELSIF current_streak_record.last_completed_date = p_completed_date - INTERVAL '1 day' THEN
        -- Consecutive day
        new_streak := current_streak_record.current_streak + 1;
    ELSE
        -- Streak broken
        new_streak := 1;
    END IF;
    
    -- Update the streak
    UPDATE user_streaks
    SET 
        current_streak = new_streak,
        longest_streak = GREATEST(current_streak_record.longest_streak, new_streak),
        last_completed_date = p_completed_date,
        updated_at = NOW()
    WHERE user_id = p_user_id AND streak_type = p_streak_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get daily quote for user
CREATE OR REPLACE FUNCTION public.get_daily_quote(p_user_id UUID, p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(id UUID, quote_text TEXT, author TEXT, sport TEXT, category TEXT) AS $$
BEGIN
    -- Use a deterministic method to select quote based on user and date
    -- This ensures the same user gets the same quote on the same day
    RETURN QUERY
    SELECT q.id, q.quote_text, q.author, q.sport, q.category
    FROM quotes q
    WHERE q.is_active = true
    ORDER BY md5(p_user_id::text || p_date::text || q.id::text)
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
