import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';

const List<String> kWarehouseTypes = <String>['Central', 'TPV'];

class WarehouseWithStock {
  final Warehouse warehouse;
  final int totalProducts;
  final double totalQuantity;

  WarehouseWithStock({
    required this.warehouse,
    required this.totalProducts,
    required this.totalQuantity,
  });
}

class AlmacenesLocalDataSource {
  AlmacenesLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  Future<void> ensureDefaultWarehouse({String name = 'Principal'}) async {
    final TypedResult? existing = await (_db.selectOnly(_db.warehouses)
          ..addColumns(<Expression<Object>>[_db.warehouses.id])
          ..where(_db.warehouses.name.equals(name))
          ..limit(1))
        .getSingleOrNull();
    if (existing?.read(_db.warehouses.id) != null) {
      return;
    }

    await createWarehouse(name: name, warehouseType: 'Central');
  }

  Future<List<Warehouse>> listActiveWarehouses() {
    return (_db.select(_db.warehouses)
          ..where((Warehouses tbl) =>
              tbl.isActive.equals(true) & _hasUsableWarehouseFields(tbl))
          ..orderBy(<OrderingTerm Function(Warehouses)>[
            (Warehouses tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
  }

  Future<List<WarehouseWithStock>> listWarehousesWithStock() async {
    final warehouses = await listActiveWarehouses();
    final List<WarehouseWithStock> result = <WarehouseWithStock>[];

    for (final warehouse in warehouses) {
      final stockData = await getWarehouseStockSummary(warehouse.id);
      result.add(WarehouseWithStock(
        warehouse: warehouse,
        totalProducts: stockData.$1,
        totalQuantity: stockData.$2,
      ));
    }

    return result;
  }

  Future<Warehouse?> getWarehouseById(String id) {
    return (_db.select(_db.warehouses)
          ..where((Warehouses tbl) =>
              tbl.id.equals(id) & _hasUsableWarehouseFields(tbl)))
        .getSingleOrNull();
  }

  Future<(int, double)> getWarehouseStockSummary(String warehouseId) async {
    final query = _db.select(_db.stockBalances).join([
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.stockBalances.productId),
      ),
    ])
      ..where(_db.stockBalances.warehouseId.equals(warehouseId) &
          _db.products.isActive.equals(true));

    final results = await query.get();

    int productCount = 0;
    double totalQty = 0;

    for (final row in results) {
      final qty = row.readTable(_db.stockBalances).qty;
      if (qty > 0) {
        productCount++;
        totalQty += qty;
      }
    }

    return (productCount, totalQty);
  }

  Future<List<StockBalanceWithProduct>> getWarehouseStock(
      String warehouseId) async {
    final query = _db.select(_db.stockBalances).join([
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.stockBalances.productId),
      ),
    ])
      ..where(_db.stockBalances.warehouseId.equals(warehouseId) &
          _db.products.isActive.equals(true))
      ..orderBy([OrderingTerm.desc(_db.stockBalances.updatedAt)]);

    final results = await query.get();

    return results.map((row) {
      return StockBalanceWithProduct(
        stockBalance: row.readTable(_db.stockBalances),
        product: row.readTable(_db.products),
      );
    }).toList();
  }

  Future<void> createWarehouse({
    required String name,
    String warehouseType = 'Central',
  }) async {
    await _licenseService.requireWriteAccess();
    await _db.into(_db.warehouses).insert(
          WarehousesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            warehouseType: Value(warehouseType),
          ),
        );
  }

  Future<void> updateWarehouse({
    required String id,
    required String name,
    required String warehouseType,
  }) async {
    await _licenseService.requireWriteAccess();
    await (_db.update(_db.warehouses)
          ..where((Warehouses tbl) => tbl.id.equals(id)))
        .write(
      WarehousesCompanion(
        name: Value(name),
        warehouseType: Value(warehouseType),
      ),
    );
  }

  Future<void> deactivateWarehouse(String id) async {
    await _licenseService.requireWriteAccess();
    await (_db.update(_db.warehouses)
          ..where((Warehouses tbl) => tbl.id.equals(id)))
        .write(
      const WarehousesCompanion(
        isActive: Value(false),
      ),
    );
  }

  Expression<bool> _hasUsableWarehouseFields(Warehouses tbl) {
    return tbl.id.isNotNull() &
        tbl.name.isNotNull() &
        tbl.warehouseType.isNotNull() &
        tbl.isActive.isNotNull() &
        tbl.createdAt.isNotNull();
  }
}

class StockBalanceWithProduct {
  final StockBalance stockBalance;
  final Product product;

  StockBalanceWithProduct({
    required this.stockBalance,
    required this.product,
  });
}
