import 'package:dartz/dartz.dart';
import 'package:cycle_sync_mvp_2/core/errors/exception.dart';
import 'package:cycle_sync_mvp_2/core/errors/failure.dart';
import 'package:cycle_sync_mvp_2/data/datasources/local_datasource.dart';
import 'package:cycle_sync_mvp_2/data/datasources/remote_datasource.dart';
import 'package:cycle_sync_mvp_2/data/models/user_profile_model.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';
import 'package:cycle_sync_mvp_2/domain/repositories/user_profile_repository.dart';

/// Implementation of UserProfileRepository
class UserProfileRepositoryImpl implements UserProfileRepository {
  final RemoteDatasource remoteDatasource;
  final LocalDatasource localDatasource;

  UserProfileRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    try {
      // Try remote first
      final remoteProfile = await remoteDatasource.getUserProfile(userId);
      // Cache locally
      await localDatasource.cacheUserProfile(remoteProfile);
      return Right(remoteProfile.toEntity());
    } on SupabaseException catch (e) {
      // Fallback to cached profile
      try {
        final cachedProfile =
            await localDatasource.getCachedUserProfile(userId);
        if (cachedProfile != null) {
          return Right(cachedProfile.toEntity());
        }
        return Left(e.toFailure());
      } catch (cacheError) {
        return Left(e.toFailure());
      }
    } on CacheException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> saveUserProfile(
    UserProfile profile,
  ) async {
    try {
      final model = UserProfileModel(
        id: profile.id,
        name: profile.name,
        cycleLength: profile.cycleLength,
        menstrualLength: profile.menstrualLength,
        lastPeriodDate: profile.lastPeriodDate,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
      );

      final saved = await remoteDatasource.saveUserProfile(model);
      // Cache locally
      await localDatasource.cacheUserProfile(saved);
      return Right(saved.toEntity());
    } on SupabaseException catch (e) {
      return Left(e.toFailure());
    } on CacheException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserSetupComplete(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile.fold(
        (failure) => Left(failure),
        (userProfile) {
          // User is setup if they have a cycle length set
          final isComplete = userProfile.cycleLength > 0;
          return Right(isComplete);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}
