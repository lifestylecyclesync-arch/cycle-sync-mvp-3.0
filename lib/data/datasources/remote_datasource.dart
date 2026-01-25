import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cycle_sync_mvp_2/core/errors/exception.dart';
import 'package:cycle_sync_mvp_2/core/logger.dart';
import 'package:cycle_sync_mvp_2/data/models/cycle_calculation_model.dart';
import 'package:cycle_sync_mvp_2/data/models/cycle_phase_model.dart';
import 'package:cycle_sync_mvp_2/data/models/user_profile_model.dart';

/// Abstract remote datasource for Supabase operations
abstract class RemoteDatasource {
  /// Fetch all cycle phases from Supabase
  Future<List<CyclePhaseModel>> getCyclePhases();

  /// Fetch user profile from Supabase by user ID
  Future<UserProfileModel> getUserProfile(String userId);

  /// Save or update user profile in Supabase
  Future<UserProfileModel> saveUserProfile(UserProfileModel profile);

  /// Fetch cycle calculations for a user within a date range
  Future<List<CycleCalculationModel>> getCycleCalculations(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Save cycle calculation to Supabase
  Future<CycleCalculationModel> saveCycleCalculation(
    CycleCalculationModel calculation,
  );

  /// Delete a cycle calculation
  Future<void> deleteCycleCalculation(String calculationId);
}

/// Implementation of RemoteDatasource using Supabase
class RemoteDatasourceImpl implements RemoteDatasource {
  final SupabaseClient supabaseClient;

  RemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<CyclePhaseModel>> getCyclePhases() async {
    try {
      AppLogger.info('Fetching cycle phases from Supabase');
      final response = await supabaseClient
          .from('cycle_phases')
          .select();
      
      final phases = (response as List)
          .map((p) => CyclePhaseModel.fromJson(p as Map<String, dynamic>))
          .toList();
      
      AppLogger.info('Fetched ${phases.length} cycle phases');
      return phases;
    } on PostgrestException catch (e) {
      AppLogger.error('Supabase error fetching cycle phases', e, StackTrace.current);
      throw SupabaseException('Failed to fetch cycle phases: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching cycle phases', e, StackTrace.current);
      throw SupabaseException('Failed to fetch cycle phases: $e');
    }
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      print('[DEBUG] ===== getUserProfile CALLED for user: $userId =====');
      print('[DEBUG] Auth user ID type: ${userId.runtimeType}');
      AppLogger.info('Fetching user profile for user: $userId');
      final response = await supabaseClient
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      
      var profile = UserProfileModel.fromJson(response);
      print('[DEBUG] Profile fetched: ${profile.name}, ID: ${profile.id}');
      AppLogger.info('Successfully fetched user profile');
      
      // Note: Lifestyle areas are fetched separately via lifestyleAreasProvider
      // They are NOT merged into the profile object
      // This keeps the profile focused on cycle data only
      
      return profile;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        AppLogger.warning('User profile not found: $userId');
        throw SupabaseException('User profile not found');
      }
      AppLogger.error('Supabase error fetching user profile', e, StackTrace.current);
      throw SupabaseException('Failed to fetch user profile: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching user profile', e, StackTrace.current);
      throw SupabaseException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<UserProfileModel> saveUserProfile(UserProfileModel profile) async {
    try {
      AppLogger.info('Saving user profile for user: ${profile.id}');
      
      final json = profile.toJson();
      final response = await supabaseClient
          .from('user_profiles')
          .upsert(json)
          .select()
          .single();
      
      final saved = UserProfileModel.fromJson(response);
      AppLogger.info('Successfully saved user profile');
      return saved;
    } on PostgrestException catch (e) {
      AppLogger.error('Supabase error saving user profile', e, StackTrace.current);
      throw SupabaseException('Failed to save user profile: ${e.message}');
    } catch (e) {
      AppLogger.error('Error saving user profile', e, StackTrace.current);
      throw SupabaseException('Failed to save user profile: $e');
    }
  }

  @override
  Future<List<CycleCalculationModel>> getCycleCalculations(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      AppLogger.info('Fetching cycle calculations for user: $userId, range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      final response = await supabaseClient
          .from('cycle_calculations')
          .select()
          .eq('user_id', userId)
          .gte('calculation_date', startDate.toIso8601String())
          .lte('calculation_date', endDate.toIso8601String())
          .order('calculation_date', ascending: true);
      
      final calculations = (response as List)
          .map((c) => CycleCalculationModel.fromJson(c as Map<String, dynamic>))
          .toList();
      
      AppLogger.info('Fetched ${calculations.length} cycle calculations');
      return calculations;
    } on PostgrestException catch (e) {
      AppLogger.error('Supabase error fetching cycle calculations', e, StackTrace.current);
      throw SupabaseException('Failed to fetch cycle calculations: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching cycle calculations', e, StackTrace.current);
      throw SupabaseException('Failed to fetch cycle calculations: $e');
    }
  }

  @override
  Future<CycleCalculationModel> saveCycleCalculation(
    CycleCalculationModel calculation,
  ) async {
    try {
      AppLogger.info('Saving cycle calculation for user: ${calculation.userId}');
      
      final json = calculation.toJson();
      final response = await supabaseClient
          .from('cycle_calculations')
          .upsert(json)
          .select()
          .single();
      
      final saved = CycleCalculationModel.fromJson(response);
      AppLogger.info('Successfully saved cycle calculation');
      return saved;
    } on PostgrestException catch (e) {
      AppLogger.error('Supabase error saving cycle calculation', e, StackTrace.current);
      throw SupabaseException('Failed to save cycle calculation: ${e.message}');
    } catch (e) {
      AppLogger.error('Error saving cycle calculation', e, StackTrace.current);
      throw SupabaseException('Failed to save cycle calculation: $e');
    }
  }

  @override
  Future<void> deleteCycleCalculation(String calculationId) async {
    try {
      AppLogger.info('Deleting cycle calculation: $calculationId');
      
      await supabaseClient
          .from('cycle_calculations')
          .delete()
          .eq('id', calculationId);
      
      AppLogger.info('Successfully deleted cycle calculation');
    } on PostgrestException catch (e) {
      AppLogger.error('Supabase error deleting cycle calculation', e, StackTrace.current);
      throw SupabaseException('Failed to delete cycle calculation: ${e.message}');
    } catch (e) {
      AppLogger.error('Error deleting cycle calculation', e, StackTrace.current);
      throw SupabaseException('Failed to delete cycle calculation: $e');
    }
  }
}
