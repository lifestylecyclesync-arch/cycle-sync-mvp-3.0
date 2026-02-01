import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';

/// Main Bottom Navigation Bar
/// 6-tab navigation with cycle phase aware styling
class MainBottomNav extends StatelessWidget {
  /// Current selected tab index
  final int currentIndex;

  /// Number of items in navigation bar
  final int itemCount;

  /// Callback when tab is tapped
  final Function(int) onTap;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.backgroundPrimary,
      elevation: 2,
      selectedItemColor: _getTabColor(currentIndex),
      unselectedItemColor: AppColors.textTertiary.withOpacity(0.6),
      selectedLabelStyle: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: AppTypography.caption,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 0 ? Icons.calendar_month : Icons.calendar_today,
          ),
          label: 'My Cycle',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 1 ? Icons.fitness_center : Icons.directions_run,
          ),
          label: 'Fitness',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 2 ? Icons.restaurant : Icons.restaurant_menu,
          ),
          label: 'Diet',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 3 ? Icons.access_time : Icons.hourglass_empty,
          ),
          label: 'Fasting',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 4 ? Icons.analytics : Icons.bar_chart,
          ),
          label: 'Reports',
        ),
      ],
    );
  }

  /// Get the accent color for the given tab index
  Color _getTabColor(int index) {
    return AppColors.getTabColor(index);
  }
}
