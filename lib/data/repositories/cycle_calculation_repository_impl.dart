import 'package:dartz/dartz.dart';
import 'package:cycle_sync_mvp_2/core/errors/exception.dart';
import 'package:cycle_sync_mvp_2/core/errors/failure.dart';
import 'package:cycle_sync_mvp_2/data/datasources/local_datasource.dart';
import 'package:cycle_sync_mvp_2/data/datasources/remote_datasource.dart';
import 'package:cycle_sync_mvp_2/data/models/cycle_calculation_model.dart';
import 'package:cycle_sync_mvp_2/domain/entities/cycle_calculation.dart';
import 'package:cycle_sync_mvp_2/domain/repositories/cycle_calculation_repository.dart';

/// Implementation of CycleCalculationRepository
class CycleCalculationRepositoryImpl implements CycleCalculationRepository {
  final RemoteDatasource remoteDatasource;
  final LocalDatasource localDatasource;

  CycleCalculationRepositoryImpl({
    required this.remoteDatasource,
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<CycleCalculation>>> getCycleCalculations(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Try to fetch from remote first
      final remoteCalcs = await remoteDatasource.getCycleCalculations(
        userId,
        startDate,
        endDate,
      );

      // Cache locally
      await localDatasource.cacheCycleCalculations(remoteCalcs);

      return Right(remoteCalcs.map((m) => m.toEntity()).toList());
    } on SupabaseException catch (e) {
      // Fallback to cached data if remote fails
      try {
        final cachedCalcs =
            await localDatasource.getCachedCycleCalculations(userId);
        return Right(cachedCalcs.map((m) => m.toEntity()).toList());
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
  Future<Either<Failure, CycleCalculation>> getCalculationForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final calculations = await getCycleCalculations(
        userId,
        date,
        date,
      );

      return calculations.fold(
        (failure) => Left(failure),
        (calcList) {
          if (calcList.isEmpty) {
            return Left(ValidationFailure(
              'No calculation found for $date',
              field: 'date',
            ));
          }
          return Right(calcList.first);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, CycleCalculation>> saveCycleCalculation(
    CycleCalculation calculation,
  ) async {
    try {
      final model = CycleCalculationModel(
        id: calculation.id,
        userId: calculation.userId,
        calculationDate: calculation.calculationDate,
        cycleDay: calculation.cycleDay,
        phaseType: calculation.phaseType,
        lifestylePhase: calculation.lifestylePhase,
        hormonalState: calculation.hormonalState,
        daysUntilNextPeriod: calculation.daysUntilNextPeriod,
        isOvulationWindow: calculation.isOvulationWindow,
        isFirstDayOfCycle: calculation.isFirstDayOfCycle,
        nextPeriodDate: calculation.nextPeriodDate,
        cycleStartDate: calculation.cycleStartDate,
        cycleDayOfMonth: calculation.cycleDayOfMonth,
        createdAt: calculation.createdAt,
        updatedAt: calculation.updatedAt,
      );

      final saved = await remoteDatasource.saveCycleCalculation(model);
      return Right(saved.toEntity());
    } on SupabaseException catch (e) {
      return Left(e.toFailure());
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}
