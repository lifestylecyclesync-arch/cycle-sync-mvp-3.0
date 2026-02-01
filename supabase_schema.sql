-- ============================================================================
-- CYCLE SYNC MVP 2 — SUPABASE SCHEMA
-- ============================================================================
-- Production-ready schema for Cycle Sync app
-- Last updated: 2025-01-30
-- 
-- Instructions:
-- 1. Copy entire file
-- 2. Paste into Supabase SQL Editor
-- 3. Run to create tables and policies
-- 4. Enable RLS on all tables
-- 5. Verify relationships in Data section
-- ============================================================================

-- ============================================================================
-- PART 1: ENABLE EXTENSIONS & SCHEMA ACCESS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enable schema access for PostgREST (must be before DROP statements)
GRANT USAGE ON SCHEMA public TO authenticated, anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated, anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated, anon;

-- ============================================================================
-- PART 2: TABLES
-- ============================================================================

-- USER PROFILES (extends auth.users)
DROP TABLE IF EXISTS public.user_profiles CASCADE;
CREATE TABLE public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  
  -- Cycle data
  cycle_length INTEGER NOT NULL DEFAULT 28 CHECK (cycle_length >= 21 AND cycle_length <= 35),
  menstrual_length INTEGER NOT NULL DEFAULT 5 CHECK (menstrual_length >= 2 AND menstrual_length <= 10),
  last_period_date DATE,
  luteal_phase_length INTEGER NOT NULL DEFAULT 14 CHECK (luteal_phase_length >= 10 AND luteal_phase_length <= 18),
  
  -- Lifestyle preferences
  lifestyle_areas TEXT[] DEFAULT '{}', -- ['Nutrition', 'Fitness', 'Fasting']
  fasting_preference TEXT DEFAULT 'beginner', -- 'beginner' or 'advanced'
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT lifestyle_areas_valid CHECK (
    lifestyle_areas IS NULL OR 
    lifestyle_areas = '{}' OR
    lifestyle_areas && ARRAY['Nutrition', 'Fitness', 'Fasting']
  )
);

-- CYCLES (menstrual cycle records)
DROP TABLE IF EXISTS public.cycles CASCADE;
CREATE TABLE public.cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  
  start_date DATE NOT NULL,
  end_date DATE,
  cycle_length INTEGER DEFAULT 28,
  notes TEXT,
  
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (user_id, start_date)
);

-- CYCLE ENTRIES (daily cycle tracking)
DROP TABLE IF EXISTS public.cycle_entries CASCADE;
CREATE TABLE public.cycle_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  cycle_id UUID REFERENCES public.cycles(id) ON DELETE SET NULL,
  
  entry_date DATE NOT NULL,
  
  -- Flow intensity (1-5 or null if not menstruating)
  flow_intensity INTEGER CHECK (flow_intensity IS NULL OR (flow_intensity >= 1 AND flow_intensity <= 5)),
  
  -- Symptoms (array of symptom tags)
  symptoms TEXT[] DEFAULT '{}',
  
  -- Notes
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (user_id, entry_date)
);

-- WORKOUTS (exercise tracking)
DROP TABLE IF EXISTS public.workouts CASCADE;
CREATE TABLE public.workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  
  workout_date DATE NOT NULL,
  workout_type TEXT NOT NULL, -- e.g., 'Cardio', 'Strength', 'Yoga', 'HIIT'
  duration_minutes INTEGER,
  intensity_level TEXT, -- 'Low', 'Moderate', 'High'
  notes TEXT,
  
  -- Cycle sync
  cycle_day INTEGER,
  hormonal_phase TEXT, -- 'Menstrual', 'Follicular', 'Ovulation', 'Luteal'
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- USER WORKOUTS (linking custom workouts to user plans)
DROP TABLE IF EXISTS public.user_workouts CASCADE;
CREATE TABLE public.user_workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  workout_id UUID REFERENCES public.workouts(id) ON DELETE CASCADE,
  
  -- For planned workouts (prescriptive)
  planned_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RECIPES (canonical recipe data)
