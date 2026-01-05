-- Drop existing tables (if any)
DROP TABLE IF EXISTS cycle_calculations CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS cycle_phases CASCADE;

-- Create user_profiles table
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  cycle_length INTEGER NOT NULL CHECK (cycle_length >= 21 AND cycle_length <= 35),
  menstrual_length INTEGER NOT NULL CHECK (menstrual_length >= 2 AND menstrual_length <= 7),
  last_period_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cycle_phases reference table (optional, for future use)
CREATE TABLE cycle_phases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phase_name VARCHAR(50) NOT NULL UNIQUE,
  phase_type VARCHAR(50) NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create cycle_calculations table
CREATE TABLE cycle_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
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

-- Create indexes for better query performance
CREATE INDEX idx_cycle_calculations_user_id ON cycle_calculations(user_id);
CREATE INDEX idx_cycle_calculations_date ON cycle_calculations(calculation_date);
CREATE INDEX idx_cycle_calculations_user_date ON cycle_calculations(user_id, calculation_date);
CREATE INDEX idx_user_profiles_name ON user_profiles(name);

-- Enable RLS (Row Level Security) for security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycle_phases ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Allow all operations for now (you can restrict later based on auth)
CREATE POLICY "Allow all operations on user_profiles" ON user_profiles
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on cycle_calculations" ON cycle_calculations
  FOR ALL USING (true);

CREATE POLICY "Allow all operations on cycle_phases" ON cycle_phases
  FOR ALL USING (true);

-- Insert sample cycle phases (optional)
INSERT INTO cycle_phases (phase_name, phase_type, description) VALUES
  ('Menstrual', 'MENSTRUAL', 'Shedding of uterine lining'),
  ('Follicular', 'FOLLICULAR', 'Growth phase with increasing estrogen'),
  ('Ovulation', 'OVULATION', 'Egg release - most fertile phase'),
  ('Luteal', 'LUTEAL', 'Progesterone dominance, preparation for menstruation')
ON CONFLICT (phase_name) DO NOTHING;

-- Insert sample user profile (optional - for testing)
INSERT INTO user_profiles (id, name, cycle_length, menstrual_length, last_period_date)
VALUES (
  gen_random_uuid(),
  'Test User',
  28,
  5,
  NOW() - INTERVAL '10 days'
)
ON CONFLICT DO NOTHING;
