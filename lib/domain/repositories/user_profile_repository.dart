import 'package:dartz/dartz.dart';
import 'package:cycle_sync_mvp_2/core/errors/failure.dart';
import 'package:cycle_sync_mvp_2/domain/entities/user_profile.dart';

/// Abstract repository for UserProfile operations
abstract class UserProfileRepository {
  /// Fetch user profile by ID
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);

  /// Save or update user profile
  Future<Either<Failure, UserProfile>> saveUserProfile(UserProfile profile);

  /// Check if user has completed initial setup
  Future<Either<Failure, bool>> isUserSetupComplete(String userId);
}
