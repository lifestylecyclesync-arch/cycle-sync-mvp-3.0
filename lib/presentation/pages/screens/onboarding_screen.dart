import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/onboarding_provider.dart';

final _logger = AppLogger('OnboardingScreen');

class OnboardingScreen extends ConsumerStatefulWidget {
  /// Starting step for onboarding (0=Welcome, 1=Cycle Data, 2=Lifestyle)
  /// Default is 0 (Welcome), but can be set to 1 to skip welcome
  final int startingStep;

  const OnboardingScreen({
    Key? key,
    this.startingStep = 0,
  }) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late int _currentStep; // 0: Welcome, 1: Cycle Data, 2: Lifestyle Selection
  
  // Cycle data
  late DateTime _lastPeriodDate;
  int _cycleLength = 28;
  int _menstrualLength = 5;
  bool _showMenstrualWarning = false;
  
  // Lifestyle selection
  final Set<String> _selectedLifestyleAreas = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.startingStep; // Use starting step from widget
    _lastPeriodDate = DateTime.now().subtract(const Duration(days: 14));
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _lastPeriodDate = picked);
    }
  }

  void _toggleLifestyleArea(String area) {
    setState(() {
      if (_selectedLifestyleAreas.contains(area)) {
        _selectedLifestyleAreas.remove(area);
      } else {
        _selectedLifestyleAreas.add(area);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    if (_cycleLength < 21 || _cycleLength > 35) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle length must be 21-35 days')),
      );
      return;
    }

    if (_menstrualLength < 2 || _menstrualLength > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menstrual length must be 2-10 days')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      _logger.i('🚀 Completing onboarding with:');
      _logger.i('  Last period: $_lastPeriodDate');
      _logger.i('  Cycle length: $_cycleLength');
      _logger.i('  Menstrual length: $_menstrualLength');
      _logger.i('  Lifestyle areas: $_selectedLifestyleAreas');

      await ref.read(completeOnboardingProvider((
        lastPeriodDate: _lastPeriodDate,
        cycleLength: _cycleLength,
        menstrualLength: _menstrualLength,
        lifestyleAreas: _selectedLifestyleAreas.toList(),
      )).future);

      _logger.i('✅ Onboarding completed successfully');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      _logger.e('❌ Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipToApp() async {
    // Skip onboarding but mark as completed with default values
    setState(() => _isLoading = true);

    try {
      _logger.i('⏭️ Skipping lifestyle selection...');
      await ref.read(completeOnboardingProvider((
        lastPeriodDate: _lastPeriodDate,
        cycleLength: _cycleLength,
        menstrualLength: _menstrualLength,
        lifestyleAreas: [], // Empty = will be prompted later
      )).future);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      _logger.e('❌ Error skipping onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: SafeArea(
        child: _currentStep == 0
            ? _buildWelcomeScreen()
            : _currentStep == 1
                ? _buildCycleDataScreen()
                : _buildLifestyleSelectionScreen(),
      ),
    );
  }

  // SCREEN 1: WELCOME
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: 40),
          // Header
          Column(
            children: [
              Text(
                'Cycle Sync',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.peach,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sync your lifestyle with your cycle.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 60),
          
          // Illustration area (placeholder)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.peach.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.favorite,
                size: 80,
                color: AppColors.peach,
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Get Started Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign in / Sign up options
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to sign in
                    Navigator.of(context).pushNamed('/signin');
                  },
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to sign up
                    Navigator.of(context).pushNamed('/signup');
                  },
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SCREEN 2: CYCLE DATA INPUT
  Widget _buildCycleDataScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Tell us about your cycle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // Last Period Date
          Text(
            'First date of your last period',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildDatePickerCard(),
          const SizedBox(height: 28),

          // Cycle Length
          Text(
            'Average cycle length',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildNumericInput(
            label: 'Cycle Length (days)',
            value: _cycleLength,
            min: 21,
            max: 35,
            onChanged: (value) => setState(() => _cycleLength = value),
          ),
          const SizedBox(height: 28),

          // Menstrual Length
          Text(
            'Average menstrual flow length',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildNumericInput(
            label: 'Menstrual Length (days)',
            value: _menstrualLength,
            min: 2,
            max: 10,
            onChanged: (value) {
              setState(() {
                _menstrualLength = value;
                _showMenstrualWarning = value > 10;
              });
            },
          ),
          
          // Warning if menstrual > 10
          if (_showMenstrualWarning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                'Most cycles range between 2–10 days. If your period is consistently longer, please consult a healthcare provider.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade900,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 48),

          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => setState(() => _currentStep = 2),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SCREEN 3: LIFESTYLE SELECTION
  Widget _buildLifestyleSelectionScreen() {
    const lifestyleOptions = ['Nutrition', 'Fitness', 'Fasting'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'What areas interest you?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least one to customize your dashboard',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),

          // Lifestyle chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: lifestyleOptions.map((area) {
              final isSelected = _selectedLifestyleAreas.contains(area);
              return FilterChip(
                label: Text(area),
                selected: isSelected,
                onSelected: (_) => _toggleLifestyleArea(area),
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.peach.withOpacity(0.3),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.peach : Colors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          // Complete Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _selectedLifestyleAreas.isEmpty
                  ? null
                  : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Complete Setup',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Skip Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isLoading ? null : _skipToApp,
              child: Text(
                'Skip for now',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: AppColors.peach),
        title: Text(DateFormat('MMMM dd, yyyy').format(_lastPeriodDate)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildNumericInput({
    required String label,
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.peach.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$value days',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.peach,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min),
              label: '$value',
              activeColor: AppColors.peach,
              onChanged: (val) => onChanged(val.toInt()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$min days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  '$max days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
