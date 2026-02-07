# Onboarding System Implementation

## Overview
Created a comprehensive onboarding system that solves the "cold start" problem by having users enter their last period date before accessing the main app. This data becomes the reference point for all cycle calculations.

## What Was Changed

### 1. Database Schema (`SUPABASE_SCHEMA.sql`)
Added two fields to `user_profiles` table:
- `onboarding_completed BOOLEAN DEFAULT FALSE` - Tracks if user completed onboarding
- `onboarding_completed_at TIMESTAMP` - Timestamp of when onboarding was completed

**Why**: Allows the app to determine if a user needs onboarding or can access the main app directly.

### 2. New Files Created

#### `lib/presentation/pages/screens/onboarding_screen.dart`
A beautiful onboarding screen with:
- Date picker for "When was your last period?"
- Slider for average cycle length (21-35 days, default 28)
- Slider for average menstrual flow length (2-10 days, default 5)
- Validation and error handling
- Loading state during submission
- Info text explaining the data is updateable

**Flow**:
1. User selects their last period date
2. User sets their cycle length (optional, defaults to 28)
3. User sets their menstrual length (optional, defaults to 5)
4. User taps "Start Tracking"
5. Data is saved and app redirects to main app

#### `lib/presentation/providers/onboarding_provider.dart`
Three providers:

1. **`onboardingStatusProvider`** - Checks if user has completed onboarding
2. **`completeOnboardingProvider`** - Saves onboarding data and marks onboarding complete
3. **`needsOnboardingProvider`** - Determines if authenticated user needs to see onboarding screen

#### `lib/presentation/providers/period_tracking_provider.dart`
Provides the ability to log new periods after onboarding:

**`logPeriodProvider`** - Handles logging a new period date:
1. Marks all previous active cycles as inactive
2. Checks if cycle with that date exists
3. Updates or creates the cycle
4. Updates user's `last_period_date`
5. Invalidates dependent providers for UI refresh

**Edge Cases Handled**:
- User logs the same period date twice (updates instead of duplicating)
- Multiple periods (creates new cycle, deactivates old)
- Invalid date ranges (validation in UI)

### 3. Updated Files

#### `lib/main.dart`
Modified `AuthWrapper` to:
1. Check if user is authenticated (existing logic)
2. If authenticated, check if onboarding is needed (new)
3. If onboarding needed → show `OnboardingScreen`
4. If onboarding complete → show `AppShell` (main app)
5. If any error → show main app (graceful fallback)

**Logic Flow**:
```
User Logs In
    ↓
AuthWrapper checks session
    ↓
Is authenticated? NO → Show LoginPage
    ↓
Is authenticated? YES → Check onboarding status
    ↓
Needs onboarding? YES → Show OnboardingScreen
    ↓
Needs onboarding? NO → Show AppShell (main app)
```

## System Architecture

### The Reference Point Problem (Solved)
**Before**: Without an initial period date, the app couldn't calculate which cycle day the user is on
**After**: User enters last period date during onboarding → This becomes the source of truth for all calculations

### How Cycle Calculations Work Now
1. User enters last period date (e.g., 2026-01-20)
2. This is stored in `user_profiles.last_period_date`
3. All providers calculate current cycle day from this date
4. When user logs a new period, `last_period_date` is updated
5. Cycle calculations automatically reflect the new reference point

### Data Flow for New Period Logging
```
User logs new period
    ↓
logPeriodProvider receives periodDate
    ↓
Deactivate all active cycles (is_active = false)
    ↓
Check if cycle exists for this date
    ↓
Exists? → Update & activate
Doesn't exist? → Create new & activate
    ↓
Update user_profiles.last_period_date
    ↓
Invalidate dependent providers
    ↓
UI refreshes with new calculations
```

## Edge Cases Handled

### 1. User Signs Up → First Time
- New user created in `auth.users`
- Trigger `handle_new_user()` creates `user_profiles` entry
- User sees onboarding screen
- Enters their last period date
- App becomes fully functional

### 2. User Logs Period Later
- Uses `logPeriodProvider` in My Cycle screen
- Previous cycle automatically marked inactive
- New cycle created
- All calculations update

### 3. User Enters Same Date Twice
- `logPeriodProvider` checks for existing cycle
- If exists with same date → Updates instead of creating duplicate

### 4. User Logs Period from Past
- Date picker allows selecting up to 365 days ago
- New cycle created with that date
- Valid for tracking missed period entries

### 5. Onboarding Check Error
- If there's an error fetching onboarding status → Gracefully show main app
- User can still use app even if check fails

## Testing Scenarios

### Scenario 1: Fresh Install
```
1. Download app → Register → See onboarding screen
2. Select 2026-01-20 as last period
3. Set cycle to 28 days, menstrual to 5 days
4. Tap "Start Tracking"
5. See My Cycle screen with calculated phases
```

### Scenario 2: Log New Period
```
1. User in My Cycle screen
2. Gets period on 2026-02-17 (28 days later)
3. Taps "Log Period" → Selects 2026-02-17
4. Previous cycle marked inactive
5. New cycle created with 2026-02-17
6. Calendar updates, phases recalculate
```

### Scenario 3: Onboarding Skip (Later Re-entry)
```
1. User completed onboarding
2. Logs back in later
3. AuthWrapper checks onboarding_completed = true
4. Skips onboarding, shows main app directly
```

## Validation Rules

- **Cycle Length**: 21-35 days (with error message)
- **Menstrual Length**: 2-10 days (with error message)
- **Last Period Date**: Up to 365 days in the past, not future
- **UI Feedback**: Loading state, error messages, success navigation

## Next Steps

1. **Deploy Schema** to Supabase
2. **Test Onboarding Flow**:
   - Create new account
   - Verify onboarding screen appears
   - Enter test data
   - Verify redirect to main app
3. **Test Period Logging**:
   - Log a new period
   - Verify cycle calculations update
   - Verify old cycle marked inactive
4. **Optional Enhancements**:
   - Edit cycle data in settings
   - View cycle history
   - Import period history from calendar app

## Files Summary

| File | Purpose |
|------|---------|
| `SUPABASE_SCHEMA.sql` | Added onboarding fields to user_profiles |
| `onboarding_screen.dart` | UI for entering initial period data |
| `onboarding_provider.dart` | Logic for onboarding checks and completion |
| `period_tracking_provider.dart` | Logic for logging new periods |
| `main.dart` | Updated routing to check onboarding |
