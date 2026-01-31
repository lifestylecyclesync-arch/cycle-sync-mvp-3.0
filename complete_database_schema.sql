-- ============================================================================
-- COMPLETE CYCLE SYNC DATABASE SCHEMA (RESTORED WORKING VERSION)
-- ============================================================================
-- Simplified, proven working schema with integrated logging tables
-- Uses direct auth.users references instead of complex triggers
-- Created: 2026-01-31

-- Drop existing tables (cascade handles dependencies)
DROP TABLE IF EXISTS fasting_logs CASCADE;
DROP TABLE IF EXISTS diet_logs CASCADE;
DROP TABLE IF EXISTS fitness_logs CASCADE;
DROP TABLE IF EXISTS user_daily_selections CASCADE;
DROP TABLE IF EXISTS daily_notes CASCADE;
DROP TABLE IF EXISTS lifestyle_areas CASCADE;
DROP TABLE IF EXISTS cycle_calculations CASCADE;
DROP TABLE IF EXISTS cycle_phase_recommendations CASCADE;
DROP TABLE IF EXISTS lifestyle_categories CASCADE;
DROP TABLE IF EXISTS cycle_phases CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
-- Drop old schema tables
DROP TABLE IF EXISTS phase_recommendations CASCADE;
DROP TABLE IF EXISTS phases CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;


-- ============================================================================
-- 1. REFERENCE TABLES (No RLS - public data)
-- ============================================================================

CREATE TABLE cycle_phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_name VARCHAR(50) NOT NULL UNIQUE,
  phase_number INTEGER NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lifestyle_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE cycle_phase_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_name VARCHAR(50) NOT NULL,
  day_range_start INTEGER NOT NULL,
  day_range_end INTEGER NOT NULL,
  hormonal_phase VARCHAR(100),
  lifestyle_phase VARCHAR(100),
  hormonal_state VARCHAR(100),
  food_vibe VARCHAR(100),
  workout_mode VARCHAR(100),
  fasting_beginner VARCHAR(100),
  fasting_advanced VARCHAR(100),
  recommendation_type VARCHAR(50) NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  tips TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 2. USER PROFILE TABLE
-- ============================================================================

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255),
  cycle_length INTEGER DEFAULT 28 CHECK (cycle_length >= 20 AND cycle_length <= 40),
  menstrual_length INTEGER DEFAULT 5 CHECK (menstrual_length >= 2 AND menstrual_length <= 10),
  last_period_date TIMESTAMP WITH TIME ZONE,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 3. USER DATA TABLES (RLS Enabled)
-- ============================================================================

CREATE TABLE lifestyle_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  area_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, area_name)
);

CREATE TABLE daily_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  note_date DATE NOT NULL,
  note_text TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, note_date)
);

CREATE TABLE cycle_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  calculation_date TIMESTAMP WITH TIME ZONE NOT NULL,
  cycle_day INTEGER NOT NULL,
  phase_type VARCHAR(50) NOT NULL,
  hormonal_state VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, calculation_date)
);

CREATE TABLE user_daily_selections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  selection_date DATE NOT NULL,
  selected_items TEXT,
  completed_items TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, selection_date)
);

-- ============================================================================
-- 4. LOGGING TABLES (RLS Enabled)
-- ============================================================================

