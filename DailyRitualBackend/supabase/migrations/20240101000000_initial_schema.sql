-- Daily Ritual Database Schema
-- Athletic Performance Journaling App

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    primary_sport TEXT,
    morning_reminder_time TIME DEFAULT '07:00:00',
    fitness_connected BOOLEAN DEFAULT false,
    whoop_connected BOOLEAN DEFAULT false,
    strava_connected BOOLEAN DEFAULT false,
    apple_health_connected BOOLEAN DEFAULT false,
    timezone TEXT DEFAULT 'UTC',
    subscription_status TEXT DEFAULT 'free' CHECK (subscription_status IN ('free', 'premium', 'trial')),
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily entries table (morning ritual + evening reflection)
CREATE TABLE daily_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,

    -- Morning ritual fields
    goals TEXT[] CHECK (array_length(goals, 1) <= 3),
    affirmation TEXT,
    gratitudes TEXT[] CHECK (array_length(gratitudes, 1) <= 3),
    daily_quote TEXT,
    quote_reflection TEXT,

    -- Training plan
    planned_training_type TEXT CHECK (planned_training_type IN ('strength', 'cardio', 'skills', 'competition', 'rest', 'cross_training', 'recovery')),
    planned_training_time TIME,
    planned_intensity TEXT CHECK (planned_intensity IN ('light', 'moderate', 'hard', 'very_hard')),
    planned_duration INTEGER, -- minutes

    morning_completed_at TIMESTAMP WITH TIME ZONE,

    -- Evening reflection fields
    quote_application TEXT, -- How did today's quote apply?
    day_went_well TEXT,
    day_improve TEXT,
    overall_mood INTEGER CHECK (overall_mood >= 1 AND overall_mood <= 5),
    evening_completed_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, date)
);

-- Workout reflections table
CREATE TABLE workout_reflections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    workout_sequence INTEGER DEFAULT 1, -- For multiple workouts per day

    -- External fitness data
    strain_score DECIMAL,
    recovery_score DECIMAL,
    sleep_performance DECIMAL,
    hrv DECIMAL,
    resting_hr INTEGER,
    max_hr INTEGER,
    average_hr INTEGER,
    calories_burned INTEGER,
    duration_minutes INTEGER,

    -- Workout details
    workout_type TEXT,
    workout_intensity TEXT CHECK (workout_intensity IN ('light', 'moderate', 'hard', 'very_hard')),
    
    -- User reflection
    training_feeling INTEGER CHECK (training_feeling >= 1 AND training_feeling <= 5), -- 1=Terrible, 5=Amazing
    what_went_well TEXT,
    what_to_improve TEXT,
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    focus_level INTEGER CHECK (focus_level >= 1 AND focus_level <= 5),
    
    -- External integration IDs
    strava_activity_id TEXT,
    apple_workout_id TEXT,
    whoop_activity_id TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Journal entries table (anytime journaling)
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT,
    content TEXT NOT NULL,
    mood INTEGER CHECK (mood >= 1 AND mood <= 10),
    energy INTEGER CHECK (energy >= 1 AND energy <= 10),
    tags TEXT[],
    is_private BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Competitions table
CREATE TABLE competitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sport TEXT,
    competition_date DATE NOT NULL,
    location TEXT,
    description TEXT,
    goal_time TEXT,
    goal_placement TEXT,
    importance_level INTEGER CHECK (importance_level >= 1 AND importance_level <= 5), -- 1=Local fun, 5=Olympic trials
    status TEXT DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'completed', 'cancelled')),
    
    -- Competition results (filled after completion)
    actual_time TEXT,
    actual_placement TEXT,
    performance_rating INTEGER CHECK (performance_rating >= 1 AND performance_rating <= 5),
    mental_performance_rating INTEGER CHECK (mental_performance_rating >= 1 AND mental_performance_rating <= 5),
    lessons_learned TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Competition preparation entries (special daily entries during prep)
