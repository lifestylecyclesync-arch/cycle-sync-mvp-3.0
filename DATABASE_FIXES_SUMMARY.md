# Database Fixes & Deployment Summary

## Issues Found in App Logs

### Error 1: Ambiguous Column Reference
```
PostgrestException: column reference "day_of_cycle" is ambiguous
```
**Root Cause**: In `get_user_current_cycle()` PL/pgSQL function, the calculation result wasn't aliased properly, causing ambiguity between the function parameter and return column.

**Fix Applied**: Added explicit aliases to all SELECT columns in the function:
```sql
CAST((EXTRACT(DAY FROM CURRENT_DATE - c.start_date)::INTEGER % c.length) + 1 AS INTEGER) AS day_of_cycle
```

### Error 2: Permission Denied for Table
```
PostgrestException: permission denied for table cycles
```
**Root Cause**: 
- User record doesn't exist in `public.users` table yet
- RLS policy requires `auth.uid() = user_id`, which fails if user record is missing
- User tried to query cycles table but had no permissions

**Fix Applied**: 
1. Enhanced RLS policies with separate INSERT, UPDATE, DELETE policies
2. Added user auto-create trigger that fires when they sign up:
```sql
CREATE FUNCTION handle_new_user()
CREATE TRIGGER on_auth_user_created
```

### Error 3: Cannot Coerce Result to JSON Object
```
PostgrestException: The result contains 0 rows
```
**Root Cause**: User record not in `public.users` table, so `.single()` call fails.

**Fix Applied**: Same as above - trigger auto-creates user record on auth signup

## Updated Schema Changes

### 1. Fixed PL/pgSQL Functions
- ✅ `get_user_current_cycle()` - Added column aliases to eliminate ambiguity
- ✅ `get_user_current_phase()` - Cleaned up variable usage
- ✅ `get_user_phase_recommendations()` - No changes needed

### 2. Enhanced RLS Policies
**Before** (too restrictive):
```sql
CREATE POLICY "Users can manage their own cycles" ON public.cycles
  FOR ALL USING (auth.uid() = user_id);
```

**After** (granular control):
```sql
CREATE POLICY "Users can manage their own cycles" ON public.cycles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert cycles" ON public.cycles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their cycles" ON public.cycles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their cycles" ON public.cycles
  FOR DELETE USING (auth.uid() = user_id);
```

### 3. Added Auto-User-Creation Trigger
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

This ensures that whenever a user signs up via Supabase Auth, their profile is automatically created in the `public.users` table.

## Deployment Steps

### Option 1: Automatic (Recommended)
The `complete_database_schema.sql` file contains DROP statements that clean up old tables and functions, then recreates everything fresh. This is the safest approach.

**Steps:**
1. Go to Supabase Dashboard: https://app.supabase.com
2. Select project: `aoimvxciibxxcxgeeocz`
3. Click "SQL Editor" → "New query"
4. Open `complete_database_schema.sql` from your workspace
5. Copy entire contents
6. Paste into SQL Editor
7. Click "Run"
8. Wait for success message

### Option 2: Manual Verification
If auto-deployment doesn't work, run these queries individually:

1. Check phases:
```sql
SELECT COUNT(*) as phase_count FROM public.phases;
```
Expected: `4`

2. Check recommendations:
```sql
SELECT COUNT(*) as recommendation_count FROM public.phase_recommendations;
```
Expected: `12`

3. Verify trigger:
```sql
SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';
```
Expected: `handle_new_user`

4. Check policies:
```sql
SELECT policyname FROM pg_policies WHERE tablename = 'cycles';
```
Expected: 4 policies (select, insert, update, delete)

## App-Side Changes

### Updated Files
1. ✅ **cycle_provider.dart** - Added better error handling for permission denied errors
2. ✅ **phase_provider.dart** - Already has Follicular fallback
3. ✅ **fitness_screen.dart** - Already uses new providers
4. ✅ **diet_screen.dart** - Already uses new providers  
5. ✅ **fasting_screen.dart** - Already uses new providers
6. ✅ **app_shell.dart** - Fixed PageController issue (no longer needed)

## Expected Behavior After Deployment

### On First Login:
1. User authenticates with Supabase
2. `handle_new_user()` trigger fires automatically
3. User record created in `public.users` table with their ID and email
4. App queries cycles table (now has permission)
5. No cycles found → returns `null` (expected for new user)
6. `userCurrentPhaseProvider` returns Follicular (default phase)
7. App displays Follicular phase recommendations (Fitness/Nutrition/Fasting)

### After Adding a Cycle:
1. User creates cycle entry with start date
2. App calculates current day of cycle
3. `get_user_current_phase()` function determines phase
4. `userCurrentPhaseProvider` returns actual phase from database
5. Phase-specific recommendations display

## Troubleshooting

### Still getting "permission denied" after deployment:
- Check that trigger exists: `SELECT proname FROM pg_proc WHERE proname = 'handle_new_user';`
- Check RLS policies: `SELECT policyname FROM pg_policies WHERE tablename = 'cycles';`
- Verify user record was created: `SELECT * FROM public.users WHERE id = 'YOUR_USER_ID';`
- If not created, manually run: `INSERT INTO public.users (id, email) VALUES ('YOUR_USER_ID', 'your@email.com');`

### Still getting "ambiguous column" error:
- Verify function was updated: `SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'get_user_current_cycle';`
- Should show aliased columns with `AS day_of_cycle` at the end

### Recommendations not displaying:
- Verify phases exist: `SELECT * FROM public.phases;`
- Verify recommendations inserted: `SELECT COUNT(*) FROM public.phase_recommendations;` (should be 12)
- Check your cycle dates are correct

## Next Steps

1. **Deploy the schema** using Option 1 above
2. **Refresh the app** (hot reload should work, or rebuild)
3. **Monitor the logs** - look for success messages instead of errors
4. **Test the flow**:
   - Log in with your email
   - Check that app shows Follicular phase recommendations
   - Add a cycle entry with today's date
   - See phase recommendations update based on cycle day

## Questions?
Check the complete_database_schema.sql file for full implementation details including all indices, RLS policies, and sample data.
