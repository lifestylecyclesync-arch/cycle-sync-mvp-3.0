import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/onboarding_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/guest_mode_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/login_page.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/app_shell.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completedOnboarding() {
    // Mark onboarding as complete and go to home
    // Note: We'll handle this in _LifestyleScreen instead
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _goToSignup() {
    // Set signup mode and proceed to cycle data screen
    ref.read(signupModeProvider.notifier).setSignupMode(true);
    _goToNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _WelcomeScreen(onGetStarted: _goToNext, onSignup: _goToSignup),
                _CycleDataScreen(onNext: _goToNext),
                _LifestyleScreen(onNext: _completedOnboarding),
              ],
            ),
          ),
          // Navigation buttons removed - skip and continue buttons handle navigation
        ],
      ),
    );
  }
}

/// Screen 1: Welcome
class _WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignup;

  const _WelcomeScreen({required this.onGetStarted, required this.onSignup});

  @override
  State<_WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<_WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Column(
        children: [
          // Main content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header text
                Padding(
                  padding: EdgeInsets.only(
                    bottom: AppConstants.spacingXxl,
                    left: AppConstants.spacingLg,
                    right: AppConstants.spacingLg,
                  ),
                  child: Text(
                    'Sync your lifestyle,\nwith your cycle',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 120),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Icon(
                              Icons.favorite,
                              size: value,
                              color: Colors.deepPurple,
                            );
                          },
                        ),
                        SizedBox(height: AppConstants.spacingXxl),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
                          child: Text(
                            'Welcome to Cycle Sync',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: AppConstants.spacingXl),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
                          child: ElevatedButton(
                            onPressed: widget.onGetStarted,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppConstants.spacingMd,
                                horizontal: AppConstants.spacingXl,
                              ),
                              child: const Text('Explore'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom buttons
          SizedBox(height: AppConstants.spacingXl),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: Text(
                'I have an account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingMd),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
            child: OutlinedButton(
              onPressed: widget.onSignup,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppConstants.spacingMd,
                  horizontal: AppConstants.spacingXl,
                ),
                child: const Text('Create account'),
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacingLg),
        ],
      ),
    );
  }
}

/// Screen 2: Cycle Data
class _CycleDataScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const _CycleDataScreen({required this.onNext});

  @override
  ConsumerState<_CycleDataScreen> createState() => _CycleDataScreenState();
}

