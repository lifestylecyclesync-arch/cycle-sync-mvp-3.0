import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/data/datasources/local_datasource.dart';

/// NOTE: All repositories disabled for MVP - no remote data access

/// Local datasource provider
final localDatasourceProvider = Provider<LocalDatasource>((ref) {
  return LocalDatasourceImpl();
});
