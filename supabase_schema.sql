-- Drop existing tables (if any) - with CASCADE to handle dependencies
DROP TABLE IF EXISTS user_daily_selections CASCADE;
DROP TABLE IF EXISTS daily_notes CASCADE;
DROP TABLE IF EXISTS lifestyle_areas CASCADE;
DROP TABLE IF EXISTS cycle_calculations CASCADE;
DROP TABLE IF EXISTS cycle_phase_recommendations CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS lifestyle_categories CASCADE;
DROP TABLE IF EXISTS cycle_phases CASCADE;

-- Create user_profiles table
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  cycle_length INTEGER NOT NULL CHECK (cycle_length >= 21 AND cycle_length <= 35),
  menstrual_length INTEGER NOT NULL CHECK (menstrual_length >= 2 AND menstrual_length <= 10),
  luteal_phase_length INTEGER NOT NULL DEFAULT 14 CHECK (luteal_phase_length >= 10 AND luteal_phase_length <= 16),
  last_period_date TIMESTAMP WITH TIME ZONE NOT NULL,
  avatar_base64 TEXT,
  fasting_preference VARCHAR(20) DEFAULT 'Beginner',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cycle_phases reference table
CREATE TABLE cycle_phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_name VARCHAR(50) NOT NULL UNIQUE,
  phase_type VARCHAR(50) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create lifestyle_categories reference table
CREATE TABLE lifestyle_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cycle_phase_recommendations reference table (adaptive syncing lookup)
CREATE TABLE cycle_phase_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_name VARCHAR(50) NOT NULL,
  lifestyle_phase VARCHAR(50) NOT NULL,
  hormonal_state VARCHAR(50) NOT NULL,
  food_vibe VARCHAR(100) NOT NULL,
  food_recipes TEXT,
  workout_mode VARCHAR(100) NOT NULL,
  workout_types TEXT,
  fasting_beginner VARCHAR(50) NOT NULL,
  fasting_advanced VARCHAR(50) NOT NULL,
  day_range_start INTEGER NOT NULL,
  day_range_end INTEGER NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(phase_name, day_range_start, day_range_end)
);

-- Create lifestyle_areas table (many-to-many between users and areas)
CREATE TABLE lifestyle_areas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  area_name VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, area_name)
);

-- Create daily_notes table for per-date notes
CREATE TABLE daily_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  note_date DATE NOT NULL,
  note_text TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, note_date)
);

-- Create cycle_calculations table
CREATE TABLE cycle_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  calculation_date TIMESTAMP WITH TIME ZONE NOT NULL,
  cycle_day INTEGER NOT NULL,
  phase_type VARCHAR(50) NOT NULL,
  lifestyle_phase VARCHAR(50) NOT NULL,
  hormonal_state VARCHAR(50) NOT NULL,
  days_until_next_period INTEGER NOT NULL,
  is_ovulation_window BOOLEAN NOT NULL DEFAULT FALSE,
  is_first_day_of_cycle BOOLEAN NOT NULL DEFAULT FALSE,
  next_period_date TIMESTAMP WITH TIME ZONE NOT NULL,
  cycle_start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  cycle_day_of_month INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, calculation_date)
);

-- Create user_daily_selections table for tracking selected recipes and workouts per day
CREATE TABLE user_daily_selections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  selection_date DATE NOT NULL,
  selected_recipes TEXT,
  selected_workouts TEXT,
  completed_workouts TEXT,
  completed_recipes TEXT,
  selected_fasting_hours NUMERIC(3,1),
  completed_fasting_hours NUMERIC(3,1),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, selection_date)
);

-- Create indexes for better query performance
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_cycle_calculations_user_id ON cycle_calculations(user_id);
CREATE INDEX idx_cycle_calculations_date ON cycle_calculations(calculation_date);
CREATE INDEX idx_cycle_calculations_user_date ON cycle_calculations(user_id, calculation_date);
CREATE INDEX idx_lifestyle_areas_user_id ON lifestyle_areas(user_id);
CREATE INDEX idx_daily_notes_user_id ON daily_notes(user_id);
CREATE INDEX idx_daily_notes_user_date ON daily_notes(user_id, note_date);
CREATE INDEX idx_cycle_phase_recommendations_phase ON cycle_phase_recommendations(phase_name);
CREATE INDEX idx_user_daily_selections_user_id ON user_daily_selections(user_id);
CREATE INDEX idx_user_daily_selections_user_date ON user_daily_selections(user_id, selection_date);

