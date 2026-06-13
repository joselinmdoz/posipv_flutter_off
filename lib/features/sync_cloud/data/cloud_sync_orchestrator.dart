import 'dart:convert';

import '../../../core/db/app_database.dart';
import 'cloud_sync_local_datasource.dart';
import 'cloud_sync_models.dart';
import 'odoo_api_client.dart';

class CloudSyncOrchestrator {
  CloudSyncOrchestrator(
    this._localDataSource,
    this._apiClient,
  );

  final CloudSyncLocalDataSource _localDataSource;
  final OdooApiClient _apiClient;

  Future<OdooPingResult> testConnection() async {
    final CloudSyncConfig config = await _localDataSource.loadConfig();
    _assertConfigBasics(config);
    return _apiClient.ping(
      serverUrl: config.serverUrl,
      databaseName: config.databaseName,
    );
  }

  Future<OdooDeviceRegistrationResult> registerCurrentDevice() async {
    final CloudSyncConfig config = await _localDataSource.loadConfig();
    final CloudSyncCredentials credentials =
        await _localDataSource.loadCredentials();
    _assertConfigBasics(config);
    final String? bootstrapToken = credentials.bootstrapToken;
    if (bootstrapToken == null || bootstrapToken.trim().isEmpty) {
      throw Exception(
        'Debes indicar el token de arranque para registrar el dispositivo.',
      );
    }
    final String deviceUuid = await _localDataSource.resolveLocalDeviceUuid();
    final OdooDeviceRegistrationResult result = await _apiClient.registerDevice(
      serverUrl: config.serverUrl,
      databaseName: config.databaseName,
      bootstrapToken: bootstrapToken,
      deviceUuid: deviceUuid,
      deviceLabel: config.deviceLabel,
      appVersion: '0.3.6',
    );
    await _localDataSource.saveApiKey(result.apiKey);
    await _localDataSource.saveConfig(
      config.copyWith(
        registeredDeviceUuid: result.deviceUuid,
        fullResyncRequired: config.fullResyncRequired,
      ),
    );
    String message = result.message;
    if (config.fullResyncRequired) {
      final CloudSyncBootstrapSummary summary =
          await _localDataSource.prepareInitialSyncBackfill();
      await _localDataSource.markFullResyncPrepared();
      message = '${result.message} Sincronización inicial preparada con '
          '${summary.totalQueued} registros locales para este servidor.';
    }
    return OdooDeviceRegistrationResult(
      deviceUuid: result.deviceUuid,
      apiKey: result.apiKey,
      message: message,
    );
  }

