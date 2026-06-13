import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/device_identity_service.dart';
import 'cloud_sync_models.dart';

class CloudSyncLocalDataSource {
  CloudSyncLocalDataSource(
    this._db, {
    DeviceIdentityService? deviceIdentityService,
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _deviceIdentityService =
            deviceIdentityService ?? DeviceIdentityService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final DeviceIdentityService _deviceIdentityService;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  static const String _prefix = 'sync_cloud.';
  static const String _enabledKey = '${_prefix}enabled';
  static const String _serverUrlKey = '${_prefix}server_url';
  static const String _databaseNameKey = '${_prefix}database_name';
  static const String _deviceLabelKey = '${_prefix}device_label';
  static const String _autoPullCatalogsKey = '${_prefix}auto_pull_catalogs';
  static const String _autoPushSalesKey = '${_prefix}auto_push_sales';
  static const String _autoPushInventoryKey = '${_prefix}auto_push_inventory';
  static const String _autoPushOrdersKey = '${_prefix}auto_push_orders';
  static const String _registeredDeviceUuidKey =
      '${_prefix}registered_device_uuid';
  static const String _lastPushAtKey = '${_prefix}last_push_at';
  static const String _lastPullAtKey = '${_prefix}last_pull_at';
  static const String _serverProfileKey = '${_prefix}server_profile';
  static const String _fullResyncRequiredKey = '${_prefix}full_resync_required';
  static const String _bootstrapTokenSecureKey =
      '${_prefix}bootstrap_token_secure';
  static const String _apiKeySecureKey = '${_prefix}api_key_secure';

  Future<CloudSyncConfig> loadConfig() async {
    final Map<String, String> values = await _loadSettings(
      <String>[
        _enabledKey,
        _serverUrlKey,
        _databaseNameKey,
        _deviceLabelKey,
        _autoPullCatalogsKey,
        _autoPushSalesKey,
        _autoPushInventoryKey,
        _autoPushOrdersKey,
        _registeredDeviceUuidKey,
        _lastPushAtKey,
        _lastPullAtKey,
        _fullResyncRequiredKey,
      ],
    );
    final String resolvedLabel =
        values[_deviceLabelKey]?.trim().isNotEmpty == true
            ? values[_deviceLabelKey]!.trim()
            : (await _deviceIdentityService.getIdentity()).displayName;
    return CloudSyncConfig(
      enabled: _boolValue(values[_enabledKey], fallback: false),
      serverUrl: values[_serverUrlKey]?.trim() ?? '',
      databaseName: values[_databaseNameKey]?.trim() ?? '',
      deviceLabel: resolvedLabel,
      autoPullCatalogs:
          _boolValue(values[_autoPullCatalogsKey], fallback: true),
      autoPushSales: _boolValue(values[_autoPushSalesKey], fallback: true),
      autoPushInventory:
          _boolValue(values[_autoPushInventoryKey], fallback: true),
      autoPushOrders: _boolValue(values[_autoPushOrdersKey], fallback: true),
      registeredDeviceUuid: _nullableValue(values[_registeredDeviceUuidKey]),
      lastPushAt: _dateValue(values[_lastPushAtKey]),
      lastPullAt: _dateValue(values[_lastPullAtKey]),
      fullResyncRequired:
          _boolValue(values[_fullResyncRequiredKey], fallback: false),
    );
  }

  Future<bool> saveConfig(CloudSyncConfig config) async {
    final Map<String, String> current = await _loadSettings(
      <String>[_serverUrlKey, _databaseNameKey, _serverProfileKey],
    );
    final String previousProfile = _nullableValue(current[_serverProfileKey]) ??
        _buildServerProfile(
          current[_serverUrlKey] ?? '',
          current[_databaseNameKey] ?? '',
        );
    final String nextProfile = _buildServerProfile(
      config.serverUrl,
      config.databaseName,
    );
    final bool profileChanged = previousProfile.isNotEmpty &&
        nextProfile.isNotEmpty &&
        previousProfile != nextProfile;

    if (profileChanged) {
      await _clearServerBindingState();
    }

    await _writeSetting(_enabledKey, config.enabled ? '1' : '0');
    await _writeSetting(_serverUrlKey, config.serverUrl.trim());
    await _writeSetting(_databaseNameKey, config.databaseName.trim());
    await _writeSetting(_deviceLabelKey, config.deviceLabel.trim());
    await _writeSetting(
      _autoPullCatalogsKey,
      config.autoPullCatalogs ? '1' : '0',
    );
    await _writeSetting(_autoPushSalesKey, config.autoPushSales ? '1' : '0');
    await _writeSetting(
      _autoPushInventoryKey,
      config.autoPushInventory ? '1' : '0',
    );
    await _writeSetting(_autoPushOrdersKey, config.autoPushOrders ? '1' : '0');
    if (config.registeredDeviceUuid == null ||
        config.registeredDeviceUuid!.trim().isEmpty) {
      await _deleteSetting(_registeredDeviceUuidKey);
    } else {
      await _writeSetting(
        _registeredDeviceUuidKey,
        config.registeredDeviceUuid!.trim(),
      );
    }
    await _setDateSetting(_lastPushAtKey, config.lastPushAt);
    await _setDateSetting(_lastPullAtKey, config.lastPullAt);
    await _writeSetting(_serverProfileKey, nextProfile);
    await _writeSetting(
      _fullResyncRequiredKey,
      (profileChanged || config.fullResyncRequired) ? '1' : '0',
    );
    return profileChanged;
  }

  Future<CloudSyncCredentials> loadCredentials() async {
    final String? bootstrapToken =
        await _secureStorage.read(key: _bootstrapTokenSecureKey);
    final String? apiKey = await _secureStorage.read(key: _apiKeySecureKey);
    return CloudSyncCredentials(
      bootstrapToken: _nullableValue(bootstrapToken),
      apiKey: _nullableValue(apiKey),
    );
  }

  Future<void> saveBootstrapToken(String? value) async {
    final String? normalized = _nullableValue(value);
    if (normalized == null) {
      await _secureStorage.delete(key: _bootstrapTokenSecureKey);
      return;
    }
    await _secureStorage.write(
      key: _bootstrapTokenSecureKey,
      value: normalized,
    );
  }

  Future<void> saveApiKey(String? value) async {
    final String? normalized = _nullableValue(value);
    if (normalized == null) {
      await _secureStorage.delete(key: _apiKeySecureKey);
      return;
    }
    await _secureStorage.write(
      key: _apiKeySecureKey,
      value: normalized,
    );
  }

  Future<String> resolveLocalDeviceUuid() async {
    final identity = await _deviceIdentityService.getIdentity();
    return identity.fingerprintHash;
  }

  Future<void> enqueueChange({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, Object?> payload,
    String? sourceModule,
  }) async {
    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            id: _uuid.v4(),
            entityType: entityType.trim(),
            entityId: entityId.trim(),
            operation: operation.trim(),
            payloadJson: jsonEncode(payload),
            sourceModule: Value(_nullableValue(sourceModule)),
          ),
        );
  }

