import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';

class InventoryView {
  const InventoryView({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.priceCents,
    required this.taxRateBps,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final int priceCents;
  final int taxRateBps;
}

class InventarioLocalDataSource {
  InventarioLocalDataSource(this._db, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<List<InventoryView>> listByWarehouse(String warehouseId) async {
    final result = await _db.customSelect(
      '''
      SELECT
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        COALESCE(sb.qty, 0) AS qty
      FROM products p
      LEFT JOIN stock_balances sb
        ON sb.product_id = p.id
       AND sb.warehouse_id = ?
      WHERE p.is_active = 1
        AND p.id IS NOT NULL
        AND p.name IS NOT NULL
        AND p.sku IS NOT NULL
        AND p.price_cents IS NOT NULL
        AND p.tax_rate_bps IS NOT NULL
      ORDER BY p.name ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(warehouseId)],
    ).get();

    return result.map((QueryRow row) {
      return InventoryView(
        productId: row.read<String>('id'),
        productName: row.read<String>('name'),
        sku: row.read<String>('sku'),
        qty: row.read<double>('qty'),
        priceCents: row.read<int>('price_cents'),
        taxRateBps: row.read<int>('tax_rate_bps'),
      );
    }).toList();
  }

  Future<void> setStock({
    required String productId,
    required String warehouseId,
    required double qty,
    required String userId,
    String note = 'Ajuste manual',
  }) async {
    await _db.transaction(() async {
      final StockBalance? current = await (_db.select(_db.stockBalances)
            ..where(
              (StockBalances tbl) =>
                  tbl.productId.equals(productId) &
                  tbl.warehouseId.equals(warehouseId),
            ))
          .getSingleOrNull();

      final double oldQty = current?.qty ?? 0;
      final double delta = qty - oldQty;

      if (current == null) {
        await _db.into(_db.stockBalances).insert(
              StockBalancesCompanion.insert(
                productId: productId,
                warehouseId: warehouseId,
                qty: Value(qty),
                updatedAt: Value(DateTime.now()),
              ),
            );
      } else {
        await (_db.update(_db.stockBalances)
              ..where(
                (StockBalances tbl) =>
                    tbl.productId.equals(productId) &
                    tbl.warehouseId.equals(warehouseId),
              ))
            .write(
          StockBalancesCompanion(
            qty: Value(qty),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: _uuid.v4(),
              productId: productId,
              warehouseId: warehouseId,
              type: 'adjust',
              qty: delta,
              refType: const Value('adjust'),
              refId: const Value(null),
              note: Value(note),
              createdBy: userId,
            ),
          );
    });
  }
}