  Future<OdooPushBatchResult> pushPendingQueue() async {
    final CloudSyncConfig config = await _localDataSource.loadConfig();
    final CloudSyncCredentials credentials =
        await _localDataSource.loadCredentials();
    _assertReadyForAuthenticatedSync(config, credentials);
    final CloudSyncBootstrapSummary bootstrapSummary =
        await _localDataSource.prepareInitialSyncBackfill();
    final bool autoPreparedSnapshot = bootstrapSummary.totalQueued > 0;
    List<SyncQueueEntry> rows =
        await _localDataSource.listPendingEntries(limit: 250);
    if (rows.isEmpty) {
      return const OdooPushBatchResult(
        ok: true,
        message: 'No hay cambios pendientes y el respaldo ya está alineado.',
        acceptedRecords: 0,
        failedRecords: 0,
      );
    }

    final String runId =
        await _localDataSource.createSyncRun(direction: 'push');
    int requestCount = 0;
    int recordCount = 0;
    int acceptedRecords = 0;
    int failedRecords = 0;

    try {
      while (rows.isNotEmpty) {
        final List<String> ids =
            rows.map((SyncQueueEntry row) => row.id).toList(growable: false);
        await _localDataSource.markEntriesProcessing(ids);
        final Map<String, List<Map<String, Object?>>> grouped =
            <String, List<Map<String, Object?>>>{};
        for (final SyncQueueEntry row in rows) {
          final dynamic decoded = jsonDecode(row.payloadJson);
          final Map<String, Object?> payload = decoded is Map<String, dynamic>
              ? decoded
              : <String, Object?>{
                  'payload': decoded,
                };
          final List<Map<String, Object?>> bucket = grouped.putIfAbsent(
            row.entityType,
            () => <Map<String, Object?>>[],
          );
          bucket.add(
            <String, Object?>{
              'queue_id': row.id,
              'entity_id': row.entityId,
              'operation': row.operation,
              'payload': payload,
            },
          );
        }

        final OdooPushBatchResult result = await _apiClient.pushBatch(
          serverUrl: config.serverUrl,
          databaseName: config.databaseName,
          deviceUuid: config.registeredDeviceUuid!,
          apiKey: credentials.apiKey!,
          payload: <String, Object?>{
            'device_uuid': config.registeredDeviceUuid,
            'batch': grouped,
          },
        );
        await _localDataSource.markEntriesDone(ids);
        requestCount++;
        recordCount += rows.length;
        acceptedRecords += result.acceptedRecords;
        failedRecords += result.failedRecords;
        rows = await _localDataSource.listPendingEntries(limit: 250);
      }

      final String message;
      if (autoPreparedSnapshot) {
        message =
            'Respaldo completo enviado a Odoo. ${bootstrapSummary.totalQueued} registros locales preparados y $acceptedRecords sincronizados.';
      } else {
        message =
            'Sincronización completada. $acceptedRecords cambios enviados a Odoo.';
      }
      await _localDataSource.finishSyncRun(
        runId: runId,
        status: failedRecords > 0 ? 'warning' : 'success',
        requestCount: requestCount,
        recordCount: recordCount,
        summary: <String, Object?>{
          'accepted': acceptedRecords,
          'failed': failedRecords,
          'full_snapshot': autoPreparedSnapshot,
        },
      );
      await _localDataSource.updateLastPushAt(DateTime.now());
      return OdooPushBatchResult(
        ok: failedRecords == 0,
        message: message,
        acceptedRecords: acceptedRecords,
        failedRecords: failedRecords,
      );
    } catch (e) {
      final List<String> processingIds =
          rows.map((SyncQueueEntry row) => row.id).toList(growable: false);
      await _localDataSource.markEntriesFailed(processingIds, e.toString());
      await _localDataSource.finishSyncRun(
        runId: runId,
        status: 'failed',
        requestCount: requestCount + 1,
        recordCount: recordCount + rows.length,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<OdooMasterDataSnapshot> pullMasterDataPreview() async {
    final CloudSyncConfig config = await _localDataSource.loadConfig();
    final CloudSyncCredentials credentials =
        await _localDataSource.loadCredentials();
    _assertReadyForAuthenticatedSync(config, credentials);
    final String runId =
        await _localDataSource.createSyncRun(direction: 'pull');
    try {
      final OdooMasterDataSnapshot snapshot = await _apiClient.pullMasterData(
        serverUrl: config.serverUrl,
        databaseName: config.databaseName,
        deviceUuid: config.registeredDeviceUuid!,
        apiKey: credentials.apiKey!,
      );
      await _localDataSource.importMasterDataSnapshot(snapshot);
      await _localDataSource.finishSyncRun(
        runId: runId,
        status: 'success',
        requestCount: 1,
        recordCount: snapshot.products.length +
            snapshot.customers.length +
            snapshot.employees.length +
            snapshot.warehouses.length +
            snapshot.terminals.length,
        summary: <String, Object?>{
          'products': snapshot.products.length,
          'customers': snapshot.customers.length,
          'employees': snapshot.employees.length,
          'warehouses': snapshot.warehouses.length,
          'terminals': snapshot.terminals.length,
        },
      );
      await _localDataSource.updateLastPullAt(DateTime.now());
      return snapshot;
    } catch (e) {
      await _localDataSource.finishSyncRun(
        runId: runId,
        status: 'failed',
        requestCount: 1,
        recordCount: 0,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<OdooWorkOrdersSnapshot> pullWorkOrdersPreview() async {
    final CloudSyncConfig config = await _localDataSource.loadConfig();
    final CloudSyncCredentials credentials =
        await _localDataSource.loadCredentials();
    _assertReadyForAuthenticatedSync(config, credentials);
    final String runId =
        await _localDataSource.createSyncRun(direction: 'pull_orders');
    try {
      final OdooWorkOrdersSnapshot snapshot = await _apiClient.pullWorkOrders(
        serverUrl: config.serverUrl,
        databaseName: config.databaseName,
        deviceUuid: config.registeredDeviceUuid!,
        apiKey: credentials.apiKey!,
      );
      await _localDataSource.importWorkOrdersSnapshot(snapshot);
      await _localDataSource.finishSyncRun(
        runId: runId,
        status: 'success',
        requestCount: 1,
        recordCount: snapshot.workOrders.length,
        summary: <String, Object?>{
          'work_orders': snapshot.workOrders.length,
        },
      );
      await _localDataSource.updateLastPullAt(DateTime.now());
      return snapshot;
    } catch (e) {
      await _localDataSource.finishSyncRun(
        runId: runId,
        status: 'failed',
        requestCount: 1,
        recordCount: 0,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<CloudSyncBootstrapSummary> prepareInitialSyncBackfill() async {
    final CloudSyncConfig config = await _localDataSource.loadConfig();
    final CloudSyncCredentials credentials =
        await _localDataSource.loadCredentials();
    _assertReadyForAuthenticatedSync(config, credentials);
    return _localDataSource.prepareInitialSyncBackfill();
  }

  void _assertConfigBasics(CloudSyncConfig config) {
    if (config.serverUrl.trim().isEmpty) {
      throw Exception('Debes indicar la URL del servidor Odoo.');
    }
    if (config.databaseName.trim().isEmpty) {
      throw Exception('Debes indicar la base de datos de Odoo.');
    }
  }

  void _assertReadyForAuthenticatedSync(
    CloudSyncConfig config,
    CloudSyncCredentials credentials,
  ) {
    _assertConfigBasics(config);
    if ((config.registeredDeviceUuid ?? '').trim().isEmpty) {
      throw Exception('Debes registrar primero este dispositivo en Odoo.');
    }
    if ((credentials.apiKey ?? '').trim().isEmpty) {
      throw Exception(
        'No hay API key guardada. Registra el dispositivo otra vez.',
      );
    }
  }
}
