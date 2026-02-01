import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/main_bottom_nav.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/dynamic_fab.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/fitness_log_dialog.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/diet_log_dialog.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/fasting_log_dialog.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/screens/my_cycle_screen.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/screens/fitness_screen.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/screens/diet_screen.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/screens/fasting_screen.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/screens/reports_screen.dart';
import 'package:logger/logger.dart';

/// Global App Shell
/// Manages navigation, FAB, and screen state persistence
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final Logger _logger = Logger();
  final GlobalKey<State> _myCycleScreenKey = GlobalKey();
  final GlobalKey<State> _fitnessScreenKey = GlobalKey();
  final GlobalKey<State> _dietScreenKey = GlobalKey();
  final GlobalKey<State> _fastingScreenKey = GlobalKey();

  /// Currently selected tab index (0-4)
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _logger.i('🚀 AppShell initialized at tab: $_currentTabIndex');
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handle bottom nav tab change
  void _handleTabChange(int newIndex) {
    if (newIndex == _currentTabIndex) {
      _logger.d('📍 Already on tab $newIndex');
      return;
    }

    _logger.i('🔄 Switching from tab $_currentTabIndex to tab $newIndex');

    setState(() {
      _currentTabIndex = newIndex;
    });
  }

  /// Handle FAB press
  void _handleFabPress() {
    _logger.i('➕ FAB pressed on tab $_currentTabIndex');

    switch (_currentTabIndex) {
      case 0: // My Cycle
        _logger.d('Opening cycle entry dialog...');
        // Trigger the cycle input dialog directly using GlobalKey with cast
        (_myCycleScreenKey.currentState as dynamic)?.showAddCycleDialog();
        break;
      case 1: // Fitness
        _logger.d('Opening fitness log dialog...');
        final selectedDate = (_fitnessScreenKey.currentState as dynamic)?.getSelectedDay();
        showFitnessLogDialog(context, ref, selectedDate: selectedDate);
        break;
      case 2: // Diet
        _logger.d('Opening diet log dialog...');
        final dietSelectedDate = (_dietScreenKey.currentState as dynamic)?.getSelectedDay();
        showDietLogDialog(context, ref, selectedDate: dietSelectedDate);
        break;
      case 3: // Fasting
        _logger.d('Opening fasting log dialog...');
        final fastingSelectedDate = (_fastingScreenKey.currentState as dynamic)?.getSelectedDay();
        showFastingLogDialog(context, ref, selectedDate: fastingSelectedDate);
        break;
      case 4: // Reports
        _logger.d('No FAB action for Reports tab');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            MyCycleScreen(key: _myCycleScreenKey),
            FitnessScreen(key: _fitnessScreenKey),
            DietScreen(key: _dietScreenKey),
            FastingScreen(key: _fastingScreenKey),
            const ReportsScreen(),
          ],
        ),
      ),
      floatingActionButton: DynamicFAB(
        tabIndex: _currentTabIndex,
        onPressed: _handleFabPress,
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _currentTabIndex,
        itemCount: 5,
        onTap: _handleTabChange,
      ),
    );
  }
}
