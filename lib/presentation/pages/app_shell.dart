import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
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
import 'package:cycle_sync_mvp_2/presentation/providers/cycle_provider.dart' as cycle_providers;
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
        showFitnessLogDialog(context, ref);
        break;
      case 2: // Diet
        _logger.d('Opening diet log dialog...');
        showDietLogDialog(context, ref);
        break;
      case 3: // Fasting
        _logger.d('Opening fasting log dialog...');
        showFastingLogDialog(context, ref);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch cycle phase from Riverpod
    final phaseAsync = ref.watch(cycle_providers.currentPhaseProvider);
    final cycleDayAsync = ref.watch(cycle_providers.currentCycleDayProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: _buildAppBar(phaseAsync, cycleDayAsync),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            MyCycleScreen(key: _myCycleScreenKey),
            const FitnessScreen(),
            const DietScreen(),
            const FastingScreen(),
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
        onTap: _handleTabChange,
      ),
    );
  }

  /// Build app bar with cycle phase info
  PreferredSizeWidget? _buildAppBar(
    AsyncValue<String> phaseAsync,
    AsyncValue<int> cycleDayAsync,
  ) {
    return phaseAsync.when(
      data: (phase) {
        return cycleDayAsync.when(
          data: (day) {
            return AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day $day',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    phase.replaceFirst(phase[0], phase[0].toUpperCase()),
                    style: AppTypography.subtitle2.copyWith(
                      color: AppColors.getPhaseColor(phase),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.lg),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getPhaseColor(phase)
                        .withValues(alpha: AppColors.opacityLight),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Center(
                    child: Text(
                      phase[0].toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.getPhaseColor(phase),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Loading...',
              style: AppTypography.body2,
            ),
          ),
          error: (err, stack) => AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Error',
              style: AppTypography.body2,
            ),
          ),
        );
      },
      loading: () => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Loading...',
          style: AppTypography.body2,
        ),
      ),
      error: (err, stack) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Error',
          style: AppTypography.body2,
        ),
      ),
    );
  }
}
