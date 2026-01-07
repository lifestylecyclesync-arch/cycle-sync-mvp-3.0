import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/enums.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/dashboard_page.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/daily_card_page.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/planner_page.dart';
import 'package:cycle_sync_mvp_2/presentation/pages/profile_page.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/bottom_nav_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/user_profile_provider.dart';
import 'package:cycle_sync_mvp_2/presentation/widgets/cycle_input_modal.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(bottomNavTabProvider);

    final body = switch (currentTab) {
      BottomNavTab.dashboard => const DashboardPage(),
      BottomNavTab.planner => const PlannerPage(),
      BottomNavTab.insights => const DailyCardPage(),
      BottomNavTab.profile => const ProfilePage(),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(currentTab),
          child: body,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCycleInputModal(context, ref),
        shape: const CircleBorder(),
        child: const Icon(Icons.edit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab.index,
        onTap: (index) {
          // Haptic feedback
          HapticFeedback.lightImpact();
          
          ref
              .read(bottomNavTabProvider.notifier)
              .selectTab(BottomNavTab.values[index]);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(
            icon: Icons.dashboard,
            label: BottomNavTab.dashboard.toDisplayString(),
            isActive: currentTab == BottomNavTab.dashboard,
          ),
          _buildNavItem(
            icon: Icons.calendar_month,
            label: BottomNavTab.planner.toDisplayString(),
            isActive: currentTab == BottomNavTab.planner,
          ),
          _buildNavItem(
            icon: Icons.favorite,
            label: BottomNavTab.insights.toDisplayString(),
            isActive: currentTab == BottomNavTab.insights,
          ),
          _buildNavItem(
            icon: Icons.person,
            label: BottomNavTab.profile.toDisplayString(),
            isActive: currentTab == BottomNavTab.profile,
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: isActive ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon),
      ),
      activeIcon: AnimatedScale(
        scale: 1.2,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  void _showCycleInputModal(BuildContext context, WidgetRef ref) {
    // Get the current user profile data
    final userProfileAsync = ref.watch(userProfileProvider);
    
    userProfileAsync.whenData((profile) {
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete your profile first')),
        );
        return;
      }
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return CycleInputModal(
            cycleLength: profile.cycleLength,
            menstrualLength: profile.menstrualLength,
            lastPeriodDate: profile.lastPeriodDate,
            lutealPhaseLength: profile.lutealPhaseLength,
          );
        },
      );
    });
  }
}
