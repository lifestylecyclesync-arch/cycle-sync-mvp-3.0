import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Track if user is in guest/demo mode
final guestModeProvider = StateProvider<bool>((ref) {
  return false; // Default to not in guest mode
});

/// Persist guest mode state
final persistGuestModeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('guest_mode') ?? false;
});

/// Guest mode notifier to enable/disable demo access
final guestModeNotifierProvider = StateNotifierProvider<GuestModeNotifier, bool>((ref) {
  return GuestModeNotifier();
});

class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(false);

  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', true);
    state = true;
  }

  Future<void> disableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', false);
    state = false;
  }
}
