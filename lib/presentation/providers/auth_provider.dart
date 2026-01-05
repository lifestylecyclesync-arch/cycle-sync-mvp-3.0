import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';

// NOTE: Auth providers disabled for MVP - no Supabase

/// Check if user is authenticated (always false for MVP)
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  AppLogger.info('Auth check: MVP mode - not authenticated');
  return false;
});

/// Get current user ID from auth (always null for MVP)
final currentAuthUserIdProvider = FutureProvider<String?>((ref) async {
  return null;
});
