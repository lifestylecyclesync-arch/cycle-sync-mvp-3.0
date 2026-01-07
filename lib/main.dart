import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/app_shell.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/onboarding_page.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/guest_mode_provider.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.info('Initializing Supabase...');
  try {
    await SupabaseConfig.initialize();
    AppLogger.info('Supabase initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Supabase', e, StackTrace.current);
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

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

  /// Get the initial page based on the current state
  /// This is evaluated ONCE at startup and determines which path to take
  Widget _getInitialPage(
    bool isGuestMode,
    AsyncValue<User?> authStateAsync,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
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
          AppLogger.info('🟡 PATH 2: No authenticated user → OnboardingPage (all screens)');
          return const OnboardingPage();
        }

        // PATH 3: Authenticated - User is logged in, check for profile
        AppLogger.info('🔵 PATH 3: User authenticated (${user.email})');
        return userProfileAsync.when(
          data: (profile) {
            // PATH 3a: Authenticated + Profile exists → AppShell
            if (profile != null) {
              AppLogger.info('🔵a: User has profile → AppShell');
              return const AppShell();
            }

            // PATH 3b: Authenticated + No profile → Complete profile
            AppLogger.info('🔵b: User missing profile → CompleteProfileFlow');
            return const _CompleteProfileFlow();
          },
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          ),
          error: (error, st) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading profile'),
                  const SizedBox(height: 16),
                  Text(error.toString()),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      ),
      error: (error, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error'),
              const SizedBox(height: 16),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Complete Profile Flow - shows screens 2 & 3 for authenticated users without profile
/// Completely isolated in its own navigation
class _CompleteProfileFlow extends ConsumerStatefulWidget {
  const _CompleteProfileFlow();

  @override
  ConsumerState<_CompleteProfileFlow> createState() => _CompleteProfileFlowState();
}

class _CompleteProfileFlowState extends ConsumerState<_CompleteProfileFlow> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completedProfile() {
    // Profile completed - navigate to AppShell
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _AuthCycleDataScreen(onNext: _goToNext),
                _AuthLifestyleScreen(onNext: _completedProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 1: Cycle Data for Authenticated Users
class _AuthCycleDataScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const _AuthCycleDataScreen({required this.onNext});

  @override
  ConsumerState<_AuthCycleDataScreen> createState() => _AuthCycleDataScreenState();
}

class _AuthCycleDataScreenState extends ConsumerState<_AuthCycleDataScreen> {
  late int _cycleLength;
  late int _menstrualLength;
  DateTime? _selectedDate;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _cycleLength = 28;
    _menstrualLength = 5;
  }

  bool _validate() {
    if (_cycleLength < 21 || _cycleLength > 35) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle length must be between 21 and 35 days')),
      );
      return false;
    }
    if (_menstrualLength < 2 || _menstrualLength > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menstrual length must be between 2 and 10 days')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppConstants.spacingXxl),
            Text(
              'Your Cycle Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: AppConstants.spacingMd),
            Text('Cycle Length: $_cycleLength days', style: Theme.of(context).textTheme.bodyMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _cycleLength > 21 ? () => setState(() => _cycleLength--) : null,
                  child: const Text('-'),
                ),
                SizedBox(width: AppConstants.spacingMd),
                SizedBox(width: 50, child: Center(child: Text('$_cycleLength'))),
                SizedBox(width: AppConstants.spacingMd),
                ElevatedButton(
                  onPressed: _cycleLength < 35 ? () => setState(() => _cycleLength++) : null,
                  child: const Text('+'),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingXl),
            Text('Menstrual Length: $_menstrualLength days', style: Theme.of(context).textTheme.bodyMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _menstrualLength > 2 ? () => setState(() => _menstrualLength--) : null,
                  child: const Text('-'),
                ),
                SizedBox(width: AppConstants.spacingMd),
                SizedBox(width: 50, child: Center(child: Text('$_menstrualLength'))),
                SizedBox(width: AppConstants.spacingMd),
                ElevatedButton(
                  onPressed: _menstrualLength < 10 ? () => setState(() => _menstrualLength++) : null,
                  child: const Text('+'),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacingXl),
            Text('Last Period Date (Optional)', style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: AppConstants.spacingMd),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Text(_selectedDate != null ? _selectedDate!.toString().split(' ')[0] : 'Select Date'),
            ),
            SizedBox(height: AppConstants.spacingXl),
            Center(
              child: ElevatedButton(
                onPressed: _isValidating
                    ? null
                    : () async {
                        if (_validate()) {
                          setState(() => _isValidating = true);
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('cycleLength', _cycleLength);
                            await prefs.setInt('menstrualLength', _menstrualLength);
                            if (_selectedDate != null) {
                              await prefs.setString('lastPeriodDate', _selectedDate!.toIso8601String());
                            }
                            widget.onNext();
                          } finally {
                            if (mounted) setState(() => _isValidating = false);
                          }
                        }
                      },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 2: Lifestyle for Authenticated Users
class _AuthLifestyleScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const _AuthLifestyleScreen({required this.onNext});

  @override
  ConsumerState<_AuthLifestyleScreen> createState() => _AuthLifestyleScreenState();
}

class _AuthLifestyleScreenState extends ConsumerState<_AuthLifestyleScreen> {
  final List<String> selectedAreas = [];
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppConstants.spacingXxl),
            Text(
              'Which lifestyle areas you want to sync with your cycle?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingXxl),
            Column(
              children: _buildLifestyleToggles(),
            ),
            SizedBox(height: AppConstants.spacingXl),
            Center(
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        try {
                          AppLogger.info('Continue button: Starting profile save');
                          final userId = ref.read(userIdProvider);
                          AppLogger.info('Current userId: $userId');
                          
                          if (userId == null) {
                            AppLogger.error('ERROR: userId is null!', Exception('userId null'), StackTrace.current);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error: Not logged in')),
                              );
                            }
                            return;
                          }

                          final prefs = await SharedPreferences.getInstance();
                          final cycleLength = prefs.getInt('cycleLength') ?? 28;
                          final menstrualLength = prefs.getInt('menstrualLength') ?? 5;
                          final lutealPhaseLength = prefs.getInt('lutealPhaseLength') ?? 14;
                          final lastPeriodStr = prefs.getString('lastPeriodDate');
                          final lastPeriodDate = lastPeriodStr != null 
                            ? DateTime.parse(lastPeriodStr) 
                            : DateTime.now();

                          AppLogger.info('Saving profile for userId: $userId with cycleLength=$cycleLength');
                          await ref.read(saveUserProfileProvider((
                            name: 'User',
                            cycleLength: cycleLength,
                            menstrualLength: menstrualLength,
                            lutealPhaseLength: lutealPhaseLength,
                            lastPeriodDate: lastPeriodDate,
                            avatarBase64: null,
                            fastingPreference: null,
                          )).future);
                          AppLogger.info('saveProfile completed successfully');

                          // Save lifestyle areas to Supabase
                          await ref.read(updateLifestyleAreasProvider(selectedAreas).future);
                          AppLogger.info('Lifestyle areas saved: $selectedAreas');

                          // Invalidate userProfileProvider so AppShell fetches the fresh data
                          AppLogger.info('Invalidating userProfileProvider');
                          ref.invalidate(userProfileProvider);
                          
                          // Wait a bit and refetch to verify
                          await Future.delayed(const Duration(milliseconds: 300));
                          AppLogger.info('Navigating to AppShell');

                          widget.onNext();
                        } catch (e) {
                          AppLogger.error('Error saving profile in Continue button', e, StackTrace.current);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            Center(
              child: GestureDetector(
                onTap: () async {
                  try {
                    AppLogger.info('Skip button: Starting profile save');
                    final userId = ref.read(userIdProvider);
                    AppLogger.info('Current userId: $userId');
                    
                    if (userId == null) {
                      AppLogger.error('ERROR: userId is null!', Exception('userId null'), StackTrace.current);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error: Not logged in')),
                        );
                      }
                      return;
                    }

                    final prefs = await SharedPreferences.getInstance();
                    final cycleLength = prefs.getInt('cycleLength') ?? 28;
                    final menstrualLength = prefs.getInt('menstrualLength') ?? 5;
                    final lutealPhaseLength = prefs.getInt('lutealPhaseLength') ?? 14;
                    final lastPeriodStr = prefs.getString('lastPeriodDate');
                    final lastPeriodDate = lastPeriodStr != null 
                      ? DateTime.parse(lastPeriodStr) 
                      : DateTime.now();

                    AppLogger.info('Saving profile for userId: $userId with cycleLength=$cycleLength');
                    await ref.read(saveUserProfileProvider((
                      name: 'User',
                      cycleLength: cycleLength,
                      menstrualLength: menstrualLength,
                      lutealPhaseLength: lutealPhaseLength,
                      lastPeriodDate: lastPeriodDate,
                      avatarBase64: null,
                      fastingPreference: null,
                    )).future);
                    AppLogger.info('saveProfile completed successfully');

                    // Save lifestyle areas to Supabase
                    await ref.read(updateLifestyleAreasProvider(selectedAreas).future);
                    AppLogger.info('Lifestyle areas saved: $selectedAreas');

                    // Invalidate userProfileProvider so AppShell fetches the fresh data
                    AppLogger.info('Invalidating userProfileProvider');
                    ref.invalidate(userProfileProvider);
                    
                    // Wait a bit and navigate
                    await Future.delayed(const Duration(milliseconds: 300));
                    AppLogger.info('Navigating to AppShell');

                    widget.onNext();
                  } catch (e) {
                    AppLogger.error('Error saving profile in Skip button', e, StackTrace.current);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLifestyleToggles() {
    final areas = ['Nutrition', 'Fitness', 'Fasting'];
    return areas.map((area) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              area,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Switch(
              value: selectedAreas.contains(area),
              onChanged: (value) {
                setState(() {
                  if (value) {
                    selectedAreas.add(area);
                  } else {
                    selectedAreas.remove(area);
                  }
                });
              },
            ),
          ],
        ),
      );
    }).toList();
  }
}
