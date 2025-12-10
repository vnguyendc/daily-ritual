-- Migration: Expand training activity types to 50+ comprehensive options
-- This migration expands the training_plans type constraint to include
-- a comprehensive list of activities similar to Whoop's activity library

-- Step 1: Drop the existing type constraint
ALTER TABLE training_plans DROP CONSTRAINT IF EXISTS training_plans_type_check;

-- Step 2: Add new expanded constraint with 50+ activity types
ALTER TABLE training_plans ADD CONSTRAINT training_plans_type_check CHECK (type IN (
  -- Strength & Conditioning
  'strength_training',
  'functional_fitness',
  'crossfit',
  'weightlifting',
  'powerlifting',
  'bodybuilding',
  'olympic_lifting',
  'calisthenics',
  
  -- Cardiovascular
  'running',
  'cycling',
  'swimming',
  'rowing',
  'elliptical',
  'stair_climbing',
  'jump_rope',
  
  -- Combat Sports
  'boxing',
  'kickboxing',
  'mma',
  'muay_thai',
  'jiu_jitsu',
  'karate',
  'taekwondo',
  'wrestling',
  
  -- Team Sports
  'basketball',
  'soccer',
  'football',
  'volleyball',
  'baseball',
  'hockey',
  'rugby',
  'lacrosse',
  
  -- Racquet Sports
  'tennis',
  'squash',
  'racquetball',
  'badminton',
  'pickleball',
  
  -- Individual Sports
  'golf',
  'skiing',
  'snowboarding',
  'surfing',
  'skateboarding',
  'rock_climbing',
  'bouldering',
  'hiking',
  'trail_running',
  
  -- Mind-Body
  'yoga',
  'pilates',
  'tai_chi',
  'meditation',
  'stretching',
  'mobility',
  
  -- Recovery & Other
  'recovery',
  'rest',
  'active_recovery',
  'physical_therapy',
  'massage',
  'walking',
  'other',
  
  -- Legacy types for backward compatibility
  'strength',
  'cardio',
  'skills',
  'competition',
  'cross_training'
));

-- Step 3: Optional data migration - Map old types to new naming convention
-- These updates preserve backward compatibility while encouraging new naming
-- Users with old type names can keep them, or be migrated

-- Uncomment to migrate existing data to new type names:
-- UPDATE training_plans SET type = 'strength_training' WHERE type = 'strength';
-- UPDATE training_plans SET type = 'running' WHERE type = 'cardio';

-- Note: We keep 'strength', 'cardio', 'skills', 'competition', 'rest', 
-- 'cross_training', 'recovery' in the constraint for backward compatibility
-- with existing data. New UI should use the expanded type names.

COMMENT ON COLUMN training_plans.type IS 
  'Activity type - 50+ options including strength_training, running, boxing, yoga, etc. Legacy types (strength, cardio, skills) still supported for backward compatibility.';