  Map<String, Object?> buildWorkOrderSyncPayload(
    WorkOrder order, {
    bool isActive = true,
    String? overrideStatus,
  }) {
    return <String, Object?>{
      'id': order.id,
      'folio': order.folio,
      'customer_name': _nullableValue(order.customerNameSnapshot),
      'title': order.title,
      'description': _nullableValue(order.description),
      'status': overrideStatus ?? order.status,
      'payment_status': order.paymentStatus,
      'priority': order.priority,
      'qty': order.qty,
      'unit_label': _nullableValue(order.unitLabel),
      'work_type': _nullableValue(order.workType),
      'note': _nullableValue(order.note),
      'created_at': order.createdAt.toIso8601String(),
      'updated_at': (order.updatedAt ?? order.createdAt).toIso8601String(),
      'due_at': order.dueAt?.toIso8601String(),
      'completed_at': order.completedAt?.toIso8601String(),
      'delivered_at': order.deliveredAt?.toIso8601String(),
      'paid_at': order.paidAt?.toIso8601String(),
      'created_by': order.createdBy,
      'updated_by': _nullableValue(order.updatedBy),
      'customer_id': _nullableValue(order.customerId),
      'assigned_employee_id': _nullableValue(order.assignedEmployeeId),
      'assigned_employee_name':
          _nullableValue(order.assignedEmployeeNameSnapshot),
      'items': _jsonList(order.itemsJson),
      'assignments': _jsonList(order.assignmentsJson),
      'tasks': _jsonList(order.tasksJson),
      'quoted_totals': _jsonList(order.quotedTotalsJson),
      'quoted_requested_lines': _jsonList(order.quotedRequestedLinesJson),
      'quoted_payment_variants': _jsonList(order.quotedPaymentVariantsJson),
      'pricing_snapshot': _jsonMap(order.pricingSnapshotJson),
      'payment_lines': _jsonList(order.paymentLinesJson),
      'is_active': isActive,
    };
  }

  Future<void> enqueueWorkOrderUpsert(
    WorkOrder order, {
    bool isActive = true,
    String? overrideStatus,
    String sourceModule = 'pedidos',
  }) {
    return enqueueChange(
      entityType: 'work_orders',
      entityId: order.id,
      operation: 'upsert',
      payload: buildWorkOrderSyncPayload(
        order,
        isActive: isActive,
        overrideStatus: overrideStatus,
      ),
      sourceModule: sourceModule,
    );
  }

  Future<List<SyncQueueEntry>> listPendingEntries({
    int limit = 100,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT id, entity_type, entity_id, operation, payload_json, source_module,
             status, retry_count, last_error, created_at, updated_at
      FROM sync_queue_entries
      WHERE status IN ('pending', 'failed')
      ORDER BY created_at ASC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[Variable<int>(limit)],
    ).get();
    return rows
        .map(
          (QueryRow row) => SyncQueueEntry(
            id: row.read<String>('id'),
            entityType: row.read<String>('entity_type'),
            entityId: row.read<String>('entity_id'),
            operation: row.read<String>('operation'),
            payloadJson: row.read<String>('payload_json'),
            sourceModule: row.readNullable<String>('source_module'),
            status: row.read<String>('status'),
            retryCount: _intFromObject(row.data['retry_count']),
            lastError: row.readNullable<String>('last_error'),
            createdAt:
                _dateFromObject(row.data['created_at']) ?? DateTime.now(),
            updatedAt: _dateFromObject(row.data['updated_at']),
          ),
        )
        .toList(growable: false);
  }

  Future<List<CloudSyncQueueEntryView>> listQueueEntries({
    int limit = 25,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT id, entity_type, entity_id, operation, source_module,
             status, retry_count, last_error, created_at
      FROM sync_queue_entries
      ORDER BY created_at DESC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[Variable<int>(limit)],
    ).get();
    return rows
        .map(
          (QueryRow row) => CloudSyncQueueEntryView(
            id: row.read<String>('id'),
            entityType: row.read<String>('entity_type'),
            entityId: row.read<String>('entity_id'),
            operation: row.read<String>('operation'),
            status: row.read<String>('status'),
            retryCount: _intFromObject(row.data['retry_count']),
            createdAt:
                _dateFromObject(row.data['created_at']) ?? DateTime.now(),
            sourceModule: row.readNullable<String>('source_module'),
            lastError: row.readNullable<String>('last_error'),
          ),
        )
        .toList(growable: false);
  }

  Future<CloudSyncQueueStats> loadQueueStats() async {
    Future<int> countByStatus(List<String> statuses) async {
      final rows = await _db.customSelect(
        '''
        SELECT COUNT(*) AS total
        FROM sync_queue_entries
        WHERE status IN (${List<String>.filled(statuses.length, '?').join(', ')})
        ''',
        variables:
            statuses.map((String value) => Variable<String>(value)).toList(),
      ).getSingle();
      return (rows.readNullable<int>('total') ?? 0);
    }

    return CloudSyncQueueStats(
      pending: await countByStatus(const <String>['pending']),
      processing: await countByStatus(const <String>['processing']),
      failed: await countByStatus(const <String>['failed']),
      done: await countByStatus(const <String>['done']),
    );
  }

