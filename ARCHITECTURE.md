# Cycle Sync - Modular Navigation Architecture

## Overview
The app uses three completely independent paths that don't interfere with each other:

```
MyApp._getInitialPage()
    ├─ PATH 1: Guest Mode (isGuestMode == true)
    │  └─ AppShell (isolated, self-contained)
    │
    ├─ PATH 2: Unauthenticated (user == null)
    │  └─ OnboardingPage (screens 1, 2, 3 - isolated)
    │
    └─ PATH 3: Authenticated (user != null)
       ├─ 3a: Has Profile → AppShell (isolated)
       └─ 3b: No Profile → _CompleteProfileFlow (isolated screens 2, 3)
```

---

## Path Isolation Guarantees

### ✅ PATH 1: Guest Mode
**Entry Point:** `MyApp._getInitialPage()` line 60-63  
**When it activates:** At startup, if `guestModeProvider == true`  
**Where it's stored:** `SharedPreferences.setBool('guest_mode', true)` (line 750 in onboarding_page.dart)  
**Isolation:** Lives in `AppShell`, never shows OnboardingPage

**How to fix issues in this path without affecting others:**
- Edit only `AppShell` or its child widgets
- Changes to `OnboardingPage` won't affect it
- Changes to `_CompleteProfileFlow` won't affect it
- **No need to touch `_getInitialPage()`** - just fix the AppShell logic

**Example:** If AppShell calendar shows wrong recommendations
```dart
// Edit ONLY: lib/presentation/pages/app_shell.dart
// NOT: lib/main.dart or onboarding_page.dart
class AppShell extends StatelessWidget {
  // Fix calendar logic here without affecting other paths
}
```

---

### ✅ PATH 2: Unauthenticated  
**Entry Point:** `MyApp._getInitialPage()` line 72-75  
**When it activates:** At startup, if no user logged in  
**Isolation:** Lives in `OnboardingPage`, completely separate from other paths

**How to fix issues in this path without affecting others:**
- Edit only `lib/presentation/pages/onboarding_page.dart`
- Changes to AppShell won't affect it
- Changes to _CompleteProfileFlow won't affect it
- **No need to touch `_getInitialPage()`** - just fix onboarding

**Example:** If screen 3 toggle switches don't save correctly
```dart
// Edit ONLY: lib/presentation/pages/onboarding_page.dart
// NOT: lib/main.dart or app_shell.dart
class _LifestyleScreen extends ConsumerStatefulWidget {
  // Fix toggle switch logic here
  // The _AuthLifestyleScreen in main.dart won't be affected
}
```

---

### ✅ PATH 3a: Authenticated + Has Profile
**Entry Point:** `MyApp._getInitialPage()` line 86-88  
**When it activates:** At startup, if user logged in AND profile exists  
**Isolation:** Lives in `AppShell`, same as PATH 1

**How to fix issues in this path without affecting others:**
- Edit only `lib/presentation/pages/app_shell.dart`
- Changes to `OnboardingPage` won't affect it
- Changes to `_CompleteProfileFlow` won't affect it

---

### ✅ PATH 3b: Authenticated + No Profile
**Entry Point:** `MyApp._getInitialPage()` line 91-93  
**When it activates:** At startup, if user logged in BUT no profile  
**Isolation:** Lives in `_CompleteProfileFlow` (screens 2 & 3 only), completely separate

**How to fix issues in this path without affecting others:**
- Edit only `_AuthCycleDataScreen` and `_AuthLifestyleScreen` in `lib/main.dart`
- Changes to `OnboardingPage` won't affect it
- Changes to AppShell won't affect it
- **No need to touch `_getInitialPage()`** - just fix the auth flow screens

**Example:** If authenticated users can't complete their profile
```dart
// Edit ONLY: lib/main.dart (_AuthCycleDataScreen and _AuthLifestyleScreen)
// NOT: lib/presentation/pages/onboarding_page.dart
class _AuthLifestyleScreen extends ConsumerStatefulWidget {
  // Fix profile completion logic here
  // The _LifestyleScreen in onboarding_page.dart won't be affected
}
```

---

## Key Isolation Principles

