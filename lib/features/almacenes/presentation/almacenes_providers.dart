import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/almacenes_local_datasource.dart';

final Provider<AlmacenesLocalDataSource> almacenesLocalDataSourceProvider =
    Provider<AlmacenesLocalDataSource>((ref) {
  return AlmacenesLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});
