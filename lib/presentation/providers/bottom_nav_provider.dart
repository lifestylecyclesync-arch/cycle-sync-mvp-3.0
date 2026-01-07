import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/enums.dart';

/// Current bottom navigation tab provider
/// Use .notifier.selectTab() to update
final bottomNavTabProvider = NotifierProvider<_BottomNavNotifier, BottomNavTab>(() {
  return _BottomNavNotifier();
});

class _BottomNavNotifier extends Notifier<BottomNavTab> {
  @override
  BottomNavTab build() {
    return BottomNavTab.dashboard;
  }

  void selectTab(BottomNavTab tab) {
    state = tab;
  }
}

/// Provider to track if user has navigated to profile screen
final isProfileCompletedProvider = NotifierProvider<_ProfileCompletedNotifier, bool>(() {
  return _ProfileCompletedNotifier();
});

class _ProfileCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void markCompleted() {
    state = true;
  }

  void reset() {
    state = false;
  }
}