CREATE TABLE competition_prep_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    competition_id UUID REFERENCES competitions(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    days_until_competition INTEGER,
    
    -- Mental preparation tracking
    confidence_level INTEGER CHECK (confidence_level >= 1 AND confidence_level <= 5),
    anxiety_level INTEGER CHECK (anxiety_level >= 1 AND anxiety_level <= 5),
    readiness_level INTEGER CHECK (readiness_level >= 1 AND readiness_level <= 5),
    
    -- Preparation notes
    mental_focus_notes TEXT,
    physical_preparation_notes TEXT,
    strategy_notes TEXT,
    concerns TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, competition_id, date)
);

-- AI insights table (generated insights for users)
CREATE TABLE ai_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    insight_type TEXT NOT NULL CHECK (insight_type IN ('morning', 'evening', 'weekly', 'competition_prep', 'pattern_analysis')),
    content TEXT NOT NULL,
    data_period_start DATE,
    data_period_end DATE,
    confidence_score DECIMAL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quotes table (curated athlete quotes)
CREATE TABLE quotes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quote_text TEXT NOT NULL,
    author TEXT,
    sport TEXT,
    category TEXT CHECK (category IN ('motivation', 'perseverance', 'confidence', 'preparation', 'competition', 'recovery', 'teamwork', 'mental_strength', 'determination')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User streaks tracking
CREATE TABLE user_streaks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    streak_type TEXT NOT NULL CHECK (streak_type IN ('morning_ritual', 'workout_reflection', 'evening_reflection', 'daily_complete')),
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_completed_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, streak_type)
);

-- Indexes for performance
CREATE INDEX idx_daily_entries_user_date ON daily_entries(user_id, date DESC);
CREATE INDEX idx_workout_reflections_user_date ON workout_reflections(user_id, date DESC);
CREATE INDEX idx_journal_entries_user_created ON journal_entries(user_id, created_at DESC);
CREATE INDEX idx_competitions_user_date ON competitions(user_id, competition_date);
CREATE INDEX idx_competition_prep_entries_competition ON competition_prep_entries(competition_id, date);
CREATE INDEX idx_ai_insights_user_type ON ai_insights(user_id, insight_type, created_at DESC);
CREATE INDEX idx_user_streaks_user ON user_streaks(user_id);

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_entries_updated_at BEFORE UPDATE ON daily_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workout_reflections_updated_at BEFORE UPDATE ON workout_reflections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON journal_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_competitions_updated_at BEFORE UPDATE ON competitions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_competition_prep_entries_updated_at BEFORE UPDATE ON competition_prep_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample quotes
INSERT INTO quotes (quote_text, author, sport, category) VALUES
('The only impossible journey is the one you never begin.', 'Tony Robbins', 'general', 'motivation'),
('Champions aren''t made in the gyms. Champions are made from something deep inside them - a desire, a dream, a vision.', 'Muhammad Ali', 'boxing', 'motivation'),
('It''s not whether you get knocked down; it''s whether you get up.', 'Vince Lombardi', 'football', 'perseverance'),
('The will to win, the desire to succeed, the urge to reach your full potential... these are the keys that will unlock the door to personal excellence.', 'Confucius', 'general', 'motivation'),
('Confidence comes from preparation.', 'John Wooden', 'basketball', 'preparation'),
('The miracle isn''t that I finished. The miracle is that I had the courage to start.', 'John Bingham', 'running', 'perseverance'),
('Your body can stand almost anything. It''s your mind that you have to convince.', 'Unknown', 'general', 'mental_strength'),
('Pain is temporary. Quitting lasts forever.', 'Lance Armstrong', 'cycling', 'perseverance'),
('The difference between the impossible and the possible lies in a person''s determination.', 'Tommy Lasorda', 'baseball', 'determination'),
('Success is where preparation and opportunity meet.', 'Bobby Unser', 'racing', 'preparation');
