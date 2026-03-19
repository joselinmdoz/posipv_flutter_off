import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/productos_local_datasource.dart';

final Provider<ProductosLocalDataSource> productosLocalDataSourceProvider =
    Provider<ProductosLocalDataSource>((ref) {
  return ProductosLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});

final StateProvider<int> productosCatalogRevisionProvider =
    StateProvider<int>((_) => 0);
