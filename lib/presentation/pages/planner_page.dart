import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/my_cycle_screen.dart';
import '../screens/fitness_screen.dart';
import '../screens/diet_screen.dart';
import '../screens/fasting_screen.dart';
import '../screens/reports_screen.dart';
import '../components/main_bottom_nav.dart';
import '../components/dynamic_fab.dart';
import '../../core/theme/app_colors.dart';

/// Main Planner Page - Manages tab navigation with IndexedStack
/// 
/// Structure:
/// - MaterialApp → MainAppScaffold (Stateful)
/// - Scaffold with IndexedStack body
/// - Dynamic FAB based on current tab
/// - Bottom navigation with 5 tabs
/// 
/// No conditional rendering, no filter logic
class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  /// Current tab index (0-4)
  int _currentTabIndex = 0;

  /// Tab screen order:
  /// 0: My Cycle
  /// 1: Fitness
  /// 2: Diet
  /// 3: Fasting
  /// 4: Reports

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      
      // BODY: IndexedStack for tab persistence and clean switching
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            MyCycleScreen(),
            FitnessScreen(),
            DietScreen(),
            FastingScreen(),
            ReportsScreen(),
          ],
        ),
      ),

      // FAB: Dynamic FAB changes per tab
      floatingActionButton: _buildFABForTab(_currentTabIndex),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,

      // BOTTOM NAV: 5-tab navigation
      bottomNavigationBar: MainBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }

  /// Builds a different FAB for each tab
  /// 
  /// Colors per tab:
  /// - My Cycle: Lavender
  /// - Fitness: Blush
  /// - Diet: Sage
  /// - Fasting: Peach
  /// - Reports: None
  Widget _buildFABForTab(int index) {
    switch (index) {
      case 0: // My Cycle
        return DynamicFAB(
          color: AppColors.lavender,
          icon: Icons.add_rounded,
          onPressed: _openCycleEntryModal,
        );
      case 1: // Fitness
        return DynamicFAB(
          color: AppColors.blush,
          icon: Icons.fitness_center_rounded,
          onPressed: _openAddWorkoutModal,
        );
      case 2: // Diet
        return DynamicFAB(
          color: AppColors.sage,
          icon: Icons.restaurant_rounded,
          onPressed: _openAddRecipeModal,
        );
      case 3: // Fasting
        return DynamicFAB(
          color: AppColors.peach,
          icon: Icons.schedule_rounded,
          onPressed: _openLogFastingModal,
        );
      case 4: // Reports
        return SizedBox.shrink(); // No FAB on Reports
      default:
        return SizedBox.shrink();
    }
  }

  // FAB action handlers - implement these based on your needs
  void _openCycleEntryModal() {
    // TODO: Implement cycle entry modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cycle entry modal')),
    );
  }

  void _openAddWorkoutModal() {
    // TODO: Implement add workout modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add workout modal')),
    );
  }

  void _openAddRecipeModal() {
    // TODO: Implement add recipe modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add recipe modal')),
    );
  }

  void _openLogFastingModal() {
    // TODO: Implement log fasting modal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log fasting modal')),
    );
  }
}
