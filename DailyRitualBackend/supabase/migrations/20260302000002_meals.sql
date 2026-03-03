-- Meals table for photo-based meal logging with AI calorie/macro estimation

CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    photo_storage_path TEXT,
    photo_url TEXT,
    food_description TEXT,
    estimated_calories INTEGER,
    estimated_protein_g DECIMAL,
    estimated_carbs_g DECIMAL,
    estimated_fat_g DECIMAL,
    estimated_fiber_g DECIMAL,
    ai_confidence DECIMAL,
    user_calories INTEGER,
    user_protein_g DECIMAL,
    user_carbs_g DECIMAL,
    user_fat_g DECIMAL,
    user_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index on (user_id, date) for daily queries
CREATE INDEX idx_meals_user_date ON meals(user_id, date DESC);

-- Enable RLS
ALTER TABLE meals ENABLE ROW LEVEL SECURITY;

-- Users can view their own meals
CREATE POLICY "Users can view own meals"
    ON meals FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own meals
CREATE POLICY "Users can insert own meals"
    ON meals FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own meals
CREATE POLICY "Users can update own meals"
    ON meals FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own meals
CREATE POLICY "Users can delete own meals"
    ON meals FOR DELETE USING (auth.uid() = user_id);

-- Service role full access
CREATE POLICY "Service role full access to meals"
    ON meals FOR ALL USING (auth.role() = 'service_role');

-- Create meal-photos storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'meal-photos',
    'meal-photos',
    false,
    10485760, -- 10MB
    ARRAY['image/jpeg', 'image/png', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: users can only access their own folder
CREATE POLICY "Users can upload own meal photos"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'meal-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can view own meal photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'meal-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete own meal photos"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'meal-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Service role full access to storage
CREATE POLICY "Service role full access to meal photos"
    ON storage.objects FOR ALL
    USING (bucket_id = 'meal-photos' AND auth.role() = 'service_role');
