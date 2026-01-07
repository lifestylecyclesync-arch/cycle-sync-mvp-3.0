import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';

/// Repository for managing daily notes in Supabase with local caching
class DailyNotesRepository {
  final SupabaseClient _supabaseClient;
  final SharedPreferences _prefs;

  DailyNotesRepository(this._supabaseClient, this._prefs);

  /// Get note for a specific date
  Future<String?> getNote(String userId, DateTime date) async {
    final dateStr = _formatDate(date);
    try {
      final response = await _supabaseClient
          .from('daily_notes')
          .select('note_text')
          .eq('user_id', userId)
          .eq('note_date', dateStr)
          .maybeSingle();

      if (response != null) {
        final note = response['note_text'] as String?;
        // Cache locally
        if (note != null) {
          await _cacheNote(dateStr, note);
        }
        return note;
      }

      // Fall back to local cache
      return _getCachedNote(dateStr);
    } catch (e) {
      AppLogger.error('Error fetching note from Supabase', e, StackTrace.current);
      // Return cached note on error
      return _getCachedNote(dateStr);
    }
  }

  /// Save or update note for a date
  Future<void> saveNote(String userId, DateTime date, String noteText) async {
    final dateStr = _formatDate(date);
    try {
      // Check if note exists
      final existing = await _supabaseClient
          .from('daily_notes')
          .select()
          .eq('user_id', userId)
          .eq('note_date', dateStr)
          .maybeSingle();

      if (existing != null) {
        // Update existing note
        await _supabaseClient
            .from('daily_notes')
            .update({
              'note_text': noteText,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('note_date', dateStr);
      } else {
        // Insert new note
        await _supabaseClient
            .from('daily_notes')
            .insert({
              'user_id': userId,
              'note_date': dateStr,
              'note_text': noteText,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      // Cache locally
      await _cacheNote(dateStr, noteText);
      AppLogger.info('Note saved for $dateStr');
    } catch (e) {
      AppLogger.error('Error saving note', e, StackTrace.current);
      rethrow;
    }
  }

  /// Delete note for a date
  Future<void> deleteNote(String userId, DateTime date) async {
    final dateStr = _formatDate(date);
    try {
      await _supabaseClient
          .from('daily_notes')
          .delete()
          .eq('user_id', userId)
          .eq('note_date', dateStr);

      // Remove from cache
      await _prefs.remove('note_$dateStr');
      AppLogger.info('Note deleted for $dateStr');
    } catch (e) {
      AppLogger.error('Error deleting note', e, StackTrace.current);
      rethrow;
    }
  }

  /// Cache note locally
  Future<void> _cacheNote(String dateStr, String noteText) async {
    try {
      await _prefs.setString('note_$dateStr', noteText);
    } catch (e) {
      AppLogger.error('Error caching note', e, StackTrace.current);
    }
  }

  /// Get cached note
  String? _getCachedNote(String dateStr) {
    try {
      return _prefs.getString('note_$dateStr');
    } catch (e) {
      AppLogger.error('Error retrieving cached note', e, StackTrace.current);
      return null;
    }
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}
