import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/configuracion_local_datasource.dart';

final Provider<ConfiguracionLocalDataSource>
    configuracionLocalDataSourceProvider =
    Provider<ConfiguracionLocalDataSource>((ref) {
  return ConfiguracionLocalDataSource(ref.watch(appDatabaseProvider));
});
