import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/db/app_database.dart';
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

final FutureProvider<List<Product>> allProductsProvider =
    FutureProvider<List<Product>>((ref) async {
  return ref.watch(productosLocalDataSourceProvider).listActiveProducts();
});
