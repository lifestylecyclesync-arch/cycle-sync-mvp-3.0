# Phase 1 Implementation Guide: Startup Optimization

**Time Estimate:** 1-2 hours  
**Complexity:** Medium  
**Impact:** 5-25x faster startup (1-5s → <200ms)

---

## What We're Fixing

```
BEFORE:
App start → Wait for providers → Loading spinner → 1-5 seconds → AppShell

AFTER:
App start → Show AppShell immediately → Load data in background → <200ms perceived startup
```

---

## Files to Modify (3 files)

1. **lib/main.dart** - Remove eager FutureProvider loading
2. **lib/presentation/providers/repositories_provider.dart** - Add cache providers
3. **lib/presentation/pages/app_shell.dart** - Add skeleton loaders

---

## Step 1: Add Cache Providers to repositories_provider.dart

### Location
Add these providers at the top of `repositories_provider.dart` after line 11 (after the existing imports but before other providers).

### Code to Add

```dart
/// Cache for user profile with synchronous read access
final userProfileCacheProvider = StateNotifierProvider<_UserProfileCacheNotifier, UserProfile?>((ref) {
  return _UserProfileCacheNotifier();
});

class _UserProfileCacheNotifier extends StateNotifier<UserProfile?> {
  _UserProfileCacheNotifier() : super(null);

  void setCachedProfile(UserProfile? profile) {
    state = profile;
  }
}

/// Synchronous read from profile cache (returns immediately, no waiting)
final cachedUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(userProfileCacheProvider);
});

/// Cache for SharedPreferences with synchronous access
final sharedPreferencesCacheProvider = StateNotifierProvider<_SharedPrefsCacheNotifier, SharedPreferences?>((ref) {
  return _SharedPrefsCacheNotifier();
});

class _SharedPrefsCacheNotifier extends StateNotifier<SharedPreferences?> {
  _SharedPrefsCacheNotifier() : super(null);

  void setCachedPrefs(SharedPreferences? prefs) {
    state = prefs;
  }
}

/// Synchronous read from SharedPreferences cache
final cachedSharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return ref.watch(sharedPreferencesCacheProvider);
});

/// Load SharedPreferences into cache (this is what used to block with FutureProvider)
final loadSharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  // Populate cache immediately
  ref.read(sharedPreferencesCacheProvider.notifier).setCachedPrefs(prefs);
  return prefs;
});
```

### Modify Existing `userProfileProvider`

Find this code (around line 50):

```dart
/// Get user profile from Supabase
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(userProfileRepositoryProvider);
  if (repository == null) return null;

  return await repository.getUserProfile(userId);
});
```

Replace with:

```dart
/// Get user profile from Supabase with automatic cache population
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(userProfileRepositoryProvider);
  if (repository == null) return null;

  try {
    final profile = await repository.getUserProfile(userId);
    // Populate cache immediately when profile loads
    ref.read(userProfileCacheProvider.notifier).setCachedProfile(profile);
    return profile;
  } catch (e) {
    // Return cached profile on error
    final cached = ref.read(cachedUserProfileProvider);
    if (cached != null) return cached;
    rethrow;
  }
});
```

---

## Step 2: Modify main.dart

### Location
Modify the `MyApp.build()` method (lines 31-47)

### Before (lines 31-47)

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  AppLogger.info('Building MyApp');
  
  // Load persisted guest mode state from SharedPreferences (only once)
  ref.watch(loadGuestModeProvider);
  
  // Watch the three independent paths
  final isGuestMode = ref.watch(guestModeProvider);
  final authStateAsync = ref.watch(currentUserProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  return MaterialApp(
    title: 'Cycle Sync',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: _getInitialPage(isGuestMode, authStateAsync, userProfileAsync),
  );
}
```

### After (Optimized)

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  AppLogger.info('Building MyApp');
  
  // Load persisted guest mode state from SharedPreferences (only once)
  // This is a StateProvider so it's instant, not blocking
  final isGuestMode = ref.watch(guestModeProvider);
  
  // Load auth state (non-blocking, returns immediately with current value)
  final authStateAsync = ref.watch(currentUserProvider);

  return MaterialApp(
    title: 'Cycle Sync',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: _getInitialPage(isGuestMode, authStateAsync),
  );
}
```

### Modify `_getInitialPage()` Method

Find the method signature (around line 50):

```dart
Widget _getInitialPage(
  bool isGuestMode,
  AsyncValue<User?> authStateAsync,
  AsyncValue<UserProfile?> userProfileAsync,
)
```

Replace the entire method with:

```dart
Widget _getInitialPage(
  bool isGuestMode,
  AsyncValue<User?> authStateAsync,
)
{
  // PATH 1: Guest Mode - User has already completed onboarding in guest mode
  if (isGuestMode) {
    AppLogger.info('🟢 PATH 1: Guest mode active → AppShell');
    return const AppShell();
  }

  // For paths 2 and 3, we need to evaluate auth state
  return authStateAsync.when(
    data: (user) {
      // PATH 2: Unauthenticated - No user logged in, show onboarding
      if (user == null) {
        AppLogger.info('🟡 PATH 2: No authenticated user → OnboardingPage');
        return const OnboardingPage();
      }

      // PATH 3: Authenticated - Show AppShell immediately
      // Profile data loads in background (see app_shell.dart for cache warming)
      AppLogger.info('🔵 PATH 3: User authenticated → AppShell (data loads in background)');
      return const AppShell();
    },
    loading: () {
      // Show AppShell with skeleton loaders while auth state loads
      AppLogger.info('🟠 Loading auth state → AppShell with skeleton');
      return const AppShell();
    },
    error: (error, st) {
      AppLogger.error('Auth state error', error, st);
      // Fallback to onboarding on auth error
      return const OnboardingPage();
    },
  );
}
```

