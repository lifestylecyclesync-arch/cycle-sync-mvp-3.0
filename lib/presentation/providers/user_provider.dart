import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/auth_provider.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? avatar;
  final int cycleLength;
  final int menstrualLength;
  final DateTime? cycleStartDate;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatar,
    required this.cycleLength,
    required this.menstrualLength,
    this.cycleStartDate,
    required this.createdAt,
  });

  /// Create from Supabase response
  factory UserProfile.fromSupabase(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'] as String,
      email: data['email'] as String,
      displayName: data['display_name'] as String?,
      avatar: data['avatar'] as String?,
      cycleLength: (data['cycle_length'] as int?) ?? 28,
      menstrualLength: (data['menstrual_length'] as int?) ?? 5,
      cycleStartDate: data['cycle_start_date'] != null
          ? DateTime.parse(data['cycle_start_date'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  /// Convert to map for Supabase update
  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'avatar': avatar,
      'cycle_length': cycleLength,
      'menstrual_length': menstrualLength,
      'cycle_start_date': cycleStartDate?.toIso8601String(),
    };
  }
}

/// User profile provider
/// Fetches user profile from Supabase
final userProfileProvider =
    FutureProvider.autoDispose<UserProfile?>((ref) async {
  // Wait for user to be authenticated
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return null;
  }

  try {
    _logger.d('📥 Fetching user profile: ${user.id}');

    final response = await SupabaseConfig.userProfilesTable
        .eq('id', user.id)
        .single()
        .timeout(const Duration(seconds: 10));

    final profile = UserProfile.fromSupabase(response);
    _logger.i('✅ User profile loaded: ${profile.displayName ?? profile.email}');
    return profile;
  } catch (e) {
    _logger.e('❌ Error fetching user profile: $e');
    // Return basic profile if not found
    return UserProfile(
      id: user.id,
      email: user.email ?? 'unknown@example.com',
      cycleLength: 28,
      menstrualLength: 5,
      createdAt: DateTime.now(),
    );
  }
});

/// Update user profile provider
/// Returns function to update user profile
final updateUserProfileProvider =
    FutureProvider.autoDispose.family<void, UserProfile>((ref, profile) async {
  _logger.i('📤 Updating user profile: ${profile.id}');

  try {
    await SupabaseConfig.client
        .from('user_profiles')
        .update(profile.toMap())
        .eq('id', profile.id);

    _logger.i('✅ User profile updated');

    // Invalidate the user profile provider to refresh
    ref.invalidate(userProfileProvider);
  } catch (e) {
    _logger.e('❌ Error updating user profile: $e');
    rethrow;
  }
});

/// User cycle length provider
/// Shorthand to get cycle length from profile
final userCycleLengthProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.cycleLength ?? 28;
});

/// User cycle start date provider
/// Shorthand to get cycle start date from profile
final userCycleStartDateProvider =
    FutureProvider.autoDispose<DateTime?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.cycleStartDate;
});
