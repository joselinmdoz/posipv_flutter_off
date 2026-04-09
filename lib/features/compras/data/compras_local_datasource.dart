import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';

class PurchaseLineInput {
  const PurchaseLineInput({
    required this.productId,
    required this.qty,
    required this.unitCostCents,
  });

  final String productId;
  final double qty;
  final int unitCostCents;
}

class CreatePurchaseInput {
  const CreatePurchaseInput({
    required this.warehouseId,
    required this.userId,
    required this.lines,
    this.supplierName,
    this.supplierDoc,
    this.note,
    this.createdAt,
  });

  final String warehouseId;
  final String userId;
  final List<PurchaseLineInput> lines;
  final String? supplierName;
  final String? supplierDoc;
  final String? note;
  final DateTime? createdAt;
}

class CreatePurchaseResult {
  const CreatePurchaseResult({
    required this.purchaseId,
    required this.folio,
    required this.totalCents,
  });

  final String purchaseId;
  final String folio;
  final int totalCents;
}

class PurchaseSummaryView {
  const PurchaseSummaryView({
    required this.id,
    required this.folio,
    required this.warehouseName,
    required this.createdByUsername,
    required this.createdAt,
    required this.linesCount,
    required this.totalCents,
    this.supplierName,
    this.supplierDoc,
  });

  final String id;
  final String folio;
  final String warehouseName;
  final String createdByUsername;
  final DateTime createdAt;
  final int linesCount;
  final int totalCents;
  final String? supplierName;
  final String? supplierDoc;
}

class PurchaseDetailLineView {
  const PurchaseDetailLineView({
    required this.purchaseItemId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitCostCents,
    required this.lineCostCents,
    required this.lotQtyIn,
    required this.lotQtyRemaining,
  });

  final String purchaseItemId;
  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final int unitCostCents;
  final int lineCostCents;
  final double lotQtyIn;
  final double lotQtyRemaining;

  double get consumedQty => lotQtyIn - lotQtyRemaining;
}

class PurchaseDetailView {
  const PurchaseDetailView({
    required this.summary,
    required this.note,
    required this.lines,
  });

  final PurchaseSummaryView summary;
  final String? note;
  final List<PurchaseDetailLineView> lines;
}

class LotStatusRowView {
  const LotStatusRowView({
    required this.lotId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.warehouseId,
    required this.warehouseName,
    required this.qtyIn,
    required this.qtyRemaining,
    required this.unitCostCents,
    required this.receivedAt,
    required this.sourceType,
    required this.sourceId,
    this.note,
  });

  final String lotId;
  final String productId;
  final String productName;
  final String sku;
  final String warehouseId;
  final String warehouseName;
  final double qtyIn;
  final double qtyRemaining;
  final int unitCostCents;
  final DateTime receivedAt;
  final String sourceType;
  final String? sourceId;
  final String? note;

  double get qtyConsumed => qtyIn - qtyRemaining;
  double get remainingRatio => qtyIn <= 0 ? 0 : qtyRemaining / qtyIn;
  bool get isDepleted => qtyRemaining <= 0.000001;
  bool get isLow => !isDepleted && remainingRatio <= 0.2;
}

class LotStatusSnapshotView {
  const LotStatusSnapshotView({
    required this.rows,
    required this.totalLots,
    required this.activeLots,
    required this.depletedLots,
    required this.lowLots,
  });

  final List<LotStatusRowView> rows;
  final int totalLots;
  final int activeLots;
  final int depletedLots;
  final int lowLots;
}

