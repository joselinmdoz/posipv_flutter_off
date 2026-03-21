import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';

class InventoryView {
  const InventoryView({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.priceCents,
    required this.taxRateBps,
    this.currencyCode = 'USD',
    this.imagePath,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final int priceCents;
  final int taxRateBps;
  final String currencyCode;
  final String? imagePath;
}

class InventoryWarehouseStockView {
  const InventoryWarehouseStockView({
    required this.warehouseId,
    required this.warehouseName,
    required this.qty,
  });

  final String warehouseId;
  final String warehouseName;
  final double qty;
}

enum InventoryListFilter { all, inStock, lowStock, outOfStock }

class InventoryMovementReason {
  const InventoryMovementReason({
    required this.code,
    required this.label,
    required this.appliesTo,
    this.isSystem = false,
    this.hiddenInManualSelector = false,
  });

  final String code;
  final String label;
  final String appliesTo;
  final bool isSystem;
  final bool hiddenInManualSelector;

  bool supportsType(String movementType) {
    if (appliesTo == 'both') {
      return true;
    }
    return appliesTo == movementType;
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'code': code,
      'label': label,
      'appliesTo': appliesTo,
      'isSystem': isSystem,
      'hiddenInManualSelector': hiddenInManualSelector,
    };
  }

  InventoryMovementReason copyWith({
    String? code,
    String? label,
    String? appliesTo,
    bool? isSystem,
    bool? hiddenInManualSelector,
  }) {
    return InventoryMovementReason(
      code: code ?? this.code,
      label: label ?? this.label,
      appliesTo: appliesTo ?? this.appliesTo,
      isSystem: isSystem ?? this.isSystem,
      hiddenInManualSelector:
          hiddenInManualSelector ?? this.hiddenInManualSelector,
    );
  }
}

class InventoryMovementView {
  const InventoryMovementView({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.warehouseId,
    required this.warehouseName,
    required this.movementType,
    required this.qty,
    required this.reasonCode,
    required this.reasonLabel,
    required this.movementSource,
    required this.refType,
    required this.refId,
    required this.note,
    required this.createdBy,
    required this.username,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String warehouseId;
  final String warehouseName;
  final String movementType;
  final double qty;
  final String reasonCode;
  final String reasonLabel;
  final String movementSource;
  final String? refType;
  final String? refId;
  final String? note;
  final String createdBy;
  final String username;
  final DateTime createdAt;
}

class InventarioLocalDataSource {
  InventarioLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  static const String _movementReasonsKey = 'inventory_movement_reasons_v1';

  static const List<InventoryMovementReason> _defaultReasons =
      <InventoryMovementReason>[
    InventoryMovementReason(
      code: 'sale',
      label: 'Venta',
      appliesTo: 'out',
      isSystem: true,
      hiddenInManualSelector: true,
    ),
    InventoryMovementReason(
      code: 'purchase',
      label: 'Compra',
      appliesTo: 'in',
    ),
    InventoryMovementReason(
      code: 'adjust',
      label: 'Ajuste',
      appliesTo: 'both',
    ),
    InventoryMovementReason(
      code: 'breakage',
      label: 'Rotura',
      appliesTo: 'out',
    ),
    InventoryMovementReason(
      code: 'shrinkage',
      label: 'Merma',
      appliesTo: 'out',
    ),
  ];

  Future<List<InventoryWarehouseStockView>> listProductStockByWarehouses(
    String productId,
  ) async {
    final String cleanProductId = productId.trim();
    if (cleanProductId.isEmpty) {
      return const <InventoryWarehouseStockView>[];
    }

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        w.id AS warehouse_id,
        w.name AS warehouse_name,
        COALESCE(sb.qty, 0.0) AS qty
      FROM warehouses w
      LEFT JOIN stock_balances sb
        ON sb.warehouse_id = w.id
       AND sb.product_id = ?
      WHERE w.is_active = 1
      ORDER BY w.name ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(cleanProductId),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return InventoryWarehouseStockView(
        warehouseId: (row.readNullable<String>('warehouse_id') ?? '').trim(),
        warehouseName:
            (row.readNullable<String>('warehouse_name') ?? '-').trim(),
        qty: row.read<double>('qty'),
      );
    }).toList();
  }

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

