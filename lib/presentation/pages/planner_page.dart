import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';
import 'package:cycle_sync_mvp_2/core/constants/enums.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_phase_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/bottom_nav_provider.dart';

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
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (userProfile) {
        print('[DailyCard] Loaded user profile with lifestyle areas: ${userProfile.lifestyleAreas}');
        return ref.watch(cyclePhaseProvider(date)).when(
          data: (phaseInfo) {
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
                      if (userProfile.lifestyleAreas.contains('Nutrition'))
                        _buildModule(
                          context,
                          'Food Vibe',
                          phaseInfo.suggestion.foodVibe,
                        ),
                      
                      if (userProfile.lifestyleAreas.contains('Fitness'))
                        _buildModule(
                          context,
                          'Workout Mode',
                          phaseInfo.suggestion.workoutMode,
                        ),
                      
                      if (userProfile.lifestyleAreas.contains('Fasting'))
                        _buildFastingModule(
                          context,
                          ref,
                          phaseInfo.suggestion,
                          userProfile.fastingPreference,
                        ),
                      
                      if (userProfile.lifestyleAreas.isEmpty)
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
                        onPressed: () => _showAddLifestyleAreaModal(context, ref, userProfile),
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
          },
          loading: () => Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Center(
            child: Text('Error: $err'),
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
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
                  ref.read(bottomNavNotifierProvider.notifier).selectTab(BottomNavTab.profile);
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
    UserProfile userProfile,
  ) {
    final areas = ['Nutrition', 'Fitness', 'Fasting'];
    final selectedAreas = List<String>.from(userProfile.lifestyleAreas);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
      ),
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