-- Enable RLS (Row Level Security) for security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE lifestyle_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_daily_selections ENABLE ROW LEVEL SECURITY;

-- Reference tables are public - disable RLS for them
ALTER TABLE cycle_phases DISABLE ROW LEVEL SECURITY;
ALTER TABLE lifestyle_categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_phase_recommendations DISABLE ROW LEVEL SECURITY;

-- Grant permissions to authenticated users on tables with RLS
GRANT SELECT, INSERT, UPDATE, DELETE ON user_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON lifestyle_areas TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_notes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cycle_calculations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_daily_selections TO authenticated;

-- Grant SELECT permissions to anon role for public reference tables
GRANT SELECT ON cycle_phases TO anon;
GRANT SELECT ON lifestyle_categories TO anon;
GRANT SELECT ON cycle_phase_recommendations TO anon;

-- Create RLS policies for user_profiles (users can only access their own)
CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own profile" ON user_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for lifestyle_areas
CREATE POLICY "Users can view their own lifestyle areas" ON lifestyle_areas
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert lifestyle areas" ON lifestyle_areas
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update lifestyle areas" ON lifestyle_areas
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete lifestyle areas" ON lifestyle_areas
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for daily_notes
CREATE POLICY "Users can view their own notes" ON daily_notes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert notes" ON daily_notes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update notes" ON daily_notes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete notes" ON daily_notes
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for cycle_calculations
CREATE POLICY "Users can view their own calculations" ON cycle_calculations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert calculations" ON cycle_calculations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update calculations" ON cycle_calculations
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete calculations" ON cycle_calculations
  FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for user_daily_selections
CREATE POLICY "Users can view their own selections" ON user_daily_selections
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert selections" ON user_daily_selections
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update selections" ON user_daily_selections
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete selections" ON user_daily_selections
  FOR DELETE USING (auth.uid() = user_id);

-- Insert reference cycle phases
INSERT INTO cycle_phases (phase_name, phase_type, description) VALUES
  ('Menstrual', 'MENSTRUAL', 'Shedding of uterine lining'),
  ('Follicular', 'FOLLICULAR', 'Growth phase with increasing estrogen'),
  ('Ovulation', 'OVULATION', 'Egg release - most fertile phase'),
  ('Luteal', 'LUTEAL', 'Progesterone dominance, preparation for menstruation')
ON CONFLICT (phase_name) DO NOTHING;

-- Insert reference lifestyle categories
INSERT INTO lifestyle_categories (category_name, description) VALUES
  ('Nutrition', 'Personalized nutrition and food recommendations'),
  ('Fitness', 'Workout and exercise recommendations'),
  ('Fasting', 'Intermittent fasting recommendations')
ON CONFLICT (category_name) DO NOTHING;

