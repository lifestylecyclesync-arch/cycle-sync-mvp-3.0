import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

/// Repository for managing user profile data in Supabase with local caching
class UserProfileRepository {
  final SupabaseClient _supabaseClient;
  final SharedPreferences _prefs;

  UserProfileRepository(this._supabaseClient, this._prefs);

  /// Get user profile from Supabase or local cache
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Try to fetch from Supabase first
      final response = await _supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = await _mapToUserProfile(response, userId);
        // Cache locally
        await _cacheUserProfile(profile);
        return profile;
      }
      
      // Fall back to local cache
      return _getCachedUserProfile();
    } catch (e) {
      AppLogger.error('Error fetching user profile from Supabase', e, StackTrace.current);
      // Return cached profile on error
      return _getCachedUserProfile();
    }
  }

  /// Create or update user profile in Supabase
  Future<UserProfile> saveUserProfile({
    required String userId,
    required String name,
    required int cycleLength,
    required int menstrualLength,
    required int lutealPhaseLength,
    required DateTime lastPeriodDate,
    String? avatarBase64,
    String? fastingPreference,
  }) async {
    try {
      final now = DateTime.now();
      
      // Check if profile exists
      final existing = await _supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      late Map<String, dynamic> result;
      
      if (existing != null) {
        // Update existing profile
        result = await _supabaseClient
            .from('user_profiles')
            .update({
              'name': name,
              'cycle_length': cycleLength,
              'menstrual_length': menstrualLength,
              'luteal_phase_length': lutealPhaseLength,
              'last_period_date': lastPeriodDate.toIso8601String(),
              'avatar_base64': avatarBase64,
              'fasting_preference': fastingPreference ?? 'Beginner',
              'updated_at': now.toIso8601String(),
            })
            .eq('user_id', userId)
            .select()
            .single();
      } else {
        // Insert new profile
        result = await _supabaseClient
            .from('user_profiles')
            .insert({
              'user_id': userId,
              'name': name,
              'cycle_length': cycleLength,
              'menstrual_length': menstrualLength,
              'luteal_phase_length': lutealPhaseLength,
              'last_period_date': lastPeriodDate.toIso8601String(),
              'avatar_base64': avatarBase64,
              'fasting_preference': fastingPreference ?? 'Beginner',
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
            })
            .select()
            .single();
      }

      final profile = await _mapToUserProfile(result, userId);
      await _cacheUserProfile(profile);
      AppLogger.info('User profile saved to Supabase: $userId');
      return profile;
    } catch (e) {
      AppLogger.error('Error saving user profile', e, StackTrace.current);
      rethrow;
    }
  }

  /// Update user avatar
  Future<void> updateAvatar(String userId, String avatarBase64) async {
    try {
      await _supabaseClient
          .from('user_profiles')
          .update({
            'avatar_base64': avatarBase64,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      AppLogger.info('Avatar updated for user: $userId');
    } catch (e) {
      AppLogger.error('Error updating avatar', e, StackTrace.current);
      rethrow;
    }
  }

  /// Update fasting preference
  Future<void> updateFastingPreference(String userId, String preference) async {
    try {
      await _supabaseClient
          .from('user_profiles')
          .update({
            'fasting_preference': preference,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      
      AppLogger.info('Fasting preference updated for user: $userId');
    } catch (e) {
      AppLogger.error('Error updating fasting preference', e, StackTrace.current);
      rethrow;
    }
  }

  /// Cache user profile locally
  Future<void> _cacheUserProfile(UserProfile profile) async {
    try {
      await _prefs.setString('cached_user_profile_json', _userProfileToJson(profile));
      AppLogger.info('User profile cached locally');
    } catch (e) {
      AppLogger.error('Error caching user profile', e, StackTrace.current);
    }
  }

  /// Get cached user profile
  UserProfile? _getCachedUserProfile() {
    try {
      final json = _prefs.getString('cached_user_profile_json');
      if (json != null) {
        return _userProfileFromJson(json);
      }
    } catch (e) {
      AppLogger.error('Error retrieving cached profile', e, StackTrace.current);
    }
    return null;
  }

  /// Map Supabase row to UserProfile
  Future<UserProfile> _mapToUserProfile(Map<String, dynamic> row, String userId) async {
    // Fetch lifestyle areas for this user
    List<String> lifestyleAreas = [];
    try {
      final areasResponse = await _supabaseClient
          .from('lifestyle_areas')
          .select('area_name')
          .eq('user_id', userId);
      
      lifestyleAreas = (areasResponse as List)
          .map((item) => item['area_name'] as String)
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching lifestyle areas', e, StackTrace.current);
      // Continue with empty list if fetch fails
    }

    return UserProfile(
      id: userId,
      name: row['name'] ?? '',
      cycleLength: row['cycle_length'] ?? 28,
      menstrualLength: row['menstrual_length'] ?? 5,
      lutealPhaseLength: row['luteal_phase_length'] ?? 14,
      lastPeriodDate: DateTime.parse(row['last_period_date']),
      lifestyleAreas: lifestyleAreas,
      fastingPreference: row['fasting_preference'] ?? 'Beginner',
      createdAt: DateTime.parse(row['created_at']),
      updatedAt: DateTime.parse(row['updated_at']),
    );
  }

  /// Convert UserProfile to JSON for caching
  String _userProfileToJson(UserProfile profile) {
    return '''
    {
      "id": "${profile.id}",
      "name": "${profile.name}",
      "cycleLength": ${profile.cycleLength},
      "menstrualLength": ${profile.menstrualLength},
      "lutealPhaseLength": ${profile.lutealPhaseLength},
      "lastPeriodDate": "${profile.lastPeriodDate.toIso8601String()}",
      "lifestyleAreas": [],
      "fastingPreference": "${profile.fastingPreference}",
      "createdAt": "${profile.createdAt.toIso8601String()}",
      "updatedAt": "${profile.updatedAt.toIso8601String()}"
    }
    ''';
  }

  /// Convert JSON to UserProfile
  UserProfile _userProfileFromJson(String json) {
    final map = json;
    return UserProfile(
      id: _extractValue(map, 'id'),
      name: _extractValue(map, 'name'),
      cycleLength: int.parse(_extractValue(map, 'cycleLength')),
      menstrualLength: int.parse(_extractValue(map, 'menstrualLength')),
      lutealPhaseLength: int.parse(_extractValue(map, 'lutealPhaseLength')),
      lastPeriodDate: DateTime.parse(_extractValue(map, 'lastPeriodDate')),
      lifestyleAreas: [],
      fastingPreference: _extractValue(map, 'fastingPreference'),
      createdAt: DateTime.parse(_extractValue(map, 'createdAt')),
      updatedAt: DateTime.parse(_extractValue(map, 'updatedAt')),
    );
  }

  String _extractValue(String json, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"?([^",}]*)');
    final match = regex.firstMatch(json);
    return match?.group(1) ?? '';
  }
}