  Future<List<InventoryView>> listStocked({String? warehouseId}) async {
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        SUM(sb.qty) AS qty
      FROM stock_balances sb
      INNER JOIN products p
        ON p.id = sb.product_id
      WHERE p.is_active = 1
        AND sb.qty > 0
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      sql.write(' AND sb.warehouse_id = ?');
      variables.add(Variable<String>(warehouseId.trim()));
    }
    sql.write(
      '''
      GROUP BY p.id, p.name, p.sku, p.price_cents, p.tax_rate_bps
      ORDER BY p.name ASC
      ''',
    );

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    return rows.map((QueryRow row) {
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

  Future<List<InventoryView>> listStockedPage({
    String? warehouseId,
    String? search,
    int limit = 60,
    int offset = 0,
  }) async {
    final int safeLimit = limit < 1 ? 1 : limit;
    final int safeOffset = offset < 0 ? 0 : offset;
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        SUM(sb.qty) AS qty
      FROM stock_balances sb
      INNER JOIN products p
        ON p.id = sb.product_id
      WHERE p.is_active = 1
        AND sb.qty > 0
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];

    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      sql.write(' AND sb.warehouse_id = ?');
      variables.add(Variable<String>(warehouseId.trim()));
    }

    if (cleanedSearch.isNotEmpty) {
      sql.write(
        '''
         AND (
           LOWER(p.name) LIKE ?
           OR LOWER(p.sku) LIKE ?
           OR LOWER(COALESCE(p.barcode, '')) LIKE ?
         )
        ''',
      );
      final String pattern = '%$cleanedSearch%';
      variables.addAll(<Variable<Object>>[
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
      ]);
    }

    sql.write(
      '''
      GROUP BY p.id, p.name, p.sku, p.price_cents, p.tax_rate_bps
      ORDER BY p.name ASC
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

    return rows.map((QueryRow row) {
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

  Future<List<InventoryView>> listInventoryPage({
    String? warehouseId,
    String? search,
    int limit = 60,
    int offset = 0,
    InventoryListFilter filter = InventoryListFilter.all,
    double lowStockThreshold = 10,
  }) async {
    final int safeLimit = limit < 1 ? 1 : limit;
    final int safeOffset = offset < 0 ? 0 : offset;
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        p.currency_code,
        p.image_path,
        COALESCE(SUM(sb.qty), 0) AS qty
      FROM products p
      LEFT JOIN stock_balances sb
        ON sb.product_id = p.id
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];

    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      sql.write(' AND sb.warehouse_id = ?');
      variables.add(Variable<String>(warehouseId.trim()));
    }

    sql.write(
      '''
      WHERE p.is_active = 1
        AND p.id IS NOT NULL
        AND p.name IS NOT NULL
        AND p.sku IS NOT NULL
        AND p.price_cents IS NOT NULL
        AND p.tax_rate_bps IS NOT NULL
      ''',
    );

    if (cleanedSearch.isNotEmpty) {
      sql.write(
        '''
         AND (
           LOWER(p.name) LIKE ?
           OR LOWER(p.sku) LIKE ?
           OR LOWER(COALESCE(p.barcode, '')) LIKE ?
         )
        ''',
      );
      final String pattern = '%$cleanedSearch%';
      variables.addAll(<Variable<Object>>[
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
      ]);
    }

    sql.write(
      '''
      GROUP BY
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        p.currency_code,
        p.image_path
      ''',
    );

    const String qtyExpr = 'COALESCE(SUM(sb.qty), 0)';
    switch (filter) {
      case InventoryListFilter.all:
        break;
      case InventoryListFilter.inStock:
        sql.write(' HAVING $qtyExpr > ?');
        variables.add(Variable<double>(lowStockThreshold));
        break;
      case InventoryListFilter.lowStock:
        sql.write(' HAVING $qtyExpr > 0 AND $qtyExpr <= ?');
        variables.add(Variable<double>(lowStockThreshold));
        break;
      case InventoryListFilter.outOfStock:
        sql.write(' HAVING $qtyExpr <= 0');
        break;
    }

    sql.write(
      '''
      ORDER BY p.name ASC
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

    return rows.map((QueryRow row) {
      return InventoryView(
        productId: row.read<String>('id'),
        productName: row.read<String>('name'),
        sku: row.read<String>('sku'),
        qty: row.read<double>('qty'),
        priceCents: row.read<int>('price_cents'),
        taxRateBps: row.read<int>('tax_rate_bps'),
        currencyCode:
            (row.readNullable<String>('currency_code') ?? 'USD').trim(),
        imagePath: row.readNullable<String>('image_path'),
      );
    }).toList();
  }

  Future<List<InventoryMovementReason>> listMovementReasons() async {
    final AppSetting? setting = await (_db.select(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(_movementReasonsKey)))
        .getSingleOrNull();
    final List<InventoryMovementReason> parsed = setting == null
        ? List<InventoryMovementReason>.from(_defaultReasons)
        : _decodeReasons(setting.value);
    final List<InventoryMovementReason> normalized = _normalizeReasons(parsed);

    if (setting == null || _encodeReasons(normalized) != setting.value) {
      await _saveReasons(normalized);
    }
    return normalized;
  }

  Future<List<InventoryMovementReason>> listManualMovementReasons({
    String? movementType,
  }) async {
    final String? safeType =
        movementType == null ? null : _sanitizeMovementType(movementType);
    final List<InventoryMovementReason> reasons = await listMovementReasons();
    return reasons.where((InventoryMovementReason reason) {
      if (reason.hiddenInManualSelector) {
        return false;
      }
      if (safeType == null) {
        return true;
      }
      return reason.supportsType(safeType);
    }).toList();
  }

  Future<void> createMovementReason({
    required String label,
    required String appliesTo,
  }) async {
    await _licenseService.requireWriteAccess();
    final String cleanLabel = label.trim();
    if (cleanLabel.isEmpty) {
      throw Exception('El motivo es obligatorio.');
    }
    final String safeAppliesTo = _sanitizeReasonAppliesTo(appliesTo);
    final List<InventoryMovementReason> reasons = await listMovementReasons();

    String code = _slug(cleanLabel);
    if (code.isEmpty) {
      throw Exception('No se pudo generar un codigo para el motivo.');
    }
    if (code == 'sale') {
      code = 'sale-2';
    }
    final Set<String> existingCodes =
        reasons.map((InventoryMovementReason row) => row.code).toSet();
    if (existingCodes.contains(code)) {
      int suffix = 2;
      while (existingCodes.contains('$code-$suffix')) {
        suffix += 1;
      }
      code = '$code-$suffix';
    }

    final List<InventoryMovementReason> updated =
        List<InventoryMovementReason>.from(reasons)
          ..add(
            InventoryMovementReason(
              code: code,
              label: cleanLabel,
              appliesTo: safeAppliesTo,
            ),
          );
    await _saveReasons(_normalizeReasons(updated));
  }

  Future<void> updateMovementReason({
    required String code,
    required String label,
    required String appliesTo,
  }) async {
    await _licenseService.requireWriteAccess();
    final String cleanCode = _sanitizeReasonCode(code);
    if (cleanCode.isEmpty) {
      throw Exception('Motivo invalido.');
    }
    if (cleanCode == 'sale') {
      throw Exception('El motivo "Venta" no se puede editar.');
    }
    final String cleanLabel = label.trim();
    if (cleanLabel.isEmpty) {
      throw Exception('El motivo es obligatorio.');
    }
    final String safeAppliesTo = _sanitizeReasonAppliesTo(appliesTo);
    final List<InventoryMovementReason> reasons = await listMovementReasons();
    final int index = reasons.indexWhere(
      (InventoryMovementReason row) => row.code == cleanCode,
    );
    if (index < 0) {
      throw Exception('El motivo no existe.');
    }
    if (reasons[index].isSystem) {
      throw Exception('Este motivo no se puede editar.');
    }

    final List<InventoryMovementReason> updated =
        List<InventoryMovementReason>.from(reasons);
    updated[index] = updated[index].copyWith(
      label: cleanLabel,
      appliesTo: safeAppliesTo,
    );
    await _saveReasons(_normalizeReasons(updated));
  }

  Future<void> deleteMovementReason(String code) async {
    await _licenseService.requireWriteAccess();
    final String cleanCode = _sanitizeReasonCode(code);
    if (cleanCode.isEmpty) {
      throw Exception('Motivo invalido.');
    }
    if (cleanCode == 'sale') {
      throw Exception('El motivo "Venta" no se puede eliminar.');
    }
    final List<InventoryMovementReason> reasons = await listMovementReasons();
    InventoryMovementReason? target;
    for (final InventoryMovementReason row in reasons) {
      if (row.code == cleanCode) {
        target = row;
        break;
      }
    }
    if (target == null) {
      throw Exception('El motivo no existe.');
    }
    if (target.isSystem) {
      throw Exception('Este motivo no se puede eliminar.');
    }

    final List<InventoryMovementReason> updated = reasons
        .where((InventoryMovementReason row) => row.code != cleanCode)
        .toList();
    await _saveReasons(_normalizeReasons(updated));
  }

  Future<List<InventoryMovementView>> listMovements({
    String? warehouseId,
    String? movementType,
    String? reasonCode,
    int limit = 250,
  }) async {
    final String? safeType = movementType == null || movementType == 'all'
        ? null
        : _sanitizeMovementType(movementType);
    final String? safeReason = reasonCode == null || reasonCode == 'all'
        ? null
        : _sanitizeReasonCode(reasonCode);

    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        sm.id AS id,
        sm.product_id AS product_id,
        p.name AS product_name,
        p.sku AS sku,
        sm.warehouse_id AS warehouse_id,
        w.name AS warehouse_name,
        sm.type AS type,
        sm.qty AS qty,
        sm.reason_code AS reason_code,
        sm.movement_source AS movement_source,
        sm.ref_type AS ref_type,
        sm.ref_id AS ref_id,
        sm.note AS note,
        sm.created_by AS created_by,
        u.username AS username,
        sm.created_at AS created_at
      FROM stock_movements sm
      LEFT JOIN products p ON p.id = sm.product_id
      LEFT JOIN warehouses w ON w.id = sm.warehouse_id
      LEFT JOIN users u ON u.id = sm.created_by
      WHERE 1 = 1
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];

    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      sql.write(' AND sm.warehouse_id = ?');
      variables.add(Variable<String>(warehouseId.trim()));
    }
    if (safeType != null) {
      sql.write(
        '''
        AND (
          sm.type = ?
          OR (
            sm.type = 'adjust'
            AND (
              (? = 'in' AND sm.qty >= 0)
              OR (? = 'out' AND sm.qty < 0)
            )
          )
        )
        ''',
      );
      variables.add(Variable<String>(safeType));
      variables.add(Variable<String>(safeType));
      variables.add(Variable<String>(safeType));
    }
    if (safeReason != null && safeReason.isNotEmpty) {
      sql.write(' AND LOWER(COALESCE(sm.reason_code, \'\')) = ?');
      variables.add(Variable<String>(safeReason));
    }

