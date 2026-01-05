import 'package:dartz/dartz.dart';
import 'package:cycle_sync_mvp_2/core/errors/failure.dart';
import 'package:cycle_sync_mvp_2/domain/entities/cycle_phase.dart';

/// Abstract repository for CyclePhase operations
abstract class CyclePhaseRepository {
  /// Fetch all cycle phases (with caching)
  Future<Either<Failure, List<CyclePhase>>> getCyclePhases();

  /// Get phase information for a specific cycle day
  Future<Either<Failure, CyclePhase>> getPhaseByDay(int cycleDay);
}
