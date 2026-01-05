import 'package:dartz/dartz.dart';
import 'package:cycle_sync_mvp_2/core/errors/exception.dart';
import 'package:cycle_sync_mvp_2/core/errors/failure.dart';
import 'package:cycle_sync_mvp_2/data/datasources/local_datasource.dart';
import 'package:cycle_sync_mvp_2/data/datasources/remote_datasource.dart';
import 'package:cycle_sync_mvp_2/domain/entities/cycle_phase.dart';
import 'package:cycle_sync_mvp_2/domain/repositories/cycle_phase_repository.dart';

/// Implementation of CyclePhaseRepository with caching strategy
class CyclePhaseRepositoryImpl implements CyclePhaseRepository {
  final RemoteDatasource remoteDatasource;
  final LocalDatasource localDatasource;

  CyclePhaseRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<CyclePhase>>> getCyclePhases() async {
    try {
      // Check if cache is stale
      final isCacheStale = await localDatasource.isCyclePhaseCacheStale();

      if (!isCacheStale) {
        // Return cached data if fresh
        final cachedPhases = await localDatasource.getCachedCyclePhases();
        if (cachedPhases.isNotEmpty) {
          return Right(cachedPhases.map((m) => m.toEntity()).toList());
        }
      }

      // Fetch from remote and cache
      final remotePhases = await remoteDatasource.getCyclePhases();
      await localDatasource.cacheCyclePhases(remotePhases);
      return Right(remotePhases.map((m) => m.toEntity()).toList());
    } on SupabaseException catch (e) {
      return Left(e.toFailure());
    } on CacheException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, CyclePhase>> getPhaseByDay(int cycleDay) async {
    try {
      final phases = await getCyclePhases();
      return phases.fold(
        (failure) => Left(failure),
        (phaseList) {
          try {
            final phase = phaseList.firstWhere(
              (p) => p.containsDay(cycleDay),
              orElse: () => throw ValidationFailure(
                'No phase found for cycle day $cycleDay',
                field: 'cycleDay',
              ),
            );
            return Right(phase);
          } catch (e) {
            if (e is ValidationFailure) {
              return Left(e);
            }
            return Left(ValidationFailure(e.toString(), field: 'cycleDay'));
          }
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}
