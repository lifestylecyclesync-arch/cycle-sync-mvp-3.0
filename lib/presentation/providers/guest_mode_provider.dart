import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Track if user is in guest/demo mode using NotifierProvider
final guestModeProvider = NotifierProvider<_GuestModeNotifier, bool>(() {
  return _GuestModeNotifier();
});

class _GuestModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false; // Default to not in guest mode
  }

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

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('guest_mode') ?? false;
  }
}

/// Load guest mode state from SharedPreferences
final loadGuestModeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final isGuest = prefs.getBool('guest_mode') ?? false;
  
  // Update the guestModeProvider with the persisted value
  await ref.read(guestModeProvider.notifier).loadFromPrefs();
  
  return isGuest;
});

/// Persist guest mode state
final persistGuestModeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('guest_mode') ?? false;
});
