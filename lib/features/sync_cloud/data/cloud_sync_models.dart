class CloudSyncConfig {
  const CloudSyncConfig({
    required this.enabled,
    required this.serverUrl,
    required this.databaseName,
    required this.deviceLabel,
    required this.autoPullCatalogs,
    required this.autoPushSales,
    required this.autoPushInventory,
    required this.autoPushOrders,
    this.registeredDeviceUuid,
    this.lastPushAt,
    this.lastPullAt,
    this.fullResyncRequired = false,
  });

  final bool enabled;
  final String serverUrl;
  final String databaseName;
  final String deviceLabel;
  final bool autoPullCatalogs;
  final bool autoPushSales;
  final bool autoPushInventory;
  final bool autoPushOrders;
  final String? registeredDeviceUuid;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;
  final bool fullResyncRequired;

  CloudSyncConfig copyWith({
    bool? enabled,
    String? serverUrl,
    String? databaseName,
    String? deviceLabel,
    bool? autoPullCatalogs,
    bool? autoPushSales,
    bool? autoPushInventory,
    bool? autoPushOrders,
    String? registeredDeviceUuid,
    DateTime? lastPushAt,
    DateTime? lastPullAt,
    bool? fullResyncRequired,
  }) {
    return CloudSyncConfig(
      enabled: enabled ?? this.enabled,
      serverUrl: serverUrl ?? this.serverUrl,
      databaseName: databaseName ?? this.databaseName,
      deviceLabel: deviceLabel ?? this.deviceLabel,
      autoPullCatalogs: autoPullCatalogs ?? this.autoPullCatalogs,
      autoPushSales: autoPushSales ?? this.autoPushSales,
      autoPushInventory: autoPushInventory ?? this.autoPushInventory,
      autoPushOrders: autoPushOrders ?? this.autoPushOrders,
      registeredDeviceUuid: registeredDeviceUuid ?? this.registeredDeviceUuid,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      fullResyncRequired: fullResyncRequired ?? this.fullResyncRequired,
    );
  }
}

class CloudSyncCredentials {
  const CloudSyncCredentials({
    this.bootstrapToken,
    this.apiKey,
  });

  final String? bootstrapToken;
  final String? apiKey;
}

class CloudSyncQueueEntryView {
  const CloudSyncQueueEntryView({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.sourceModule,
    this.lastError,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final String? sourceModule;
  final String? lastError;
}

class CloudSyncQueueStats {
  const CloudSyncQueueStats({
    required this.pending,
    required this.processing,
    required this.failed,
    required this.done,
  });

  final int pending;
  final int processing;
  final int failed;
  final int done;

  int get total => pending + processing + failed + done;
}

class OdooPingResult {
  const OdooPingResult({
    required this.ok,
    required this.message,
    this.serverVersion,
    this.serverTime,
    this.databaseName,
  });

  final bool ok;
  final String message;
  final String? serverVersion;
  final DateTime? serverTime;
  final String? databaseName;
}

class OdooDeviceRegistrationResult {
  const OdooDeviceRegistrationResult({
    required this.deviceUuid,
    required this.apiKey,
    required this.message,
  });

  final String deviceUuid;
  final String apiKey;
  final String message;
}

class OdooPushBatchResult {
  const OdooPushBatchResult({
    required this.ok,
    required this.message,
    required this.acceptedRecords,
    required this.failedRecords,
  });

  final bool ok;
  final String message;
  final int acceptedRecords;
  final int failedRecords;
}

class OdooMasterDataSnapshot {
  const OdooMasterDataSnapshot({
    required this.products,
    required this.customers,
    required this.employees,
    required this.warehouses,
    required this.terminals,
    this.message,
  });

  final List<Map<String, Object?>> products;
  final List<Map<String, Object?>> customers;
  final List<Map<String, Object?>> employees;
  final List<Map<String, Object?>> warehouses;
  final List<Map<String, Object?>> terminals;
  final String? message;
}

class OdooWorkOrdersSnapshot {
  const OdooWorkOrdersSnapshot({
    required this.workOrders,
    this.message,
  });

  final List<Map<String, Object?>> workOrders;
  final String? message;
}

class CloudSyncBootstrapSummary {
  const CloudSyncBootstrapSummary({
    required this.productsQueued,
    required this.customersQueued,
    required this.employeesQueued,
    required this.warehousesQueued,
    required this.terminalsQueued,
    required this.salesQueued,
    required this.stockMovementsQueued,
    required this.workOrdersQueued,
  });

  final int productsQueued;
  final int customersQueued;
  final int employeesQueued;
  final int warehousesQueued;
  final int terminalsQueued;
  final int salesQueued;
  final int stockMovementsQueued;
  final int workOrdersQueued;

  int get totalQueued =>
      productsQueued +
      customersQueued +
      employeesQueued +
      warehousesQueued +
      terminalsQueued +
      salesQueued +
      stockMovementsQueued +
      workOrdersQueued;
}
