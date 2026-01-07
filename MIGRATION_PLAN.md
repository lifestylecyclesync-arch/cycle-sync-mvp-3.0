# Migration Plan: SharedPreferences → Supabase

## Overview
Migrate the app from offline-first (SharedPreferences) to online-first with Supabase backend while maintaining offline functionality via local caching.

---

## Phase 1: Database Setup ✅ (COMPLETED)
- [x] Update `supabase_schema.sql` with new tables
  - user_profiles (name, cycle data, avatar, fasting preference)
  - lifestyle_areas (many-to-many with auth.users)
  - daily_notes (per-date notes)
  - cycle_calculations (cached calculations)
- [x] Enable Row Level Security (RLS) policies
- [x] Set up proper foreign keys to auth.users

---

## Phase 2: Authentication Layer (TODO)
**Status:** Not started

### Tasks:
1. Create/update `auth_service.dart`
   - Sign up with email/password
   - Login with email/password
   - Sign out
   - Get current user
   - Handle auth state changes

2. Create `auth_provider.dart` (Riverpod)
   - Watch auth state
   - Expose currentUser
   - Expose isAuthenticated

3. Update onboarding flow
   - Add sign-up screen before cycle data input
   - Transition from guest mode → authenticated mode

4. Add auth error handling
   - Network errors
   - Invalid credentials
   - Email already exists

---

## Phase 3: Data Layer Migration (TODO)
**Status:** Not started

### Current SharedPreferences Keys → Supabase:
| Data | SharedPrefs Key | Supabase Table | Notes |
|------|-----------------|----------------|-------|
| Cycle length | cycleLength | user_profiles | integer |
| Menstrual length | menstrualLength | user_profiles | integer |
| Luteal phase | lutealPhaseLength | user_profiles | integer (new) |
| Last period | lastPeriodDate | user_profiles | timestamp |
| Name | userName | user_profiles | string |
| Avatar | userAvatarPath | user_profiles | base64 text |
| Fasting pref | fastingPreference | user_profiles | enum |
| Lifestyle areas | lifestyleAreas | lifestyle_areas | array (normalized) |
| Notes | notes_YYYY_MM_DD | daily_notes | per-date records |
| Onboarding flag | onboarding_completed | (derived) | check user_profiles exists |

### Tasks:
1. Update `user_profile_repository_impl.dart`
   - `getUserProfile()` → fetch from Supabase
   - `saveUserProfile()` → save to Supabase
   - `updateUserProfile()` → update specific fields
   - Add local cache layer (SharedPreferences)

2. Create `lifestyle_areas_repository.dart`
   - `getLifestyleAreas(userId)` → fetch from Supabase
   - `addLifestyleArea(userId, area)` → insert
   - `removeLifestyleArea(userId, area)` → delete
   - Sync with local cache

3. Create `daily_notes_repository.dart`
   - `getNote(userId, date)` → fetch from Supabase
   - `saveNote(userId, date, text)` → upsert
   - `deleteNote(userId, date)` → delete
   - Sync with local cache

4. Add offline sync mechanism
   - Queue failed mutations
   - Retry on network reconnect
   - Merge conflicts intelligently

---

## Phase 4: Provider Updates (TODO)
**Status:** Not started

### Tasks:
1. Update `user_profile_provider.dart`
   - Add loading state
   - Add error state
   - Fetch from Supabase instead of SharedPreferences

2. Create `lifestyle_areas_provider.dart`
   - Watch lifestyle areas for current user
   - Support add/remove operations

3. Create `daily_notes_provider.dart`
   - Watch notes for specific date
   - Support save/delete operations

4. Add network status provider
   - Watch connectivity
   - Trigger syncs on reconnect

---

## Phase 5: UI Updates (TODO)
**Status:** Not started

### Tasks:
1. Update `onboarding_page.dart`
   - Add sign-up screen (Screen 0)
   - Shift cycle data to Screen 1-2
   - Shift lifestyle areas to Screen 3

2. Update `planner_page.dart`
   - Add error handling for Supabase calls
   - Show sync status
   - Handle offline gracefully

3. Update `profile_page.dart`
   - Add loading states for save operations
   - Show sync indicators
   - Handle profile picture upload to Supabase Storage

4. Add network status indicator
   - Show in header when offline
   - Show sync status for pending changes

---

## Phase 6: Profile Picture Storage (TODO)
**Status:** Not started

### Tasks:
1. Set up Supabase Storage bucket
   - Create `user-avatars` bucket
   - Set up proper access policies

2. Update profile picture upload
   - Upload image to Storage instead of base64
   - Store URL in user_profiles.avatar_url
   - Display from URL instead of base64

3. Handle cleanup
   - Delete old avatar from Storage when updating
   - Clean up unused files

---

## Phase 7: Testing & Cleanup (TODO)
**Status:** Not started

### Tasks:
1. Test authentication flow
   - Sign up works
   - Login works
   - Logout works
   - Auth persists on app restart

2. Test data sync
   - Create profile → saves to Supabase
   - Update profile → Supabase reflects change
   - Add note → persists
   - Offline changes sync when online

3. Test offline functionality
   - App works without internet
   - Changes are queued
   - Sync happens automatically when online

4. Remove SharedPreferences
   - Delete old migrations
   - Clean up dependencies
   - Remove SharedPreferences usage

---

## Implementation Order
1. **Week 1:** Auth (Phase 2)
2. **Week 2:** Data Layer (Phase 3)
3. **Week 3:** Providers (Phase 4)
4. **Week 4:** UI & Profile Storage (Phase 5-6)
5. **Week 5:** Testing & Cleanup (Phase 7)

---

## Key Libraries Needed
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  connectivity_plus: ^5.0.0  # For offline detection
  hive: ^2.0.0  # Optional: for robust offline caching
```

---

## Notes
- **RLS is enabled** - Only authenticated users can access their own data
- **Offline-first approach** - Local cache + queue syncing for better UX
- **No migrations** - Clean slate with Supabase, SharedPreferences will be phased out
- **Auth via Supabase** - Uses email/password authentication

---

## Current Status
✅ Database schema created
⏳ Awaiting implementation start