### 1. **Evaluation Happens Once**
```dart
// Line 53 in main.dart
Widget _getInitialPage(...) {
  // This evaluates ONCE at startup
  // It determines which path, then NEVER re-evaluates the path decision
  if (isGuestMode) return const AppShell();
  if (user == null) return const OnboardingPage();
  if (profile != null) return const AppShell();
  return const _CompleteProfileFlow();
}
```
**Why this matters:** Once a path is chosen, it doesn't swap. No more "taking back to screen 1" issues.

### 2. **Each Path Has Its Own Navigation Stack**
- **PATH 1/3a:** AppShell has its own `Navigator` via BottomNavigationBar
- **PATH 2:** OnboardingPage has its own `PageView` (screens 1, 2, 3)
- **PATH 3b:** _CompleteProfileFlow has its own `PageView` (screens 2, 3 only)

**Why this matters:** Navigation in one path doesn't affect another.

### 3. **Profile Completion Triggers Parent Rebuild**
```dart
// Line 186 in main.dart (_CompleteProfileFlow)
void _completedProfile() {
  // Profile completed - invalidate to trigger parent rebuild
  if (mounted) {
    ref.invalidate(userProfileProvider);
  }
}
```
**Then in MyApp:**
```dart
// Line 42 - watches userProfileProvider
final userProfileAsync = ref.watch(userProfileProvider);
// When invalidated, this rebuilds
// Path 3b transitions to Path 3a (AppShell)
```
**Why this matters:** Clean transition without navigation confusion.

### 4. **Guest Mode Persists Independently**
```dart
// Line 37 in guest_mode_provider.dart
final loadGuestModeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isGuest = prefs.getBool('guest_mode') ?? false;
  ref.read(guestModeProvider.notifier).state = isGuest;
  return isGuest;
});
```
**Why this matters:** Guest mode state is independent from auth state. Fixing one doesn't affect the other.

---

## How to Safely Fix Issues

### Scenario 1: Calendar in AppShell shows wrong cycle phase
**Path affected:** PATH 1 and 3a  
**Files to edit:** `lib/presentation/pages/app_shell.dart`, `lib/providers/cycle_phase_provider.dart`  
**Files NOT to touch:** `lib/main.dart`, `lib/presentation/pages/onboarding_page.dart`  
**Result:** PATH 2 and 3b unaffected ✅

### Scenario 2: Onboarding screen 3 toggle switches don't save
**Path affected:** PATH 2  
**Files to edit:** `lib/presentation/pages/onboarding_page.dart` (\_LifestyleScreen)  
**Files NOT to touch:** `lib/main.dart`, `lib/presentation/pages/app_shell.dart`  
**Result:** PATH 1, 3a, 3b unaffected ✅

### Scenario 3: Authenticated users can't complete their profile
**Path affected:** PATH 3b  
**Files to edit:** `lib/main.dart` (\_AuthCycleDataScreen, \_AuthLifestyleScreen)  
**Files NOT to touch:** `lib/main.dart (_getInitialPage)`, `lib/presentation/pages/onboarding_page.dart`, `lib/presentation/pages/app_shell.dart`  
**Result:** PATH 1, 2, 3a unaffected ✅

### Scenario 4: Guest mode flag not persisting across app restarts
**Path affected:** PATH 1  
**Files to edit:** `lib/presentation/providers/guest_mode_provider.dart`, `lib/presentation/pages/onboarding_page.dart` (line 750)  
**Files NOT to touch:** `lib/main.dart (_getInitialPage)`, `lib/presentation/pages/app_shell.dart`  
**Result:** PATH 2, 3a, 3b unaffected ✅

---

## Testing Strategy

Each path should be tested independently:

1. **PATH 1:** Fresh install → Tap "Explore" → Complete onboarding → Restart app → Should show AppShell
2. **PATH 2:** Fresh install → Tap "Create Account" → Complete signup → Should show AppShell
3. **PATH 3a:** Login with existing account that has profile → Should show AppShell directly
4. **PATH 3b:** Login with new account (no profile) → Should show complete profile flow → Complete → Should show AppShell

---

## Design Benefits

✅ **No Cascading Failures:** Bug in one path doesn't break others  
✅ **Easy Debugging:** Know exactly which files to edit for each path  
✅ **Clean Transitions:** Profile completion triggers parent rebuild, not navigation push  
✅ **Persistent State:** Guest mode survives app restarts via SharedPreferences  
✅ **Independent Navigation:** Each path manages its own screens  
✅ **Single Responsibility:** Each class does one thing well
