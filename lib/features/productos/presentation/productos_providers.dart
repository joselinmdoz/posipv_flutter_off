import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/productos_local_datasource.dart';

final Provider<ProductosLocalDataSource> productosLocalDataSourceProvider =
    Provider<ProductosLocalDataSource>((ref) {
  return ProductosLocalDataSource(ref.watch(appDatabaseProvider));
});