class PurchaseWarehouseOption {
  const PurchaseWarehouseOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class PurchaseProductOption {
  const PurchaseProductOption({
    required this.id,
    required this.sku,
    required this.name,
    required this.salePriceCents,
    required this.defaultCostCents,
  });

  final String id;
  final String sku;
  final String name;
  final int salePriceCents;
  final int defaultCostCents;
}

class ComprasLocalDataSource {
  ComprasLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  Future<List<PurchaseWarehouseOption>> listActiveWarehouses() async {
    final List<Warehouse> rows = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) =>
              tbl.isActive.equals(true) &
              tbl.id.isNotNull() &
              tbl.name.isNotNull() &
              tbl.createdAt.isNotNull())
          ..orderBy(<OrderingTerm Function(Warehouses)>[
            (Warehouses tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
    return rows
        .map(
          (Warehouse row) => PurchaseWarehouseOption(
            id: row.id,
            name: row.name,
          ),
        )
        .toList(growable: false);
  }

  Future<List<PurchaseProductOption>> listActiveProducts({
    String? search,
    int limit = 200,
  }) async {
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final int safeLimit = limit <= 0 ? 200 : limit;
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        p.id AS id,
        p.sku AS sku,
        p.name AS name,
        p.price_cents AS sale_price_cents,
        p.cost_price_cents AS cost_price_cents
      FROM products p
      WHERE p.is_active = 1
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (cleanedSearch.isNotEmpty) {
      final String pattern = '%$cleanedSearch%';
      sql.write(
        '''
        AND (
          LOWER(COALESCE(p.name, '')) LIKE ?
          OR LOWER(COALESCE(p.sku, '')) LIKE ?
          OR LOWER(COALESCE(p.barcode, '')) LIKE ?
        )
        ''',
      );
      variables.addAll(<Variable<Object>>[
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
      ]);
    }
    sql.write(
      '''
      ORDER BY p.name ASC
      LIMIT ?
      ''',
    );
    variables.add(Variable<int>(safeLimit));

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    return rows.map((QueryRow row) {
      return PurchaseProductOption(
        id: (row.readNullable<String>('id') ?? '').trim(),
        sku: (row.readNullable<String>('sku') ?? '').trim(),
        name: (row.readNullable<String>('name') ?? '').trim(),
        salePriceCents: (row.data['sale_price_cents'] as num?)?.toInt() ?? 0,
        defaultCostCents: (row.data['cost_price_cents'] as num?)?.toInt() ?? 0,
      );
    }).where((PurchaseProductOption row) {
      return row.id.isNotEmpty && row.name.isNotEmpty;
    }).toList(growable: false);
  }

  Future<List<PurchaseSummaryView>> listPurchases({
    String? search,
    String? warehouseId,
    int limit = 100,
    int offset = 0,
  }) async {
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final String cleanedWarehouseId = (warehouseId ?? '').trim();
    final int safeLimit = limit <= 0 ? 100 : limit;
    final int safeOffset = offset < 0 ? 0 : offset;

    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        p.id AS purchase_id,
        p.folio AS folio,
        p.created_at AS created_at,
        p.supplier_name AS supplier_name,
        p.supplier_doc AS supplier_doc,
        COALESCE(w.name, 'Almacen') AS warehouse_name,
        COALESCE(u.username, 'Usuario') AS created_by,
        CAST(COUNT(pi.id) AS INTEGER) AS lines_count,
        COALESCE(SUM(pi.line_cost_cents), 0) AS total_cents
      FROM purchases p
      INNER JOIN warehouses w
        ON w.id = p.warehouse_id
      INNER JOIN users u
        ON u.id = p.created_by
      LEFT JOIN purchase_items pi
        ON pi.purchase_id = p.id
      WHERE LOWER(COALESCE(p.status, '')) = 'posted'
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];

    if (cleanedWarehouseId.isNotEmpty) {
      sql.write(' AND p.warehouse_id = ? ');
      variables.add(Variable<String>(cleanedWarehouseId));
    }
    if (cleanedSearch.isNotEmpty) {
      final String pattern = '%$cleanedSearch%';
      sql.write(
        '''
        AND (
          LOWER(COALESCE(p.folio, '')) LIKE ?
          OR LOWER(COALESCE(p.supplier_name, '')) LIKE ?
          OR LOWER(COALESCE(p.supplier_doc, '')) LIKE ?
          OR LOWER(COALESCE(w.name, '')) LIKE ?
        )
        ''',
      );
      variables.addAll(<Variable<Object>>[
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
      ]);
    }

    sql.write(
      '''
      GROUP BY
        p.id,
        p.folio,
        p.created_at,
        p.supplier_name,
        p.supplier_doc,
        w.name,
        u.username
      ORDER BY p.created_at DESC, p.id DESC
      LIMIT ? OFFSET ?
      ''',
    );
    variables.addAll(<Variable<Object>>[
      Variable<int>(safeLimit),
      Variable<int>(safeOffset),
    ]);

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    return rows
        .map((QueryRow row) {
          return PurchaseSummaryView(
            id: (row.readNullable<String>('purchase_id') ?? '').trim(),
            folio: (row.readNullable<String>('folio') ?? '-').trim(),
            warehouseName:
                (row.readNullable<String>('warehouse_name') ?? 'Almacen')
                    .trim(),
            createdByUsername:
                (row.readNullable<String>('created_by') ?? 'Usuario').trim(),
            createdAt:
                row.readNullable<DateTime>('created_at') ?? DateTime.now(),
            linesCount: (row.data['lines_count'] as num?)?.toInt() ?? 0,
            totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
            supplierName:
                _normalizeOptional(row.readNullable<String>('supplier_name')),
            supplierDoc:
                _normalizeOptional(row.readNullable<String>('supplier_doc')),
          );
        })
        .where((PurchaseSummaryView row) => row.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<PurchaseDetailView?> getPurchaseDetail(String purchaseId) async {
    final String id = purchaseId.trim();
    if (id.isEmpty) {
      return null;
    }

    final List<QueryRow> headerRows = await _db.customSelect(
      '''
      SELECT
        p.id AS purchase_id,
        p.folio AS folio,
        p.created_at AS created_at,
        p.supplier_name AS supplier_name,
        p.supplier_doc AS supplier_doc,
        p.note AS note,
        COALESCE(w.name, 'Almacen') AS warehouse_name,
        COALESCE(u.username, 'Usuario') AS created_by,
        CAST(COUNT(pi.id) AS INTEGER) AS lines_count,
        COALESCE(SUM(pi.line_cost_cents), 0) AS total_cents
      FROM purchases p
      INNER JOIN warehouses w ON w.id = p.warehouse_id
      INNER JOIN users u ON u.id = p.created_by
      LEFT JOIN purchase_items pi ON pi.purchase_id = p.id
      WHERE p.id = ?
      GROUP BY
        p.id,
        p.folio,
        p.created_at,
        p.supplier_name,
        p.supplier_doc,
        p.note,
        w.name,
        u.username
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();
    if (headerRows.isEmpty) {
      return null;
    }

    final QueryRow header = headerRows.first;
    final PurchaseSummaryView summary = PurchaseSummaryView(
      id: (header.readNullable<String>('purchase_id') ?? '').trim(),
      folio: (header.readNullable<String>('folio') ?? '-').trim(),
      warehouseName:
          (header.readNullable<String>('warehouse_name') ?? 'Almacen').trim(),
      createdByUsername:
          (header.readNullable<String>('created_by') ?? 'Usuario').trim(),
      createdAt: header.readNullable<DateTime>('created_at') ?? DateTime.now(),
      linesCount: (header.data['lines_count'] as num?)?.toInt() ?? 0,
      totalCents: (header.data['total_cents'] as num?)?.toInt() ?? 0,
      supplierName: _normalizeOptional(header.readNullable<String>(
        'supplier_name',
      )),
      supplierDoc: _normalizeOptional(header.readNullable<String>(
        'supplier_doc',
      )),
    );

    final List<QueryRow> lineRows = await _db.customSelect(
      '''
      SELECT
        pi.id AS purchase_item_id,
        pi.product_id AS product_id,
        COALESCE(p.name, 'Producto') AS product_name,
        COALESCE(p.sku, '-') AS sku,
        COALESCE(pi.qty, 0) AS qty,
        COALESCE(pi.unit_cost_cents, 0) AS unit_cost_cents,
        COALESCE(pi.line_cost_cents, 0) AS line_cost_cents,
        COALESCE(pi.qty, 0) AS lot_qty_in,
        COALESCE(SUM(sl.qty_remaining), 0) AS lot_qty_remaining
      FROM purchase_items pi
      LEFT JOIN products p ON p.id = pi.product_id
      LEFT JOIN stock_lots sl ON sl.purchase_item_id = pi.id
      WHERE pi.purchase_id = ?
      GROUP BY
        pi.id,
        pi.product_id,
        p.name,
        p.sku,
        pi.qty,
        pi.unit_cost_cents,
        pi.line_cost_cents
      ORDER BY p.name ASC, pi.id ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();

    final List<PurchaseDetailLineView> lines = lineRows.map((QueryRow row) {
      return PurchaseDetailLineView(
        purchaseItemId:
            (row.readNullable<String>('purchase_item_id') ?? '').trim(),
        productId: (row.readNullable<String>('product_id') ?? '').trim(),
        productName:
            (row.readNullable<String>('product_name') ?? 'Producto').trim(),
        sku: (row.readNullable<String>('sku') ?? '-').trim(),
        qty: (row.data['qty'] as num?)?.toDouble() ?? 0,
        unitCostCents: (row.data['unit_cost_cents'] as num?)?.toInt() ?? 0,
        lineCostCents: (row.data['line_cost_cents'] as num?)?.toInt() ?? 0,
        lotQtyIn: (row.data['lot_qty_in'] as num?)?.toDouble() ?? 0,
        lotQtyRemaining:
            (row.data['lot_qty_remaining'] as num?)?.toDouble() ?? 0,
      );
    }).where((PurchaseDetailLineView row) {
      return row.purchaseItemId.isNotEmpty;
    }).toList(growable: false);

    return PurchaseDetailView(
      summary: summary,
      note: _normalizeOptional(header.readNullable<String>('note')),
      lines: lines,
    );
  }

  Future<LotStatusSnapshotView> loadLotStatusSnapshot({
    String? warehouseId,
    String? productId,
    bool alertsOnly = false,
    int limit = 500,
  }) async {
    final String safeWarehouseId = (warehouseId ?? '').trim();
    final String safeProductId = (productId ?? '').trim();
    final int safeLimit = limit < 1 ? 1 : limit;

    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        l.id AS lot_id,
        l.product_id AS product_id,
        COALESCE(p.name, 'Producto') AS product_name,
        COALESCE(p.sku, '-') AS sku,
        l.warehouse_id AS warehouse_id,
        COALESCE(w.name, 'Almacen') AS warehouse_name,
        COALESCE(l.qty_in, 0) AS qty_in,
        COALESCE(l.qty_remaining, 0) AS qty_remaining,
        COALESCE(l.unit_cost_cents, 0) AS unit_cost_cents,
        l.received_at AS received_at,
        COALESCE(l.source_type, '') AS source_type,
        l.source_id AS source_id,
        l.note AS note
      FROM stock_lots l
      LEFT JOIN products p ON p.id = l.product_id
      LEFT JOIN warehouses w ON w.id = l.warehouse_id
      WHERE 1 = 1
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (safeWarehouseId.isNotEmpty) {
      sql.write(' AND l.warehouse_id = ?');
      variables.add(Variable<String>(safeWarehouseId));
    }
    if (safeProductId.isNotEmpty) {
      sql.write(' AND l.product_id = ?');
      variables.add(Variable<String>(safeProductId));
    }
    if (alertsOnly) {
      sql.write(
        '''
         AND (
          COALESCE(l.qty_remaining, 0) <= 0
          OR (
            COALESCE(l.qty_in, 0) > 0
            AND (COALESCE(l.qty_remaining, 0) / COALESCE(l.qty_in, 1)) <= 0.2
          )
        )
        ''',
      );
    }
    sql.write(
      '''
      ORDER BY
        COALESCE(l.qty_remaining, 0) ASC,
        COALESCE(l.received_at, l.created_at) ASC,
        l.id ASC
      LIMIT ?
      ''',
    );
    variables.add(Variable<int>(safeLimit));

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    final List<LotStatusRowView> mapped = rows
        .map((QueryRow row) {
          return LotStatusRowView(
            lotId: (row.readNullable<String>('lot_id') ?? '').trim(),
            productId: (row.readNullable<String>('product_id') ?? '').trim(),
            productName:
                (row.readNullable<String>('product_name') ?? 'Producto').trim(),
            sku: (row.readNullable<String>('sku') ?? '-').trim(),
            warehouseId:
                (row.readNullable<String>('warehouse_id') ?? '').trim(),
            warehouseName:
                (row.readNullable<String>('warehouse_name') ?? 'Almacen')
                    .trim(),
            qtyIn: (row.data['qty_in'] as num?)?.toDouble() ?? 0,
            qtyRemaining: (row.data['qty_remaining'] as num?)?.toDouble() ?? 0,
            unitCostCents: (row.data['unit_cost_cents'] as num?)?.toInt() ?? 0,
            receivedAt:
                row.readNullable<DateTime>('received_at') ?? DateTime.now(),
            sourceType: (row.readNullable<String>('source_type') ?? '').trim(),
            sourceId: _normalizeOptional(row.readNullable<String>('source_id')),
            note: _normalizeOptional(row.readNullable<String>('note')),
          );
        })
        .where((LotStatusRowView row) => row.lotId.isNotEmpty)
        .toList(growable: false);

    int activeLots = 0;
    int depletedLots = 0;
    int lowLots = 0;
    for (final LotStatusRowView row in mapped) {
      if (row.isDepleted) {
        depletedLots += 1;
      } else {
        activeLots += 1;
      }
      if (row.isLow) {
        lowLots += 1;
      }
    }

    return LotStatusSnapshotView(
      rows: mapped,
      totalLots: mapped.length,
      activeLots: activeLots,
      depletedLots: depletedLots,
      lowLots: lowLots,
    );
  }

  Future<CreatePurchaseResult> createPurchase(CreatePurchaseInput input) async {
    await _licenseService.requireWriteAccess();
    final String safeWarehouseId = input.warehouseId.trim();
    final String safeUserId = input.userId.trim();
    final List<PurchaseLineInput> lines = input.lines
        .where((PurchaseLineInput row) => row.productId.trim().isNotEmpty)
        .toList(growable: false);

    if (safeWarehouseId.isEmpty) {
      throw Exception('Debes seleccionar un almacén válido.');
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }
    if (lines.isEmpty) {
      throw Exception('La compra debe tener al menos una línea.');
    }

    return _db.transaction(() async {
      final Warehouse? warehouse = await (_db.select(_db.warehouses)
            ..where((Warehouses tbl) =>
                tbl.id.equals(safeWarehouseId) & tbl.isActive.equals(true)))
          .getSingleOrNull();
      if (warehouse == null) {
        throw Exception('El almacén seleccionado no es válido.');
      }

      final User? user = await (_db.select(_db.users)
            ..where((Users tbl) => tbl.id.equals(safeUserId)))
          .getSingleOrNull();
      if (user == null || !user.isActive) {
        throw Exception('El usuario no es válido o está inactivo.');
      }

      final DateTime now = input.createdAt ?? DateTime.now();
      final String folio = await _nextPurchaseFolio(now);
      final String purchaseId = _uuid.v4();
      final String? supplierName = _normalizeOptional(input.supplierName);
      final String? supplierDoc = _normalizeOptional(input.supplierDoc);
      final String? note = _normalizeOptional(input.note);

      int totalCents = 0;
      final List<_PreparedPurchaseLine> prepared = <_PreparedPurchaseLine>[];
      final Set<String> affectedProductIds = <String>{};
      for (final PurchaseLineInput line in lines) {
        if (line.qty <= 0) {
          throw Exception('Todas las cantidades deben ser mayores que 0.');
        }
        if (line.unitCostCents < 0) {
          throw Exception('El costo unitario no puede ser negativo.');
        }
        final String productId = line.productId.trim();
        final Product? product = await (_db.select(_db.products)
              ..where((Products tbl) => tbl.id.equals(productId)))
            .getSingleOrNull();
        if (product == null || !product.isActive) {
          throw Exception('Producto inválido en la compra: $productId');
        }
        final int lineCostCents = (line.qty * line.unitCostCents).round();
        totalCents += lineCostCents;
        prepared.add(
          _PreparedPurchaseLine(
            product: product,
            qty: line.qty,
            unitCostCents: line.unitCostCents,
            lineCostCents: lineCostCents,
          ),
        );
        affectedProductIds.add(product.id);
      }

      await _db.into(_db.purchases).insert(
            PurchasesCompanion.insert(
              id: purchaseId,
              folio: folio,
              warehouseId: safeWarehouseId,
              supplierName: Value(supplierName),
              supplierDoc: Value(supplierDoc),
              note: Value(note),
              createdBy: safeUserId,
              createdAt: Value(now),
            ),
          );

      for (final _PreparedPurchaseLine line in prepared) {
        final String purchaseItemId = _uuid.v4();
        await _db.into(_db.purchaseItems).insert(
              PurchaseItemsCompanion.insert(
                id: purchaseItemId,
                purchaseId: purchaseId,
                productId: line.product.id,
                qty: line.qty,
                unitCostCents: Value(line.unitCostCents),
                lineCostCents: Value(line.lineCostCents),
                unitPriceSnapshotCents: Value(line.product.priceCents),
              ),
            );

        await _db.into(_db.stockLots).insert(
              StockLotsCompanion.insert(
                id: _uuid.v4(),
                productId: line.product.id,
                warehouseId: safeWarehouseId,
                purchaseItemId: Value(purchaseItemId),
                sourceType: const Value('purchase'),
                sourceId: Value(purchaseId),
                qtyIn: Value(line.qty),
                qtyRemaining: Value(line.qty),
                unitCostCents: Value(line.unitCostCents),
                receivedAt: Value(now),
                createdAt: Value(now),
                note: Value(note),
              ),
            );

        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: _uuid.v4(),
                productId: line.product.id,
                warehouseId: safeWarehouseId,
                type: 'in',
                qty: line.qty,
                reasonCode: const Value('purchase'),
                movementSource: const Value('purchase'),
                refType: const Value('purchase'),
                refId: Value(purchaseId),
                note: Value('Compra $folio'),
                createdBy: safeUserId,
                createdAt: Value(now),
              ),
            );

        await _applyStockDelta(
          productId: line.product.id,
          warehouseId: safeWarehouseId,
          delta: line.qty,
          now: now,
        );
      }

      for (final String productId in affectedProductIds) {
        await _syncProductCostFromActiveLot(
          productId: productId,
          now: now,
        );
      }

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'PURCHASE_POSTED',
              entity: 'purchase',
              entityId: purchaseId,
              payloadJson: jsonEncode(<String, Object?>{
                'folio': folio,
                'warehouseId': safeWarehouseId,
                'lines': prepared.length,
                'totalCents': totalCents,
                'supplierName': supplierName,
                'supplierDoc': supplierDoc,
              }),
            ),
          );

      return CreatePurchaseResult(
        purchaseId: purchaseId,
        folio: folio,
        totalCents: totalCents,
      );
    });
  }

