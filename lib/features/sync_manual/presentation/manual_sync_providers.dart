import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/manual_sync_local_datasource.dart';

final Provider<ManualSyncLocalDataSource> manualSyncLocalDataSourceProvider =
    Provider<ManualSyncLocalDataSource>((Ref ref) {
  return ManualSyncLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});