DROP TABLE IF EXISTS public.recipes CASCADE;
CREATE TABLE public.recipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  
  -- Nutrition per serving
  calories NUMERIC(8, 2),
  protein_g NUMERIC(8, 2),
  carbs_g NUMERIC(8, 2),
  fat_g NUMERIC(8, 2),
  fiber_g NUMERIC(8, 2),
  
  -- Recipe metadata
  prep_time_minutes INTEGER,
  cook_time_minutes INTEGER,
  servings INTEGER DEFAULT 1,
  
  -- Categorization
  meal_type TEXT, -- 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  cuisine_type TEXT, -- 'Mediterranean', 'Asian', 'Indian', etc.
  dietary_tags TEXT[] DEFAULT '{}', -- ['Vegetarian', 'Gluten-Free', 'Vegan', ...]
  
  -- Cycle phase association
  associated_phases TEXT[] DEFAULT '{}', -- ['Menstrual', 'Follicular', ...]
  food_vibe TEXT, -- 'Gut-Friendly Low-Carb', 'Carb-Boost Hormone Fuel', etc.
  
  -- Image and source
  image_url TEXT,
  source_url TEXT,
  is_custom BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- USER RECIPES (user's saved and planned recipes)
DROP TABLE IF EXISTS public.user_recipes CASCADE;
CREATE TABLE public.user_recipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  
  -- User's personal notes
  personal_notes TEXT,
  
  -- Meal planning
  planned_date DATE,
  meal_type TEXT, -- 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  
  is_favorite BOOLEAN DEFAULT FALSE,
  times_prepared INTEGER DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (user_id, recipe_id, planned_date)
);

-- FASTING SESSIONS (intermittent fasting logs)
DROP TABLE IF EXISTS public.fasting_sessions CASCADE;
CREATE TABLE public.fasting_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  
  fasting_date DATE NOT NULL,
  
  -- Duration tracking
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  duration_hours NUMERIC(4, 2),
  
  fasting_style TEXT, -- 'Short Fast (13h)', 'Medium Fast (15h)', 'Long Fast (17h)', 'Extended Fast (24h)'
  notes TEXT,
  
  -- Cycle sync
  cycle_day INTEGER,
  hormonal_phase TEXT, -- 'Menstrual', 'Follicular', 'Ovulation', 'Luteal'
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- LEARN TEMPLATES (non-hardcoded learn card messages)
DROP TABLE IF EXISTS public.learn_templates CASCADE;
CREATE TABLE public.learn_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  category TEXT NOT NULL, -- 'Fitness', 'Diet', 'Fasting'
  template_text TEXT NOT NULL, -- 'You are in the {placeholder} phase...'
  placeholder_key TEXT, -- 'Workout Mode', 'Food Vibe', 'Fast Style' (can be null for static text)
  sort_order INTEGER DEFAULT 0, -- For consistent ordering
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (category, sort_order)
);

-- NUTRITION DATA (daily nutrition summary)
DROP TABLE IF EXISTS public.nutrition_data CASCADE;
CREATE TABLE public.nutrition_data (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  
  nutrition_date DATE NOT NULL,
  
  -- Daily totals
  total_calories NUMERIC(8, 2),
  total_protein_g NUMERIC(8, 2),
  total_carbs_g NUMERIC(8, 2),
  total_fat_g NUMERIC(8, 2),
  total_fiber_g NUMERIC(8, 2),
  
  -- Micronutrients
  iron_mg NUMERIC(8, 2),
  magnesium_mg NUMERIC(8, 2),
  calcium_mg NUMERIC(8, 2),
  
  -- Cycle sync
  cycle_day INTEGER,
  hormonal_phase TEXT,
  food_vibe TEXT,
  
  notes TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (user_id, nutrition_date)
);

-- ============================================================================
-- PART 3: INDEXES (for performance)
-- ============================================================================

