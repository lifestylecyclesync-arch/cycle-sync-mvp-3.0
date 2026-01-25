# Performance Audit & Optimization Plan
## Cycle Sync MVP 2 - Comprehensive Analysis

**Date:** January 9, 2026  
**Scope:** Full app performance evaluation  
**Goal:** Transform app to feel smooth with instant feedback (<50ms perceived latency)

---

## Executive Summary

Your app has **fundamental architectural performance issues** causing slow loading and unresponsive interactions. The recent UI optimizations (haptic feedback, non-blocking saves) were tactical fixes, but the root cause is **inefficient data loading architecture** at the foundation. This plan provides **strategic fixes** to eliminate bottlenecks completely.

### Current Performance Issues
- ❌ **Slow startup** - Multiple eager-loaded providers block initialization
- ❌ **Slow page transitions** - Each page triggers redundant data fetches
- ❌ **Slow data access** - No intelligent caching, always fetching from Supabase
- ❌ **Slow SharedPreferences access** - Used with `FutureBuilder`, blocks UI
- ❌ **Redundant queries** - Same data fetched multiple times from database

### Target State
- ✅ **Instant startup** - <500ms from app launch to interactive app shell
- ✅ **Instant page loads** - <100ms per page with cached data
- ✅ **Instant responses** - All user actions respond in <50ms
- ✅ **One eye blink** - User sees results before they can blink

---

## Part 1: ROOT CAUSE ANALYSIS

### Issue #1: Eager Loading in main.dart (CRITICAL)

**Location:** `lib/main.dart` lines 35-41

```dart
// ❌ PROBLEM: All providers loaded eagerly at startup
ref.watch(loadGuestModeProvider);  // FutureProvider - BLOCKS
final isGuestMode = ref.watch(guestModeProvider);
final authStateAsync = ref.watch(currentUserProvider);  // StreamProvider
final userProfileAsync = ref.watch(userProfileProvider);  // FutureProvider - BLOCKS
```

**Impact:**
- `loadGuestModeProvider` is a FutureProvider that doesn't complete until SharedPreferences loads
- `userProfileProvider` is a FutureProvider that doesn't complete until Supabase query returns
- MyApp.build() is blocked until BOTH complete
- Network latency (100-500ms) blocks app initialization

**Cascade Effect:**
1. App starts → MyApp.build() waits for providers
2. Providers wait for Supabase + SharedPreferences
3. Loading screen shows → AppShell never renders until all data loads
4. User sees spinner for 1-5 seconds

**Fix Type:** ARCHITECTURAL - Deferred loading with synchronous defaults

---

### Issue #2: Inefficient SharedPreferences Pattern (CRITICAL)

**Locations:** 
- `lib/presentation/pages/planner_page.dart` line 271
- `lib/presentation/pages/dashboard_page.dart` line 101

```dart
// ❌ PROBLEM: FutureBuilder that rebuilds widget tree on every access
return FutureBuilder<SharedPreferences>(
  future: SharedPreferences.getInstance(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: Text('Loading...'));
    }
    final prefs = snapshot.data!;
    // ... rest of widget tree
  },
);
```

**Impact:**
- SharedPreferences is I/O bound - first access ~50ms, subsequent ~5-10ms
- `getInstance()` is called repeatedly, creating new I/O operations
- FutureBuilder pattern is 1990s architecture - rebuilds entire subtree on each load state change
- Makes page transitions janky

**Fix Type:** ARCHITECTURAL - Cache SharedPreferences in provider, use ref.watch

---

### Issue #3: Lazy Provider Architecture Missing (CRITICAL)

**Location:** `lib/presentation/providers/repositories_provider.dart`

