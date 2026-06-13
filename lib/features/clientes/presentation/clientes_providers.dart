import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/clientes_local_datasource.dart';
import '../../sync_cloud/presentation/cloud_sync_providers.dart';

final Provider<ClientesLocalDataSource> clientesLocalDataSourceProvider =
    Provider<ClientesLocalDataSource>((ref) {
  return ClientesLocalDataSource(
    ref.watch(appDatabaseProvider),
    cloudSyncLocalDataSource: ref.watch(cloudSyncLocalDataSourceProvider),
  );
});

final StateProvider<int> clientesRefreshSignalProvider =
    StateProvider<int>((_) => 0);
