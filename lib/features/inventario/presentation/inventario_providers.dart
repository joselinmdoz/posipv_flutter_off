import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/inventario_local_datasource.dart';

final Provider<InventarioLocalDataSource> inventarioLocalDataSourceProvider =
    Provider<InventarioLocalDataSource>((ref) {
  return InventarioLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});

final StateProvider<int> inventoryRefreshSignalProvider =
    StateProvider<int>((_) => 0);