  Future<void> markEntriesProcessing(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await (_db.update(_db.syncQueueEntries)
          ..where((SyncQueueEntries tbl) => tbl.id.isIn(ids)))
        .write(
      SyncQueueEntriesCompanion(
        status: const Value('processing'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markEntriesDone(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await (_db.update(_db.syncQueueEntries)
          ..where((SyncQueueEntries tbl) => tbl.id.isIn(ids)))
        .write(
      SyncQueueEntriesCompanion(
        status: const Value('done'),
        lastError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markEntriesFailed(List<String> ids, String error) async {
    if (ids.isEmpty) {
      return;
    }
    await _db.customStatement(
      '''
      UPDATE sync_queue_entries
      SET
        status = 'failed',
        retry_count = retry_count + 1,
        last_error = ?,
        updated_at = ?
      WHERE id IN (${List<String>.filled(ids.length, '?').join(', ')})
      ''',
      <Object?>[
        error.trim(),
        DateTime.now().toIso8601String(),
        ...ids,
      ],
    );
  }

  Future<String> createSyncRun({
    required String direction,
  }) async {
    final String id = _uuid.v4();
    await _db.into(_db.syncRuns).insert(
          SyncRunsCompanion.insert(
            id: id,
            direction: direction.trim(),
          ),
        );
    return id;
  }

  Future<void> finishSyncRun({
    required String runId,
    required String status,
    required int requestCount,
    required int recordCount,
    Map<String, Object?>? summary,
    String? errorMessage,
  }) async {
    await (_db.update(_db.syncRuns)
          ..where((SyncRuns tbl) => tbl.id.equals(runId)))
        .write(
      SyncRunsCompanion(
        status: Value(status.trim()),
        requestCount: Value(requestCount),
        recordCount: Value(recordCount),
        summaryJson: Value(jsonEncode(summary ?? <String, Object?>{})),
        errorMessage: Value(_nullableValue(errorMessage)),
        finishedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateLastPushAt(DateTime value) =>
      _writeSetting(_lastPushAtKey, value.toIso8601String());

  Future<void> updateLastPullAt(DateTime value) =>
      _writeSetting(_lastPullAtKey, value.toIso8601String());

  Future<void> markFullResyncPrepared() =>
      _writeSetting(_fullResyncRequiredKey, '0');

  Future<void> importMasterDataSnapshot(OdooMasterDataSnapshot snapshot) async {
    await _db.transaction(() async {
      final DateTime now = DateTime.now();
      final Set<String> importedWarehouseIds =
          await _importWarehouses(snapshot.warehouses, now);
      await _importProducts(snapshot.products, now);
      await _importCustomers(snapshot.customers, now);
      await _importEmployees(snapshot.employees, now);
      await _importTerminals(snapshot.terminals, importedWarehouseIds, now);
    });
  }

  Future<void> importWorkOrdersSnapshot(
    OdooWorkOrdersSnapshot snapshot,
  ) async {
    await _db.transaction(() async {
      final DateTime now = DateTime.now();
      final String syncUserId = await _resolveSyncUserId();
      final Set<String> customerIds =
          (await (_db.select(_db.customers)).get()).map((e) => e.id).toSet();
      final Set<String> employeeIds =
          (await (_db.select(_db.employees)).get()).map((e) => e.id).toSet();
      final Set<String> productIds =
          (await (_db.select(_db.products)).get()).map((e) => e.id).toSet();
      await _importWorkOrders(
        snapshot.workOrders,
        now: now,
        syncUserId: syncUserId,
        existingCustomerIds: customerIds,
        existingEmployeeIds: employeeIds,
        existingProductIds: productIds,
      );
    });
  }

  Future<CloudSyncBootstrapSummary> prepareInitialSyncBackfill() async {
    final Set<String> existingQueueKeys = await _loadExistingQueueKeys();
    int productsQueued = 0;
    int customersQueued = 0;
    int employeesQueued = 0;
    int warehousesQueued = 0;
    int terminalsQueued = 0;
    int salesQueued = 0;
    int stockMovementsQueued = 0;
    int workOrdersQueued = 0;

    final List<Product> products = await (_db.select(_db.products)).get();
    for (final Product product in products) {
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'products',
        entityId: product.id,
        sourceModule: 'productos',
        payload: <String, Object?>{
          'id': product.id,
          'sku': product.sku,
          'barcode': product.barcode,
          'name': product.name,
          'sale_price': product.priceCents / 100,
          'cost_price': product.costPriceCents / 100,
          'currency_code': product.currencyCode,
          'category': product.category,
          'product_type': product.productType,
          'unit_measure': product.unitMeasure,
          'order_costing_mode': product.orderCostingMode,
          'is_active': product.isActive,
          'updated_at':
              (product.updatedAt ?? product.createdAt).toIso8601String(),
        },
      );
      if (queued) {
        productsQueued++;
      }
    }

    final List<Customer> customers = await (_db.select(_db.customers)).get();
    for (final Customer customer in customers) {
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'customers',
        entityId: customer.id,
        sourceModule: 'clientes',
        payload: <String, Object?>{
          'id': customer.id,
          'code': customer.code,
          'name': customer.fullName,
          'identity_number': customer.identityNumber,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'company': customer.company,
          'customer_type': customer.customerType,
          'is_vip': customer.isVip,
          'discount_bps': customer.discountBps,
          'is_active': customer.isActive,
          'updated_at':
              (customer.updatedAt ?? customer.createdAt).toIso8601String(),
        },
      );
      if (queued) {
        customersQueued++;
      }
    }

    final List<Employee> employees = await (_db.select(_db.employees)).get();
    final List<User> users = await (_db.select(_db.users)).get();
    final Map<String, User> userById = <String, User>{
      for (final User user in users) user.id: user,
    };
    for (final Employee employee in employees) {
      final String? associatedUsername =
          userById[employee.associatedUserId ?? '']?.username;
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'employees',
        entityId: employee.id,
        sourceModule: 'empleados',
        payload: <String, Object?>{
          'id': employee.id,
          'code': employee.code,
          'name': employee.name,
          'sex': employee.sex,
          'identity_number': employee.identityNumber,
          'associated_username': associatedUsername,
          'is_active': employee.isActive,
          'updated_at':
              (employee.updatedAt ?? employee.createdAt).toIso8601String(),
        },
      );
      if (queued) {
        employeesQueued++;
      }
    }

    final List<Warehouse> warehouses = await (_db.select(_db.warehouses)).get();
    for (final Warehouse warehouse in warehouses) {
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'warehouses',
        entityId: warehouse.id,
        sourceModule: 'almacenes',
        payload: <String, Object?>{
          'id': warehouse.id,
          'name': warehouse.name,
          'warehouse_type': warehouse.warehouseType,
          'is_active': warehouse.isActive,
          'updated_at': warehouse.createdAt.toIso8601String(),
        },
      );
      if (queued) {
        warehousesQueued++;
      }
    }

    final List<PosTerminal> terminals =
        await (_db.select(_db.posTerminals)).get();
    for (final PosTerminal terminal in terminals) {
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'terminals',
        entityId: terminal.id,
        sourceModule: 'tpv',
        payload: <String, Object?>{
          'id': terminal.id,
          'code': terminal.code,
          'name': terminal.name,
          'warehouse_id': terminal.warehouseId,
          'currency_code': terminal.currencyCode,
          'payment_methods': _normalizedStringList(
            _safeJsonDecode(terminal.paymentMethodsJson),
          ),
          'is_active': terminal.isActive,
          'updated_at':
              (terminal.updatedAt ?? terminal.createdAt).toIso8601String(),
        },
      );
      if (queued) {
        terminalsQueued++;
      }
    }

    final List<Sale> sales = await (_db.select(_db.sales)).get();
    for (final Sale sale in sales) {
      final Map<String, Object?> payload = await _buildSaleSyncPayload(sale.id);
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'sales',
        entityId: sale.id,
        sourceModule: 'ventas',
        payload: payload,
      );
      if (queued) {
        salesQueued++;
      }
    }

    final List<StockMovement> stockMovements =
        await (_db.select(_db.stockMovements)).get();
    for (final StockMovement movement in stockMovements) {
      final Map<String, Object?> payload =
          await _buildStockMovementSyncPayload(movement.id);
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'stock_movements',
        entityId: movement.id,
        sourceModule: 'inventario',
        payload: payload,
      );
      if (queued) {
        stockMovementsQueued++;
      }
    }

    final List<WorkOrder> workOrders = await (_db.select(_db.workOrders)).get();
    for (final WorkOrder order in workOrders) {
      final bool queued = await _enqueueIfMissing(
        existingQueueKeys: existingQueueKeys,
        entityType: 'work_orders',
        entityId: order.id,
        sourceModule: 'pedidos',
        payload: buildWorkOrderSyncPayload(order),
      );
      if (queued) {
        workOrdersQueued++;
      }
    }

    return CloudSyncBootstrapSummary(
      productsQueued: productsQueued,
      customersQueued: customersQueued,
      employeesQueued: employeesQueued,
      warehousesQueued: warehousesQueued,
      terminalsQueued: terminalsQueued,
      salesQueued: salesQueued,
      stockMovementsQueued: stockMovementsQueued,
      workOrdersQueued: workOrdersQueued,
    );
  }

  Future<Map<String, Object?>> _buildSaleSyncPayload(String saleId) async {
    final QueryRow header = await _db.customSelect(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS folio,
        s.status AS status,
        s.created_at AS created_at,
        s.subtotal_cents AS subtotal_cents,
        s.tax_cents AS tax_cents,
        s.total_cents AS total_cents,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(u.username, 'Sin usuario') AS cashier_name,
        t.name AS terminal_name,
        c.full_name AS customer_name
      FROM sales s
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      LEFT JOIN users u ON u.id = s.cashier_id
      LEFT JOIN pos_terminals t ON t.id = s.terminal_id
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE s.id = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(saleId.trim())],
    ).getSingle();
    final List<QueryRow> lineRows = await _db.customSelect(
      '''
      SELECT
        si.id AS sale_item_id,
        si.qty AS qty,
        si.unit_price_cents AS unit_price_cents,
        si.unit_cost_cents AS unit_cost_cents,
        si.tax_rate_bps AS tax_rate_bps,
        si.line_total_cents AS line_total_cents,
        COALESCE(p.name, 'Producto') AS product_name,
        COALESCE(p.sku, '-') AS product_sku
      FROM sale_items si
      LEFT JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
      ORDER BY si.id ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(saleId.trim())],
    ).get();
    final List<QueryRow> paymentRows = await _db.customSelect(
      '''
      SELECT
        id,
        method,
        amount_cents,
        transaction_id,
        source_currency_code,
        source_amount_cents,
        created_at
      FROM payments
      WHERE sale_id = ?
      ORDER BY created_at ASC, id ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(saleId.trim())],
    ).get();
    return <String, Object?>{
      'id': saleId.trim(),
      'folio': (header.readNullable<String>('folio') ?? '').trim(),
      'warehouse_name':
          (header.readNullable<String>('warehouse_name') ?? 'Sin almacén')
              .trim(),
      'terminal_name':
          _nullableValue(header.readNullable<String>('terminal_name')),
      'cashier_name':
          (header.readNullable<String>('cashier_name') ?? 'Sin usuario').trim(),
      'customer_name':
          _nullableValue(header.readNullable<String>('customer_name')),
      'subtotal': _amountFromCents(header.data['subtotal_cents']),
      'tax': _amountFromCents(header.data['tax_cents']),
      'total': _amountFromCents(header.data['total_cents']),
      'status': (header.readNullable<String>('status') ?? 'posted').trim(),
      'created_at': header.read<DateTime>('created_at').toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'is_active':
          (header.readNullable<String>('status') ?? '').trim().toLowerCase() !=
              'deleted',
      'lines': lineRows.map((QueryRow row) {
        return <String, Object?>{
          'id': (row.readNullable<String>('sale_item_id') ?? '').trim(),
          'product_name':
              (row.readNullable<String>('product_name') ?? 'Producto').trim(),
          'product_sku':
              (row.readNullable<String>('product_sku') ?? '-').trim(),
          'qty': (row.data['qty'] as num?)?.toDouble() ?? 0,
          'unit_price': _amountFromCents(row.data['unit_price_cents']),
          'unit_cost': _amountFromCents(row.data['unit_cost_cents']),
          'tax_rate_bps': (row.data['tax_rate_bps'] as num?)?.toInt() ?? 0,
          'line_total': _amountFromCents(row.data['line_total_cents']),
        };
      }).toList(growable: false),
      'payments': paymentRows.map((QueryRow row) {
        final DateTime? createdAt = row.readNullable<DateTime>('created_at');
        return <String, Object?>{
          'id': (row.readNullable<String>('id') ?? '').trim(),
          'method': (row.readNullable<String>('method') ?? '').trim(),
          'amount': _amountFromCents(row.data['amount_cents']),
          'transaction_id':
              _nullableValue(row.readNullable<String>('transaction_id')),
          'source_currency_code':
              _nullableValue(row.readNullable<String>('source_currency_code')),
          'source_amount': _amountFromCents(
            row.data['source_amount_cents'],
            allowNull: true,
          ),
          'created_at': createdAt?.toIso8601String(),
        };
      }).toList(growable: false),
    };
  }

  Future<Map<String, Object?>> _buildStockMovementSyncPayload(
    String movementId,
  ) async {
    final QueryRow row = await _db.customSelect(
      '''
      SELECT
        sm.id AS id,
        sm.type AS type,
        sm.qty AS qty,
        sm.reason_code AS reason_code,
        sm.movement_source AS movement_source,
        sm.ref_type AS ref_type,
        sm.ref_id AS ref_id,
        sm.note AS note,
        sm.is_voided AS is_voided,
        sm.created_at AS created_at,
        COALESCE(p.name, 'Producto') AS product_name,
        COALESCE(p.sku, '-') AS product_sku,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(u.username, sm.created_by) AS created_by_name
      FROM stock_movements sm
      LEFT JOIN products p ON p.id = sm.product_id
      LEFT JOIN warehouses w ON w.id = sm.warehouse_id
      LEFT JOIN users u ON u.id = sm.created_by
      WHERE sm.id = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(movementId.trim())],
    ).getSingle();
    return <String, Object?>{
      'id': (row.readNullable<String>('id') ?? movementId).trim(),
      'product_name':
          (row.readNullable<String>('product_name') ?? 'Producto').trim(),
      'product_sku': (row.readNullable<String>('product_sku') ?? '-').trim(),
      'warehouse_name':
          (row.readNullable<String>('warehouse_name') ?? 'Sin almacén').trim(),
      'type': (row.readNullable<String>('type') ?? '').trim(),
      'qty': (row.data['qty'] as num?)?.toDouble() ?? 0,
      'reason_code': _nullableValue(row.readNullable<String>('reason_code')),
      'movement_source':
          _nullableValue(row.readNullable<String>('movement_source')),
      'ref_type': _nullableValue(row.readNullable<String>('ref_type')),
      'ref_id': _nullableValue(row.readNullable<String>('ref_id')),
      'note': _nullableValue(row.readNullable<String>('note')),
      'is_voided': _boolFromDbValue(row.data['is_voided']),
      'created_by_name':
          (row.readNullable<String>('created_by_name') ?? '').trim(),
      'created_at': row.read<DateTime>('created_at').toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, String>> _loadSettings(List<String> keys) async {
    if (keys.isEmpty) {
      return <String, String>{};
    }
    final String placeholders =
        List<String>.filled(keys.length, '?').join(', ');
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT key, value
      FROM app_settings
      WHERE key IN ($placeholders)
      ''',
      variables: keys.map((String key) => Variable<String>(key)).toList(),
    ).get();
    return <String, String>{
      for (final QueryRow row in rows)
        (row.read<String>('key')).trim(): row.read<String>('value'),
    };
  }

  Future<void> _writeSetting(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> _deleteSetting(String key) async {
    await (_db.delete(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(key)))
        .go();
  }

  Future<void> _setDateSetting(String key, DateTime? value) async {
    if (value == null) {
      await _deleteSetting(key);
      return;
    }
    await _writeSetting(key, value.toIso8601String());
  }

  bool _boolValue(String? raw, {required bool fallback}) {
    final String clean = (raw ?? '').trim().toLowerCase();
    if (clean == '1' || clean == 'true' || clean == 'yes') {
      return true;
    }
    if (clean == '0' || clean == 'false' || clean == 'no') {
      return false;
    }
    return fallback;
  }

  DateTime? _dateValue(String? raw) {
    final String clean = (raw ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return DateTime.tryParse(clean);
  }

  DateTime? _dateFromObject(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    final String clean = raw.toString().trim();
    if (clean.isEmpty) {
      return null;
    }
    final int? asInt = int.tryParse(clean);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(clean);
  }

  int _intFromObject(Object? raw, {int fallback = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    final String clean = raw?.toString().trim() ?? '';
    return int.tryParse(clean) ?? fallback;
  }

  String? _nullableValue(String? raw) {
    final String clean = (raw ?? '').trim();
    return clean.isEmpty ? null : clean;
  }

  Future<Set<String>> _loadExistingQueueKeys() async {
    final List<SyncQueueEntry> rows = await (_db.select(_db.syncQueueEntries)
          ..where(
            (SyncQueueEntries tbl) => tbl.status.isIn(
              const <String>['pending', 'processing', 'failed'],
            ),
          ))
        .get();
    return rows
        .map((SyncQueueEntry row) => _queueKey(row.entityType, row.entityId))
        .toSet();
  }

  Future<void> _clearServerBindingState() async {
    await _deleteSetting(_registeredDeviceUuidKey);
    await _deleteSetting(_lastPushAtKey);
    await _deleteSetting(_lastPullAtKey);
    await _secureStorage.delete(key: _apiKeySecureKey);
    await _db.transaction(() async {
      await _db.delete(_db.syncQueueEntries).go();
      await _db.delete(_db.syncRuns).go();
    });
  }

  String _buildServerProfile(String serverUrl, String databaseName) {
    final String normalizedUrl = _normalizeServerUrl(serverUrl);
    final String normalizedDb = databaseName.trim().toLowerCase();
    if (normalizedUrl.isEmpty || normalizedDb.isEmpty) {
      return '';
    }
    return '$normalizedUrl|$normalizedDb';
  }

  String _normalizeServerUrl(String value) {
    String normalized = value.trim().toLowerCase();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  Future<bool> _enqueueIfMissing({
    required Set<String> existingQueueKeys,
    required String entityType,
    required String entityId,
    required String sourceModule,
    required Map<String, Object?> payload,
  }) async {
    final String key = _queueKey(entityType, entityId);
    if (existingQueueKeys.contains(key)) {
      return false;
    }
    await enqueueChange(
      entityType: entityType,
      entityId: entityId,
      operation: 'upsert',
      payload: payload,
      sourceModule: sourceModule,
    );
    existingQueueKeys.add(key);
    return true;
  }

  Future<void> _importProducts(
    List<Map<String, Object?>> items,
    DateTime now,
  ) async {
    for (final Map<String, Object?> item in items) {
      final String externalId = _prefixedExternalId('product', item['id']);
      final String sku =
          _normalizedString(item['sku']) ?? 'ODOO-P-${_idSuffix(item['id'])}';
      final String name = _normalizedString(item['name']) ??
          'Producto Odoo ${_idSuffix(item['id'])}';
      final String category = _normalizedString(item['category']) ?? 'General';
      final String productType = _mapProductType(item['product_type']);
      final String unitMeasure =
          _normalizedString(item['unit_measure']) ?? 'Unidad';
      final String currencyCode =
          (_normalizedString(item['currency_code']) ?? 'USD').toUpperCase();
      final DateTime? updatedAt = _dateTime(item['updated_at']);
      await _db.into(_db.products).insertOnConflictUpdate(
            ProductsCompanion(
              id: Value(externalId),
              sku: Value(sku),
              barcode: Value(_normalizedString(item['barcode'])),
              name: Value(name),
              priceCents:
                  Value(_moneyToCents(item['sale_price'] ?? item['price'])),
              taxRateBps: const Value(0),
              imagePath: const Value(null),
              costPriceCents: Value(_moneyToCents(item['cost_price'])),
              category: Value(category),
              productType: Value(productType),
              unitMeasure: Value(unitMeasure),
              orderCostingMode: const Value('ordered_qty'),
              currencyCode: Value(currencyCode),
              isActive:
                  Value(_boolValueFromObject(item['active'], fallback: true)),
              createdAt: Value(updatedAt ?? now),
              updatedAt: Value(updatedAt ?? now),
            ),
          );
      await _upsertProductCatalogItem(
        kind: 'category',
        value: category,
        now: now,
      );
      await _upsertProductCatalogItem(
        kind: 'type',
        value: productType,
        now: now,
      );
      await _upsertProductCatalogItem(
        kind: 'unit',
        value: unitMeasure,
        now: now,
      );
    }
  }

  Future<void> _importCustomers(
    List<Map<String, Object?>> items,
    DateTime now,
  ) async {
    for (final Map<String, Object?> item in items) {
      final String externalId = _prefixedExternalId('customer', item['id']);
      final String code =
          _normalizedString(item['code']) ?? 'ODOO-C-${_idSuffix(item['id'])}';
      final String fullName = _normalizedString(item['name']) ??
          'Cliente Odoo ${_idSuffix(item['id'])}';
      final DateTime? updatedAt = _dateTime(item['updated_at']);
      await _db.into(_db.customers).insertOnConflictUpdate(
            CustomersCompanion(
              id: Value(externalId),
              code: Value(code),
              fullName: Value(fullName),
              identityNumber: Value(
                _normalizedString(item['identity_number']) ??
                    _normalizedString(item['vat']),
              ),
              phone: Value(_normalizedString(item['phone'])),
              email: Value(_normalizedString(item['email'])),
              address: Value(
                _normalizedString(item['address']) ??
                    _normalizedString(item['street']),
              ),
              company: Value(_normalizedString(item['company'])),
              avatarPath: const Value(null),
              customerType: Value(
                _normalizedString(item['customer_type']) ?? 'general',
              ),
              isVip:
                  Value(_boolValueFromObject(item['is_vip'], fallback: false)),
              creditAvailableCents: const Value(0),
              discountBps: Value(_intValue(item['discount_bps'])),
              adminNote: const Value('Sincronizado desde Odoo'),
              isActive: Value(
                _boolValueFromObject(
                  item['active'] ?? item['is_active'],
                  fallback: true,
                ),
              ),
              createdAt: Value(updatedAt ?? now),
              updatedAt: Value(updatedAt ?? now),
            ),
          );
    }
  }

  Future<void> _importEmployees(
    List<Map<String, Object?>> items,
    DateTime now,
  ) async {
    for (final Map<String, Object?> item in items) {
      final String externalId = _prefixedExternalId('employee', item['id']);
      final String code =
          _normalizedString(item['code']) ?? 'ODOO-E-${_idSuffix(item['id'])}';
      final String name = _normalizedString(item['name']) ??
          'Empleado Odoo ${_idSuffix(item['id'])}';
      final DateTime? updatedAt = _dateTime(item['updated_at']);
      await _db.into(_db.employees).insertOnConflictUpdate(
            EmployeesCompanion(
              id: Value(externalId),
              code: Value(code),
              name: Value(name),
              sex: Value(
                _normalizedString(item['sex']) ??
                    _normalizedString(item['gender']),
              ),
              identityNumber: Value(
                _normalizedString(item['identity_number']) ??
                    _normalizedString(item['identification_id']),
              ),
              address: const Value(null),
              imagePath: const Value(null),
              associatedUserId: const Value(null),
              isActive: Value(
                _boolValueFromObject(
                  item['active'] ?? item['is_active'],
                  fallback: true,
                ),
              ),
              createdAt: Value(updatedAt ?? now),
              updatedAt: Value(updatedAt ?? now),
            ),
          );
    }
  }

  Future<Set<String>> _importWarehouses(
    List<Map<String, Object?>> items,
    DateTime now,
  ) async {
    final Set<String> importedIds = <String>{};
    for (final Map<String, Object?> item in items) {
      final String externalId = _prefixedExternalId('warehouse', item['id']);
      importedIds.add(externalId);
      final String name = _normalizedString(item['name']) ??
          'Almacén Odoo ${_idSuffix(item['id'])}';
      await _db.into(_db.warehouses).insertOnConflictUpdate(
            WarehousesCompanion(
              id: Value(externalId),
              name: Value(name),
              warehouseType: Value(
                _normalizedString(item['warehouse_type']) ?? 'Central',
              ),
              isActive: Value(
                _boolValueFromObject(
                  item['active'] ?? item['is_active'],
                  fallback: true,
                ),
              ),
              createdAt: Value(_dateTime(item['updated_at']) ?? now),
            ),
          );
    }
    return importedIds;
  }

  Future<void> _importTerminals(
    List<Map<String, Object?>> items,
    Set<String> importedWarehouseIds,
    DateTime now,
  ) async {
    final Set<String> usedWarehouseIds = <String>{};
    final existingTerminals = await (_db.select(_db.posTerminals)).get();
    for (final PosTerminal terminal in existingTerminals) {
      usedWarehouseIds.add(terminal.warehouseId);
    }

    for (final Map<String, Object?> item in items) {
      final String externalId = _prefixedExternalId('terminal', item['id']);
      final String? warehouseId = _warehouseExternalIdFromSnapshot(item);
      if (warehouseId == null || !importedWarehouseIds.contains(warehouseId)) {
        continue;
      }

      final PosTerminal? existing = await (_db.select(_db.posTerminals)
            ..where((PosTerminals tbl) => tbl.id.equals(externalId)))
          .getSingleOrNull();
      if (existing == null && usedWarehouseIds.contains(warehouseId)) {
        continue;
      }

      final String code = _normalizedString(item['code']) ??
          'ODOO-TPV-${_idSuffix(item['id'])}';
      final String name = _normalizedString(item['name']) ??
          'TPV Odoo ${_idSuffix(item['id'])}';
      final String currencyCode =
          (_normalizedString(item['currency_code']) ?? 'USD').toUpperCase();
      final String currencySymbol = _currencySymbolFromCode(currencyCode);
      final List<String> paymentMethods =
          _normalizedStringList(item['payment_methods']);
      final DateTime? updatedAt = _dateTime(item['updated_at']);

      await _db.into(_db.posTerminals).insertOnConflictUpdate(
            PosTerminalsCompanion(
              id: Value(externalId),
              code: Value(code),
              name: Value(name),
              warehouseId: Value(warehouseId),
              currencyCode: Value(currencyCode),
              currencySymbol: Value(currencySymbol),
              paymentMethodsJson: Value(
                jsonEncode(
                  paymentMethods.isEmpty
                      ? const <String>['cash']
                      : paymentMethods,
                ),
              ),
              cashDenominationsJson: const Value(
                '[10000,5000,2000,1000,500,100]',
              ),
              imagePath: const Value(null),
              isActive: Value(
                _boolValueFromObject(
                  item['active'] ?? item['is_active'],
                  fallback: true,
                ),
              ),
              createdAt: Value(updatedAt ?? now),
              updatedAt: Value(updatedAt ?? now),
            ),
          );
      usedWarehouseIds.add(warehouseId);
    }
  }

  Future<void> _importWorkOrders(
    List<Map<String, Object?>> items, {
    required DateTime now,
    required String syncUserId,
    required Set<String> existingCustomerIds,
    required Set<String> existingEmployeeIds,
    required Set<String> existingProductIds,
  }) async {
    for (final Map<String, Object?> item in items) {
      final String? id = _normalizedString(item['id']);
      if (id == null) {
        continue;
      }

      final WorkOrder? existing = await (_db.select(_db.workOrders)
            ..where((WorkOrders tbl) => tbl.id.equals(id)))
          .getSingleOrNull();

      final DateTime remoteUpdatedAt =
          _dateTime(item['updated_at'] ?? item['source_updated_at']) ??
              _dateTime(item['created_at']) ??
              now;
      final DateTime localLastTouched =
          existing?.updatedAt ?? existing?.createdAt ?? DateTime(1970);
      if (existing != null && localLastTouched.isAfter(remoteUpdatedAt)) {
        continue;
      }

      final bool isActive = _boolValueFromObject(
        item['is_active'] ?? item['active'],
        fallback: true,
      );
      if (!isActive) {
        if (existing != null) {
          await (_db.delete(_db.workOrders)
                ..where((WorkOrders tbl) => tbl.id.equals(id)))
              .go();
        }
        continue;
      }

      final DateTime createdAt = _dateTime(item['created_at']) ??
          existing?.createdAt ??
          remoteUpdatedAt;
      final DateTime updatedAt =
          _dateTime(item['updated_at'] ?? item['source_updated_at']) ??
              existing?.updatedAt ??
              remoteUpdatedAt;
      final String? customerId = _resolveReferenceId(
        entity: 'customer',
        rawId: item['customer_id'],
        existingIds: existingCustomerIds,
      );
      final String? assignedEmployeeId = _resolveReferenceId(
        entity: 'employee',
        rawId: item['assigned_employee_id'],
        existingIds: existingEmployeeIds,
      );
      final List<Map<String, Object?>> normalizedItems =
          _normalizeWorkOrderItems(
        item['items'],
        existingProductIds,
      );
      final List<Map<String, Object?>> normalizedAssignments =
          _normalizeWorkOrderAssignments(
        item['assignments'],
        existingEmployeeIds,
      );
      final List<Map<String, Object?>> normalizedTasks =
          _normalizeWorkOrderTasks(
        item['tasks'],
        existingProductIds,
        existingEmployeeIds,
      );
      final List<Map<String, Object?>> normalizedQuotedRequestedLines =
          _normalizeQuotedRequestedLines(
        item['quoted_requested_lines'],
        existingProductIds,
      );

      await _db.into(_db.workOrders).insertOnConflictUpdate(
            WorkOrdersCompanion(
              id: Value(id),
              folio: Value(
                _normalizedString(item['folio']) ?? 'ODOO-PED-${_idSuffix(id)}',
              ),
              customerId: Value(customerId),
              customerNameSnapshot:
                  Value(_normalizedString(item['customer_name'])),
              assignedEmployeeId: Value(assignedEmployeeId),
              assignedEmployeeNameSnapshot: Value(
                _normalizedString(item['assigned_employee_name']),
              ),
              workType:
                  Value(_normalizedString(item['work_type']) ?? 'General'),
              title: Value(
                _normalizedString(item['title']) ?? 'Pedido sincronizado',
              ),
              description: Value(_normalizedString(item['description'])),
              itemsJson: Value(jsonEncode(normalizedItems)),
              assignmentsJson: Value(jsonEncode(normalizedAssignments)),
              tasksJson: Value(jsonEncode(normalizedTasks)),
              qty: Value((item['qty'] as num?)?.toDouble() ?? 1),
              unitLabel: Value(_normalizedString(item['unit_label']) ?? 'ud'),
              status: Value(_normalizedString(item['status']) ?? 'pending'),
              paymentStatus: Value(
                _normalizedString(item['payment_status']) ?? 'unpaid',
              ),
              priority: Value(_normalizedString(item['priority']) ?? 'normal'),
              dueAt: Value(_dateTime(item['due_at'])),
              note: Value(_normalizedString(item['note'])),
              quotedTotalsJson: Value(
                jsonEncode(_jsonEncodableList(item['quoted_totals'])),
              ),
              quotedRequestedLinesJson: Value(
                jsonEncode(normalizedQuotedRequestedLines),
              ),
              quotedPaymentVariantsJson: Value(
                jsonEncode(_jsonEncodableList(item['quoted_payment_variants'])),
              ),
              pricingSnapshotJson: Value(
                jsonEncode(_jsonEncodableMap(item['pricing_snapshot'])),
              ),
              paymentLinesJson: Value(
                jsonEncode(_jsonEncodableList(item['payment_lines'])),
              ),
              createdBy: Value(existing?.createdBy ?? syncUserId),
              updatedBy: Value(syncUserId),
              createdAt: Value(createdAt),
              updatedAt: Value(updatedAt),
              completedAt: Value(_dateTime(item['completed_at'])),
              paidAt: Value(_dateTime(item['paid_at'])),
              deliveredAt: Value(_dateTime(item['delivered_at'])),
            ),
          );
    }
  }

  Future<void> _upsertProductCatalogItem({
    required String kind,
    required String value,
    required DateTime now,
  }) async {
    final String cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      return;
    }
    final ProductCatalogItem? existing =
        await (_db.select(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) =>
                  tbl.kind.equals(kind) & tbl.value.equals(cleanValue))
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.productCatalogItems)
            ..where((ProductCatalogItems tbl) => tbl.id.equals(existing.id)))
          .write(
        ProductCatalogItemsCompanion(
          isActive: const Value(true),
          updatedAt: Value(now),
        ),
      );
      return;
    }
    await _db.into(_db.productCatalogItems).insert(
          ProductCatalogItemsCompanion.insert(
            id: 'sync-$kind-${_slug(cleanValue)}',
            kind: kind,
            value: cleanValue,
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<String> _resolveSyncUserId() async {
    final User? adminUser = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.username.equals('admin'))
          ..limit(1))
        .getSingleOrNull();
    if (adminUser != null) {
      return adminUser.id;
    }
    final User? anyUser =
        await (_db.select(_db.users)..limit(1)).getSingleOrNull();
    if (anyUser != null) {
      return anyUser.id;
    }
    throw Exception(
      'No existe un usuario local para registrar pedidos sincronizados.',
    );
  }

  String? _resolveReferenceId({
    required String entity,
    required Object? rawId,
    required Set<String> existingIds,
  }) {
    final String? clean = _normalizedString(rawId);
    if (clean == null) {
      return null;
    }
    if (existingIds.contains(clean)) {
      return clean;
    }
    final String prefix = 'odoo-$entity-';
    if (clean.startsWith(prefix)) {
      final String suffix = clean.substring(prefix.length);
      if (existingIds.contains(suffix)) {
        return suffix;
      }
    } else {
      final String prefixed = '$prefix$clean';
      if (existingIds.contains(prefixed)) {
        return prefixed;
      }
    }
    return null;
  }

  String? _normalizeReferenceForJson({
    required String entity,
    required Object? rawId,
    required Set<String> existingIds,
  }) {
    final String? clean = _normalizedString(rawId);
    if (clean == null) {
      return null;
    }
    if (existingIds.contains(clean)) {
      return clean;
    }
    final String prefix = 'odoo-$entity-';
    if (clean.startsWith(prefix)) {
      final String suffix = clean.substring(prefix.length);
      if (existingIds.contains(suffix)) {
        return suffix;
      }
      return clean;
    }
    final String prefixed = '$prefix$clean';
    if (existingIds.contains(prefixed)) {
      return prefixed;
    }
    return clean;
  }

  List<Map<String, Object?>> _normalizeWorkOrderItems(
    Object? raw,
    Set<String> existingProductIds,
  ) {
    final List<Map<String, Object?>> rows = _listOfMaps(raw);
    return rows
        .map(
          (Map<String, Object?> item) => <String, Object?>{
            'productId': _normalizeReferenceForJson(
              entity: 'product',
              rawId: item['productId'],
              existingIds: existingProductIds,
            ),
            'productName': _normalizedString(item['productName']) ?? 'Producto',
            'productSku': _normalizedString(item['productSku']) ?? '-',
            'unitLabel': _normalizedString(item['unitLabel']) ?? 'ud',
            'qty': (item['qty'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _normalizeWorkOrderAssignments(
    Object? raw,
    Set<String> existingEmployeeIds,
  ) {
    final List<Map<String, Object?>> rows = _listOfMaps(raw);
    return rows
        .map(
          (Map<String, Object?> item) => <String, Object?>{
            'employeeId': _normalizeReferenceForJson(
                  entity: 'employee',
                  rawId: item['employeeId'],
                  existingIds: existingEmployeeIds,
                ) ??
                '',
            'employeeName':
                _normalizedString(item['employeeName']) ?? 'Empleado',
            'employeeCode': _normalizedString(item['employeeCode']) ?? '-',
            'roleName': _normalizedString(item['roleName']) ?? 'Operario',
            'employeeImagePath': null,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _normalizeWorkOrderTasks(
    Object? raw,
    Set<String> existingProductIds,
    Set<String> existingEmployeeIds,
  ) {
    final List<Map<String, Object?>> rows = _listOfMaps(raw);
    return rows
        .map(
          (Map<String, Object?> item) => <String, Object?>{
            'id': _normalizedString(item['id']) ?? _uuid.v4(),
            'title': _normalizedString(item['title']) ?? 'Trabajo realizado',
            'description': _normalizedString(item['description']),
            'createdAt': (_dateTime(item['createdAt'] ?? item['created_at']) ??
                    DateTime.now())
                .toIso8601String(),
            'materials': _normalizeWorkOrderTaskMaterials(
              item['materials'],
              existingProductIds,
            ),
            'wasteMaterials': _normalizeWorkOrderTaskMaterials(
              item['wasteMaterials'] ?? item['waste_materials'],
              existingProductIds,
            ),
            'workers': _normalizeWorkOrderTaskWorkers(
              item['workers'],
              existingEmployeeIds,
            ),
            'imagePaths': const <String>[],
          },
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _normalizeWorkOrderTaskMaterials(
    Object? raw,
    Set<String> existingProductIds,
  ) {
    final List<Map<String, Object?>> rows = _listOfMaps(raw);
    return rows
        .map(
          (Map<String, Object?> item) => <String, Object?>{
            'productId': _normalizeReferenceForJson(
                  entity: 'product',
                  rawId: item['productId'],
                  existingIds: existingProductIds,
                ) ??
                '',
            'productName': _normalizedString(item['productName']) ?? 'Material',
            'productSku': _normalizedString(item['productSku']) ?? '-',
            'unitLabel': _normalizedString(item['unitLabel']) ?? 'ud',
            'qty': (item['qty'] as num?)?.toDouble() ?? 0.0,
            'widthMeters': (item['widthMeters'] as num?)?.toDouble(),
            'heightMeters': (item['heightMeters'] as num?)?.toDouble(),
            'areaSqm': (item['areaSqm'] as num?)?.toDouble(),
          },
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _normalizeWorkOrderTaskWorkers(
    Object? raw,
    Set<String> existingEmployeeIds,
  ) {
    final List<Map<String, Object?>> rows = _listOfMaps(raw);
    return rows
        .map(
          (Map<String, Object?> item) => <String, Object?>{
            'employeeId': _normalizeReferenceForJson(
                  entity: 'employee',
                  rawId: item['employeeId'],
                  existingIds: existingEmployeeIds,
                ) ??
                '',
            'employeeName':
                _normalizedString(item['employeeName']) ?? 'Empleado',
            'employeeCode': _normalizedString(item['employeeCode']) ?? '-',
            'roleName': _normalizedString(item['roleName']) ?? 'Operario',
            'employeeImagePath': null,
          },
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _normalizeQuotedRequestedLines(
    Object? raw,
    Set<String> existingProductIds,
  ) {
    final List<Map<String, Object?>> rows = _listOfMaps(raw);
    return rows
        .map(
          (Map<String, Object?> item) => <String, Object?>{
            ...item,
            'productId': _normalizeReferenceForJson(
              entity: 'product',
              rawId: item['productId'],
              existingIds: existingProductIds,
            ),
          },
        )
        .toList(growable: false);
  }

  List<Map<String, Object?>> _listOfMaps(Object? raw) {
    if (raw is! List) {
      return const <Map<String, Object?>>[];
    }
    return raw
        .whereType<Map>()
        .map(
          (Map row) => <String, Object?>{
            for (final MapEntry entry in row.entries)
              entry.key.toString(): entry.value,
          },
        )
        .toList(growable: false);
  }

  List<Object?> _jsonEncodableList(Object? raw) {
    if (raw is! List) {
      return const <Object?>[];
    }
    return raw.map<Object?>((Object? item) {
      if (item is Map) {
        return _jsonEncodableMap(item);
      }
      if (item is List) {
        return _jsonEncodableList(item);
      }
      return item;
    }).toList(growable: false);
  }

  Map<String, Object?> _jsonEncodableMap(Object? raw) {
    if (raw is! Map) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      for (final MapEntry entry in raw.entries)
        entry.key.toString(): entry.value is Map
            ? _jsonEncodableMap(entry.value)
            : entry.value is List
                ? _jsonEncodableList(entry.value)
                : entry.value,
    };
  }

  String _prefixedExternalId(String entity, Object? rawId) =>
      'odoo-$entity-${_idSuffix(rawId)}';

  String _idSuffix(Object? rawId) {
    final String value = (rawId ?? '').toString().trim();
    return value.isEmpty ? _uuid.v4() : value;
  }

  String? _warehouseExternalIdFromSnapshot(Map<String, Object?> item) {
    final Object? rawWarehouseId =
        item['warehouse_id'] ?? item['warehouse_external_uuid'];
    if (rawWarehouseId == null || rawWarehouseId.toString().trim().isEmpty) {
      return null;
    }
    final String clean = rawWarehouseId.toString().trim();
    if (clean.startsWith('odoo-warehouse-')) {
      return clean;
    }
    return _prefixedExternalId('warehouse', rawWarehouseId);
  }

  String _mapProductType(Object? raw) {
    final String clean = (raw ?? '').toString().trim().toLowerCase();
    if (clean == 'service' || clean == 'servicio') {
      return 'Servicio';
    }
    if (clean == 'digital' || clean == 'consu') {
      return 'Digital';
    }
    return 'Fisico';
  }

  int _moneyToCents(Object? raw) {
    final num? numeric = raw is num ? raw : num.tryParse('$raw');
    if (numeric == null) {
      return 0;
    }
    return (numeric * 100).round();
  }

  double? _amountFromCents(Object? raw, {bool allowNull = false}) {
    if (raw == null) {
      return allowNull ? null : 0;
    }
    final num? numeric = raw is num ? raw : num.tryParse('$raw');
    if (numeric == null) {
      return allowNull ? null : 0;
    }
    return numeric.toDouble() / 100;
  }

  int _intValue(Object? raw) {
    final num? numeric = raw is num ? raw : num.tryParse('${raw ?? ''}');
    return numeric?.round() ?? 0;
  }

  DateTime? _dateTime(Object? raw) {
    final String clean = (raw ?? '').toString().trim();
    if (clean.isEmpty) {
      return null;
    }
    return DateTime.tryParse(clean);
  }

  String? _normalizedString(Object? raw) {
    final String clean = (raw ?? '').toString().trim();
    return clean.isEmpty ? null : clean;
  }

  bool _boolValueFromObject(Object? raw, {required bool fallback}) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    final String clean = (raw ?? '').toString().trim().toLowerCase();
    if (clean == 'true' || clean == '1' || clean == 'yes') {
      return true;
    }
    if (clean == 'false' || clean == '0' || clean == 'no') {
      return false;
    }
    return fallback;
  }

  bool _boolFromDbValue(Object? raw, {bool fallback = false}) {
    return _boolValueFromObject(raw, fallback: fallback);
  }

  List<String> _normalizedStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    final List<String> values = <String>[];
    for (final Object? item in raw) {
      final String? clean = _normalizedString(item);
      if (clean != null) {
        values.add(clean);
      }
    }
    return values;
  }

  List<Object?> _jsonList(String? raw) {
    final Object? decoded = _safeJsonDecode(raw);
    if (decoded is! List) {
      return const <Object?>[];
    }
    return List<Object?>.from(decoded);
  }

  Map<String, Object?> _jsonMap(String? raw) {
    final Object? decoded = _safeJsonDecode(raw);
    if (decoded is! Map) {
      return const <String, Object?>{};
    }
    return Map<String, Object?>.from(decoded);
  }

  String _currencySymbolFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return 'EUR';
      case 'CUP':
        return '₱';
      default:
        return code.toUpperCase();
    }
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _queueKey(String entityType, String entityId) =>
      '${entityType.trim()}|${entityId.trim()}';

  Object? _safeJsonDecode(String? raw) {
    final String clean = (raw ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(clean);
    } catch (_) {
      return null;
    }
  }
}
