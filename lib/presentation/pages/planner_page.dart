import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/core/constants/enums.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_phase_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/repositories_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/bottom_nav_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/guest_mode_provider.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    final days = <DateTime>[];
    
    // Add empty days for days before month starts
    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(month.year, month.month, 1 - (firstWeekday - i)));
    }
    
    // Add all days in month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    
    // Add empty days for remaining weeks
    while (days.length % 7 != 0) {
      days.add(DateTime(month.year, month.month + 1, days.length - daysInMonth + 1));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Month header with navigation
            Padding(
              padding: EdgeInsets.all(AppConstants.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            
            // Day names header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
              child: Row(
                children: const [
                  DayHeader(label: 'Sun'),
                  DayHeader(label: 'Mon'),
                  DayHeader(label: 'Tue'),
                  DayHeader(label: 'Wed'),
                  DayHeader(label: 'Thu'),
                  DayHeader(label: 'Fri'),
                  DayHeader(label: 'Sat'),
                ],
              ),
            ),
            
            // Calendar grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth = day.month == _currentMonth.month;
                    
                    return GestureDetector(
                      onTap: isCurrentMonth ? () {
                        _showDailyCard(context, day);
                      } : null,
                      child: CalendarDayCell(
                        date: day,
                        isCurrentMonth: isCurrentMonth,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  void _showDailyCard(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DailyCardSheet(date: date),
    );
  }
}

class DayHeader extends StatelessWidget {
  final String label;

  const DayHeader({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class CalendarDayCell extends ConsumerWidget {
  final DateTime date;
  final bool isCurrentMonth;

  const CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phase circle indicator
          if (isCurrentMonth)
            _buildPhaseCircle(ref),
          
          // Date number
          Center(
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCurrentMonth ? Colors.black : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCircle(WidgetRef ref) {
    return ref.watch(cyclePhaseProvider(date)).when(
      data: (phaseInfo) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hexToColor(phaseInfo.colorCode).withOpacity(0.35),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
    } else if (hexString.length == 8) {
      buffer.write(hexString.replaceFirst('#', ''));
    }
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class DailyCardSheet extends ConsumerWidget {
  final DateTime date;

  const DailyCardSheet({required this.date, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(guestModeProvider);
    
    // If guest mode, load from SharedPreferences
    if (isGuest) {
      return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Failed to load data'));
          }

          final prefs = snapshot.data!;
          final lifestyleAreas = prefs.getStringList('lifestyleAreas') ?? [];
          final fastingPref = prefs.getString('fasting_preference') ?? 'Beginner';

          return ref.watch(cyclePhaseProvider(date)).when(
            data: (phaseInfo) => _buildDailyCardContent(
              context,
              ref,
              phaseInfo,
              lifestyleAreas,
              fastingPref,
              date,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
      );
    }

    // Authenticated mode: fetch from Supabase
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (userProfile) {
        if (userProfile == null) {
          return Center(
            child: Text('Profile not found. Please complete onboarding.'),
          );
        }

        print('[DailyCard] Loaded user profile with lifestyle areas: ${userProfile.lifestyleAreas}');
        return ref.watch(cyclePhaseProvider(date)).when(
          data: (phaseInfo) => _buildDailyCardContent(
            context,
            ref,
            phaseInfo,
            userProfile.lifestyleAreas,
            userProfile.fastingPreference,
            date,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildDailyCardContent(
    BuildContext context,
    WidgetRef ref,
    dynamic phaseInfo,
    List<String> lifestyleAreas,
    String fastingPref,
    DateTime selectedDate,
  ) {
    // Fetch recommendations once at page level to avoid duplicate queries
    final phaseName = phaseInfo.displayName;
    final recommendationsAsync = ref.watch(phaseRecommendationsProvider(phaseName));
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppConstants.borderRadiusLarge),
              topRight: Radius.circular(AppConstants.borderRadiusLarge),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(AppConstants.spacingLg),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Text(
                'Day ${phaseInfo.dayOfCycle} • ${phaseInfo.lifestylePhase}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Text(
                '${phaseInfo.displayName} Phase (Days ${phaseInfo.startDay}–${phaseInfo.endDay})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: AppConstants.spacingXl),
              
              // Modules based on selected lifestyle areas
              if (lifestyleAreas.contains('Nutrition'))
                _buildNutritionModule(
                  context,
                  ref,
                  phaseInfo.suggestion.foodVibe,
                  phaseName,
                  selectedDate,
                  recommendationsAsync,
                ),
              
              if (lifestyleAreas.contains('Fitness'))
                _buildFitnessModule(
                  context,
                  ref,
                  phaseInfo.suggestion.workoutMode,
                  phaseName,
                  selectedDate,
                  recommendationsAsync,
                ),
              
              if (lifestyleAreas.contains('Fasting'))
                _buildFastingModule(
                  context,
                  ref,
                  phaseInfo.suggestion,
                  fastingPref,
                ),
              
              if (lifestyleAreas.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingXl),
                  child: Text(
                    'Add lifestyle areas to see personalized recommendations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              SizedBox(height: AppConstants.spacingXl),
              
              // Actions
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Lifestyle Area'),
                onPressed: () => _showAddLifestyleAreaModal(context, ref, lifestyleAreas),
              ),
              SizedBox(height: AppConstants.spacingMd),
              OutlinedButton.icon(
                icon: const Icon(Icons.note_add),
                label: const Text('Log Notes'),
                onPressed: () => _showLogNotesModal(context, date),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutritionModule(
    BuildContext context,
    WidgetRef ref,
    String foodVibe,
    String phaseName,
    DateTime selectedDate,
    AsyncValue<Map<String, dynamic>?> recommendationsAsync,
  ) {
    final userId = ref.watch(userIdProvider);

    return recommendationsAsync.when(
      data: (data) {
        if (data == null) {
          return _buildModule(context, 'Diet', foodVibe);
        }
        
        final recipes = (data['food_recipes'] as String?)?.split(' • ') ?? [];
        return Padding(
          padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showDietModal(context, foodVibe, recipes, userId, selectedDate, ref);
                  },
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: AppConstants.spacingSm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          foodVibe,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(width: AppConstants.spacingSm),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(
                height: AppConstants.spacingLg,
                color: Colors.grey.shade200,
              ),
              // Show selected recipe if it exists
              if (userId != null)
                ref.watch(dailySelectionsProvider(selectedDate)).when(
                  data: (selections) {
                    final selectedRecipesJson = selections?['selected_recipes'] as String?;
                    List<String> selectedRecipes = [];
                    
                    if (selectedRecipesJson != null && selectedRecipesJson.isNotEmpty) {
                      try {
                        selectedRecipes = List<String>.from(jsonDecode(selectedRecipesJson) as List);
                      } catch (e) {
                        print('[Error] Failed to parse recipes: $e');
                      }
                    }
                    
                    if (selectedRecipes.isEmpty) {
                      return SizedBox(height: AppConstants.spacingSm);
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppConstants.spacingMd),
                        ...selectedRecipes.map((recipe) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                              ),
                              SizedBox(width: AppConstants.spacingSm),
                              Expanded(
                                child: Text(
                                  recipe,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    );
                  },
                  loading: () => Padding(
                    padding: EdgeInsets.only(top: AppConstants.spacingMd),
                    child: const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, stack) => SizedBox(height: AppConstants.spacingSm),
                )
              else
                SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Food Vibe',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
      error: (err, stack) => _buildModule(context, 'Food Vibe', foodVibe),
    );
  }

  Widget _buildFitnessModule(
    BuildContext context,
    WidgetRef ref,
    String workoutMode,
    String phaseName,
    DateTime selectedDate,
    AsyncValue<Map<String, dynamic>?> recommendationsAsync,
  ) {
    print('[DEBUG] _buildFitnessModule called with workoutMode: $workoutMode, phaseName: $phaseName');
    final userId = ref.watch(userIdProvider);

    return recommendationsAsync.when(
      data: (data) {
        if (data == null) {
          // Show clickable workout mode even when recommendation data is null
          return Padding(
            padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Mode',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppConstants.spacingSm),
                InkWell(
                  onTap: () {
                    print('[DEBUG] Workout Mode tapped (from fallback) - workoutMode: $workoutMode');
                    // Fetch data and show modal
                    ref.read(phaseRecommendationsProvider(phaseName)).whenData((recData) {
                      if (recData != null) {
                        final workouts = (recData['workout_types'] as String?)?.split(' • ') ?? [];
                        _showWorkoutTypesModal(context, workoutMode, workouts, userId, selectedDate, ref);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No workout types available for this phase'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                  },
                  splashColor: Colors.blue.withOpacity(0.1),
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      workoutMode,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: AppConstants.spacingLg,
                  color: Colors.grey.shade200,
                ),
              ],
            ),
          );
        }
        
        final workouts = (data['workout_types'] as String?)?.split(' • ') ?? [];
        
        return Padding(
          padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Mode',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    print('[DEBUG] Workout Mode tapped - workouts count: ${workouts.length}, userId: $userId');
                    _showWorkoutTypesModal(context, workoutMode, workouts, userId, selectedDate, ref);
                  },
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: AppConstants.spacingSm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          workoutMode,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(width: AppConstants.spacingSm),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Show selected workout if it exists
              if (userId != null)
                ref.watch(dailySelectionsProvider(selectedDate)).when(
                  data: (selections) {
                    final selectedWorkoutsJson = selections?['selected_workouts'] as String?;
                    List<String> selectedWorkouts = [];
                    
                    if (selectedWorkoutsJson != null && selectedWorkoutsJson.isNotEmpty) {
                      try {
                        selectedWorkouts = List<String>.from(jsonDecode(selectedWorkoutsJson) as List);
                      } catch (e) {
                        print('[Error] Failed to parse workouts: $e');
                      }
                    }
                    
                    if (selectedWorkouts.isEmpty) {
                      return SizedBox(height: AppConstants.spacingSm);
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppConstants.spacingMd),
                        ...selectedWorkouts.map((workout) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$workout marked as planned'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                SizedBox(width: AppConstants.spacingSm),
                                Expanded(
                                  child: Text(
                                    workout,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    );
                  },
                  loading: () => Padding(
                    padding: EdgeInsets.only(top: AppConstants.spacingMd),
                    child: const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, stack) => SizedBox(height: AppConstants.spacingSm),
                )
              else
                SizedBox(height: AppConstants.spacingSm),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Mode',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppConstants.spacingMd),
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
      error: (err, stack) => _buildModule(context, 'Workout Mode', workoutMode),
    );
  }

  Widget _buildModule(
    BuildContext context,
    String title,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.spacingSm),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Divider(
            height: AppConstants.spacingLg,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildFastingModule(
    BuildContext context,
    WidgetRef ref,
    LifestyleSuggestion suggestion,
    String preference,
  ) {
    final fastStyle = preference == 'Beginner'
        ? suggestion.fastStyleBeginner
        : suggestion.fastStyleAdvanced;

    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fast Style',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fastStyle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(bottomNavTabProvider.notifier).selectTab(BottomNavTab.profile);
                  Navigator.pop(context);
                },
                child: Text(
                  'Change in Profile',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          Divider(
            height: AppConstants.spacingLg,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  void _showAddLifestyleAreaModal(
    BuildContext context,
    WidgetRef ref,
    List<String> currentAreas,
  ) {
    final categoriesAsync = ref.watch(lifestyleCategoriesProvider);
    final selectedAreas = List<String>.from(currentAreas);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => categoriesAsync.when(
          data: (areas) => AlertDialog(
            title: const Text('Add Lifestyle Area'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: areas.map((area) {
                final isSelected = selectedAreas.contains(area);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedAreas.add(area);
                      } else {
                        selectedAreas.remove(area);
                      }
                    });
                  },
                  title: Text(area),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList('lifestyleAreas', selectedAreas);
                  ref.invalidate(userProfileProvider);
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lifestyle areas updated')),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
          loading: () => AlertDialog(
            title: const Text('Loading...'),
            content: const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load categories: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDietModal(
    BuildContext context,
    String foodVibe,
    List<String> recipes,
    String? userId,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Recipe',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingSm),
              Text(
                foodVibe,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppConstants.spacingMd),
              if (recipes.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  child: Text(
                    'No recipes available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: recipes
                        .map((recipe) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                print('[DEBUG] Recipe tapped: $recipe, userId: $userId, date: $selectedDate');
                                if (userId != null) {
                                  final selectionsRepo = ref.read(dailySelectionsRepositoryProvider);
                                  try {
                                    print('[DEBUG] About to save recipe: $recipe');
                                    await selectionsRepo.selectRecipe(userId, selectedDate, recipe.trim());
                                    await Future.delayed(Duration(milliseconds: 100));
                                    print('[DEBUG] Recipe saved, invalidating provider...');
                                    if (context.mounted) {
                                      ref.invalidate(dailySelectionsProvider(selectedDate));
                                      print('[DEBUG] Provider invalidated, closing modal...');
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✓ ${recipe.trim()} selected'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('[ERROR] Failed to save recipe: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error saving selection: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMd,
                                  vertical: AppConstants.spacingSm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppConstants.spacingMd),
                                    Expanded(
                                      child: Text(
                                        recipe.trim(),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                ),
              SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        );
      },
    );
  }

  void _showWorkoutTypesModal(
    BuildContext context,
    String workoutMode,
    List<String> workouts,
    String? userId,
    DateTime selectedDate,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Workout',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppConstants.spacingMd),
              if (workouts.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
                  child: Text(
                    'No workout types available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: workouts
                        .map((workout) => Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacingSm),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                if (userId != null) {
                                  final selectionsRepo = ref.read(dailySelectionsRepositoryProvider);
                                  try {
                                    await selectionsRepo.selectWorkout(userId, selectedDate, workout.trim());
                                    await Future.delayed(Duration(milliseconds: 100));
                                    if (context.mounted) {
                                      ref.invalidate(dailySelectionsProvider(selectedDate));
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✓ ${workout.trim()} selected'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error saving selection: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingMd,
                                  vertical: AppConstants.spacingSm,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppConstants.spacingMd),
                                    Expanded(
                                      child: Text(
                                        workout.trim(),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                        .toList(),
                  ),
                ),
              SizedBox(height: AppConstants.spacingMd),
            ],
          ),
        );
      },
    );
  }

  void _showLogNotesModal(BuildContext context, DateTime date) {
    final dateKey = 'notes_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        final notesController = TextEditingController();
        
        // Load existing notes
        Future.microtask(() async {
          final prefs = await SharedPreferences.getInstance();
          final existingNotes = prefs.getString(dateKey) ?? '';
          if (notesController.text.isEmpty) {
            notesController.text = existingNotes;
          }
        });

        return AlertDialog(
          title: Text('Notes for ${date.day}/${date.month}/${date.year}'),
          content: TextField(
            controller: notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write your notes here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final note = notesController.text.trim();
                
                if (note.isEmpty) {
                  // Remove empty notes
                  await prefs.remove(dateKey);
                } else {
                  // Save note
                  await prefs.setString(dateKey, note);
                }
                
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  final message = note.isEmpty ? 'Notes cleared' : 'Notes saved';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