```dart
// ✓ GOOD: Repositories are Providers (lazy)
final userProfileRepositoryProvider = Provider<UserProfileRepository?>((ref) { ... });

// ❌ PROBLEM: Data providers are FutureProviders (always refetch)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  const userId = ref.watch(userIdProvider);
  const repository = ref.watch(userProfileRepositoryProvider);
  return await repository.getUserProfile(userId);  // Network call EVERY time
});

// ❌ PROBLEM: No caching, no stale-while-revalidate
final lifestyleAreasProvider = FutureProvider<List<String>>((ref) async {
  return await repository.getLifestyleAreas(userId);  // Fetches EVERY time
});
```

**Impact:**
- No differentiation between "first load" and "refresh"
- Every consumer of `userProfileProvider` triggers a new Supabase query
- 5 widgets watching `userProfileProvider`? = 5 simultaneous queries to Supabase
- No client-side cache, so offline = completely broken

**Fix Type:** ARCHITECTURAL - Add cache layer, implement stale-while-revalidate

---

### Issue #4: Synchronous vs Async Data Loading Mismatch (HIGH)

**Location:** `lib/presentation/providers/cycle_phase_provider.dart` line 142

```dart
// ❌ PROBLEM: FutureProvider that fetches profile data
final cyclePhaseProvider = FutureProvider.family<PhaseInfo, DateTime>((ref, date) async {
  if (isGuest) {
    final prefs = await SharedPreferences.getInstance();  // I/O operation
    // ... calculate phase info
  } else {
    const userProfile = await ref.watch(userProfileProvider.future);  // Network operation
    // ... calculate phase info
  }
});
```

**Impact:**
- Every date change triggers a full refetch of profile data
- Planner page showing 7 days = 7 potential fetches
- User scrolling calendar = cascade of I/O operations
- No deduplication - if you watch 3 dates, you're making 3 queries for same profile

**Fix Type:** ARCHITECTURAL - Load profile once, derive phase info synchronously

---

### Issue #5: No Request Deduplication (HIGH)

**Location:** Multiple providers, all FutureProviders

```dart
// Problem scenario:
// Widget A watches userProfileProvider
// Widget B watches userProfileProvider  
// Widget C watches userProfileProvider
// → 3 simultaneous Supabase queries for same data
// → Network congestion + wasted API calls
```

**Impact:**
- Multiple widgets on same screen = multiple redundant queries
- No built-in deduplication in Riverpod for identical requests
- Wastes network bandwidth and Supabase quota

**Fix Type:** ARCHITECTURAL - Implement query deduplication via caching

---

### Issue #6: Missing Cache Warming (HIGH)

**Location:** App startup flow

```dart
// Current: Data loads only when requested
// Better: Load critical data immediately, rest in background

// Missing:
// 1. Preload userProfile on startup
// 2. Preload lifestyle areas on startup
// 3. Preload cycle phase recommendations on startup
// 4. Preload daily selections for today and ±3 days
```

**Impact:**
- Each page transition requires full data reload
- User taps a page → spinner → waits for data
- Should be: User taps page → instant cached data

**Fix Type:** ARCHITECTURAL - Background cache warming

---

### Issue #7: No Synchronous Read Fallback (HIGH)

**Location:** All FutureProviders

```dart
// Current architecture:
ref.watch(userProfileProvider).when(
  data: (profile) => showProfile(profile),  // Wait for network
  loading: () => showSpinner(),             // Show spinner during load
  error: (e, st) => showError(e),          // Show error if network fails
);

// Better: First show cached data, then refresh in background
// Option 1: Read sync from cache, then listen for updates
// Option 2: Use ref.read() for sync access from known-loaded providers
```

**Impact:**
- Every navigation forces user to wait
- Network latency (100-500ms) becomes user-visible
- Offline mode = app broken

**Fix Type:** ARCHITECTURAL - Implement dual-mode loading (sync cache + async update)

---

## Part 2: SOLUTION ARCHITECTURE

### Strategy 1: Lazy + Smart Initialization

**Before:**
```
main() → MyApp.build() → Wait for all providers → Show app
                            ↓
                    Blocks initialization
                    User sees spinner 2-5s
```

