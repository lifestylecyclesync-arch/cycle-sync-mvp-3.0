import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// App state model
class AppState {
  final bool isLoading;
  final String? error;
  final DateTime? selectedDate;

  const AppState({
    required this.isLoading,
    required this.error,
    required this.selectedDate,
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

/// App state notifier for managing simple app-level state
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier()
      : super(const AppState(
          isLoading: false,
          error: null,
          selectedDate: null,
        )) {
    _logger.i('🚀 AppStateNotifier initialized');
  }

  /// Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set error
  void setError(String? error) {
    state = state.copyWith(error: error);
    if (error != null) {
      _logger.e('⚠️ App error: $error');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set selected date
  void setSelectedDate(DateTime? date) {
    state = state.copyWith(selectedDate: date);
    _logger.d('📅 Selected date: $date');
  }
}

/// App state provider
final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
});
