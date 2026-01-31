# Supabase Schema Deployment Instructions

## Step 1: Navigate to Supabase SQL Editor
1. Go to https://app.supabase.com
2. Select your project: `aoimvxciibxxcxgeeocz`
3. Click on "SQL Editor" in the left sidebar

## Step 2: Run Updated Schema
1. Click "New query"
2. Copy the entire contents of `complete_database_schema.sql`
3. Paste into the SQL Editor
4. Click "Run" button
5. Wait for confirmation message

## Step 3: Verify Deployment
Run these verification queries one at a time:

```sql
-- Check phases exist
SELECT COUNT(*) as phase_count FROM public.phases;

-- Check recommendations exist
SELECT COUNT(*) as recommendation_count FROM public.phase_recommendations;

-- Check user creation trigger exists
SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';
```

## Key Changes Made:
1. **Fixed PL/pgSQL function**: Aliased `day_of_cycle` calculation to avoid ambiguity
2. **Enhanced RLS policies**: Added separate INSERT, UPDATE, DELETE policies for cycles
3. **Added user auto-create trigger**: `handle_new_user()` creates user record when they sign up via auth
4. **Improved permissions**: Users can now insert their own profile and manage cycles

## Result:
- Phase data stored in single source of truth table
- User profiles auto-created on signup
- Users can create and manage their own cycles
- App can dynamically calculate current phase based on cycle data

## Troubleshooting:
If you get "permission denied" errors:
1. Check that policies are created: `SELECT * FROM pg_policies;`
2. Verify user role has proper permissions (should be `authenticated`)
3. Redeploy entire schema

If you get "column ambiguous" errors:
1. Verify `get_user_current_cycle` function was updated with aliased columns
2. Check function definition: `\df+ get_user_current_cycle`