    sql.write(' ORDER BY sm.created_at DESC LIMIT ?');
    variables.add(Variable<int>(limit < 1 ? 1 : limit));

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    final List<InventoryMovementReason> reasons = await listMovementReasons();
    final Map<String, String> reasonLabelByCode = <String, String>{
      for (final InventoryMovementReason reason in reasons)
        reason.code: reason.label,
    };

    return rows.map((QueryRow row) {
      final String rawType = (row.read<String>('type')).trim().toLowerCase();
      final double rawQty = row.read<double>('qty');
      final String movementType = _normalizeMovementType(rawType, rawQty);
      final String? refType = row.readNullable<String>('ref_type');
      final String reason = _resolveReasonCode(
        explicitReasonCode: row.readNullable<String>('reason_code'),
        refType: refType,
      );
      final String movementSource = _resolveMovementSource(
        explicitSource: row.readNullable<String>('movement_source'),
        refType: refType,
      );

      final String createdBy = row.read<String>('created_by');
      final String username =
          (row.readNullable<String>('username') ?? '').trim();
      return InventoryMovementView(
        id: row.read<String>('id'),
        productId: row.read<String>('product_id'),
        productName: (row.readNullable<String>('product_name') ?? '-').trim(),
        sku: (row.readNullable<String>('sku') ?? '-').trim(),
        warehouseId: row.read<String>('warehouse_id'),
        warehouseName:
            (row.readNullable<String>('warehouse_name') ?? '-').trim(),
        movementType: movementType,
        qty: rawQty.abs(),
        reasonCode: reason,
        reasonLabel: reasonLabelByCode[reason] ?? _fallbackReasonLabel(reason),
        movementSource: movementSource,
        refType: refType,
        refId: row.readNullable<String>('ref_id'),
        note: row.readNullable<String>('note'),
        createdBy: createdBy,
        username: username.isEmpty ? createdBy : username,
        createdAt: row.read<DateTime>('created_at'),
      );
    }).toList();
  }

