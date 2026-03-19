import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  TextColumn get role => text().withDefault(const Constant('cajero'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text().unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  IntColumn get priceCents => integer().withDefault(const Constant(0))();
  IntColumn get taxRateBps => integer().withDefault(const Constant(0))();
  TextColumn get imagePath => text().nullable()();
  IntColumn get costPriceCents => integer().withDefault(const Constant(0))();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get productType => text().withDefault(const Constant('Fisico'))();
  TextColumn get unitMeasure => text().withDefault(const Constant('Unidad'))();
  TextColumn get currencyCode => text().withDefault(const Constant('USD'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class ProductCatalogItems extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get value => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column>>[
        <Column>{kind, value},
      ];
}

class Warehouses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get warehouseType =>
      text().withDefault(const Constant('Central'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class PosTerminals extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get warehouseId => text().references(Warehouses, #id).unique()();
  TextColumn get currencyCode => text().withDefault(const Constant('USD'))();
  TextColumn get currencySymbol => text().withDefault(const Constant(r'$'))();
  TextColumn get paymentMethodsJson =>
      text().withDefault(const Constant('["cash"]'))();
  TextColumn get cashDenominationsJson =>
      text().withDefault(const Constant('[10000,5000,2000,1000,500,100]'))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class PosSessions extends Table {
  TextColumn get id => text()();
  TextColumn get terminalId => text().references(PosTerminals, #id)();
  TextColumn get userId => text().references(Users, #id)();
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get openingFloatCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get closingCashCents => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class PosSessionCashBreakdowns extends Table {
  TextColumn get sessionId => text().references(PosSessions, #id)();
  IntColumn get denominationCents => integer()();
  IntColumn get unitCount => integer().withDefault(const Constant(0))();
  IntColumn get subtotalCents => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => <Column>{sessionId, denominationCents};
}

class Employees extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get sex => text().nullable()();
  TextColumn get identityNumber => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get associatedUserId => text().references(Users, #id).nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class PosSessionEmployees extends Table {
  TextColumn get sessionId => text().references(PosSessions, #id)();
  TextColumn get employeeId => text().references(Employees, #id)();
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{sessionId, employeeId};
}

class StockBalances extends Table {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  RealColumn get qty => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{productId, warehouseId};
}

class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  TextColumn get type => text()();
  RealColumn get qty => real()();
  TextColumn get reasonCode => text().nullable()();
  TextColumn get movementSource =>
      text().withDefault(const Constant('manual'))();
  TextColumn get refType => text().nullable()();
  TextColumn get refId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdBy => text().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get folio => text().unique()();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  TextColumn get cashierId => text().references(Users, #id)();
  TextColumn get terminalId =>
      text().references(PosTerminals, #id).nullable()();
  TextColumn get terminalSessionId =>
      text().references(PosSessions, #id).nullable()();
  IntColumn get subtotalCents => integer()();
  IntColumn get taxCents => integer()();
  IntColumn get totalCents => integer()();
  TextColumn get status => text().withDefault(const Constant('posted'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get qty => real()();
  IntColumn get unitPriceCents => integer()();
  IntColumn get taxRateBps => integer()();
  IntColumn get lineSubtotalCents => integer()();
  IntColumn get lineTaxCents => integer()();
  IntColumn get lineTotalCents => integer()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text().references(Sales, #id)();
  TextColumn get method => text()();
  IntColumn get amountCents => integer()();
  TextColumn get sourceCurrencyCode => text().nullable()();
  IntColumn get sourceAmountCents => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class IpvReports extends Table {
  TextColumn get id => text()();
  TextColumn get terminalId => text().references(PosTerminals, #id)();
  TextColumn get warehouseId => text().references(Warehouses, #id)();
  TextColumn get sessionId => text().references(PosSessions, #id).unique()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
  @ReferenceName('openedIpvReports')
  TextColumn get openedBy => text().references(Users, #id)();
  @ReferenceName('closedIpvReports')
  TextColumn get closedBy => text().references(Users, #id).nullable()();
  TextColumn get openingSource =>
      text().withDefault(const Constant('initial_stock'))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

class IpvReportLines extends Table {
  TextColumn get reportId => text().references(IpvReports, #id)();
  TextColumn get productId => text().references(Products, #id)();
  RealColumn get startQty => real().withDefault(const Constant(0))();
  RealColumn get entriesQty => real().withDefault(const Constant(0))();
  RealColumn get outputsQty => real().withDefault(const Constant(0))();
  RealColumn get salesQty => real().withDefault(const Constant(0))();
  RealColumn get finalQty => real().withDefault(const Constant(0))();
  IntColumn get salePriceCents => integer().withDefault(const Constant(0))();
  IntColumn get totalAmountCents => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => <Column>{reportId, productId};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{key};
}

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).nullable()();
  TextColumn get action => text()();
  TextColumn get entity => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{id};
}

@DriftDatabase(
  tables: <Type>[
    Users,
    Products,
    ProductCatalogItems,
    Warehouses,
    PosTerminals,
    PosSessions,
    PosSessionCashBreakdowns,
    Employees,
    PosSessionEmployees,
    StockBalances,
    StockMovements,
    Sales,
    SaleItems,
    Payments,
    IpvReports,
    IpvReportLines,
    AppSettings,
    AuditLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  final Uuid _uuid = const Uuid();

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createPerformanceIndexes();
          await _seedDefaultProductCatalogItems();
          await _bootstrapTerminalsForTpvWarehouses();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(appSettings);
          }
          if (from < 3) {
            await m.addColumn(products, products.imagePath);
            await m.addColumn(products, products.costPriceCents);
            await m.addColumn(products, products.category);
            await m.addColumn(products, products.productType);
            await m.addColumn(products, products.unitMeasure);
            await m.addColumn(products, products.currencyCode);
          }
          if (from < 4) {
            await m.createTable(productCatalogItems);
            await _seedDefaultProductCatalogItems();
          }
          if (from < 5) {
            await m.addColumn(products, products.barcode);
          }
          if (from < 6) {
            await _addWarehouseColumnIfMissing(
              m,
              'warehouse_type',
              () => m.addColumn(warehouses, warehouses.warehouseType),
            );
            await _addWarehouseColumnIfMissing(
              m,
              'created_at',
              () => m.addColumn(warehouses, warehouses.createdAt),
            );
          }
          if (from < 7) {
            await m.createTable(posTerminals);
            await m.createTable(posSessions);
            await _bootstrapTerminalsForTpvWarehouses();
          }
          if (from < 8) {
            await _addSalesColumnIfMissing(
              m,
              'terminal_id',
              () => m.addColumn(sales, sales.terminalId),
            );
            await _addSalesColumnIfMissing(
              m,
              'terminal_session_id',
              () => m.addColumn(sales, sales.terminalSessionId),
            );
          }
          if (from < 9) {
            await _addPosTerminalColumnIfMissing(
              m,
              'currency_code',
              () => m.addColumn(posTerminals, posTerminals.currencyCode),
            );
            await _addPosTerminalColumnIfMissing(
              m,
              'currency_symbol',
              () => m.addColumn(posTerminals, posTerminals.currencySymbol),
            );
            await _addPosTerminalColumnIfMissing(
              m,
              'payment_methods_json',
              () => m.addColumn(posTerminals, posTerminals.paymentMethodsJson),
            );
            await _addPosTerminalColumnIfMissing(
              m,
              'cash_denominations_json',
              () => m.addColumn(
                posTerminals,
                posTerminals.cashDenominationsJson,
              ),
            );
          }
          if (from < 10) {
            await m.createTable(posSessionCashBreakdowns);
          }
          if (from < 11) {
            await _addStockMovementColumnIfMissing(
              m,
              'reason_code',
              () => m.addColumn(stockMovements, stockMovements.reasonCode),
            );
            await _addStockMovementColumnIfMissing(
              m,
              'movement_source',
              () => m.addColumn(
                stockMovements,
                stockMovements.movementSource,
              ),
            );
            await customStatement(
              '''
              UPDATE stock_movements
              SET reason_code = CASE
                WHEN reason_code IS NOT NULL AND TRIM(reason_code) <> '' THEN reason_code
                WHEN ref_type IN ('sale', 'sale_pos', 'sale_direct') THEN 'sale'
                ELSE 'adjust'
              END
              ''',
            );
            await customStatement(
              '''
              UPDATE stock_movements
              SET movement_source = CASE
                WHEN movement_source IS NOT NULL AND TRIM(movement_source) <> '' THEN movement_source
                WHEN ref_type IN ('sale', 'sale_pos') THEN 'pos'
                WHEN ref_type = 'sale_direct' THEN 'direct_sale'
                ELSE 'manual'
              END
              ''',
            );
          }
          if (from < 12) {
            if (!await _tableExists('employees')) {
              await m.createTable(employees);
            }
            if (!await _tableExists('pos_session_employees')) {
              await m.createTable(posSessionEmployees);
            }
            if (!await _tableExists('ipv_reports')) {
              await m.createTable(ipvReports);
            }
            if (!await _tableExists('ipv_report_lines')) {
              await m.createTable(ipvReportLines);
            }
          }
          if (from < 13) {
            await _addEmployeeColumnIfMissing(
              m,
              'sex',
              () => m.addColumn(employees, employees.sex),
            );
            await _addEmployeeColumnIfMissing(
              m,
              'identity_number',
              () => m.addColumn(employees, employees.identityNumber),
            );
            await _addEmployeeColumnIfMissing(
              m,
              'address',
              () => m.addColumn(employees, employees.address),
            );
            await _addEmployeeColumnIfMissing(
              m,
              'image_path',
              () => m.addColumn(employees, employees.imagePath),
            );
            await _addEmployeeColumnIfMissing(
              m,
              'associated_user_id',
              () => m.addColumn(employees, employees.associatedUserId),
            );
          }
          if (from < 14) {
            await _createPerformanceIndexes();
          }
          if (from < 15) {
            await _addPaymentColumnIfMissing(
              m,
              'source_currency_code',
              () => m.addColumn(payments, payments.sourceCurrencyCode),
            );
            await _addPaymentColumnIfMissing(
              m,
              'source_amount_cents',
              () => m.addColumn(payments, payments.sourceAmountCents),
            );
          }
        },
      );

  Future<void> _addWarehouseColumnIfMissing(
    Migrator migrator,
    String columnName,
    Future<void> Function() addColumn,
  ) async {
    final bool exists = await _tableHasColumn('warehouses', columnName);
    if (!exists) {
      await addColumn();
    }
  }

  Future<void> _addSalesColumnIfMissing(
    Migrator migrator,
    String columnName,
    Future<void> Function() addColumn,
  ) async {
    final bool exists = await _tableHasColumn('sales', columnName);
    if (!exists) {
      await addColumn();
    }
  }

  Future<void> _addPosTerminalColumnIfMissing(
    Migrator migrator,
    String columnName,
    Future<void> Function() addColumn,
  ) async {
    final bool exists = await _tableHasColumn('pos_terminals', columnName);
    if (!exists) {
      await addColumn();
    }
  }

  Future<void> _addStockMovementColumnIfMissing(
    Migrator migrator,
    String columnName,
    Future<void> Function() addColumn,
  ) async {
    final bool exists = await _tableHasColumn('stock_movements', columnName);
    if (!exists) {
      await addColumn();
    }
  }

  Future<void> _addEmployeeColumnIfMissing(
    Migrator migrator,
    String columnName,
    Future<void> Function() addColumn,
  ) async {
    final bool exists = await _tableHasColumn('employees', columnName);
    if (!exists) {
      await addColumn();
    }
  }

  Future<void> _addPaymentColumnIfMissing(
    Migrator migrator,
    String columnName,
    Future<void> Function() addColumn,
  ) async {
    final bool exists = await _tableHasColumn('payments', columnName);
    if (!exists) {
      await addColumn();
    }
  }

  Future<void> _createPerformanceIndexes() async {
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_products_active_name
      ON products (is_active, name)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_products_barcode
      ON products (barcode)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_stock_balances_warehouse_product
      ON stock_balances (warehouse_id, product_id)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_stock_movements_warehouse_created_at
      ON stock_movements (warehouse_id, created_at)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_stock_movements_product_warehouse
      ON stock_movements (product_id, warehouse_id)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_sales_status_created_at
      ON sales (status, created_at)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_sales_terminal_session_status
      ON sales (terminal_session_id, status)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_sales_warehouse_created_at
      ON sales (warehouse_id, created_at)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id
      ON sale_items (sale_id)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_payments_sale_id
      ON payments (sale_id)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_pos_sessions_status_closed_at
      ON pos_sessions (status, closed_at)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_pos_sessions_terminal_user_status
      ON pos_sessions (terminal_id, user_id, status)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_ipv_reports_status_closed_at
      ON ipv_reports (status, closed_at)
      ''',
    );
    await customStatement(
      '''
      CREATE INDEX IF NOT EXISTS idx_ipv_reports_terminal_status_closed_at
      ON ipv_reports (terminal_id, status, closed_at)
      ''',
    );
  }

  Future<void> _bootstrapTerminalsForTpvWarehouses() async {
    final List<Warehouse> tpvWarehouses = await (select(warehouses)
          ..where((Warehouses tbl) =>
              tbl.warehouseType.equals('TPV') & tbl.isActive.equals(true)))
        .get();
    if (tpvWarehouses.isEmpty) {
      return;
    }

    for (final Warehouse warehouse in tpvWarehouses) {
      final TypedResult? existing = await (selectOnly(posTerminals)
            ..addColumns(<Expression<Object>>[posTerminals.id])
            ..where(posTerminals.warehouseId.equals(warehouse.id))
            ..limit(1))
          .getSingleOrNull();
      if (existing?.read(posTerminals.id) != null) {
        continue;
      }

      final String code = await _nextTerminalCodeSeed(warehouse);
      await into(posTerminals).insert(
        PosTerminalsCompanion.insert(
          id: _uuid.v4(),
          code: code,
          name: warehouse.name,
          warehouseId: warehouse.id,
        ),
      );
    }
  }

  Future<String> _nextTerminalCodeSeed(Warehouse warehouse) async {
    final String normalized = _slug(warehouse.name).toUpperCase();
    final String suffix = warehouse.id.replaceAll('-', '').toUpperCase();
    final String fallback = suffix.substring(0, math.min(6, suffix.length));
    final String base = normalized.isEmpty
        ? 'TPV-$fallback'
        : 'TPV-${normalized.substring(0, math.min(8, normalized.length))}';

    String code = base;
    int index = 2;
    while (await _terminalCodeExists(code)) {
      code = '$base-$index';
      index += 1;
    }
    return code;
  }

  Future<bool> _terminalCodeExists(String code) async {
    final TypedResult? existing = await (selectOnly(posTerminals)
          ..addColumns(<Expression<Object>>[posTerminals.id])
          ..where(posTerminals.code.equals(code))
          ..limit(1))
        .getSingleOrNull();
    return existing?.read(posTerminals.id) != null;
  }

  Future<bool> _tableHasColumn(String tableName, String columnName) async {
    final List<QueryRow> rows =
        await customSelect('PRAGMA table_info($tableName)').get();

    for (final QueryRow row in rows) {
      final Object? rawName = row.data['name'];
      final String name = (rawName is String ? rawName : '').toLowerCase();
      if (name == columnName.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _tableExists(String tableName) async {
    final List<QueryRow> rows = await customSelect(
      '''
      SELECT 1
      FROM sqlite_master
      WHERE type = 'table'
        AND name = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _seedDefaultProductCatalogItems() async {
    const Map<String, List<String>> defaults = <String, List<String>>{
      'type': <String>['Fisico', 'Servicio', 'Digital'],
      'category': <String>['General'],
      'unit': <String>['Unidad', 'Caja', 'Kg', 'Litro', 'Metro', 'Paquete'],
    };

    for (final MapEntry<String, List<String>> entry in defaults.entries) {
      for (final String value in entry.value) {
        await into(productCatalogItems).insert(
          ProductCatalogItemsCompanion.insert(
            id: '${entry.key}-${_slug(value)}',
            kind: entry.key,
            value: value,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }
  }

  String _slug(String value) {
    final String cleaned = value.trim().toLowerCase();
    return cleaned
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(documentsDir.path, 'app.db'));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}