-- Insert adaptive cycle syncing recommendations
INSERT INTO cycle_phase_recommendations (phase_name, lifestyle_phase, hormonal_state, food_vibe, food_recipes, workout_mode, workout_types, fasting_beginner, fasting_advanced, day_range_start, day_range_end, description) VALUES
  ('Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut-Friendly Low-Carb', 'Lentil & Spinach Stew • Beetroot & Quinoa Salad • Moroccan Chickpea Tagine • Black Bean Chili con Carne • Braised Kale & White Beans • Red Lentil & Carrot Soup', 'Low-Impact Workout', 'Walking • Rest • Hot Girl Walk • Yoga • Mat Pilates • Foam rolling • Low-Impact Strength Training', 'Short Fast (13h)', 'Medium Fast (15h)', 1, 4, 'Early to mid menstrual phase'),
  ('Menstrual', 'Glow Reset', 'Low E, Low P', 'Gut-Friendly Low-Carb', 'Lentil & Spinach Stew • Beetroot & Quinoa Salad • Moroccan Chickpea Tagine • Black Bean Chili con Carne • Braised Kale & White Beans • Red Lentil & Carrot Soup', 'Low-Impact Workout', 'Walking • Mat Pilates • Hot Girl Walk • Restorative Flow • Yoga • Low-Impact Strength Training', 'Medium Fast (15h)', 'Medium Fast (15h)', 5, 5, 'Late menstrual phase'),
  ('Follicular', 'Power Up', 'Rising E', 'Gut-Friendly Low-Carb', 'Grilled Salmon with Quinoa & Greens • Chicken & Broccoli Stir-Fry • Tofu & Vegetable Power Bowl • Shrimp & Zucchini Noodles • Turkey & Spinach Meatballs • Eggplant & Chickpea Curry', 'Moderate to High-Intensity Workout', 'Cardio • 12-3-30 Treadmill • Incline walking • HIIT • Cycling • Spin class • Strength Training • Reformer Pilates • Power yoga', 'Long Fast (17h)', 'Extended Fast (24h)', 6, 6, 'Early follicular phase - day after menstruation'),
  ('Follicular', 'Power Up', 'Rising E', 'Gut-Friendly Low-Carb', 'Grilled Salmon with Quinoa & Greens • Chicken & Broccoli Stir-Fry • Tofu & Vegetable Power Bowl • Shrimp & Zucchini Noodles • Turkey & Spinach Meatballs • Eggplant & Chickpea Curry', 'Moderate to High-Intensity Workout', 'Cardio • 12-3-30 Treadmill • Incline walking • HIIT • Cycling • Spin Class • Strength Training • Reformer Pilates • Power yoga', 'Long Fast (17h)', 'Long Fast (17h)', 7, 10, 'Early follicular phase - energy rising'),
  ('Follicular', 'Main Character', 'Peak E', 'Carb-Boost Hormone Fuel', 'Mediterranean Grain Bowl • Sweet Potato & Black Bean Tacos • Pasta Primavera • Mango & Avocado Salad • Quinoa Tabouleh • Roasted Vegetable Couscous', 'Strength & Resistance', 'Strength Training • Heavy lifting • Strength Reformer Pilates', 'Short Fast (13h)', 'Medium Fast (15h)', 11, 12, 'Late follicular phase - pre-ovulation'),
  ('Ovulation', 'Main Character', 'Peak E', 'Carb-Boost Hormone Fuel', 'Mediterranean Grain Bowl • Sweet Potato & Black Bean Tacos • Pasta Primavera • Mango & Avocado Salad • Quinoa Tabouleh • Roasted Vegetable Couscous', 'Strength & Resistance', 'Heavy lifting • Strength Training • Strength Reformer Pilates', 'Short Fast (13h)', 'Long Fast (17h)', 13, 15, 'Ovulation window - peak fertility'),
  ('Luteal', 'Power Up', 'Declining E, Rising P', 'Gut-Friendly Low-Carb', 'Turkey & Vegetable Stir-Fry • Lentil & Carrot Curry • Cauliflower Rice Buddha Bowl • Chickpea & Spinach Sauté • Grilled Chicken with Brussels Sprouts • Tempeh & Broccoli Stir-Fry', 'Moderate to High-Intensity Workout', 'Spin Class • Strength Training • Endurance Runs • Circuits • Power yoga • Reformer Pilates', 'Medium Fast (15h)', 'Long Fast (17h)', 16, 19, 'Early luteal phase'),
  ('Luteal', 'Cozy Care', 'Low E, High P', 'Carb-Boost Hormone Fuel', 'Pumpkin Soup with Wholegrain Bread • Roasted Sweet Potato & Kale Bowl • Baked Salmon with Brown Rice Pilaf • Cozy Vegetable Stew with Barley • Butternut Squash Risotto • Apple & Cinnamon Overnight Oats', 'Moderate to Low-Impact Strength', 'Hot Girl Walk • Low-Impact Strength Training • Reformer Pilates • Mat Pilates • Swimming', 'No Fast', 'Short Fast (13h)', 20, 28, 'Late luteal phase - before menstruation')
ON CONFLICT (phase_name, day_range_start, day_range_end) DO NOTHING;

-- Disable RLS on reference tables (these are read-only curated data, not user-specific)
ALTER TABLE cycle_phase_recommendations DISABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_phases DISABLE ROW LEVEL SECURITY;
ALTER TABLE lifestyle_categories DISABLE ROW LEVEL SECURITY;

-- Grant SELECT permissions to authenticated users for reference tables
GRANT SELECT ON cycle_phases TO authenticated;
GRANT SELECT ON lifestyle_categories TO authenticated;
GRANT SELECT ON cycle_phase_recommendations TO authenticated;

-- User profiles and lifestyle area selections are created dynamically when users sign up and complete onboarding