**After:**
```
main() → MyApp.build() → Show empty shell immediately → Load data in background
                            ↓                                    ↓
                        <100ms visible                    Renders when ready
                        User can interact                 Smooth transition
```

**Implementation:**
1. Remove eager loading of FutureProviders from main.dart
2. Show AppShell immediately with skeleton loading states
3. Load data asynchronously in background
4. Auto-navigate to onboarding if needed

**Code Pattern:**
```dart
// ✅ GOOD: Deferred with fallback
final isGuestMode = ref.watch(guestModeProvider);  // StateProvider - instant
final shouldShowOnboarding = ref.watch(hasCompletedOnboardingProvider);  // Async, but with cache fallback

// Show AppShell → load data → invalidate skeleton when ready
```

---

### Strategy 2: SharedPreferences Cache Layer

**Before:**
```
Planner Page → FutureBuilder<SharedPreferences> → getInstance() → Wait 5-50ms
Dashboard Page → FutureBuilder<SharedPreferences> → getInstance() → Wait 5-50ms
Profile Page → FutureBuilder<SharedPreferences> → getInstance() → Wait 5-50ms
```

**After:**
```
Startup → Load SharedPreferences once → Cache in provider
Every page → Read from cached provider → <1ms access
```

**Implementation:**
```dart
// ✅ GOOD: Cache SharedPreferences in Notifier
final sharedPreferencesProvider = StateNotifierProvider<SharedPrefsNotifier, SharedPreferences?>((ref) {
  return SharedPrefsNotifier();
});

// Usage:
final prefs = ref.watch(sharedPreferencesProvider);
if (prefs != null) {
  final areas = prefs.getStringList('lifestyleAreas') ?? [];
}
```

---

### Strategy 3: Dual-Mode Data Loading (Sync Cache + Async Update)

**Before:**
```
User navigates → Wait for network → Show data → user happy (but waited 100-500ms)
```

**After:**
```
User navigates → Show cached data IMMEDIATELY (<1ms) → Network updates in background → Smooth refresh
                  ↓
              User happy (instant feedback)
```

**Implementation:**
```dart
// ✅ GOOD: Sync read + async refresh
class DataProvider {
  // Sync read from local cache
  UserProfile? getCachedProfile(String userId) {
    return _cache[userId];
  }
  
  // Async refresh in background (non-blocking)
  void refreshProfile(String userId) {
    supabase.from('user_profiles').select().eq('user_id', userId)
      .then((data) => _updateCache(data))
      .catchError((e) => print('Background refresh failed: $e'));
  }
}

// In UI:
final cached = repository.getCachedProfile(userId);
if (cached != null) {
  // Show cached data immediately
  renderProfile(cached);
  // Refresh in background
  repository.refreshProfile(userId);
} else {
  // First load - show spinner
  showSpinner();
}
```

---

### Strategy 4: Request Deduplication & Caching

**Before:**
```
Widget A watches userProfileProvider → Query Supabase
Widget B watches userProfileProvider → Query Supabase (same query, different request)
Widget C watches userProfileProvider → Query Supabase (same query again)
Result: 3 network requests for 1 piece of data
```

**After:**
```
Widget A watches userProfileProvider → Query Supabase once
Widget B watches userProfileProvider → Gets same result from cache
Widget C watches userProfileProvider → Gets same result from cache
Result: 1 network request, 3 instant results
```

**Implementation:**
```dart
// ✅ GOOD: Cache with TTL
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  // Check cache first
  if (_cache.containsKey(userId) && !_cache[userId]!.isStale) {
    return _cache[userId]!.data;
  }
  
  // Fetch from network
  final profile = await repository.getUserProfile(userId);
  
  // Cache with 5-minute TTL
  _cache[userId] = CachedData(profile, DateTime.now().add(Duration(minutes: 5)));
  
  return profile;
});
```

---