CREATE TABLE fitness_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  activity_type TEXT NOT NULL,
  duration_minutes INTEGER,
  intensity TEXT CHECK (intensity IN ('Low', 'Medium', 'High')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE diet_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL,
  meal_type TEXT NOT NULL CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack')),
  food_items TEXT[] DEFAULT '{}',
  calories INTEGER,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE fasting_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fasting_date DATE NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  duration_hours DECIMAL(5, 2),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 5. INDEXES
-- ============================================================================

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_lifestyle_areas_user_id ON lifestyle_areas(user_id);
CREATE INDEX idx_daily_notes_user_id ON daily_notes(user_id);
CREATE INDEX idx_daily_notes_date ON daily_notes(note_date);
CREATE INDEX idx_cycle_calculations_user_id ON cycle_calculations(user_id);
CREATE INDEX idx_cycle_calculations_date ON cycle_calculations(calculation_date);
CREATE INDEX idx_user_daily_selections_user_id ON user_daily_selections(user_id);
CREATE INDEX idx_user_daily_selections_date ON user_daily_selections(selection_date);
CREATE INDEX idx_fitness_logs_user_id ON fitness_logs(user_id);
CREATE INDEX idx_fitness_logs_date ON fitness_logs(activity_date);
CREATE INDEX idx_diet_logs_user_id ON diet_logs(user_id);
CREATE INDEX idx_diet_logs_date ON diet_logs(log_date);
CREATE INDEX idx_fasting_logs_user_id ON fasting_logs(user_id);
CREATE INDEX idx_fasting_logs_date ON fasting_logs(fasting_date);

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================

-- Reference tables - NO RLS (public data)
ALTER TABLE cycle_phases DISABLE ROW LEVEL SECURITY;
ALTER TABLE lifestyle_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_phase_recommendations DISABLE ROW LEVEL SECURITY;

-- User profile - DISABLE RLS (simple approach - authenticated users only)
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- User data tables - ENABLE RLS
ALTER TABLE lifestyle_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_daily_selections ENABLE ROW LEVEL SECURITY;

-- Logging tables - ENABLE RLS
ALTER TABLE fitness_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fasting_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. RLS POLICIES - User Profiles
-- ============================================================================
-- (No policies needed - RLS is disabled for simplicity)

-- ============================================================================
-- 8. RLS POLICIES - User Data Tables
-- ============================================================================

-- lifestyle_areas - all operations for own data
CREATE POLICY "lifestyle_areas_auth_users"
  ON lifestyle_areas FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- daily_notes - all operations for own data
CREATE POLICY "daily_notes_auth_users"
  ON daily_notes FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- cycle_calculations - all operations for own data
CREATE POLICY "cycle_calculations_auth_users"
  ON cycle_calculations FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- user_daily_selections - all operations for own data
CREATE POLICY "user_daily_selections_auth_users"
  ON user_daily_selections FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 9. RLS POLICIES - Logging Tables
-- ============================================================================

-- fitness_logs - all operations for own data
CREATE POLICY "fitness_logs_auth_users"
  ON fitness_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- diet_logs - all operations for own data
CREATE POLICY "diet_logs_auth_users"
  ON diet_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- fasting_logs - all operations for own data
CREATE POLICY "fasting_logs_auth_users"
  ON fasting_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 10. REFERENCE DATA
-- ============================================================================

-- Cycle Phases
INSERT INTO cycle_phases (phase_name, phase_number, description)
VALUES
  ('Menstrual', 1, 'Day 1-5: Renewal and recovery phase'),
  ('Follicular', 2, 'Day 6-12: Rising energy and growth phase'),
  ('Ovulation', 3, 'Day 13-15: Peak energy and confidence phase'),
  ('Luteal', 4, 'Day 16-28: Introspection and preparation phase');

-- Lifestyle Categories
INSERT INTO lifestyle_categories (category_name, description)
VALUES
  ('Nutrition', 'Food and dietary choices'),
  ('Fitness', 'Physical activity and exercise'),
  ('Fasting', 'Intermittent fasting practices');

-- Phase Recommendations
INSERT INTO cycle_phase_recommendations (phase_name, day_range_start, day_range_end, hormonal_phase, lifestyle_phase, hormonal_state, food_vibe, workout_mode, fasting_beginner, fasting_advanced, recommendation_type, title, description, tips)
VALUES
  -- MENSTRUAL PHASE (Days 1-4)
  ('Menstrual', 1, 4, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Short Fast (13h)', 'Medium Fast (15h)', 'Phase', 'Menstrual (Days 1-4)', 'Renewal and recovery phase - Early', ARRAY['Menstrual Phase']),
  ('Menstrual', 1, 4, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Short Fast (13h)', 'Medium Fast (15h)', 'Nutrition', 'Gut‑Friendly Low‑Carb', 'Replenish iron and minerals', ARRAY['Lentil & Spinach Stew', 'Beetroot & Quinoa Salad', 'Moroccan Chickpea Tagine', 'Black Bean Chili con Carne', 'Braised Kale & White Beans', 'Red Lentil & Carrot Soup']),
  ('Menstrual', 1, 4, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Short Fast (13h)', 'Medium Fast (15h)', 'Fitness', 'Low‑Impact Workout', 'Focus on gentle movement and recovery', ARRAY['Walking', 'Rest', 'Hot Girl Walk', 'Yoga', 'Mat Pilates', 'Foam rolling', 'Low‑Impact Strength Training']),
  ('Menstrual', 1, 4, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Short Fast (13h)', 'Medium Fast (15h)', 'Fasting', 'Short Fast', 'Keep fasting windows short', ARRAY['Short Fast (13h)', 'Medium Fast (15h)', 'Focus on nourishment', 'Listen to hunger cues']),
  
  -- MENSTRUAL PHASE (Day 5)
  ('Menstrual', 5, 5, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Medium Fast (15h)', 'Medium Fast (15h)', 'Phase', 'Menstrual (Day 5)', 'Renewal and recovery phase - Final', ARRAY['Menstrual Phase']),
  ('Menstrual', 5, 5, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Medium Fast (15h)', 'Medium Fast (15h)', 'Nutrition', 'Gut‑Friendly Low‑Carb', 'Replenish iron and minerals', ARRAY['Lentil & Spinach Stew', 'Beetroot & Quinoa Salad', 'Moroccan Chickpea Tagine', 'Black Bean Chili con Carne', 'Braised Kale & White Beans', 'Red Lentil & Carrot Soup']),
  ('Menstrual', 5, 5, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Medium Fast (15h)', 'Medium Fast (15h)', 'Fitness', 'Low‑Impact Workout', 'Focus on gentle movement and recovery', ARRAY['Walking', 'Mat Pilates', 'Hot Girl Walk', 'Restorative Flow', 'Yoga', 'Low‑Impact Strength Training']),
  ('Menstrual', 5, 5, 'Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut‑Friendly Low‑Carb', 'Low‑Impact Workout', 'Medium Fast (15h)', 'Medium Fast (15h)', 'Fasting', 'Medium Fast', 'Balanced approach as cycle transitions', ARRAY['Medium Fast (15h)', 'Medium Fast (15h)', 'Listen to body', 'Gentle transition']),
  
  -- FOLLICULAR EARLY (Day 6)
  ('Follicular', 6, 6, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Extended Fast (24h)', 'Phase', 'Follicular Early (Day 6)', 'Rising energy and growth phase - Day 1', ARRAY['Follicular Phase']),
  ('Follicular', 6, 6, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Extended Fast (24h)', 'Nutrition', 'Gut‑Friendly Low‑Carb', 'Eat light, fresh foods', ARRAY['Grilled Salmon with Quinoa & Greens', 'Chicken & Broccoli Stir‑Fry', 'Tofu & Vegetable Power Bowl', 'Shrimp & Zucchini Noodles', 'Turkey & Spinach Meatballs', 'Eggplant & Chickpea Curry']),
  ('Follicular', 6, 6, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Extended Fast (24h)', 'Fitness', 'Moderate to High‑Intensity Workout', 'Push your limits with rising energy', ARRAY['Cardio', '12‑3‑30 Treadmill', 'Incline walking', 'HIIT', 'Cycling', 'Spin class', 'Strength Training', 'Reformer Pilates', 'Power yoga']),
  ('Follicular', 6, 6, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Extended Fast (24h)', 'Fasting', 'Long Fast', 'Extend fasting with rising energy', ARRAY['Long Fast (17h)', 'Extended Fast (24h)', 'Feel energized', 'Flexible schedule']),
  
  -- FOLLICULAR EARLY (Days 7-10)
  ('Follicular', 7, 10, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Long Fast (17h)', 'Phase', 'Follicular Early (Days 7-10)', 'Rising energy and growth phase - Peak', ARRAY['Follicular Phase']),
  ('Follicular', 7, 10, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Long Fast (17h)', 'Nutrition', 'Gut‑Friendly Low‑Carb', 'Eat light, fresh foods', ARRAY['Grilled Salmon with Quinoa & Greens', 'Chicken & Broccoli Stir‑Fry', 'Tofu & Vegetable Power Bowl', 'Shrimp & Zucchini Noodles', 'Turkey & Spinach Meatballs', 'Eggplant & Chickpea Curry']),
  ('Follicular', 7, 10, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Long Fast (17h)', 'Fitness', 'Moderate to High‑Intensity Workout', 'Push your limits with rising energy', ARRAY['Cardio', '12‑3‑30 Treadmill', 'Incline walking', 'HIIT', 'Cycling', 'Spin Class', 'Strength Training', 'Reformer Pilates', 'Power yoga']),
  ('Follicular', 7, 10, 'Follicular (Early)', 'Power Up', 'Rising E', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Long Fast (17h)', 'Long Fast (17h)', 'Fasting', 'Long Fast', 'Extend fasting with rising energy', ARRAY['Long Fast (17h)', 'Long Fast (17h)', 'Feel energized', 'Flexible schedule']),
  
  -- FOLLICULAR LATE (Days 11-12)
  ('Follicular', 11, 12, 'Follicular (Late)', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Medium Fast (15h)', 'Phase', 'Follicular Late (Days 11-12)', 'Peak energy phase - Main Character energy', ARRAY['Follicular Phase']),
  ('Follicular', 11, 12, 'Follicular (Late)', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Medium Fast (15h)', 'Nutrition', 'Carb‑Boost Hormone Fuel', 'Support peak energy with carbs', ARRAY['Mediterranean Grain Bowl', 'Sweet Potato & Black Bean Tacos', 'Pasta Primavera', 'Mango & Avocado Salad', 'Quinoa Tabouleh', 'Roasted Vegetable Couscous']),
  ('Follicular', 11, 12, 'Follicular (Late)', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Medium Fast (15h)', 'Fitness', 'Strength & Resistance', 'Build strength and power', ARRAY['Strength Training', 'Heavy lifting', 'Strength Reformer Pilates']),
  ('Follicular', 11, 12, 'Follicular (Late)', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Medium Fast (15h)', 'Fasting', 'Short to Medium Fast', 'Nourish during peak energy', ARRAY['Short Fast (13h)', 'Medium Fast (15h)', 'Listen to body', 'Eat when hungry']),
  
  -- OVULATION (Days 13-15)
  ('Ovulation', 13, 15, 'Ovulation', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Long Fast (17h)', 'Phase', 'Ovulation (Days 13-15)', 'Peak energy and confidence phase', ARRAY['Ovulation Phase']),
  ('Ovulation', 13, 15, 'Ovulation', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Long Fast (17h)', 'Nutrition', 'Carb‑Boost Hormone Fuel', 'Eat more to fuel peak', ARRAY['Mediterranean Grain Bowl', 'Sweet Potato & Black Bean Tacos', 'Pasta Primavera', 'Mango & Avocado Salad', 'Quinoa Tabouleh', 'Roasted Vegetable Couscous']),
  ('Ovulation', 13, 15, 'Ovulation', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Long Fast (17h)', 'Fitness', 'Strength & Resistance', 'Your strongest phase for intensity', ARRAY['Heavy lifting', 'Strength Training', 'Strength Reformer Pilates']),
  ('Ovulation', 13, 15, 'Ovulation', 'Main Character', 'Peak E', 'Carb‑Boost Hormone Fuel', 'Strength & Resistance', 'Short Fast (13h)', 'Long Fast (17h)', 'Fasting', 'Short to Long Fast', 'Fuel your peak', ARRAY['Short Fast (13h)', 'Long Fast (17h)', 'Peak energy window', 'Eat nutrient-dense']),
  
  -- EARLY LUTEAL (Days 16-19)
  ('Luteal', 16, 19, 'Early Luteal', 'Power Up', 'Declining E, Rising P', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Medium Fast (15h)', 'Long Fast (17h)', 'Phase', 'Early Luteal (Days 16-19)', 'Hormonal transition phase - maintain power', ARRAY['Luteal Phase']),
  ('Luteal', 16, 19, 'Early Luteal', 'Power Up', 'Declining E, Rising P', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Medium Fast (15h)', 'Long Fast (17h)', 'Nutrition', 'Gut‑Friendly Low‑Carb', 'Support hormonal transition', ARRAY['Turkey & Vegetable Stir‑Fry', 'Lentil & Carrot Curry', 'Cauliflower Rice Buddha Bowl', 'Chickpea & Spinach Sauté', 'Grilled Chicken with Brussels Sprouts', 'Tempeh & Broccoli Stir‑Fry']),
  ('Luteal', 16, 19, 'Early Luteal', 'Power Up', 'Declining E, Rising P', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Medium Fast (15h)', 'Long Fast (17h)', 'Fitness', 'Moderate to High‑Intensity Workout', 'Maintain intensity with balance', ARRAY['Spin Class', 'Strength Training', 'Endurance Runs', 'Circuits', 'Power yoga', 'Reformer Pilates']),
  ('Luteal', 16, 19, 'Early Luteal', 'Power Up', 'Declining E, Rising P', 'Gut‑Friendly Low‑Carb', 'Moderate to High‑Intensity Workout', 'Medium Fast (15h)', 'Long Fast (17h)', 'Fasting', 'Medium to Long Fast', 'Balanced fasting window', ARRAY['Medium Fast (15h)', 'Long Fast (17h)', 'Listen to body', 'Avoid extended fasts']),
  
  -- LATE LUTEAL (Days 20-28)
  ('Luteal', 20, 28, 'Late Luteal', 'Cozy Care', 'Low E, High P', 'Carb‑Boost Hormone Fuel', 'Moderate to Low-Impact Strength', 'No Fast', 'Short Fast (13h)', 'Phase', 'Late Luteal (Days 20-28)', 'Introspection and preparation phase - Cozy Care', ARRAY['Luteal Phase']),
  ('Luteal', 20, 28, 'Late Luteal', 'Cozy Care', 'Low E, High P', 'Carb‑Boost Hormone Fuel', 'Moderate to Low-Impact Strength', 'No Fast', 'Short Fast (13h)', 'Nutrition', 'Carb‑Boost Hormone Fuel', 'Support hormonal needs with nourishing food', ARRAY['Pumpkin Soup with Wholegrain Bread', 'Roasted Sweet Potato & Kale Bowl', 'Baked Salmon with Brown Rice Pilaf', 'Cozy Vegetable Stew with Barley', 'Butternut Squash Risotto', 'Apple & Cinnamon Overnight Oats']),
  ('Luteal', 20, 28, 'Late Luteal', 'Cozy Care', 'Low E, High P', 'Carb‑Boost Hormone Fuel', 'Moderate to Low-Impact Strength', 'No Fast', 'Short Fast (13h)', 'Fitness', 'Moderate to Low-Impact Strength', 'Prioritize consistency over intensity', ARRAY['Hot Girl Walk', 'Low‑Impact Strength Training', 'Reformer Pilates', 'Mat Pilates', 'Swimming']),
  ('Luteal', 20, 28, 'Late Luteal', 'Cozy Care', 'Low E, High P', 'Carb‑Boost Hormone Fuel', 'Moderate to Low-Impact Strength', 'No Fast', 'Short Fast (13h)', 'Fasting', 'No Fast or Short Fast', 'Gentle fasting window', ARRAY['No fasting - Beginner', 'Short Fast (13h) - Advanced', 'Frequent eating windows', 'Eat when hungry']);

-- ============================================================================
-- 11. HELPER FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION get_current_cycle_day(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  v_last_period_date TIMESTAMP WITH TIME ZONE;
  v_cycle_length INTEGER;
  v_days_since_period BIGINT;
  v_current_cycle_day INTEGER;
BEGIN
  SELECT last_period_date, cycle_length
  INTO v_last_period_date, v_cycle_length
  FROM user_profiles
  WHERE user_id = user_uuid;
  
  IF v_last_period_date IS NULL THEN
    RETURN NULL;
  END IF;
  
  v_days_since_period := CURRENT_DATE - DATE(v_last_period_date);
  v_current_cycle_day := (v_days_since_period::INTEGER % v_cycle_length) + 1;
  
  RETURN v_current_cycle_day;
END;
$$ LANGUAGE plpgsql STABLE;

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

-- ============================================================================
-- 12. GRANT PERMISSIONS (Critical for authenticated users)
-- ============================================================================

-- Grant permissions on all tables to authenticated users
GRANT ALL ON public.user_profiles TO authenticated;
GRANT ALL ON public.lifestyle_areas TO authenticated;
GRANT ALL ON public.daily_notes TO authenticated;
GRANT ALL ON public.cycle_calculations TO authenticated;
GRANT ALL ON public.user_daily_selections TO authenticated;
GRANT ALL ON public.fitness_logs TO authenticated;
GRANT ALL ON public.diet_logs TO authenticated;
GRANT ALL ON public.fasting_logs TO authenticated;

-- Grant permissions on reference tables (read-only)
GRANT SELECT ON public.cycle_phases TO authenticated;
GRANT SELECT ON public.lifestyle_categories TO authenticated;
GRANT SELECT ON public.cycle_phase_recommendations TO authenticated;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
