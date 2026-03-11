import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/inventario_local_datasource.dart';

final Provider<InventarioLocalDataSource> inventarioLocalDataSourceProvider =
    Provider<InventarioLocalDataSource>((ref) {
  return InventarioLocalDataSource(ref.watch(appDatabaseProvider));
});
