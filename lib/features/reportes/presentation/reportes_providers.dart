import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/reportes_local_datasource.dart';

final Provider<ReportesLocalDataSource> reportesLocalDataSourceProvider =
    Provider<ReportesLocalDataSource>((ref) {
  return ReportesLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});