CREATE INDEX idx_cycles_user_id ON public.cycles(user_id);
CREATE INDEX idx_cycles_start_date ON public.cycles(start_date);
CREATE INDEX idx_cycle_entries_user_id ON public.cycle_entries(user_id);
CREATE INDEX idx_cycle_entries_entry_date ON public.cycle_entries(entry_date);
CREATE INDEX idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX idx_workouts_workout_date ON public.workouts(workout_date);
CREATE INDEX idx_user_workouts_user_id ON public.user_workouts(user_id);
CREATE INDEX idx_user_recipes_user_id ON public.user_recipes(user_id);
CREATE INDEX idx_fasting_sessions_user_id ON public.fasting_sessions(user_id);
CREATE INDEX idx_fasting_sessions_fasting_date ON public.fasting_sessions(fasting_date);
CREATE INDEX idx_nutrition_data_user_id ON public.nutrition_data(user_id);
CREATE INDEX idx_nutrition_data_nutrition_date ON public.nutrition_data(nutrition_date);
CREATE INDEX idx_learn_templates_category ON public.learn_templates(category);

-- ============================================================================
-- PART 3B: CYCLE CALCULATION FUNCTIONS
-- ============================================================================

-- Function to calculate current cycle day based on last period date
CREATE OR REPLACE FUNCTION get_current_cycle_day(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  v_last_period_date DATE;
  v_cycle_length INTEGER;
  v_days_since_period BIGINT;
  v_current_cycle_day INTEGER;
BEGIN
  SELECT last_period_date, cycle_length
  INTO v_last_period_date, v_cycle_length
  FROM public.user_profiles
  WHERE id = user_uuid;
  
  IF v_last_period_date IS NULL THEN
    RETURN NULL;
  END IF;
  
  v_days_since_period := CURRENT_DATE - v_last_period_date;
  v_current_cycle_day := (v_days_since_period::INTEGER % v_cycle_length) + 1;
  
  RETURN v_current_cycle_day;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to determine current hormonal phase
CREATE OR REPLACE FUNCTION get_current_phase(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
  v_cycle_day INTEGER;
  v_phase_name TEXT;
BEGIN
  v_cycle_day := get_current_cycle_day(user_uuid);
  
  IF v_cycle_day IS NULL THEN
    RETURN NULL;
  END IF;
  
  CASE
    WHEN v_cycle_day BETWEEN 1 AND 5 THEN v_phase_name := 'Menstrual';
    WHEN v_cycle_day BETWEEN 6 AND 12 THEN v_phase_name := 'Follicular';
    WHEN v_cycle_day BETWEEN 13 AND 15 THEN v_phase_name := 'Ovulation';
    WHEN v_cycle_day BETWEEN 16 AND 28 THEN v_phase_name := 'Luteal';
    ELSE v_phase_name := NULL;
  END CASE;
  
  RETURN v_phase_name;
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger to sync cycle start date to user profile when cycle is created or updated
CREATE OR REPLACE FUNCTION sync_cycle_to_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the user's last_period_date when a new cycle is created
  UPDATE public.user_profiles
  SET 
    last_period_date = NEW.start_date,
    cycle_length = COALESCE(NEW.cycle_length, 28),
    updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on cycles table
CREATE TRIGGER sync_cycle_on_insert_or_update
  AFTER INSERT OR UPDATE ON public.cycles
  FOR EACH ROW
  EXECUTE FUNCTION sync_cycle_to_user_profile();

-- ============================================================================
-- PART 4: ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cycle_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fasting_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nutrition_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learn_templates ENABLE ROW LEVEL SECURITY;

-- user_profiles: Users can only access their own profile
CREATE POLICY "Users can read own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.user_profiles
  FOR DELETE USING (auth.uid() = id);

-- Service role bypass for admin operations
CREATE POLICY "Service role bypass (admin)" ON public.user_profiles
  FOR ALL USING (auth.role() = 'service_role');

-- cycles: Users can only access their own cycles
CREATE POLICY "Users can read own cycles" ON public.cycles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cycles" ON public.cycles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cycles" ON public.cycles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cycles" ON public.cycles
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.cycles
  FOR ALL USING (auth.role() = 'service_role');

-- cycle_entries: Users can only access their own entries
CREATE POLICY "Users can read own cycle entries" ON public.cycle_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cycle entries" ON public.cycle_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cycle entries" ON public.cycle_entries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cycle entries" ON public.cycle_entries
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.cycle_entries
  FOR ALL USING (auth.role() = 'service_role');

-- workouts: Users can only access their own workouts
CREATE POLICY "Users can read own workouts" ON public.workouts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts" ON public.workouts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workouts" ON public.workouts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workouts" ON public.workouts
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.workouts
  FOR ALL USING (auth.role() = 'service_role');

-- user_workouts: Users can only access their own user_workouts
CREATE POLICY "Users can read own user_workouts" ON public.user_workouts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own user_workouts" ON public.user_workouts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own user_workouts" ON public.user_workouts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own user_workouts" ON public.user_workouts
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.user_workouts
  FOR ALL USING (auth.role() = 'service_role');

-- recipes: Everyone can read recipes (they're canonical), users can insert custom ones
CREATE POLICY "Anyone can read recipes" ON public.recipes
  FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert custom recipes" ON public.recipes
  FOR INSERT WITH CHECK (is_custom = TRUE);

CREATE POLICY "Service role bypass" ON public.recipes
  FOR ALL USING (auth.role() = 'service_role');

-- user_recipes: Users can only access their own user_recipes
CREATE POLICY "Users can read own user_recipes" ON public.user_recipes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own user_recipes" ON public.user_recipes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own user_recipes" ON public.user_recipes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own user_recipes" ON public.user_recipes
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.user_recipes
  FOR ALL USING (auth.role() = 'service_role');

-- fasting_sessions: Users can only access their own sessions
CREATE POLICY "Users can read own fasting sessions" ON public.fasting_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fasting sessions" ON public.fasting_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own fasting sessions" ON public.fasting_sessions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own fasting sessions" ON public.fasting_sessions
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.fasting_sessions
  FOR ALL USING (auth.role() = 'service_role');

-- nutrition_data: Users can only access their own nutrition data
CREATE POLICY "Users can read own nutrition data" ON public.nutrition_data
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition data" ON public.nutrition_data
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition data" ON public.nutrition_data
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition data" ON public.nutrition_data
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Service role bypass" ON public.nutrition_data
  FOR ALL USING (auth.role() = 'service_role');

-- learn_templates: Everyone can read templates (they're global), only admin can modify
-- For now, we'll allow all reads and skip the write restriction
CREATE POLICY "Anyone can read learn templates" ON public.learn_templates
  FOR SELECT USING (TRUE);

CREATE POLICY "Service role bypass" ON public.learn_templates
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================================
-- PART 5: GRANT API ACCESS TO ROLES
-- ============================================================================

-- Re-enable schema access for PostgREST (in case it was reset)
GRANT USAGE ON SCHEMA public TO authenticated, anon, postgres;

-- CRITICAL: Grant access to information_schema so PostgREST can introspect tables
GRANT SELECT ON information_schema.tables TO authenticated, anon, postgres;
GRANT SELECT ON information_schema.columns TO authenticated, anon, postgres;
GRANT SELECT ON information_schema.table_privileges TO authenticated, anon, postgres;

-- Grant access to authenticated users and anon role for all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_profiles TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cycles TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cycle_entries TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.workouts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_workouts TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.recipes TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_recipes TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fasting_sessions TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.nutrition_data TO authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.learn_templates TO authenticated, anon;

-- Grant sequence access for auto-increment IDs
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon;

-- Grant function execution access for cycle calculation functions
GRANT EXECUTE ON FUNCTION public.get_current_cycle_day(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_current_phase(UUID) TO authenticated, anon;

-- ============================================================================
-- PART 6: SAMPLE DATA (TEMPLATES & RECIPES)
-- ============================================================================

-- Learn templates - My Cycle (2 placeholders: Hormonal Phase, Lifestyle Phase)
INSERT INTO public.learn_templates (category, template_text, placeholder_key, sort_order, is_active) VALUES
('My Cycle', 'This is your {Hormonal Phase} phase
we call this a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 1, TRUE),
('My Cycle', 'Welcome to your {Hormonal Phase} phase
this is a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 2, TRUE),
('My Cycle', 'This is your {Hormonal Phase} phase
expressed as a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 3, TRUE),
('My Cycle', 'You''ve entered your {Hormonal Phase} phase
expressed as a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 4, TRUE),
('My Cycle', 'You are in your {Hormonal Phase} phase today
this is a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 5, TRUE),
('My Cycle', 'You''re fully in your {Hormonal Phase} phase
today unfolds as a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 6, TRUE),
('My Cycle', 'You''re moving through your {Hormonal Phase} phase
embrace this {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 7, TRUE),
('My Cycle', 'You''re flowing through your {Hormonal Phase} phase
it''s a true {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 8, TRUE),
('My Cycle', 'You''re in your {Hormonal Phase} phase
today is a {Lifestyle Phase} day for you.', 'Hormonal Phase|Lifestyle Phase', 9, TRUE),
('My Cycle', 'You''re in your {Hormonal Phase} phase
today unfolds as a {Lifestyle Phase} day for you.', 'Hormonal Phase|Lifestyle Phase', 10, TRUE),
('My Cycle', 'You''re in your {Hormonal Phase} phase today
think of it as a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 11, TRUE),

-- Learn templates - Fitness (1 placeholder: Workout Mode)
('Fitness', 'Your body feels best with {Workout Mode} today.', 'Workout Mode', 1, TRUE),
('Fitness', 'Your body is primed for {Workout Mode} today.', 'Workout Mode', 2, TRUE),
('Fitness', 'Today your energy aligns with {Workout Mode}.', 'Workout Mode', 3, TRUE),
('Fitness', 'Your energy naturally supports {Workout Mode} today.', 'Workout Mode', 4, TRUE),
('Fitness', 'Your body responds well to {Workout Mode} right now.', 'Workout Mode', 5, TRUE),
('Fitness', 'Your body welcomes {Workout Mode} today.', 'Workout Mode', 6, TRUE),
('Fitness', '{Workout Mode} feels most supportive.', 'Workout Mode', 7, TRUE),
('Fitness', 'Your body finds harmony with {Workout Mode} today.', 'Workout Mode', 8, TRUE),

-- Learn templates - Diet (1 placeholder: Food Vibe)
('Diet', 'Your body thrives on {Food Vibe} today.', 'Food Vibe', 1, TRUE),
('Diet', 'Your body feels deeply nourished by {Food Vibe} today.', 'Food Vibe', 2, TRUE),
('Diet', 'Today''s best nourishment is {Food Vibe}.', 'Food Vibe', 3, TRUE),
('Diet', 'Your body responds beautifully to {Food Vibe} today.', 'Food Vibe', 4, TRUE),
('Diet', 'Lean into {Food Vibe} today.', 'Food Vibe', 5, TRUE),
('Diet', 'Let {Food Vibe} guide your meals today.', 'Food Vibe', 6, TRUE),
('Diet', 'With your body in this phase, {Food Vibe} supports balance.', 'Food Vibe', 7, TRUE),
('Diet', '{Food Vibe} brings the balance you need today.', 'Food Vibe', 8, TRUE),

-- Learn templates - Fasting (1 placeholder: Fast Style)
('Fasting', 'Your ideal fasting window today is {Fast Style}.', 'Fast Style', 1, TRUE),
('Fasting', 'Your body settles well into a {Fast Style} today.', 'Fast Style', 2, TRUE),
('Fasting', 'Your body feels supported by a {Fast Style} today.', 'Fast Style', 3, TRUE),
('Fasting', 'Your system adapts well to a {Fast Style} today.', 'Fast Style', 4, TRUE),
('Fasting', 'Keep fasting to {Fast Style} today.', 'Fast Style', 5, TRUE),
('Fasting', 'A {Fast Style} keeps things balanced today.', 'Fast Style', 6, TRUE),
('Fasting', 'With today''s rhythm, a {Fast Style} works best.', 'Fast Style', 7, TRUE),
('Fasting', 'Your rhythm today pairs well with a {Fast Style}.', 'Fast Style', 8, TRUE);

-- SAMPLE DATA (RECIPES)

-- Menstrual phase recipes
INSERT INTO public.recipes (
  name, description, calories, protein_g, carbs_g, fat_g, fiber_g,
  prep_time_minutes, cook_time_minutes, servings,
  meal_type, cuisine_type, dietary_tags, associated_phases, food_vibe,
  is_custom
) VALUES
('Lentil & Spinach Stew', 'Hearty, iron-rich stew perfect for menstrual phase', 280, 15, 35, 6, 8, 10, 25, 1, 'Lunch', 'Mediterranean', '{"Vegetarian", "Gluten-Free"}', '{"Menstrual"}', 'Gut-Friendly Low-Carb', FALSE),
('Beetroot & Quinoa Salad', 'Iron-boosting salad with earthy beets', 320, 12, 38, 12, 6, 15, 0, 1, 'Lunch', 'Mediterranean', '{"Vegetarian", "Gluten-Free"}', '{"Menstrual"}', 'Gut-Friendly Low-Carb', FALSE),
('Moroccan Chickpea Tagine', 'Warming spiced chickpea stew', 350, 14, 42, 10, 9, 15, 30, 1, 'Dinner', 'North African', '{"Vegetarian", "Vegan"}', '{"Menstrual"}', 'Gut-Friendly Low-Carb', FALSE),

-- Follicular phase recipes
('Grilled Salmon with Quinoa & Greens', 'High-protein salmon power bowl', 450, 35, 35, 18, 5, 15, 20, 1, 'Dinner', 'Mediterranean', '{"Gluten-Free"}', '{"Follicular"}', 'Gut-Friendly Low-Carb', FALSE),
('Chicken & Broccoli Stir-Fry', 'Energizing stir-fry with lean protein', 380, 38, 28, 12, 6, 15, 15, 1, 'Dinner', 'Asian', '{"Gluten-Free"}', '{"Follicular"}', 'Gut-Friendly Low-Carb', FALSE),

-- Ovulation phase recipes
('Mediterranean Grain Bowl', 'Nutrient-dense grain bowl with vegetables', 420, 16, 52, 14, 8, 15, 0, 1, 'Lunch', 'Mediterranean', '{"Vegetarian"}', '{"Ovulation"}', 'Carb-Boost Hormone Fuel', FALSE),
('Sweet Potato & Black Bean Tacos', 'Colorful, carb-rich tacos', 380, 14, 48, 14, 9, 15, 20, 1, 'Dinner', 'Mexican', '{"Vegetarian", "Vegan"}', '{"Ovulation"}', 'Carb-Boost Hormone Fuel', FALSE),

-- Luteal phase recipes
('Pumpkin Soup with Wholegrain Bread', 'Cozy, nourishing soup', 320, 12, 42, 10, 7, 10, 20, 1, 'Lunch', 'European', '{"Vegetarian"}', '{"Luteal"}', 'Carb-Boost Hormone Fuel', FALSE),
('Baked Salmon with Brown Rice Pilaf', 'Magnesium-rich comfort dinner', 480, 38, 42, 18, 6, 15, 30, 1, 'Dinner', 'Mediterranean', '{"Gluten-Free"}', '{"Luteal"}', 'Carb-Boost Hormone Fuel', FALSE);

-- ============================================================================
-- PART 7: VERIFICATION QUERIES
-- ============================================================================

-- Run these queries to verify the schema was created successfully:

/*
-- Check all tables exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- Check user_profiles structure
\d public.user_profiles

-- Check RLS policies
SELECT tablename, policyname, permissive, roles, qual FROM pg_policies ORDER BY tablename;

-- Check sample recipes
SELECT name, food_vibe, associated_phases FROM public.recipes LIMIT 5;

-- Check indexes
SELECT tablename, indexname FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename;
*/

-- ============================================================================
-- PART 8: END OF SCHEMA
-- ============================================================================
