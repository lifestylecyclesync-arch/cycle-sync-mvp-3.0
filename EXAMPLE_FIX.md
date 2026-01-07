# Example: Fixing a Guest Mode Calendar Issue

## Problem Report
**User:** "When I'm in guest mode and click on a calendar date, it shows an error"  
**Affected Path:** PATH 1 (Guest Mode)  
**Files to Edit:** `lib/presentation/pages/planner_page.dart` ONLY  
**Files NOT to Touch:** `lib/main.dart`, `onboarding_page.dart`, `app_shell.dart`

---

## The Fix (DailyCardSheet - Guest Mode Branch)

### Before (Broken)
```dart
// lines 263-284 in planner_page.dart
if (isGuest) {
  return FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: Text('Failed to load data'));
      }

      final prefs = snapshot.data!;
      final lifestyleAreas = prefs.getStringList('lifestyleAreas') ?? [];
      // BUG: lifestyleAreas might be null or empty
      // This causes error when cyclePhaseProvider tries to use it
      
      return ref.watch(cyclePhaseProvider(date)).when(
        data: (phaseInfo) => _buildDailyCardContent(
          context,
          ref,
          phaseInfo,
          lifestyleAreas,  // ← Could be empty, causing error
          fastingPref,
        ),
        // ...
      );
    },
  );
}
```

### After (Fixed)
```dart
// lines 263-284 in planner_page.dart (FIXED)
if (isGuest) {
  return FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: Text('Failed to load data'));
      }

      final prefs = snapshot.data!;
      final lifestyleAreas = prefs.getStringList('lifestyleAreas') ?? [];
      
      // FIX: Validate that data exists before using
      if (lifestyleAreas.isEmpty) {
        return const Center(
          child: Text('Please complete onboarding first'),
        );
      }

      return ref.watch(cyclePhaseProvider(date)).when(
        data: (phaseInfo) => _buildDailyCardContent(
          context,
          ref,
          phaseInfo,
          lifestyleAreas,  // ← Now validated
          fastingPref,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading recommendations: $err'),
        ),
      );
    },
  );
}
```

---

## Why This Fix is Safe

### ✅ PATH 1 (Guest Mode) - AFFECTED
- We fixed the DailyCardSheet guest mode branch
- Users in guest mode now get proper error handling
- **Result:** Guest mode calendar works correctly ✅

### ✅ PATH 2 (Unauthenticated) - NOT AFFECTED
- The OnboardingPage screens are completely separate
- Users filling out onboarding don't touch DailyCardSheet
- **Result:** No impact on signup flow ✅

### ✅ PATH 3a (Authenticated + Profile) - NOT AFFECTED
- The authenticated mode branch in DailyCardSheet (lines 299-320) wasn't touched
- Users with accounts and profiles use different code path
- **Result:** Authenticated users unaffected ✅

### ✅ PATH 3b (Authenticated + No Profile) - NOT AFFECTED
- _CompleteProfileFlow only shows screens 2 & 3
- Users completing profile never reach DailyCardSheet
- **Result:** Profile completion flow unaffected ✅

### ✅ main.dart (_getInitialPage) - NOT AFFECTED
- We didn't touch the routing logic
- Path selection still works the same way
- **Result:** All paths still route correctly ✅

---

## Code Flow Illustration

```
User (Guest Mode)
     ↓
AppShell (PATH 1)
     ↓
PlannerPage
     ↓
User clicks date
     ↓
DailyCardSheet.build()
     ├─ isGuest == true?
     │  └─ Go to Guest branch (lines 263-284)
     │     └─ NEW: Check if lifestyleAreas.isEmpty
     │        ├─ Yes → Show error message ✅
     │        └─ No → Show recommendations ✅
     │
     └─ isGuest == false?
        └─ Go to Auth branch (lines 299-320)
           └─ UNCHANGED - still works perfectly
```

---

## Testing the Fix

### Test PATH 1 (Guest Mode)
```
1. Fresh install
2. Tap "Explore" 
3. Complete onboarding (fill all screens)
4. Tap date in calendar
5. Should see correct recommendations (FIX VERIFIED ✅)
6. Restart app
7. Should still see recommendations (persistence works ✅)
```

### Test PATH 2 (Unaffected)
```
1. Fresh install
2. Tap "Create Account"
3. Complete signup
4. Should see AppShell (STILL WORKS ✅)
```

### Test PATH 3a (Unaffected)
```
1. Login with existing account
2. Tap date in calendar
3. Should see authenticated recommendations (STILL WORKS ✅)
```

---

## Key Takeaway

**This fix only edited one branch of one method in one file.** It didn't require:
- ❌ Touching `_getInitialPage()` in main.dart
- ❌ Modifying OnboardingPage
- ❌ Changing AppShell
- ❌ Touching authentication logic

**Result:** All three paths continue working independently. ✅
