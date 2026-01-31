-- ============================================================================
-- PHASE RECOMMENDATIONS TABLE
-- ============================================================================
-- Single source of truth for all cycle phase recommendations
-- Last updated: 2026-01-30

-- ============================================================================
-- CREATE TABLE
-- ============================================================================

CREATE TABLE public.phase_recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Phase identifier
  phase_name TEXT NOT NULL CHECK (phase_name IN ('Menstrual', 'Follicular', 'Ovulation', 'Luteal')),
  
  -- Category
  category TEXT NOT NULL CHECK (category IN ('Fitness', 'Nutrition', 'Fasting')),
  
  -- Content
  title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT NOT NULL,
  tips TEXT[] DEFAULT '{}', -- Array of actionable tips
  
  -- Optional fields per category
  fasting_hours_min INTEGER, -- For Fasting category (e.g., 12)
  fasting_hours_max INTEGER, -- For Fasting category (e.g., 14)
  fasting_style TEXT, -- e.g., "Rest & Recovery", "Medium Fast"
  
  -- Metadata
  order_index INTEGER DEFAULT 0, -- For sorting within a phase
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (phase_name, category)
);

-- ============================================================================
-- INDEX
-- ============================================================================

CREATE INDEX idx_phase_recommendations_phase ON public.phase_recommendations(phase_name);
CREATE INDEX idx_phase_recommendations_category ON public.phase_recommendations(category);

-- ============================================================================
-- RLS POLICY
-- ============================================================================

ALTER TABLE public.phase_recommendations ENABLE ROW LEVEL SECURITY;