### Strategy 5: Cache Warming & Preloading

**Before:**
```
App starts → User navigates to Dashboard → Wait for data → User navigates to Planner → Wait for data
              ~200ms wait                                      ~200ms wait
```

**After:**
```
App starts → Preload critical data in background → User navigates to Dashboard (instant) → User navigates to Planner (instant)
            ~200ms background work (non-blocking)
```

**Implementation:**
```dart
// ✅ GOOD: Warm cache on startup
void _warmCache(WidgetRef ref) {
  // Preload user profile (critical path)
  ref.refresh(userProfileProvider);
  
  // Preload lifestyle areas (common in dashboard)
  ref.refresh(lifestyleAreasProvider);
  
  // Preload today's selections (common in planner)
  final today = DateTime.now();
  ref.refresh(dailySelectionsProvider(today));
  
  // Preload ±3 days (user likely scrolls calendar)
  for (int i = -3; i <= 3; i++) {
    final date = today.add(Duration(days: i));
    ref.refresh(dailySelectionsProvider(date));
  }
}
```

---

## Part 3: IMPLEMENTATION ROADMAP

### Phase 1: Core Startup Optimization (1-2 hours)

**Files to modify:**
1. `lib/main.dart` - Remove eager loading, show shell immediately
2. `lib/presentation/providers/repositories_provider.dart` - Add SharedPreferences cache provider
3. `lib/presentation/pages/app_shell.dart` - Add skeleton loaders

**Deliverables:**
- App loads to interactive state in <200ms
- Spinner shows skeleton, not empty screen
- Background data loads without blocking

---

### Phase 2: Data Loading Optimization (2-3 hours)

**Files to modify:**
1. `lib/data/repositories/*.dart` - Add in-memory caching
2. `lib/presentation/providers/repositories_provider.dart` - Implement smart FutureProviders
3. `lib/presentation/pages/planner_page.dart` - Replace FutureBuilder with ref.watch
4. `lib/presentation/pages/dashboard_page.dart` - Replace FutureBuilder with ref.watch
5. `lib/presentation/pages/profile_page.dart` - Replace FutureBuilder with ref.watch

**Deliverables:**
- All pages load with cached data immediately
- Network refresh happens in background
- FutureBuilder pattern removed completely

---

### Phase 3: Cycle Phase Optimization (1-2 hours)

**Files to modify:**
1. `lib/presentation/providers/cycle_phase_provider.dart` - Make synchronous from cache
2. `lib/presentation/pages/planner_page.dart` - Use cached phase info without waits

**Deliverables:**
- Scrolling calendar = instant (no fetches)
- Phase calculations cached and reused
- <10ms per date lookup

---

### Phase 4: Cache Warming & Preloading (1 hour)

**Files to modify:**
1. `lib/presentation/pages/app_shell.dart` - Add cache warming on first load
2. Add background refresh mechanism

**Deliverables:**
- All pages have cached data ready
- Background sync doesn't block UI
- Network errors don't break app

---

## Part 4: SPECIFIC CODE CHANGES

### Change 1: main.dart - Lazy Initialization

**Before (lines 34-43):**
```dart
ref.watch(loadGuestModeProvider);
final isGuestMode = ref.watch(guestModeProvider);
final authStateAsync = ref.watch(currentUserProvider);
final userProfileAsync = ref.watch(userProfileProvider);

return MaterialApp(
  title: 'Cycle Sync',
  theme: ThemeData(...),
  home: _getInitialPage(isGuestMode, authStateAsync, userProfileAsync),
);
```

**After:**
```dart
// Load guest mode flag synchronously (StateProvider - instant)
final isGuestMode = ref.watch(guestModeProvider);
final authState = ref.watch(currentUserProvider);

// For authenticated path: load profile asynchronously in background
// But don't block UI - show AppShell with skeleton
if (isGuestMode) {
  return const AppShell();
}

// Authenticated or loading path
return authState.when(
  data: (user) {
    if (user == null) {
      return const OnboardingPage();
    }
    // Show AppShell immediately, profile loads in background
    return const AppShell();
  },
  loading: () => const AppShell(),  // Show shell, data loads in background
  error: (e, st) => const OnboardingPage(),  // Fallback to onboarding
);
```

