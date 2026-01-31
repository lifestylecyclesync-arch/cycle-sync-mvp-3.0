import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/constants/app_constants.dart';

/// Dynamic Floating Action Button
/// Changes color and action based on current tab
class DynamicFAB extends StatelessWidget {
  /// Current selected tab index
  final int tabIndex;

  /// Callback when FAB is pressed
  final VoidCallback onPressed;

  const DynamicFAB({
    Key? key,
    required this.tabIndex,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // No FAB for Reports tab (index 4)
    if (tabIndex == 4) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: _getFabColor(),
      elevation: 4,
      child: Icon(
        _getFabIcon(),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Get FAB color based on tab index
  /// My Cycle → Lavender
  /// Fitness → Blush
  /// Diet → Sage
  /// Fasting → Peach
  Color _getFabColor() {
    return AppColors.getTabColor(tabIndex);
  }

  /// Get FAB icon based on tab index
  IconData _getFabIcon() {
    switch (tabIndex) {
      case 0: // My Cycle
        return Icons.add_circle_outline;
      case 1: // Fitness
        return Icons.add;
      case 2: // Diet
        return Icons.add;
      case 3: // Fasting
        return Icons.add;
      default:
        return Icons.add;
    }
  }

  /// Get FAB tooltip based on tab index
  String _getFabTooltip() {
    switch (tabIndex) {
      case 0:
        return 'Add cycle entry';
      case 1:
        return 'Add workout';
      case 2:
        return 'Add recipe';
      case 3:
        return 'Log fasting';
      default:
        return '';
    }
  }
}
