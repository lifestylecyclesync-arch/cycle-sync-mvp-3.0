-- ============================================================================
-- MIGRATION: Add Learn Templates Table
-- ============================================================================
-- This migration adds the learn_templates table for non-hardcoded templates
-- Run this ONLY on existing databases (not on fresh schema creation)
-- ============================================================================

-- Create learn_templates table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.learn_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  category TEXT NOT NULL, -- 'My Cycle', 'Fitness', 'Diet', 'Fasting'
  template_text TEXT NOT NULL,
  placeholder_key TEXT, -- 'Workout Mode|Food Vibe|Fast Style|Hormonal Phase|Lifestyle Phase'
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (category, sort_order)
);

-- Create index for learn_templates
CREATE INDEX IF NOT EXISTS idx_learn_templates_category ON public.learn_templates(category);

-- Enable RLS on learn_templates
ALTER TABLE public.learn_templates ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read templates (they're global)
CREATE POLICY IF NOT EXISTS "Anyone can read learn templates" ON public.learn_templates
  FOR SELECT USING (TRUE);

-- ============================================================================
-- INSERT SAMPLE TEMPLATES
-- ============================================================================

-- My Cycle templates (11 templates, 2 placeholders each)
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
think of it as a {Lifestyle Phase} day.', 'Hormonal Phase|Lifestyle Phase', 11, TRUE)
ON CONFLICT DO NOTHING;

-- Fitness templates (8 templates, 1 placeholder each)
INSERT INTO public.learn_templates (category, template_text, placeholder_key, sort_order, is_active) VALUES
('Fitness', 'Your body feels best with {Workout Mode} today.', 'Workout Mode', 1, TRUE),
('Fitness', 'Your body is primed for {Workout Mode} today.', 'Workout Mode', 2, TRUE),
('Fitness', 'Today your energy aligns with {Workout Mode}.', 'Workout Mode', 3, TRUE),
('Fitness', 'Your energy naturally supports {Workout Mode} today.', 'Workout Mode', 4, TRUE),
('Fitness', 'Your body responds well to {Workout Mode} right now.', 'Workout Mode', 5, TRUE),
('Fitness', 'Your body welcomes {Workout Mode} today.', 'Workout Mode', 6, TRUE),
('Fitness', '{Workout Mode} feels most supportive.', 'Workout Mode', 7, TRUE),
('Fitness', 'Your body finds harmony with {Workout Mode} today.', 'Workout Mode', 8, TRUE)
ON CONFLICT DO NOTHING;

-- Diet templates (8 templates, 1 placeholder each)
INSERT INTO public.learn_templates (category, template_text, placeholder_key, sort_order, is_active) VALUES
('Diet', 'Your body thrives on {Food Vibe} today.', 'Food Vibe', 1, TRUE),
('Diet', 'Your body feels deeply nourished by {Food Vibe} today.', 'Food Vibe', 2, TRUE),
('Diet', 'Today''s best nourishment is {Food Vibe}.', 'Food Vibe', 3, TRUE),
('Diet', 'Your body responds beautifully to {Food Vibe} today.', 'Food Vibe', 4, TRUE),
('Diet', 'Lean into {Food Vibe} today.', 'Food Vibe', 5, TRUE),
('Diet', 'Let {Food Vibe} guide your meals today.', 'Food Vibe', 6, TRUE),
('Diet', 'With your body in this phase, {Food Vibe} supports balance.', 'Food Vibe', 7, TRUE),
('Diet', '{Food Vibe} brings the balance you need today.', 'Food Vibe', 8, TRUE)
ON CONFLICT DO NOTHING;

-- Fasting templates (8 templates, 1 placeholder each)
INSERT INTO public.learn_templates (category, template_text, placeholder_key, sort_order, is_active) VALUES
('Fasting', 'Your ideal fasting window today is {Fast Style}.', 'Fast Style', 1, TRUE),
('Fasting', 'Your body settles well into a {Fast Style} today.', 'Fast Style', 2, TRUE),
('Fasting', 'Your body feels supported by a {Fast Style} today.', 'Fast Style', 3, TRUE),
('Fasting', 'Your system adapts well to a {Fast Style} today.', 'Fast Style', 4, TRUE),
('Fasting', 'Keep fasting to {Fast Style} today.', 'Fast Style', 5, TRUE),
('Fasting', 'A {Fast Style} keeps things balanced today.', 'Fast Style', 6, TRUE),
('Fasting', 'With today''s rhythm, a {Fast Style} works best.', 'Fast Style', 7, TRUE),
('Fasting', 'Your rhythm today pairs well with a {Fast Style}.', 'Fast Style', 8, TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
