import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/clientes_local_datasource.dart';

final Provider<ClientesLocalDataSource> clientesLocalDataSourceProvider =
    Provider<ClientesLocalDataSource>((ref) {
  return ClientesLocalDataSource(ref.watch(appDatabaseProvider));
});

final StateProvider<int> clientesRefreshSignalProvider =
    StateProvider<int>((_) => 0);
