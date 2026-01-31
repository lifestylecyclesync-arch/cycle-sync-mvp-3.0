# Complete Scalable Database Architecture - Phase Recommendations

## Overview
This is a fully scalable, database-driven system with **zero hardcoding**. All phase definitions, recommendations, and calculations are managed through Supabase.

## Key Components

### 1. **Database Schema** (`complete_database_schema.sql`)
Deploy this SQL file to your Supabase project:

**Key Tables:**
- `phases` - Single source of truth for phase definitions (Menstrual, Follicular, Ovulation, Luteal)
- `cycles` - User cycle tracking with start date and length
- `phase_recommendations` - All recommendations linked to phases via FK
- `fitness_logs`, `diet_logs`, `fasting_logs` - User activity logs

**Helper Functions:**
- `get_user_current_cycle()` - Calculate which day of cycle the user is on
- `get_user_current_phase()` - Determine current phase based on cycle data
- `get_user_phase_recommendations()` - Fetch recommendations for user's current phase and category

### 2. **New Provider** (`phase_provider.dart`)
Replaces the old hardcoded cycle_provider. Features:

- **`allPhasesProvider`** - Fetches all phases from database
- **`userCurrentCycleProvider`** - Gets user's active cycle with calculated day
- **`userCurrentPhaseProvider`** - Returns user's current phase (with Follicular fallback)
- **`userPhaseRecommendationsProvider`** - Fetches recommendations for current phase/category

### 3. **Updated Screens**
- `fitness_screen.dart`
- `diet_screen.dart`
- `fasting_screen.dart`

All now use the new phase provider instead of hardcoded values.

## Scalability Features

### ✅ No Hardcoding
- Phase names, dates, colors all in database
- Recommendations linked via phase_id foreign key
- Can add/modify phases without code changes

### ✅ Extensible
- Add new phases by inserting into `phases` table
- Add recommendations for any phase/category combination
- New category types require only database insert

### ✅ Multi-User Ready
- User cycles tracked separately
- Each user gets their own phase calculation
- RLS policies ensure data isolation

### ✅ Dynamic Phase Calculation
- Day-of-cycle calculated from start_date
- Phases automatically determined based on day ranges
- Cycle length customizable per user

## How to Deploy

### Step 1: Run SQL Schema in Supabase
Copy entire `complete_database_schema.sql` and run in Supabase SQL Editor:
1. Go to Supabase Dashboard → SQL Editor
2. New Query
3. Paste the entire SQL file
4. Run

This creates:
- All 7 tables with constraints
- RLS policies
- Helper functions
- Sample phases (4)
- Sample recommendations (12 - one per phase/category combo)

### Step 2: Add User to Database
When user signs up, create their record:
```dart
await SupabaseConfig.client
    .from('users')
    .insert({'id': userId, 'email': userEmail});
```

### Step 3: Create User's First Cycle
```dart
await SupabaseConfig.client
    .from('cycles')
    .insert({
      'user_id': userId,
      'start_date': DateTime(2026, 1, 15), // Cycle start
      'length': 28, // Typical cycle length
    });
```

### Step 4: Rebuild App
```bash
flutter clean
flutter pub get
flutter run
```

## Database Relationships

```
phases (id, name, day_start, day_end, ...)
  ↓ (1:many)
phase_recommendations (id, phase_id, category, title, ...)

users (id, email, ...)
  ↓ (1:many)
cycles (id, user_id, start_date, length, ...)
  ↓ (1:many)
fitness_logs (id, user_id, ...)
diet_logs (id, user_id, ...)
fasting_logs (id, user_id, ...)
```

## Adding New Recommendations

To add a new fitness tip for Menstrual phase:

```sql
INSERT INTO phase_recommendations (
  phase_id,
  category,
  title,
  description,
  tips,
  order_index
) VALUES (
  (SELECT id FROM phases WHERE name = 'Menstrual'),
  'Fitness',
  'New Title',
  'Description...',
  ARRAY['Tip 1', 'Tip 2', 'Tip 3'],
  1
);
```

## Adding New Phases

To add a custom phase (e.g., "Follicular Extended"):

```sql
INSERT INTO phases (
  name,
  day_start,
  day_end,
  description,
  icon_name,
  color_hex,
  order_index
) VALUES (
  'Follicular Extended',
  6,
  14,
  'Extended follicular with high energy',
  'energy',
  '#D4E9E2',
  2
);

-- Then add recommendations for this new phase
INSERT INTO phase_recommendations (...) VALUES (...);
```

## Fallback Behavior

- If user has no cycle data → Uses Follicular phase recommendations
- If phase lookup fails → Falls back to Follicular
- If category recommendations empty → Shows empty state gracefully

## Performance

- Indexes on `phase_name`, `category`, `user_id`, `start_date`
- RLS policies pre-filter data at database level
- Riverpod auto-dispose reduces memory usage
- Lazy loading with `.autoDispose`

## Future Enhancements

1. **Real-time Subscriptions** - Subscribe to cycles changes
2. **Analytics** - Track which recommendations users engage with most
3. **Custom Phases** - Allow users to define custom phase lengths
4. **A/B Testing** - Different recommendations for different users
5. **Predictions** - ML-based phase prediction beyond 28-day cycles

---

**Status:** ✅ Ready to deploy
**Deployment Path:** `complete_database_schema.sql` → Supabase SQL Editor
**Testing:** Once deployed, users with cycle data will see phase-specific recommendations