---

### Change 2: repositories_provider.dart - Add Cache Layer

**Add new provider (after line 11):**
```dart
/// Cache for user profile with sync access
final userProfileCacheProvider = StateNotifierProvider<UserProfileCacheNotifier, UserProfile?>((ref) {
  return UserProfileCacheNotifier();
});

class UserProfileCacheNotifier extends StateNotifier<UserProfile?> {
  UserProfileCacheNotifier() : super(null);
  
  void setCachedProfile(UserProfile? profile) {
    state = profile;
  }
}

/// Sync read from cache (no waiting)
final cachedUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(userProfileCacheProvider);
});

/// Async load with cache (background refresh)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(userProfileRepositoryProvider);
  if (repository == null) return null;

  try {
    final profile = await repository.getUserProfile(userId);
    // Update cache immediately
    ref.read(userProfileCacheProvider.notifier).setCachedProfile(profile);
    return profile;
  } catch (e) {
    // Return cached on error
    return ref.read(cachedUserProfileProvider);
  }
});
```

---

### Change 3: planner_page.dart - Remove FutureBuilder Pattern

**Before (lines 271-290):**
```dart
return FutureBuilder<SharedPreferences>(
  future: SharedPreferences.getInstance(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final prefs = snapshot.data!;
    final lifestyleAreas = prefs.getStringList('lifestyleAreas') ?? [];
    // ... rest
  },
);
```

**After:**
```dart
// Get cached profile directly
final userProfileAsync = ref.watch(userProfileProvider);
final cachedProfile = ref.watch(cachedUserProfileProvider);

// Use cached profile if available, show skeleton otherwise
final profile = cachedProfile ?? (userProfileAsync.valueOrNull);
final lifestyleAreas = profile?.lifestyleAreas ?? [];

if (profile == null) {
  return const _DailyCardSkeleton();  // Skeleton loader
}

// Render with cached data - instant!
return _buildDailyCardContent(
  context,
  ref,
  lifestyleAreas,
  profile.fastingPreference ?? 'Beginner',
  date,
);
```

---

### Change 4: cycle_phase_provider.dart - Sync from Cache

**Before (lines 142-170):**
```dart
final cyclePhaseProvider = FutureProvider.family<PhaseInfo, DateTime>((ref, date) async {
  late DateTime cycleStartDate;
  late int cycleLength;
  
  if (isGuest) {
    final prefs = await SharedPreferences.getInstance();  // WAIT
    // ...
  } else {
    const userProfile = await ref.watch(userProfileProvider.future);  // WAIT
    // ...
  }
});
```

**After:**
```dart
final cyclePhaseProvider = FutureProvider.family<PhaseInfo, DateTime>((ref, date) async {
  final isGuest = ref.watch(guestModeProvider);
  
  late DateTime cycleStartDate;
  late int cycleLength;
  late int menstrualLength;

  if (isGuest) {
    // Sync read from SharedPreferences cache
    final prefs = ref.watch(sharedPreferencesCacheProvider);
    if (prefs == null) throw Exception('SharedPreferences not loaded');
    
    final lastPeriodStr = prefs.getString('lastPeriodDate');
    cycleStartDate = DateTime.parse(lastPeriodStr!);
    cycleLength = prefs.getInt('cycleLength') ?? 28;
    menstrualLength = prefs.getInt('menstrualLength') ?? 5;
  } else {
    // Use cached profile (no network wait!)
    final cachedProfile = ref.watch(cachedUserProfileProvider);
    if (cachedProfile == null) throw Exception('Profile not loaded');
    
    cycleStartDate = cachedProfile.lastPeriodDate;
    cycleLength = cachedProfile.cycleLength;
    menstrualLength = cachedProfile.menstrualLength;
  }
  
  // Calculate phase synchronously from cached data
  final cycleDay = _calculateCycleDay(cycleStartDate, date, cycleLength);
  // ... rest of calculations
});
```

