import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/constants/enums.dart';

/// Current bottom navigation tab
final bottomNavTabProvider = StateProvider<BottomNavTab>((ref) {
  return BottomNavTab.dashboard;
});

/// Provider to track if user has navigated to profile screen
final isProfileCompletedProvider = StateProvider<bool>((ref) {
  return false;
});

/// Update the current tab
class BottomNavNotifier extends StateNotifier<BottomNavTab> {
  BottomNavNotifier() : super(BottomNavTab.dashboard);

  void selectTab(BottomNavTab tab) {
    state = tab;
  }

  BottomNavTab get currentTab => state;
}

/// Bottom navigation state notifier provider
final bottomNavNotifierProvider =
    StateNotifierProvider<BottomNavNotifier, BottomNavTab>((ref) {
  return BottomNavNotifier();
});
