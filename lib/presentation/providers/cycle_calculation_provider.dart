import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: Cycle calculations disabled for MVP - no data fetching

/// Selected date for planner/daily view
/// Defaults to today
final selectedDateProvider = NotifierProvider<_SelectedDateNotifier, DateTime>(() {
  return _SelectedDateNotifier();
});

class _SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setDate(DateTime date) {
    state = date;
  }

  void setToToday() {
    state = DateTime.now();
  }
}
