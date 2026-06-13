import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/cloud_sync_local_datasource.dart';
import '../data/cloud_sync_orchestrator.dart';
import '../data/odoo_api_client.dart';

final cloudSyncLocalDataSourceProvider =
    Provider<CloudSyncLocalDataSource>((Ref ref) {
  return CloudSyncLocalDataSource(ref.read(appDatabaseProvider));
});

final odooApiClientProvider = Provider<OdooApiClient>((Ref ref) {
  return OdooApiClient();
});

final cloudSyncOrchestratorProvider =
    Provider<CloudSyncOrchestrator>((Ref ref) {
  return CloudSyncOrchestrator(
    ref.read(cloudSyncLocalDataSourceProvider),
    ref.read(odooApiClientProvider),
  );
});