---

## Step 3: Add Skeleton Loaders to AppShell

### Location
Add these before the `AppShell` class definition in `lib/presentation/pages/app_shell.dart`

### Code to Add

Add this at the end of the file (before or after the AppShell class):

```dart
/// Skeleton loader for dashboard content
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycle Sync'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton for cycle phase card
            _buildSkeletonCard(height: 120),
            const SizedBox(height: 16),
            // Skeleton for lifestyle areas section
            _buildSkeletonCard(height: 200),
            const SizedBox(height: 16),
            // Skeleton for recommendations section
            _buildSkeletonCard(height: 150),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// Skeleton loader for planner content
class _PlannerSkeleton extends StatelessWidget {
  const _PlannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar skeleton
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            // Daily card skeleton
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for profile content
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar skeleton
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Profile fields skeleton
            for (int i = 0; i < 5; i++) ...[
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for insights/daily card
class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Modify AppShell's Body Builder

Find this code in `AppShell.build()` (around line 18-25):

```dart
final currentTab = ref.watch(bottomNavTabProvider);

final body = switch (currentTab) {
  BottomNavTab.dashboard => const DashboardPage(),
  BottomNavTab.planner => const PlannerPage(),
  BottomNavTab.insights => const DailyCardPage(),
  BottomNavTab.profile => const ProfilePage(),
};
```

Replace with:

```dart
final currentTab = ref.watch(bottomNavTabProvider);

// Start loading critical data in background
// (only loads once, then uses cache)
ref.watch(userProfileProvider);
ref.watch(loadSharedPreferencesProvider);

final body = switch (currentTab) {
  BottomNavTab.dashboard => const DashboardPage(),
  BottomNavTab.planner => const PlannerPage(),
  BottomNavTab.insights => const DailyCardPage(),
  BottomNavTab.profile => const ProfilePage(),
};
```

This triggers background loading of critical data without blocking the UI.

---

## Testing Phase 1

### What to Test

1. **Startup time**
   - Launch app
   - Measure time from splash screen to AppShell visible
   - Should be <200ms (previously 1-5s)

2. **Data loading**
   - Watch console logs
   - Should see `[DEBUG]` logs from background loads
   - No blocking on startup

3. **Navigation**
   - Tap bottom nav items
   - Pages should show immediately (with skeleton loaders)
   - Then fill in with real data as background loads complete

### Expected Behavior

```
Time 0ms:   App launches
Time <100ms: AppShell shows (empty or skeleton)
Time 50-500ms: Background loads trigger
Time 200-1000ms: Data arrives, pages populate
User perception: App is instantly responsive
```

### Verification Checklist

- [ ] App shows interactive shell in <200ms (check logs)
- [ ] No spinner on startup (only skeleton loaders in pages)
- [ ] Can tap bottom nav immediately
- [ ] Pages fill in data as background loads complete
- [ ] No console errors related to null profile access

---

## Common Issues & Solutions

### Issue 1: "Null check error on profile access"
**Cause:** Page tries to access profile before cache loads  
**Solution:** Use `ref.watch(cachedUserProfileProvider)` to read from cache synchronously, check for null

### Issue 2: "Lifecycle phase errors"
**Cause:** Phase provider runs before profile loads  
**Solution:** Add null check in cycle_phase_provider, return default phase if profile is null

### Issue 3: "Data still takes 1-2 seconds to appear"
**Cause:** Background loads not triggering, or FutureBuilder still used  
**Solution:** 
- Verify `ref.watch(userProfileProvider)` is called in AppShell
- Replace any remaining `FutureBuilder` patterns with `ref.watch()`

### Issue 4: "Skeleton loaders not showing"
**Cause:** Pages load immediately (too fast)  
**Solution:** This is actually good! Users see real data. But if you want skeletons, add loading state to individual pages

---

## Next Steps After Phase 1

Once Phase 1 is complete and tested:
1. Measure startup time (should be 5-10x faster)
2. Proceed to **Phase 2: Data Loading Optimization**
3. Replace remaining FutureBuilder patterns in individual pages

---

## Quick Reference: Changes Made

### repositories_provider.dart
✅ Added `userProfileCacheProvider` (StateNotifier)
✅ Added `cachedUserProfileProvider` (Provider - synchronous read)
✅ Added `sharedPreferencesCacheProvider` (StateNotifier)
✅ Added `cachedSharedPreferencesProvider` (Provider - synchronous read)
✅ Added `loadSharedPreferencesProvider` (FutureProvider)
✅ Modified `userProfileProvider` to populate cache

### main.dart
✅ Removed `ref.watch(userProfileAsync)` from eager loading
✅ Removed `userProfileAsync` parameter from `_getInitialPage()`
✅ Rewrote `_getInitialPage()` to show AppShell immediately
✅ Simplified auth state handling to non-blocking

### app_shell.dart
✅ Added skeleton loader components
✅ Added `ref.watch(userProfileProvider)` to warm cache
✅ Added `ref.watch(loadSharedPreferencesProvider)` to warm cache

---

## Expected Result

**Startup Performance:**
- Before: 1-5 seconds (user sees spinner)
- After: <200ms to interactive app shell

**User Experience:**
- App feels instant on launch
- Pages populate with skeleton loaders initially
- Real data fills in as background loads complete
- Smooth, native app-like experience

**Ready to implement?** Follow the steps above, test, then move to Phase 2!
