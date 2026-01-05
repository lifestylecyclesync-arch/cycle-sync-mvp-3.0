import 'package:cycle_sync_mvp_2/core/errors/exception.dart';
import 'package:cycle_sync_mvp_2/data/models/cycle_calculation_model.dart';
import 'package:cycle_sync_mvp_2/data/models/cycle_phase_model.dart';
import 'package:cycle_sync_mvp_2/data/models/user_profile_model.dart';

/// Abstract local datasource for caching with Hive and SharedPreferences
abstract class LocalDatasource {
  /// Cache cycle phases (static data, rarely changes)
  Future<void> cacheCyclePhases(List<CyclePhaseModel> phases);

  /// Fetch cached cycle phases
  Future<List<CyclePhaseModel>> getCachedCyclePhases();

  /// Cache user profile locally
  Future<void> cacheUserProfile(UserProfileModel profile);

  /// Fetch cached user profile
  Future<UserProfileModel?> getCachedUserProfile(String userId);

  /// Cache cycle calculations for offline access
  Future<void> cacheCycleCalculations(List<CycleCalculationModel> calculations);

  /// Fetch cached cycle calculations
  Future<List<CycleCalculationModel>> getCachedCycleCalculations(String userId);

  /// Clear all cached data
  Future<void> clearCache();

  /// Check if cycle phases cache is stale (older than 30 days)
  Future<bool> isCyclePhaseCacheStale();
}

/// Implementation of LocalDatasource using Hive and SharedPreferences
class LocalDatasourceImpl implements LocalDatasource {
  // TODO: Inject Hive boxes and SharedPreferences here
  // final Box<CyclePhaseModel> cyclePhaseBox;
  // final Box<CycleCalculationModel> calculationBox;
  // final SharedPreferences prefs;

  // LocalDatasourceImpl({
  //   required this.cyclePhaseBox,
  //   required this.calculationBox,
  //   required this.prefs,
  // });

  @override
  Future<void> cacheCyclePhases(List<CyclePhaseModel> phases) async {
    try {
      // TODO: Implement Hive box put operations
      // for (var phase in phases) {
      //   await cyclePhaseBox.put(phase.id, phase);
      // }
      // Update last sync timestamp
      // await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw CacheException('Failed to cache cycle phases: $e');
    }
  }

  @override
  Future<List<CyclePhaseModel>> getCachedCyclePhases() async {
    try {
      // TODO: Implement Hive box get operations
      // return cyclePhaseBox.values.toList();
      return [];
    } catch (e) {
      throw CacheException('Failed to get cached cycle phases: $e');
    }
  }

  @override
  Future<void> cacheUserProfile(UserProfileModel profile) async {
    try {
      // TODO: Implement SharedPreferences save
      // await prefs.setString('user_profile_${profile.id}', jsonEncode(profile.toJson()));
    } catch (e) {
      throw CacheException('Failed to cache user profile: $e');
    }
  }

  @override
  Future<UserProfileModel?> getCachedUserProfile(String userId) async {
    try {
      // TODO: Implement SharedPreferences retrieve
      // final json = prefs.getString('user_profile_$userId');
      // if (json == null) return null;
      // return UserProfileModel.fromJson(jsonDecode(json));
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached user profile: $e');
    }
  }

  @override
  Future<void> cacheCycleCalculations(
    List<CycleCalculationModel> calculations,
  ) async {
    try {
      // TODO: Implement Hive box put operations
      // for (var calc in calculations) {
      //   await calculationBox.put(calc.id, calc);
      // }
    } catch (e) {
      throw CacheException('Failed to cache cycle calculations: $e');
    }
  }

  @override
  Future<List<CycleCalculationModel>> getCachedCycleCalculations(
    String userId,
  ) async {
    try {
      // TODO: Implement Hive box get with filter by userId
      // return calculationBox.values
      //     .where((c) => c.userId == userId)
      //     .toList();
      return [];
    } catch (e) {
      throw CacheException('Failed to get cached cycle calculations: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      // TODO: Implement clear operations
      // await cyclePhaseBox.clear();
      // await calculationBox.clear();
      // await prefs.clear();
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }

  @override
  Future<bool> isCyclePhaseCacheStale() async {
    try {
      // TODO: Implement stale check
      // final lastSync = prefs.getString(_lastSyncKey);
      // if (lastSync == null) return true;
      // final lastSyncDate = DateTime.parse(lastSync);
      // return DateTime.now().difference(lastSyncDate).inDays > 30;
      return true;
    } catch (e) {
      throw CacheException('Failed to check cache staleness: $e');
    }
  }
}
