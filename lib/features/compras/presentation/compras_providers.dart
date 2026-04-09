import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/compras_local_datasource.dart';

final Provider<ComprasLocalDataSource> comprasLocalDataSourceProvider =
    Provider<ComprasLocalDataSource>((Ref ref) {
  return ComprasLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});

final StateProvider<int> comprasRefreshSignalProvider =
    StateProvider<int>((_) => 0);
