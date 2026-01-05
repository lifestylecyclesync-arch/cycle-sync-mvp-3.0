import 'package:flutter_riverpod/flutter_riverpod.dart';

// NOTE: Cycle calculations disabled for MVP - no data fetching

/// Selected date for planner/daily view
/// Defaults to today
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