  Future<void> _applyStockDelta({
    required String productId,
    required String warehouseId,
    required double delta,
    required DateTime now,
  }) async {
    final StockBalance? balance = await (_db.select(_db.stockBalances)
          ..where(
            (StockBalances tbl) =>
                tbl.productId.equals(productId) &
                tbl.warehouseId.equals(warehouseId),
          ))
        .getSingleOrNull();
    if (balance == null) {
      await _db.into(_db.stockBalances).insert(
            StockBalancesCompanion.insert(
              productId: productId,
              warehouseId: warehouseId,
              qty: Value(delta),
              updatedAt: Value(now),
            ),
          );
      return;
    }
    await (_db.update(_db.stockBalances)
          ..where(
            (StockBalances tbl) =>
                tbl.productId.equals(productId) &
                tbl.warehouseId.equals(warehouseId),
          ))
        .write(
      StockBalancesCompanion(
        qty: Value(balance.qty + delta),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> _syncProductCostFromActiveLot({
    required String productId,
    required DateTime now,
  }) async {
    final String safeProductId = productId.trim();
    if (safeProductId.isEmpty) {
      return;
    }

    final QueryRow? lotRow = await _db.customSelect(
      '''
      SELECT
        COALESCE(l.unit_cost_cents, 0) AS unit_cost_cents
      FROM stock_lots l
      WHERE l.product_id = ?
        AND COALESCE(l.qty_remaining, 0) > 0
      ORDER BY l.received_at ASC, l.created_at ASC, l.id ASC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeProductId),
      ],
    ).getSingleOrNull();

    if (lotRow == null) {
      return;
    }

    final int unitCostCents =
        (lotRow.data['unit_cost_cents'] as num?)?.toInt() ?? 0;
    await (_db.update(_db.products)
          ..where((Products tbl) => tbl.id.equals(safeProductId)))
        .write(
      ProductsCompanion(
        costPriceCents: Value(unitCostCents < 0 ? 0 : unitCostCents),
        updatedAt: Value(now),
      ),
    );
  }

  Future<String> _nextPurchaseFolio(DateTime now) async {
    final String y = now.year.toString().padLeft(4, '0');
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    final String ss = now.second.toString().padLeft(2, '0');
    final String base = 'CMP-$y$m$d-$hh$mm$ss';
    String candidate = base;
    int suffix = 1;

    while (true) {
      final Purchase? existing = await (_db.select(_db.purchases)
            ..where((Purchases tbl) => tbl.folio.equals(candidate)))
          .getSingleOrNull();
      if (existing == null) {
        return candidate;
      }
      candidate = '$base-$suffix';
      suffix += 1;
    }
  }

  String? _normalizeOptional(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }
}

class _PreparedPurchaseLine {
  const _PreparedPurchaseLine({
    required this.product,
    required this.qty,
    required this.unitCostCents,
    required this.lineCostCents,
  });

  final Product product;
  final double qty;
  final int unitCostCents;
  final int lineCostCents;
}