class _CycleDataScreenState extends ConsumerState<_CycleDataScreen> {
  late int _cycleLength;
  late int _menstrualLength;
  DateTime? _selectedDate;
  String? _menstrualWarning;
  final bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _cycleLength = 28;
    _menstrualLength = 5;
    _selectedDate = null;
  }

  void _validateMenstrualLength() {
    if (_menstrualLength > 10) {
      setState(() => _menstrualWarning = 'Most cycles range between 2–10 days. If your period is consistently longer, please consult a healthcare provider.');
    } else {
      setState(() => _menstrualWarning = null);
    }
  }

  bool _validate() {
    if (_cycleLength < 21 || _cycleLength > 35) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle length must be between 21-35 days')),
      );
      return false;
    }

    if (_menstrualLength < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menstrual length must be at least 2 days')),
      );
      return false;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return false;
    }

    if (_selectedDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date cannot be in the future')),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: AppConstants.spacingXxl),
            Text(
              'Your Cycle Information',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacingXxl),
            // Cycle Length
            Text(
              'Cycle Length (days)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _cycleLength > 21 ? () => setState(() => _cycleLength--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$_cycleLength',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _cycleLength < 35 ? () => setState(() => _cycleLength++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppConstants.spacingXxl),
            // Menstrual Length
            Text(
              'Menstrual Length (days)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _menstrualLength > 2 ? () {
                      setState(() => _menstrualLength--);
                      _validateMenstrualLength();
                    } : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$_menstrualLength',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _menstrualLength++);
                      _validateMenstrualLength();
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            if (_menstrualWarning != null) ...[
              SizedBox(height: AppConstants.spacingMd),
              Container(
                padding: EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        _menstrualWarning!,
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: AppConstants.spacingXl),
            Text(
              'When did your last period start?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now().subtract(Duration(days: 30)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Select a date',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _selectedDate != null ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppConstants.spacingXl),
            Center(
              child: ElevatedButton(
                onPressed: _isValidating ? null : () async {
                  if (_validate()) {
                    // Save cycle data to SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('cycleLength', _cycleLength);
                    await prefs.setInt('menstrualLength', _menstrualLength);
                    if (_selectedDate != null) {
                      await prefs.setString('lastPeriodDate', _selectedDate!.toIso8601String());
                    }
                    widget.onNext();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                    horizontal: AppConstants.spacingXl,
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            Center(
              child: GestureDetector(
                onTap: () async {
                  // Save cycle data even when skipping
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('cycleLength', _cycleLength);
                  await prefs.setInt('menstrualLength', _menstrualLength);
                  if (_selectedDate != null) {
                    await prefs.setString('lastPeriodDate', _selectedDate!.toIso8601String());
                  }
                  widget.onNext();
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
}

/// Screen 3: Lifestyle Areas
class _LifestyleScreen extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  const _LifestyleScreen({required this.onNext});

  @override
  ConsumerState<_LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends ConsumerState<_LifestyleScreen> with SingleTickerProviderStateMixin {
  final List<String> selectedAreas = [];
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(lifestyleCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) => _buildCategoriesUI(context, categories),
      loading: () => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppConstants.spacingXxl),
              const CircularProgressIndicator(),
              SizedBox(height: AppConstants.spacingMd),
              Text('Loading lifestyle options...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppConstants.spacingXxl),
              Text('Error loading categories. Using defaults...'),
              SizedBox(height: AppConstants.spacingMd),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(lifestyleCategoriesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesUI(BuildContext context, List<String> allAreas) {
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
              children: List.generate(allAreas.length, (index) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval(index * 0.1, (index + 1) * 0.1 + 0.6, curve: Curves.elasticOut),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          allAreas[index],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Switch(
                          value: selectedAreas.contains(allAreas[index]),
                          onChanged: (value) {
                            setState(() {
                              if (value) {
                                selectedAreas.add(allAreas[index]);
                              } else {
                                selectedAreas.remove(allAreas[index]);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: AppConstants.spacingXxl),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final isSignupMode = ref.read(signupModeProvider);
                    
                    // If in signup mode, show email/password dialog first
                    if (isSignupMode) {
                      if (!context.mounted) return;
                      
                      final emailController = TextEditingController();
                      final passwordController = TextEditingController();
                      
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Create Account'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'your@email.com',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: passwordController,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'At least 6 characters',
                                  ),
                                  obscureText: true,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill in all fields')),
                                  );
                                  return;
                                }
                                Navigator.pop(context, {
                                  'email': emailController.text.trim(),
                                  'password': passwordController.text,
                                });
                              },
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      );
                      
                      if (result == null) return; // User cancelled
                      
                      // Perform signup
                      await ref.read(signUpProvider(
                        (email: result['email']!, password: result['password']!),
                      ).future);
                      
                      // Wait a moment for auth state to update
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Get userId from auth
                      final userId = ref.watch(userIdProvider);
                      if (userId == null) {
                        throw Exception('User not authenticated');
                      }

                      // Get cycle data from SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final cycleLength = prefs.getInt('cycleLength') ?? 28;
                      final menstrualLength = prefs.getInt('menstrualLength') ?? 5;
                      final lutealPhaseLength = prefs.getInt('lutealPhaseLength') ?? 14;
                      final lastPeriodDateStr = prefs.getString('lastPeriodDate');
                      
                      if (lastPeriodDateStr == null) {
                        throw Exception('Cycle data not found');
                      }

                      final lastPeriodDate = DateTime.parse(lastPeriodDateStr);
                      final userName = prefs.getString('userName') ?? 'User';

                      // Save profile to Supabase
                      await ref.read(saveUserProfileProvider((
                        name: userName,
                        cycleLength: cycleLength,
                        menstrualLength: menstrualLength,
                        lutealPhaseLength: lutealPhaseLength,
                        lastPeriodDate: lastPeriodDate,
                        avatarBase64: null,
                        fastingPreference: 'Beginner',
                      )).future);

                      // Save lifestyle areas to Supabase
                      await ref.read(updateLifestyleAreasProvider(selectedAreas).future);

                      // Mark onboarding as complete
                      await ref.read(completeOnboardingProvider.future);
                      ref.invalidate(hasCompletedOnboardingProvider);
                      ref.invalidate(userProfileProvider);  // Refetch profile with lifestyle areas
                      
                      // Reset signup mode for next time
                      ref.read(signupModeProvider.notifier).setSignupMode(false);
                    } else {
                      // Guest mode - save lifestyle areas and set the flag
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('lifestyleAreas', selectedAreas);
                      await prefs.setBool('guest_mode', true); // Persist guest mode flag
                      await ref.read(guestModeProvider.notifier).enableGuestMode();
                    }
                    
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AppShell()),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppConstants.spacingMd,
                    horizontal: AppConstants.spacingXl,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            Center(
              child: GestureDetector(
                onTap: () async {
                  try {
                    // Get userId from auth
                    final userId = ref.watch(userIdProvider);
                    if (userId == null) {
                      throw Exception('User not authenticated');
                    }

                    // Get cycle data from SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    final cycleLength = prefs.getInt('cycleLength') ?? 28;
                    final menstrualLength = prefs.getInt('menstrualLength') ?? 5;
                    final lutealPhaseLength = prefs.getInt('lutealPhaseLength') ?? 14;
                    final lastPeriodDateStr = prefs.getString('lastPeriodDate');
                    
                    if (lastPeriodDateStr == null) {
                      throw Exception('Cycle data not found');
                    }

                    final lastPeriodDate = DateTime.parse(lastPeriodDateStr);
                    final userName = prefs.getString('userName') ?? 'User';

                    // Save profile to Supabase
                    await ref.read(saveUserProfileProvider((
                      name: userName,
                      cycleLength: cycleLength,
                      menstrualLength: menstrualLength,
                      lutealPhaseLength: lutealPhaseLength,
                      lastPeriodDate: lastPeriodDate,
                      avatarBase64: null,
                      fastingPreference: 'Beginner',
                    )).future);

                    // Save lifestyle areas to Supabase
                    await ref.read(updateLifestyleAreasProvider(selectedAreas).future);

                    // Mark onboarding as complete
                    await ref.read(completeOnboardingProvider.future);
                    ref.invalidate(hasCompletedOnboardingProvider);
                    ref.invalidate(userProfileProvider);  // Refetch profile with lifestyle areas
                    
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
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
}


