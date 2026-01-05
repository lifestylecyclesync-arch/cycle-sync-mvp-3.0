import 'package:dartz/dartz.dart';
import 'package:cycle_sync_mvp_2/core/errors/failure.dart';
import 'package:cycle_sync_mvp_2/domain/entities/cycle_calculation.dart';

/// Abstract repository for CycleCalculation operations
abstract class CycleCalculationRepository {
  /// Fetch cycle calculations for a user within a date range
  Future<Either<Failure, List<CycleCalculation>>> getCycleCalculations(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get calculation for a specific date
  Future<Either<Failure, CycleCalculation>> getCalculationForDate(
    String userId,
    DateTime date,
  );

  /// Save a cycle calculation
  Future<Either<Failure, CycleCalculation>> saveCycleCalculation(
    CycleCalculation calculation,
  );
}