  Future<void> createManualMovement({
    required String productId,
    required String warehouseId,
    required String type,
    required double qty,
    required String reasonCode,
    required String userId,
    String? note,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeType = _sanitizeMovementType(type);
    if (qty <= 0) {
      throw Exception('La cantidad debe ser mayor que 0.');
    }
    final String safeReasonCode = _sanitizeReasonCode(reasonCode);
    final List<InventoryMovementReason> manualReasons =
        await listManualMovementReasons(movementType: safeType);
    final bool reasonAllowed = manualReasons.any(
      (InventoryMovementReason row) => row.code == safeReasonCode,
    );
    if (!reasonAllowed) {
      throw Exception('Motivo de movimiento invalido.');
    }

    await _db.transaction(() async {
      final StockBalance? current = await (_db.select(_db.stockBalances)
            ..where(
              (StockBalances tbl) =>
                  tbl.productId.equals(productId) &
                  tbl.warehouseId.equals(warehouseId),
            ))
          .getSingleOrNull();
      final double oldQty = current?.qty ?? 0;
      final double nextQty = safeType == 'in' ? oldQty + qty : oldQty - qty;
      if (nextQty < 0) {
        throw Exception('La salida supera el stock disponible.');
      }

      await _upsertStockBalance(
        productId: productId,
        warehouseId: warehouseId,
        qty: nextQty,
      );

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: _uuid.v4(),
              productId: productId,
              warehouseId: warehouseId,
              type: safeType,
              qty: qty,
              reasonCode: Value(safeReasonCode),
              movementSource: const Value('manual'),
              refType: const Value('manual_move'),
              refId: const Value(null),
              note: Value(_normalizeOptional(note)),
              createdBy: userId,
            ),
          );
    });
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