-- Everyone can read phase recommendations (they're canonical)
CREATE POLICY "Anyone can read phase recommendations" ON public.phase_recommendations
  FOR SELECT USING (TRUE);

-- ============================================================================
-- SAMPLE DATA - All recommendations currently in the app
-- ============================================================================

-- MENSTRUAL PHASE
INSERT INTO public.phase_recommendations (phase_name, category, title, subtitle, description, tips, order_index, fasting_hours_min, fasting_hours_max, fasting_style)
VALUES
(
  'Menstrual',
  'Fitness',
  'Rest & Recovery',
  'Focus on gentle movement',
  'Your body needs recovery time. Embrace restorative practices that honor your natural rhythm.',
  ARRAY['Gentle yoga or stretching (20-30 min)', 'Walks in nature', 'Foam rolling or self-massage', 'Rest days encouraged'],
  1,
  NULL,
  NULL,
  NULL
),
(
  'Menstrual',
  'Nutrition',
  'Iron & Hydration',
  'Replenish what you''re losing',
  'Prioritize iron-rich foods and minerals. Stay well hydrated and focus on gut-friendly, nourishing meals.',
  ARRAY['Red meat, lentils, spinach for iron', 'Herbal teas with ginger or turmeric', 'Stay hydrated (3-4L water)', 'Anti-inflammatory foods: berries, dark leafy greens'],
  1,
  NULL,
  NULL,
  NULL
),
(
  'Menstrual',
  'Fasting',
  'Short Fast',
  'Light fasting window',
  'Keep fasting windows shorter to support your body during menstruation. Focus on nourishment.',
  ARRAY['12-14 hours recommended', 'Eat nutrient-dense foods when breaking fast', 'Listen to hunger cues', 'Hydration is key'],
  1,
  12,
  14,
  'Short Fast (12-14h)'
);

-- FOLLICULAR PHASE
INSERT INTO public.phase_recommendations (phase_name, category, title, subtitle, description, tips, order_index, fasting_hours_min, fasting_hours_max, fasting_style)
VALUES
(
  'Follicular',
  'Fitness',
  'High Energy Phase',
  'Push your limits',
  'Energy and endurance peak in this phase. It''s the perfect time for high-intensity workouts and challenging new exercises.',
  ARRAY['HIIT or high-intensity cardio', 'Start new fitness routines or challenges', 'Strength training (3-4x/week)', 'Consider group fitness classes for motivation'],
  2,
  NULL,
  NULL,
  NULL
),
(
  'Follicular',
  'Nutrition',
  'Light & Fresh',
  'Embrace raw and energizing foods',
  'Your metabolism is rising. Eat lighter, fresher foods that match your energy levels. Lower carbs are often preferred.',
  ARRAY['Fresh salads and raw vegetables', 'Light proteins: fish, chicken breast', 'Fruits and refreshing smoothies', 'Reduce heavy, cooked meals'],
  2,
  NULL,
  NULL,
  NULL
),
(
  'Follicular',
  'Fasting',
  'Flexible Medium Fast',
  'Extend your window moderately',
  'Gradually extend your fasting window. Your body can handle longer fasts during this phase.',
  ARRAY['14-16 hours recommended', 'Feel energized during fast', 'Flexible schedule OK', 'Listen to your body'],
  2,
  14,
  16,
  'Medium Fast (14-16h)'
);

-- OVULATION PHASE
INSERT INTO public.phase_recommendations (phase_name, category, title, subtitle, description, tips, order_index, fasting_hours_min, fasting_hours_max, fasting_style)
VALUES
(
  'Ovulation',
  'Fitness',
  'Peak Performance',
  'Your strongest phase',
  'Testosterone peaks in this phase! Go for your personal records, intense intervals, and challenging strength sessions.',
  ARRAY['Peak PR attempts', 'Intense HIIT workouts', 'Advanced strength training', 'Competitive sports or challenges'],
  3,
  NULL,
  NULL,
  NULL
),
(
  'Ovulation',
  'Nutrition',
  'Lean Protein & Volume',
  'Support your peak phase',
  'Eat more protein and volume. Your appetite and calorie needs are highest. Carbs are well-utilized now.',
  ARRAY['Lean proteins: chicken, fish, turkey', 'High-volume vegetables', 'Moderate carbs (rice, sweet potato)', 'Balanced macros for satiety'],
  3,
  NULL,
  NULL,
  NULL
),
(
  'Ovulation',
  'Fasting',
  'Extended Fast',
  'Your fasting sweet spot',
  'Extended fasting windows work best during ovulation. Your body is resilient and fat-burning is optimized.',
  ARRAY['16-18 hours recommended', 'Ketosis-friendly phase', 'Extended energy levels', 'Great for longer fasts'],
  3,
  16,
  18,
  'Extended Fast (16-18h)'
);

-- LUTEAL PHASE
INSERT INTO public.phase_recommendations (phase_name, category, title, subtitle, description, tips, order_index, fasting_hours_min, fasting_hours_max, fasting_style)
VALUES
(
  'Luteal',
  'Fitness',
  'Moderate Activity & Pilates',
  'Introspective movement',
  'Energy dips, but this phase is perfect for mind-body connection. Prioritize consistency over intensity.',
  ARRAY['Pilates and core work', 'Moderate cardio (30-40 min)', 'Yoga and stretching', 'Walking or cycling at easy pace'],
  4,
  NULL,
  NULL,
  NULL
),
(
  'Luteal',
  'Nutrition',
  'Complex Carbs & Serotonin',
  'Comfort and hormone support',
  'Calorie needs increase. Focus on complex carbs, healthy fats, and serotonin-boosting foods. Magnesium is key.',
  ARRAY['Whole grains and complex carbs', 'Nuts, seeds, avocado for healthy fats', 'Chocolate (dark 70%+)', 'Omega-3 rich foods: salmon, walnuts'],
  4,
  NULL,
  NULL,
  NULL
),
(
  'Luteal',
  'Fasting',
  'Short Fast',
  'Gentle fasting window',
  'Shorten your fasting window during luteal. Your body needs more frequent nourishment to support hormonal needs.',
  ARRAY['12-14 hours recommended', 'More frequent eating windows', 'Eat when hungry', 'Avoid extended fasts'],
  4,
  12,
  14,
  'Short Fast (12-14h)'
);

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================

/*
-- Check all recommendations inserted
SELECT phase_name, category, title FROM public.phase_recommendations ORDER BY phase_name, category;

-- Check by phase
SELECT * FROM public.phase_recommendations WHERE phase_name = 'Follicular';
*/

-- ============================================================================
-- END OF PHASE RECOMMENDATIONS SCHEMA
-- ============================================================================