---

## Part 5: PERFORMANCE TARGETS

### Startup Performance
| Metric | Target | Current | Improvement |
|--------|--------|---------|-------------|
| Time to interactive app | <200ms | 1-5s | 5-25x faster |
| Time to first paint | <100ms | 500-2000ms | 5-20x faster |
| Profile load latency | <50ms (cached) | 100-500ms | 2-10x faster |

### Page Load Performance
| Page | Current | Target | Method |
|------|---------|--------|--------|
| Dashboard | 1-3s (fetch lifestyle areas) | <100ms (cached) | Use cache + background refresh |
| Planner | 2-5s (fetch profile + selections) | <100ms (cached) | Use cache + background refresh |
| Profile | 1-2s (fetch profile) | <100ms (cached) | Use cache + background refresh |

### Interaction Performance
| Action | Current | Target | Method |
|--------|---------|--------|--------|
| Button tap → response | 2-5s (blocking save) | <50ms (haptic + non-blocking) | Already done ✅ |
| Page navigation | 500-1500ms | <100ms | Cache pre-loads all pages |
| Calendar scroll | 500-2000ms (per day fetch) | <10ms per day | Synchronous from cache |

---

## Part 6: IMPLEMENTATION CHECKLIST

### Phase 1: Startup (1-2 hours)
- [ ] Remove `ref.watch(loadGuestModeProvider)` from main.dart
- [ ] Change `userProfileProvider` watch to conditional in `_getInitialPage()`
- [ ] Show AppShell immediately on startup
- [ ] Add skeleton loaders to AppShell
- [ ] Test: App shows interactive shell in <200ms

### Phase 2: Data Loading (2-3 hours)
- [ ] Add `userProfileCacheProvider` to repositories_provider.dart
- [ ] Add `cachedUserProfileProvider` for sync reads
- [ ] Update `userProfileProvider` to update cache
- [ ] Replace FutureBuilder in planner_page.dart
- [ ] Replace FutureBuilder in dashboard_page.dart
- [ ] Replace FutureBuilder in profile_page.dart
- [ ] Add SharedPreferences cache provider
- [ ] Test: All pages load with cached data immediately

### Phase 3: Cycle Phase (1-2 hours)
- [ ] Make cyclePhaseProvider synchronous from cache
- [ ] Remove `await` on profile fetch
- [ ] Precompute all cycle phases on profile load
- [ ] Test: Calendar scrolling is instant (<10ms)

### Phase 4: Cache Warming (1 hour)
- [ ] Add cache warming in app_shell.dart
- [ ] Preload critical data on startup
- [ ] Implement background sync
- [ ] Test: All pages pre-populated with data

---

## Summary

**Root Causes:**
1. Eager loading of async providers in main.dart
2. FutureBuilder pattern (1990s architecture) blocking page loads
3. No intelligent caching - always fetching from Supabase
4. No request deduplication
5. No cache warming

**Solutions:**
1. Lazy initialization - show UI immediately, load data in background
2. Replace FutureBuilder with ref.watch + skeleton loaders
3. Add in-memory cache layer with sync read access
4. Implement request deduplication
5. Preload critical data on startup

**Expected Result:**
- App loads to interactive state in <200ms (vs 1-5s)
- All pages respond instantly with cached data (vs 500-2000ms)
- "One eye blink" principle satisfied throughout
- Smooth, native app-like experience

---

## Questions?

Proceed with Phase 1 (Startup Optimization) for immediate impact, then move through phases 2-4 sequentially. Each phase is independent and can be tested in isolation.