      await _upsertStockBalance(
        productId: productId,
        warehouseId: warehouseId,
        qty: qty,
      );

      if (delta.abs() < 0.000001) {
        return;
      }

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: _uuid.v4(),
              productId: productId,
              warehouseId: warehouseId,
              type: delta > 0 ? 'in' : 'out',
              qty: delta.abs(),
              reasonCode: const Value('adjust'),
              movementSource: const Value('manual'),
              refType: const Value('adjust'),
              refId: const Value(null),
              note: Value(note),
              createdBy: userId,
            ),
          );
    });
  }

  Future<void> _upsertStockBalance({
    required String productId,
    required String warehouseId,
    required double qty,
  }) async {
    final StockBalance? current = await (_db.select(_db.stockBalances)
          ..where(
            (StockBalances tbl) =>
                tbl.productId.equals(productId) &
                tbl.warehouseId.equals(warehouseId),
          ))
        .getSingleOrNull();

    if (current == null) {
      await _db.into(_db.stockBalances).insert(
            StockBalancesCompanion.insert(
              productId: productId,
              warehouseId: warehouseId,
              qty: Value(qty),
              updatedAt: Value(DateTime.now()),
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
        qty: Value(qty),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _saveReasons(List<InventoryMovementReason> reasons) async {
    final String value = _encodeReasons(reasons);
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _movementReasonsKey,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  List<InventoryMovementReason> _decodeReasons(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) {
        return <InventoryMovementReason>[];
      }

      final List<InventoryMovementReason> result = <InventoryMovementReason>[];
      for (final Object? item in decoded) {
        if (item is! Map<String, Object?>) {
          continue;
        }
        final String code = _sanitizeReasonCode(item['code'] as String? ?? '');
        final String label = (item['label'] as String? ?? '').trim();
        if (code.isEmpty || label.isEmpty) {
          continue;
        }
        final String appliesTo = _sanitizeReasonAppliesTo(
          item['appliesTo'] as String? ?? 'both',
        );
        final bool isSystem = item['isSystem'] == true;
        final bool hiddenManual = item['hiddenInManualSelector'] == true;
        result.add(
          InventoryMovementReason(
            code: code,
            label: label,
            appliesTo: appliesTo,
            isSystem: isSystem,
            hiddenInManualSelector: hiddenManual,
          ),
        );
      }
      return result;
    } catch (_) {
      return <InventoryMovementReason>[];
    }
  }

  List<InventoryMovementReason> _normalizeReasons(
    List<InventoryMovementReason> raw,
  ) {
    final Map<String, InventoryMovementReason> byCode =
        <String, InventoryMovementReason>{};
    for (final InventoryMovementReason row in raw) {
      final String code = _sanitizeReasonCode(row.code);
      if (code.isEmpty) {
        continue;
      }
      if (code == 'sale') {
        continue;
      }
      final String label = row.label.trim();
      if (label.isEmpty) {
        continue;
      }
      byCode[code] = row.copyWith(
        code: code,
        label: label,
        appliesTo: _sanitizeReasonAppliesTo(row.appliesTo),
      );
    }

    if (byCode.values.every((InventoryMovementReason row) {
      return row.hiddenInManualSelector;
    })) {
      byCode['adjust'] = const InventoryMovementReason(
        code: 'adjust',
        label: 'Ajuste',
        appliesTo: 'both',
      );
    }

    final List<InventoryMovementReason> ordered = byCode.values.toList()
      ..sort(
        (InventoryMovementReason a, InventoryMovementReason b) {
          return a.label.toLowerCase().compareTo(b.label.toLowerCase());
        },
      );

    return <InventoryMovementReason>[
      const InventoryMovementReason(
        code: 'sale',
        label: 'Venta',
        appliesTo: 'out',
        isSystem: true,
        hiddenInManualSelector: true,
      ),
      ...ordered,
    ];
  }

  String _encodeReasons(List<InventoryMovementReason> reasons) {
    return jsonEncode(
      reasons.map((InventoryMovementReason row) => row.toJson()).toList(),
    );
  }

  String _sanitizeMovementType(String raw) {
    final String value = raw.trim().toLowerCase();
    if (value != 'in' && value != 'out') {
      throw Exception('Tipo de movimiento invalido.');
    }
    return value;
  }

  String _sanitizeReasonAppliesTo(String raw) {
    final String value = raw.trim().toLowerCase();
    if (value == 'in' || value == 'out' || value == 'both') {
      return value;
    }
    return 'both';
  }

  String _sanitizeReasonCode(String raw) {
    return _slug(raw);
  }

  String _normalizeMovementType(String rawType, double rawQty) {
    if (rawType == 'in' || rawType == 'out') {
      return rawType;
    }
    return rawQty >= 0 ? 'in' : 'out';
  }

  String _resolveReasonCode({
    required String? explicitReasonCode,
    required String? refType,
  }) {
    final String explicit = _sanitizeReasonCode(explicitReasonCode ?? '');
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final String normalizedRefType = (refType ?? '').trim().toLowerCase();
    if (normalizedRefType == 'sale' ||
        normalizedRefType == 'sale_pos' ||
        normalizedRefType == 'sale_direct') {
      return 'sale';
    }
    return 'adjust';
  }

  String _resolveMovementSource({
    required String? explicitSource,
    required String? refType,
  }) {
    final String explicit = (explicitSource ?? '').trim().toLowerCase();
    if (explicit.isNotEmpty) {
      return explicit;
    }

    final String normalizedRefType = (refType ?? '').trim().toLowerCase();
    if (normalizedRefType == 'sale_pos' || normalizedRefType == 'sale') {
      return 'pos';
    }
    if (normalizedRefType == 'sale_direct') {
      return 'direct_sale';
    }
    return 'manual';
  }

  String _fallbackReasonLabel(String reasonCode) {
    switch (reasonCode) {
      case 'sale':
        return 'Venta';
      case 'purchase':
        return 'Compra';
      case 'breakage':
        return 'Rotura';
      case 'shrinkage':
        return 'Merma';
      case 'adjust':
        return 'Ajuste';
      default:
        return reasonCode.isEmpty ? 'Sin motivo' : reasonCode;
    }
  }

  String? _normalizeOptional(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
