import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';

class InventoryView {
  const InventoryView({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.totalQty,
    required this.priceCents,
    required this.taxRateBps,
    this.currencyCode = 'USD',
    this.imagePath,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final double totalQty;
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

class InventoryArchivedMovementView {
  const InventoryArchivedMovementView({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.warehouseName,
    required this.movementType,
    required this.qty,
    required this.reasonCode,
    required this.reasonLabel,
    required this.createdByUsername,
    required this.createdAt,
    required this.voidedByUsername,
    required this.voidedAt,
    this.voidNote,
  });

  final String id;
  final String productId;
  final String productName;
  final String sku;
  final String warehouseName;
  final String movementType;
  final double qty;
  final String reasonCode;
  final String reasonLabel;
  final String createdByUsername;
  final DateTime createdAt;
  final String voidedByUsername;
  final DateTime? voidedAt;
  final String? voidNote;
}

class InventoryMovementProductOption {
  const InventoryMovementProductOption({
    required this.productId,
    required this.productName,
    required this.sku,
  });

  final String productId;
  final String productName;
  final String sku;
}

class InventoryMovementExportFilters {
  const InventoryMovementExportFilters({
    this.warehouse = 'Todos',
    this.movementType = 'Todos',
    this.reason = 'Todos',
    this.product = 'Todos',
    this.dateFrom = '-',
    this.dateTo = '-',
    this.search = '-',
  });

  final String warehouse;
  final String movementType;
  final String reason;
  final String product;
  final String dateFrom;
  final String dateTo;
  final String search;
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
  static const String _exportMovementsBlockedMessage =
      'Modo demo: exportar movimientos de inventario (CSV/PDF) '
      'esta disponible solo con licencia activa.';

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
      code: 'consignment_sale',
      label: 'Venta en consignacion',
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
      code: 'transfer',
      label: 'Transferencia',
      appliesTo: 'out',
      isSystem: true,
      hiddenInManualSelector: true,
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
        p.currency_code,
        p.image_path,
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
        totalQty: row.read<double>('qty'),
        priceCents: row.read<int>('price_cents'),
        taxRateBps: row.read<int>('tax_rate_bps'),
        currencyCode:
            (row.readNullable<String>('currency_code') ?? 'USD').trim(),
        imagePath: row.readNullable<String>('image_path'),
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
        p.currency_code,
        p.image_path,
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
      GROUP BY
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        p.currency_code,
        p.image_path
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
        totalQty: row.read<double>('qty'),
        priceCents: row.read<int>('price_cents'),
        taxRateBps: row.read<int>('tax_rate_bps'),
        currencyCode:
            (row.readNullable<String>('currency_code') ?? 'USD').trim(),
        imagePath: row.readNullable<String>('image_path'),
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
        p.currency_code,
        p.image_path,
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
      GROUP BY
        p.id,
        p.name,
        p.sku,
        p.price_cents,
        p.tax_rate_bps,
        p.currency_code,
        p.image_path
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
        totalQty: row.read<double>('qty'),
        priceCents: row.read<int>('price_cents'),
        taxRateBps: row.read<int>('tax_rate_bps'),
        currencyCode:
            (row.readNullable<String>('currency_code') ?? 'USD').trim(),
        imagePath: row.readNullable<String>('image_path'),
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
    final String? cleanWarehouseId =
        (warehouseId == null || warehouseId.trim().isEmpty)
            ? null
            : warehouseId.trim();
    final String scopedQtyExpr = cleanWarehouseId == null
        ? 'COALESCE(SUM(sb.qty), 0)'
        : 'COALESCE(SUM(CASE WHEN sb.warehouse_id = ? THEN sb.qty ELSE 0 END), 0)';
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
        $scopedQtyExpr AS qty,
        COALESCE(SUM(sb.qty), 0) AS total_qty
      FROM products p
      LEFT JOIN stock_balances sb
        ON sb.product_id = p.id
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (cleanWarehouseId != null) {
      variables.add(Variable<String>(cleanWarehouseId));
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

    switch (filter) {
      case InventoryListFilter.all:
        break;
      case InventoryListFilter.inStock:
        sql.write(' HAVING qty > ?');
        variables.add(Variable<double>(lowStockThreshold));
        break;
      case InventoryListFilter.lowStock:
        sql.write(' HAVING qty > 0 AND qty <= ?');
        variables.add(Variable<double>(lowStockThreshold));
        break;
      case InventoryListFilter.outOfStock:
        sql.write(' HAVING qty <= 0');
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
        totalQty: row.read<double>('total_qty'),
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
    String? productId,
    DateTime? createdFrom,
    DateTime? createdTo,
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
        AND COALESCE(sm.is_voided, 0) = 0
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
    if (productId != null && productId.trim().isNotEmpty) {
      sql.write(' AND sm.product_id = ?');
      variables.add(Variable<String>(productId.trim()));
    }
    if (createdFrom != null) {
      sql.write(' AND sm.created_at >= ?');
      variables.add(Variable<DateTime>(createdFrom));
    }
    if (createdTo != null) {
      sql.write(' AND sm.created_at < ?');
      variables.add(Variable<DateTime>(createdTo));
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

  Future<List<InventoryMovementProductOption>> listMovementProducts({
    String? warehouseId,
    int limit = 1000,
  }) async {
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        sm.product_id AS product_id,
        COALESCE(p.name, '') AS product_name,
        COALESCE(p.sku, '') AS sku
      FROM stock_movements sm
      LEFT JOIN products p ON p.id = sm.product_id
      WHERE COALESCE(sm.is_voided, 0) = 0
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      sql.write(' AND sm.warehouse_id = ?');
      variables.add(Variable<String>(warehouseId.trim()));
    }
    sql.write(
      '''
      GROUP BY sm.product_id, p.name, p.sku
      ORDER BY LOWER(COALESCE(p.name, '')), LOWER(COALESCE(p.sku, ''))
      LIMIT ?
      ''',
    );
    variables.add(Variable<int>(limit < 1 ? 1 : limit));

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    return rows
        .map((QueryRow row) {
          final String productId =
              (row.readNullable<String>('product_id') ?? '').trim();
          if (productId.isEmpty) {
            return null;
          }
          final String name =
              (row.readNullable<String>('product_name') ?? '').trim();
          final String sku = (row.readNullable<String>('sku') ?? '').trim();
          return InventoryMovementProductOption(
            productId: productId,
            productName: name.isEmpty ? 'Producto' : name,
            sku: sku.isEmpty ? '-' : sku,
          );
        })
        .whereType<InventoryMovementProductOption>()
        .toList(growable: false);
  }

  Future<String> exportMovementsCsv({
    required List<InventoryMovementView> movements,
    InventoryMovementExportFilters filters =
        const InventoryMovementExportFilters(),
  }) async {
    await _licenseService.requireFullAccess(
      message: _exportMovementsBlockedMessage,
    );
    if (movements.isEmpty) {
      throw Exception('No hay movimientos filtrados para exportar.');
    }
    final DateTime now = DateTime.now();
    final String stamp = _ts(now);
    final Directory dir = await _resolveMovementsExportDir();
    final File file = File(p.join(dir.path, 'movimientos-$stamp.csv'));

    final StringBuffer csv = StringBuffer()
      ..writeln('Reporte,Movimientos de inventario')
      ..writeln('Generado,${_csvCell(_formatDateTimeExport(now))}')
      ..writeln('Registros,${movements.length}')
      ..writeln('Almacen,${_csvCell(filters.warehouse)}')
      ..writeln('Tipo,${_csvCell(filters.movementType)}')
      ..writeln('Motivo,${_csvCell(filters.reason)}')
      ..writeln('Producto,${_csvCell(filters.product)}')
      ..writeln('Fecha desde,${_csvCell(filters.dateFrom)}')
      ..writeln('Fecha hasta,${_csvCell(filters.dateTo)}')
      ..writeln('Busqueda,${_csvCell(filters.search)}')
      ..writeln('')
      ..writeln(
        'ID,Fecha,Almacen,Producto,SKU,Tipo,Cantidad,Motivo,Codigo motivo,Origen,Ref tipo,Ref ID,Nota,Usuario,Usuario ID',
      );

    for (final InventoryMovementView row in movements) {
      csv.writeln(
        <String>[
          _csvCell(row.id),
          _csvCell(_formatDateTimeExport(row.createdAt)),
          _csvCell(row.warehouseName),
          _csvCell(row.productName),
          _csvCell(row.sku),
          _csvCell(_movementTypeLabel(row.movementType)),
          _csvCell(_formatQtyForExport(row.qty)),
          _csvCell(row.reasonLabel),
          _csvCell(row.reasonCode),
          _csvCell(row.movementSource),
          _csvCell(_safeText(row.refType)),
          _csvCell(_safeText(row.refId)),
          _csvCell(_safeText(row.note)),
          _csvCell(row.username),
          _csvCell(row.createdBy),
        ].join(','),
      );
    }

    await file.writeAsString(csv.toString(), encoding: utf8, flush: true);
    return file.path;
  }

  Future<String> exportMovementsPdf({
    required List<InventoryMovementView> movements,
    InventoryMovementExportFilters filters =
        const InventoryMovementExportFilters(),
  }) async {
    await _licenseService.requireFullAccess(
      message: _exportMovementsBlockedMessage,
    );
    if (movements.isEmpty) {
      throw Exception('No hay movimientos filtrados para exportar.');
    }
    final DateTime now = DateTime.now();
    final String stamp = _ts(now);
    final Directory dir = await _resolveMovementsExportDir();
    final File file = File(p.join(dir.path, 'movimientos-$stamp.pdf'));

    final pw.Document doc = pw.Document();
    final String generatedAt = _formatDateTimeExport(now);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(20, 20, 20, 20),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'Movimientos de Inventario',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generado: $generatedAt',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Registros: ${movements.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('Filtros aplicados',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Almacén: ${filters.warehouse}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Tipo: ${filters.movementType}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Motivo: ${filters.reason}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Producto: ${filters.product}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Desde: ${filters.dateFrom}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Hasta: ${filters.dateTo}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Búsqueda: ${filters.search}',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            ...movements.asMap().entries.map(
                  (MapEntry<int, InventoryMovementView> entry) =>
                      _buildMovementPdfCard(entry.value, index: entry.key + 1),
                ),
          ];
        },
      ),
    );

    await file.writeAsBytes(await doc.save(), flush: true);
    return file.path;
  }

  Future<List<InventoryArchivedMovementView>> listArchivedMovements({
    String? warehouseId,
    String? movementType,
    String? search,
    int limit = 250,
  }) async {
    final bool wantsAdjust = movementType == 'adjust';
    final String? safeType = movementType == null ||
            movementType == 'all' ||
            movementType == 'adjust'
        ? null
        : _sanitizeMovementType(movementType);
    final String cleanedSearch = (search ?? '').trim().toLowerCase();

    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        sm.id AS id,
        sm.product_id AS product_id,
        p.name AS product_name,
        p.sku AS sku,
        w.name AS warehouse_name,
        sm.type AS type,
        sm.qty AS qty,
        sm.reason_code AS reason_code,
        sm.ref_type AS ref_type,
        sm.created_by AS created_by,
        uc.username AS created_username,
        sm.created_at AS created_at,
        sm.voided_by AS voided_by,
        uv.username AS voided_username,
        sm.voided_at AS voided_at,
        sm.void_note AS void_note
      FROM stock_movements sm
      LEFT JOIN products p ON p.id = sm.product_id
      LEFT JOIN warehouses w ON w.id = sm.warehouse_id
      LEFT JOIN users uc ON uc.id = sm.created_by
      LEFT JOIN users uv ON uv.id = sm.voided_by
      WHERE COALESCE(sm.is_voided, 0) = 1
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];

    if (warehouseId != null && warehouseId.trim().isNotEmpty) {
      sql.write(' AND sm.warehouse_id = ?');
      variables.add(Variable<String>(warehouseId.trim()));
    }
    if (cleanedSearch.isNotEmpty) {
      sql.write(
        '''
        AND (
          LOWER(COALESCE(p.name, '')) LIKE ?
          OR LOWER(COALESCE(p.sku, '')) LIKE ?
        )
        ''',
      );
      final String pattern = '%$cleanedSearch%';
      variables.add(Variable<String>(pattern));
      variables.add(Variable<String>(pattern));
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
    sql.write(' ORDER BY COALESCE(sm.voided_at, sm.created_at) DESC LIMIT ?');
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

    final List<InventoryArchivedMovementView> mapped = rows.map((QueryRow row) {
      final String rawType =
          (row.readNullable<String>('type') ?? '').trim().toLowerCase();
      final double rawQty = row.readNullable<double>('qty') ?? 0;
      final String movementType = _normalizeMovementType(rawType, rawQty);
      final String reasonCode = _resolveReasonCode(
        explicitReasonCode: row.readNullable<String>('reason_code'),
        refType: row.readNullable<String>('ref_type'),
      );
      final String createdBy =
          (row.readNullable<String>('created_by') ?? '').trim();
      final String voidedBy =
          (row.readNullable<String>('voided_by') ?? '').trim();
      final String createdUsername =
          (row.readNullable<String>('created_username') ?? '').trim();
      final String voidedUsername =
          (row.readNullable<String>('voided_username') ?? '').trim();
      return InventoryArchivedMovementView(
        id: row.read<String>('id'),
        productId: row.read<String>('product_id'),
        productName: (row.readNullable<String>('product_name') ?? '-').trim(),
        sku: (row.readNullable<String>('sku') ?? '-').trim(),
        warehouseName:
            (row.readNullable<String>('warehouse_name') ?? '-').trim(),
        movementType: movementType,
        qty: rawQty.abs(),
        reasonCode: reasonCode,
        reasonLabel: reasonLabelByCode[reasonCode] ??
            _fallbackReasonLabel(
              reasonCode,
            ),
        createdByUsername:
            createdUsername.isEmpty ? createdBy : createdUsername,
        createdAt: row.read<DateTime>('created_at'),
        voidedByUsername: voidedUsername.isEmpty
            ? (voidedBy.isEmpty ? '-' : voidedBy)
            : voidedUsername,
        voidedAt: row.readNullable<DateTime>('voided_at'),
        voidNote: row.readNullable<String>('void_note'),
      );
    }).toList(growable: false);

    if (!wantsAdjust) {
      return mapped;
    }
    return mapped
        .where(
            (InventoryArchivedMovementView row) => row.reasonCode == 'adjust')
        .toList(growable: false);
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
    final String safeProductId = productId.trim();
    final String safeWarehouseId = warehouseId.trim();
    final String safeUserId = userId.trim();
    if (safeProductId.isEmpty || safeWarehouseId.isEmpty) {
      throw Exception('Producto o almacén inválido.');
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }
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
      final DateTime now = DateTime.now();
      final String movementId = _uuid.v4();
      final StockBalance? current = await (_db.select(_db.stockBalances)
            ..where(
              (StockBalances tbl) =>
                  tbl.productId.equals(safeProductId) &
                  tbl.warehouseId.equals(safeWarehouseId),
            ))
          .getSingleOrNull();
      final double oldQty = current?.qty ?? 0;
      final double nextQty = safeType == 'in' ? oldQty + qty : oldQty - qty;
      if (nextQty < 0) {
        throw Exception('La salida supera el stock disponible.');
      }

      await _upsertStockBalance(
        productId: safeProductId,
        warehouseId: safeWarehouseId,
        qty: nextQty,
      );

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: movementId,
              productId: safeProductId,
              warehouseId: safeWarehouseId,
              type: safeType,
              qty: qty,
              reasonCode: Value(safeReasonCode),
              movementSource: const Value('manual'),
              refType: const Value('manual_move'),
              refId: const Value(null),
              note: Value(_normalizeOptional(note)),
              createdBy: safeUserId,
              createdAt: Value(now),
            ),
          );

      await _applyManualMovementLotImpact(
        movementId: movementId,
        productId: safeProductId,
        warehouseId: safeWarehouseId,
        type: safeType,
        qty: qty.abs(),
        note: _normalizeOptional(note),
        userId: safeUserId,
        at: now,
      );
    });
  }

  Future<void> createWarehouseTransfer({
    required String productId,
    required String sourceWarehouseId,
    required String destinationWarehouseId,
    required double qty,
    required String userId,
    String? note,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeProductId = productId.trim();
    final String safeSourceWarehouseId = sourceWarehouseId.trim();
    final String safeDestinationWarehouseId = destinationWarehouseId.trim();
    final String safeUserId = userId.trim();
    if (safeProductId.isEmpty ||
        safeSourceWarehouseId.isEmpty ||
        safeDestinationWarehouseId.isEmpty) {
      throw Exception('Producto o almacén inválido.');
    }
    if (safeSourceWarehouseId == safeDestinationWarehouseId) {
      throw Exception(
        'El almacén destino debe ser diferente al almacén de origen.',
      );
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }
    if (qty <= 0) {
      throw Exception('La cantidad debe ser mayor que 0.');
    }

    await _db.transaction(() async {
      final StockBalance? sourceBalance = await (_db.select(_db.stockBalances)
            ..where(
              (StockBalances tbl) =>
                  tbl.productId.equals(safeProductId) &
                  tbl.warehouseId.equals(safeSourceWarehouseId),
            ))
          .getSingleOrNull();
      final StockBalance? destinationBalance =
          await (_db.select(_db.stockBalances)
                ..where(
                  (StockBalances tbl) =>
                      tbl.productId.equals(safeProductId) &
                      tbl.warehouseId.equals(safeDestinationWarehouseId),
                ))
              .getSingleOrNull();
      final double sourceQty = sourceBalance?.qty ?? 0;
      if (qty > sourceQty) {
        throw Exception('La transferencia supera el stock disponible.');
      }
      final double destinationQty = destinationBalance?.qty ?? 0;
      final DateTime now = DateTime.now();
      final String transferId = _uuid.v4();
      final String outMovementId = _uuid.v4();
      final String inMovementId = _uuid.v4();
      final String? normalizedNote = _normalizeOptional(note);

      await _upsertStockBalance(
        productId: safeProductId,
        warehouseId: safeSourceWarehouseId,
        qty: sourceQty - qty,
      );
      await _upsertStockBalance(
        productId: safeProductId,
        warehouseId: safeDestinationWarehouseId,
        qty: destinationQty + qty,
      );

      final int fallbackCostCents = await _productCostCents(safeProductId);
      final List<_ManualLotAllocation> sourceAllocations =
          await _consumeFifoLotsForManualOut(
        movementId: outMovementId,
        productId: safeProductId,
        warehouseId: safeSourceWarehouseId,
        qty: qty,
        fallbackUnitCostCents: fallbackCostCents,
        note: normalizedNote,
        at: now,
      );

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: outMovementId,
              productId: safeProductId,
              warehouseId: safeSourceWarehouseId,
              type: 'out',
              qty: qty,
              reasonCode: const Value('transfer'),
              movementSource: const Value('transfer'),
              refType: const Value('transfer_out'),
              refId: Value(transferId),
              note: Value(normalizedNote),
              createdBy: safeUserId,
              createdAt: Value(now),
            ),
          );

      final List<_ManualLotAllocation> destinationAllocations =
          <_ManualLotAllocation>[];
      for (final _ManualLotAllocation allocation in sourceAllocations) {
        final String destinationLotId = _uuid.v4();
        final double lineQty = allocation.qty <= 0 ? 0 : allocation.qty;
        if (lineQty <= 0.000001) {
          continue;
        }
        await _db.into(_db.stockLots).insert(
              StockLotsCompanion.insert(
                id: destinationLotId,
                productId: safeProductId,
                warehouseId: safeDestinationWarehouseId,
                purchaseItemId: Value(allocation.purchaseItemId),
                sourceType: const Value('transfer'),
                sourceId: Value(transferId),
                qtyIn: Value(lineQty),
                qtyRemaining: Value(lineQty),
                unitCostCents: Value(allocation.unitCostCents),
                receivedAt: Value(now),
                createdAt: Value(now),
                note: Value(normalizedNote),
              ),
            );
        destinationAllocations.add(
          _ManualLotAllocation(
            lotId: destinationLotId,
            qty: lineQty,
            unitCostCents: allocation.unitCostCents,
            lineCostCents: (lineQty * allocation.unitCostCents).round(),
            purchaseItemId: allocation.purchaseItemId,
          ),
        );
      }

      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: inMovementId,
              productId: safeProductId,
              warehouseId: safeDestinationWarehouseId,
              type: 'in',
              qty: qty,
              reasonCode: const Value('transfer'),
              movementSource: const Value('transfer'),
              refType: const Value('transfer_in'),
              refId: Value(transferId),
              note: Value(normalizedNote),
              createdBy: safeUserId,
              createdAt: Value(now),
            ),
          );

      await _recordManualMovementLotState(
        movementId: outMovementId,
        userId: safeUserId,
        state: _ManualMovementLotState(
          type: 'out',
          allocations: sourceAllocations,
        ),
      );
      await _recordManualMovementLotState(
        movementId: inMovementId,
        userId: safeUserId,
        state: _ManualMovementLotState(
          type: 'in',
          allocations: destinationAllocations,
        ),
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'STOCK_TRANSFER_CREATED',
              entity: 'stock_transfer',
              entityId: transferId,
              payloadJson: jsonEncode(<String, Object?>{
                'productId': safeProductId,
                'sourceWarehouseId': safeSourceWarehouseId,
                'destinationWarehouseId': safeDestinationWarehouseId,
                'qty': qty,
                'outMovementId': outMovementId,
                'inMovementId': inMovementId,
              }),
            ),
          );
    });
  }

  Future<void> updateManualMovement({
    required String movementId,
    required String productId,
    required String warehouseId,
    required String type,
    required double qty,
    required String reasonCode,
    required String userId,
    String? note,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeMovementId = movementId.trim();
    final String safeProductId = productId.trim();
    final String safeWarehouseId = warehouseId.trim();
    final String safeUserId = userId.trim();
    if (safeMovementId.isEmpty) {
      throw Exception('Movimiento inválido.');
    }
    if (safeProductId.isEmpty || safeWarehouseId.isEmpty) {
      throw Exception('Producto o almacén inválido.');
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }
    if (qty <= 0) {
      throw Exception('La cantidad debe ser mayor que 0.');
    }
    final String safeType = _sanitizeMovementType(type);
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
      final StockMovement? existing = await (_db.select(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(safeMovementId)))
          .getSingleOrNull();
      if (existing == null) {
        throw Exception('El movimiento no existe.');
      }
      if (existing.isVoided) {
        throw Exception('No se puede editar un movimiento archivado.');
      }

      final String source = existing.movementSource.trim().toLowerCase();
      final String refType = (existing.refType ?? '').trim().toLowerCase();
      if (source != 'manual' || _isSaleRefType(refType)) {
        throw Exception('Solo se pueden editar movimientos manuales.');
      }

      final double oldSignedDelta = _signedMovementDelta(existing);
      final double nextSignedDelta = safeType == 'in' ? qty.abs() : -qty.abs();

      if (existing.productId == safeProductId &&
          existing.warehouseId == safeWarehouseId) {
        final StockBalance? current = await (_db.select(_db.stockBalances)
              ..where(
                (StockBalances tbl) =>
                    tbl.productId.equals(safeProductId) &
                    tbl.warehouseId.equals(safeWarehouseId),
              ))
            .getSingleOrNull();
        final double oldQty = current?.qty ?? 0;
        final double nextQty = oldQty + (nextSignedDelta - oldSignedDelta);
        if (nextQty < 0) {
          throw Exception('La edición deja el stock en negativo.');
        }
        await _upsertStockBalance(
          productId: safeProductId,
          warehouseId: safeWarehouseId,
          qty: nextQty,
        );
      } else {
        final StockBalance? oldBalance = await (_db.select(_db.stockBalances)
              ..where(
                (StockBalances tbl) =>
                    tbl.productId.equals(existing.productId) &
                    tbl.warehouseId.equals(existing.warehouseId),
              ))
            .getSingleOrNull();
        final double oldBalanceQty = oldBalance?.qty ?? 0;
        final double revertedOldQty = oldBalanceQty - oldSignedDelta;
        if (revertedOldQty < 0) {
          throw Exception(
            'No hay stock suficiente para revertir el movimiento anterior.',
          );
        }
        await _upsertStockBalance(
          productId: existing.productId,
          warehouseId: existing.warehouseId,
          qty: revertedOldQty,
        );

        final StockBalance? nextBalance = await (_db.select(_db.stockBalances)
              ..where(
                (StockBalances tbl) =>
                    tbl.productId.equals(safeProductId) &
                    tbl.warehouseId.equals(safeWarehouseId),
              ))
            .getSingleOrNull();
        final double nextBalanceQty = nextBalance?.qty ?? 0;
        final double nextQty = nextBalanceQty + nextSignedDelta;
        if (nextQty < 0) {
          throw Exception('La edición deja el stock en negativo.');
        }
        await _upsertStockBalance(
          productId: safeProductId,
          warehouseId: safeWarehouseId,
          qty: nextQty,
        );
      }

      await _revertManualMovementLotImpact(
        movementId: existing.id,
        productId: existing.productId,
        warehouseId: existing.warehouseId,
        type: _normalizeMovementType(existing.type, existing.qty),
        qty: existing.qty.abs(),
      );

      final DateTime now = DateTime.now();
      await _applyManualMovementLotImpact(
        movementId: safeMovementId,
        productId: safeProductId,
        warehouseId: safeWarehouseId,
        type: safeType,
        qty: qty.abs(),
        note: _normalizeOptional(note),
        userId: safeUserId,
        at: now,
      );

      await (_db.update(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(safeMovementId)))
          .write(
        StockMovementsCompanion(
          productId: Value(safeProductId),
          warehouseId: Value(safeWarehouseId),
          type: Value(safeType),
          qty: Value(qty.abs()),
          reasonCode: Value(safeReasonCode),
          movementSource: const Value('manual'),
          refType: const Value('manual_move'),
          refId: const Value(null),
          note: Value(_normalizeOptional(note)),
        ),
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'STOCK_MOVEMENT_EDITED',
              entity: 'stock_movement',
              entityId: safeMovementId,
              payloadJson: jsonEncode(<String, Object?>{
                'from': <String, Object?>{
                  'productId': existing.productId,
                  'warehouseId': existing.warehouseId,
                  'type': existing.type,
                  'qty': existing.qty,
                  'reasonCode': existing.reasonCode,
                },
                'to': <String, Object?>{
                  'productId': safeProductId,
                  'warehouseId': safeWarehouseId,
                  'type': safeType,
                  'qty': qty.abs(),
                  'reasonCode': safeReasonCode,
                },
              }),
            ),
          );
    });
  }

  Future<void> archiveManualMovement({
    required String movementId,
    required String userId,
    String? note,
    bool allowAnyMovement = false,
    bool allowNegativeResult = false,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeMovementId = movementId.trim();
    if (safeMovementId.isEmpty) {
      throw Exception('Movimiento inválido.');
    }
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }

    await _db.transaction(() async {
      final StockMovement? movement = await (_db.select(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(safeMovementId)))
          .getSingleOrNull();
      if (movement == null) {
        throw Exception('El movimiento no existe.');
      }
      if (movement.isVoided) {
        return;
      }

      final String source = movement.movementSource.trim().toLowerCase();
      final String refType = (movement.refType ?? '').trim().toLowerCase();
      if (!allowAnyMovement &&
          (source != 'manual' || _isSaleRefType(refType))) {
        throw Exception('Solo se pueden anular movimientos manuales.');
      }

      final StockBalance? current = await (_db.select(_db.stockBalances)
            ..where(
              (StockBalances tbl) =>
                  tbl.productId.equals(movement.productId) &
                  tbl.warehouseId.equals(movement.warehouseId),
            ))
          .getSingleOrNull();
      final double oldQty = current?.qty ?? 0;
      final double signedDelta = _signedMovementDelta(movement);
      final double nextQty = oldQty - signedDelta;
      if (!allowNegativeResult && nextQty < 0) {
        throw Exception(
          'No hay stock suficiente para anular este movimiento.',
        );
      }

      await _upsertStockBalance(
        productId: movement.productId,
        warehouseId: movement.warehouseId,
        qty: nextQty,
      );

      await _revertManualMovementLotImpact(
        movementId: movement.id,
        productId: movement.productId,
        warehouseId: movement.warehouseId,
        type: _normalizeMovementType(movement.type, movement.qty),
        qty: movement.qty.abs(),
      );

      await (_db.update(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(movement.id)))
          .write(
        StockMovementsCompanion(
          isVoided: const Value(true),
          voidedAt: Value(DateTime.now()),
          voidedBy: Value(safeUserId),
          voidNote: Value(_normalizeOptional(note)),
        ),
      );
    });
  }

  Future<void> restoreArchivedMovement({
    required String movementId,
    required String userId,
    bool allowNegativeResult = false,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeMovementId = movementId.trim();
    if (safeMovementId.isEmpty) {
      throw Exception('Movimiento inválido.');
    }
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }

    await _db.transaction(() async {
      final StockMovement? movement = await (_db.select(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(safeMovementId)))
          .getSingleOrNull();
      if (movement == null) {
        throw Exception('El movimiento no existe.');
      }
      if (!movement.isVoided) {
        return;
      }

      final StockBalance? current = await (_db.select(_db.stockBalances)
            ..where(
              (StockBalances tbl) =>
                  tbl.productId.equals(movement.productId) &
                  tbl.warehouseId.equals(movement.warehouseId),
            ))
          .getSingleOrNull();
      final double oldQty = current?.qty ?? 0;
      final double signedDelta = _signedMovementDelta(movement);
      final double nextQty = oldQty + signedDelta;
      if (!allowNegativeResult && nextQty < 0) {
        throw Exception(
          'No hay stock suficiente para restaurar este movimiento.',
        );
      }

      await _upsertStockBalance(
        productId: movement.productId,
        warehouseId: movement.warehouseId,
        qty: nextQty,
      );

      await _applyManualMovementLotImpact(
        movementId: movement.id,
        productId: movement.productId,
        warehouseId: movement.warehouseId,
        type: _normalizeMovementType(movement.type, movement.qty),
        qty: movement.qty.abs(),
        note: _normalizeOptional(movement.note),
        userId: safeUserId,
        at: DateTime.now(),
      );

      await (_db.update(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(movement.id)))
          .write(
        const StockMovementsCompanion(
          isVoided: Value(false),
          voidedAt: Value(null),
          voidedBy: Value(null),
          voidNote: Value(null),
        ),
      );

      final String auditNote = _appendAuditNote(
        movement.note,
        'Restaurado por $safeUserId',
      );
      await (_db.update(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(movement.id)))
          .write(
        StockMovementsCompanion(
          note: Value(auditNote),
        ),
      );
    });
  }

  Future<void> permanentlyDeleteArchivedMovement({
    required String movementId,
    required String userId,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeMovementId = movementId.trim();
    if (safeMovementId.isEmpty) {
      throw Exception('Movimiento inválido.');
    }
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }

    await _db.transaction(() async {
      final StockMovement? movement = await (_db.select(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(safeMovementId)))
          .getSingleOrNull();
      if (movement == null) {
        return;
      }
      if (!movement.isVoided) {
        throw Exception(
          'Solo se pueden eliminar definitivamente movimientos archivados.',
        );
      }

      await (_db.delete(_db.stockLots)
            ..where((StockLots tbl) =>
                tbl.sourceId.equals(safeMovementId) &
                tbl.sourceType.like('manual%')))
          .go();

      await (_db.delete(_db.stockMovements)
            ..where((StockMovements tbl) => tbl.id.equals(safeMovementId)))
          .go();

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'STOCK_MOVEMENT_PURGED',
              entity: 'stock_movement',
              entityId: safeMovementId,
              payloadJson: jsonEncode(<String, Object?>{
                'productId': movement.productId,
                'warehouseId': movement.warehouseId,
                'type': movement.type,
                'qty': movement.qty,
                'reasonCode': movement.reasonCode,
                'movementSource': movement.movementSource,
                'refType': movement.refType,
                'refId': movement.refId,
              }),
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

      final DateTime now = DateTime.now();
      final String movementId = _uuid.v4();
      await _db.into(_db.stockMovements).insert(
            StockMovementsCompanion.insert(
              id: movementId,
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
              createdAt: Value(now),
            ),
          );
      await _applyManualMovementLotImpact(
        movementId: movementId,
        productId: productId,
        warehouseId: warehouseId,
        type: delta > 0 ? 'in' : 'out',
        qty: delta.abs(),
        note: _normalizeOptional(note),
        userId: userId,
        at: now,
      );
    });
  }

  Future<void> _applyManualMovementLotImpact({
    required String movementId,
    required String productId,
    required String warehouseId,
    required String type,
    required double qty,
    required String? note,
    required String userId,
    required DateTime at,
  }) async {
    if (qty <= 0.000001) {
      return;
    }
    final String safeType = _sanitizeMovementType(type);
    if (safeType == 'in') {
      final int fallbackCostCents = await _productCostCents(productId);
      final String lotId = _uuid.v4();
      await _db.into(_db.stockLots).insert(
            StockLotsCompanion.insert(
              id: lotId,
              productId: productId,
              warehouseId: warehouseId,
              purchaseItemId: const Value(null),
              sourceType: const Value('manual_movement'),
              sourceId: Value(movementId),
              qtyIn: Value(qty),
              qtyRemaining: Value(qty),
              unitCostCents: Value(fallbackCostCents),
              receivedAt: Value(at),
              createdAt: Value(at),
              note: Value(note),
            ),
          );
      await _recordManualMovementLotState(
        movementId: movementId,
        userId: userId,
        state: _ManualMovementLotState(
          type: 'in',
          allocations: <_ManualLotAllocation>[
            _ManualLotAllocation(
              lotId: lotId,
              qty: qty,
              unitCostCents: fallbackCostCents,
              lineCostCents: (qty * fallbackCostCents).round(),
            ),
          ],
        ),
      );
      return;
    }

    final int fallbackCostCents = await _productCostCents(productId);
    final List<_ManualLotAllocation> allocations =
        await _consumeFifoLotsForManualOut(
      movementId: movementId,
      productId: productId,
      warehouseId: warehouseId,
      qty: qty,
      fallbackUnitCostCents: fallbackCostCents,
      note: note,
      at: at,
    );
    await _recordManualMovementLotState(
      movementId: movementId,
      userId: userId,
      state: _ManualMovementLotState(
        type: 'out',
        allocations: allocations,
      ),
    );
  }

  Future<void> _revertManualMovementLotImpact({
    required String movementId,
    required String productId,
    required String warehouseId,
    required String type,
    required double qty,
  }) async {
    if (qty <= 0.000001) {
      return;
    }
    final _ManualMovementLotState? state =
        await _loadManualMovementLotState(movementId);
    if (state == null) {
      return;
    }

    if (state.type == 'in') {
      for (final _ManualLotAllocation allocation in state.allocations) {
        final String lotId = allocation.lotId;
        final StockLot? lot = await (_db.select(_db.stockLots)
              ..where((StockLots tbl) => tbl.id.equals(lotId)))
            .getSingleOrNull();
        if (lot == null) {
          continue;
        }
        final double consumed = lot.qtyIn - lot.qtyRemaining;
        if (consumed > 0.000001) {
          throw Exception(
            'No se puede anular/editar este movimiento porque su lote ya tiene consumo FIFO.',
          );
        }
        await (_db.delete(_db.stockLots)
              ..where((StockLots tbl) => tbl.id.equals(lotId)))
            .go();
      }
      return;
    }

    for (final _ManualLotAllocation allocation in state.allocations) {
      final StockLot? lot = await (_db.select(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(allocation.lotId)))
          .getSingleOrNull();
      if (lot == null) {
        continue;
      }
      await (_db.update(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lot.id)))
          .write(
        StockLotsCompanion(
          qtyRemaining: Value(lot.qtyRemaining + allocation.qty),
        ),
      );
    }
  }

  Future<List<_ManualLotAllocation>> _consumeFifoLotsForManualOut({
    required String movementId,
    required String productId,
    required String warehouseId,
    required double qty,
    required int fallbackUnitCostCents,
    required String? note,
    required DateTime at,
  }) async {
    if (qty <= 0.000001) {
      return const <_ManualLotAllocation>[];
    }
    const double epsilon = 0.000001;
    double remaining = qty;
    final List<_ManualLotAllocation> out = <_ManualLotAllocation>[];

    final List<QueryRow> lotRows = await _db.customSelect(
      '''
      SELECT
        l.id AS lot_id,
        l.purchase_item_id AS purchase_item_id,
        COALESCE(l.qty_remaining, 0) AS qty_remaining,
        COALESCE(l.unit_cost_cents, 0) AS unit_cost_cents
      FROM stock_lots l
      WHERE l.product_id = ?
        AND l.warehouse_id = ?
        AND COALESCE(l.qty_remaining, 0) > 0
      ORDER BY l.received_at ASC, l.created_at ASC, l.id ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(productId),
        Variable<String>(warehouseId),
      ],
    ).get();

    for (final QueryRow row in lotRows) {
      if (remaining <= epsilon) {
        break;
      }
      final String lotId = (row.readNullable<String>('lot_id') ?? '').trim();
      if (lotId.isEmpty) {
        continue;
      }
      final double lotRemaining =
          (row.data['qty_remaining'] as num?)?.toDouble() ?? 0;
      if (lotRemaining <= epsilon) {
        continue;
      }
      final double take = lotRemaining < remaining ? lotRemaining : remaining;
      final int unitCostCents =
          (row.data['unit_cost_cents'] as num?)?.toInt() ??
              fallbackUnitCostCents;
      await (_db.update(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .write(
        StockLotsCompanion(
          qtyRemaining: Value(lotRemaining - take),
        ),
      );
      out.add(
        _ManualLotAllocation(
          lotId: lotId,
          qty: take,
          unitCostCents: unitCostCents,
          lineCostCents: (take * unitCostCents).round(),
          purchaseItemId:
              _normalizeOptional(row.readNullable<String>('purchase_item_id')),
        ),
      );
      remaining -= take;
    }

    if (remaining > epsilon) {
      final String fallbackLotId = _uuid.v4();
      await _db.into(_db.stockLots).insert(
            StockLotsCompanion.insert(
              id: fallbackLotId,
              productId: productId,
              warehouseId: warehouseId,
              purchaseItemId: const Value(null),
              sourceType: const Value('manual_fallback'),
              sourceId: Value(movementId),
              qtyIn: Value(remaining),
              qtyRemaining: const Value(0),
              unitCostCents: Value(fallbackUnitCostCents),
              receivedAt: Value(at),
              createdAt: Value(at),
              note: Value(note),
            ),
          );
      out.add(
        _ManualLotAllocation(
          lotId: fallbackLotId,
          qty: remaining,
          unitCostCents: fallbackUnitCostCents,
          lineCostCents: (remaining * fallbackUnitCostCents).round(),
          purchaseItemId: null,
        ),
      );
    }
    return out;
  }

  Future<int> _productCostCents(String productId) async {
    final Product? product = await (_db.select(_db.products)
          ..where((Products tbl) => tbl.id.equals(productId)))
        .getSingleOrNull();
    if (product == null) {
      return 0;
    }
    return product.costPriceCents < 0 ? 0 : product.costPriceCents;
  }

  Future<void> _recordManualMovementLotState({
    required String movementId,
    required String userId,
    required _ManualMovementLotState state,
  }) async {
    await _db.into(_db.auditLogs).insert(
          AuditLogsCompanion.insert(
            id: _uuid.v4(),
            userId: Value(userId.trim().isEmpty ? null : userId.trim()),
            action: 'STOCK_MOVEMENT_LOT_APPLIED',
            entity: 'stock_movement',
            entityId: movementId,
            payloadJson: jsonEncode(state.toJson()),
          ),
        );
  }

  Future<_ManualMovementLotState?> _loadManualMovementLotState(
    String movementId,
  ) async {
    final String id = movementId.trim();
    if (id.isEmpty) {
      return null;
    }
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT payload_json
      FROM audit_logs
      WHERE action = 'STOCK_MOVEMENT_LOT_APPLIED'
        AND entity = 'stock_movement'
        AND entity_id = ?
      ORDER BY created_at DESC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(id),
      ],
    ).get();
    if (rows.isEmpty) {
      return null;
    }
    final String raw =
        (rows.first.readNullable<String>('payload_json') ?? '').trim();
    if (raw.isEmpty) {
      return null;
    }
    return _ManualMovementLotState.fromJson(raw);
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

    byCode['transfer'] = const InventoryMovementReason(
      code: 'transfer',
      label: 'Transferencia',
      appliesTo: 'out',
      isSystem: true,
      hiddenInManualSelector: true,
    );
    byCode['consignment_sale'] = const InventoryMovementReason(
      code: 'consignment_sale',
      label: 'Venta en consignacion',
      appliesTo: 'out',
      isSystem: true,
      hiddenInManualSelector: true,
    );

    final List<InventoryMovementReason> ordered = byCode.values
        .where((InventoryMovementReason row) => row.code != 'consignment_sale')
        .toList()
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
      const InventoryMovementReason(
        code: 'consignment_sale',
        label: 'Venta en consignacion',
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

  Future<Directory> _resolveMovementsExportDir() async {
    final Directory preferredBase = await _resolveDownloadsBaseDir();
    Directory dir = Directory(
      p.join(preferredBase.path, 'POSIPV', 'Exportaciones', 'Movimientos'),
    );
    try {
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final Directory docs = await getApplicationDocumentsDirectory();
      dir = Directory(
        p.join(docs.path, 'exports', 'inventario', 'movimientos'),
      );
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }
    return dir;
  }

  Future<Directory> _resolveDownloadsBaseDir() async {
    if (Platform.isAndroid) {
      const List<String> candidates = <String>[
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Descargas',
      ];
      for (final String path in candidates) {
        final Directory dir = Directory(path);
        try {
          if (dir.existsSync()) {
            return dir;
          }
          await dir.create(recursive: true);
          if (dir.existsSync()) {
            return dir;
          }
        } catch (_) {}
      }
      return getApplicationDocumentsDirectory();
    }

    final Directory? downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }
    return getApplicationDocumentsDirectory();
  }

  pw.Widget _buildMovementPdfCard(
    InventoryMovementView row, {
    required int index,
  }) {
    pw.Widget item(String label, String value) {
      return pw.Container(
        width: 250,
        margin: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(
              fontSize: 8.4,
              color: PdfColors.black,
            ),
            children: <pw.InlineSpan>[
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: value),
            ],
          ),
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            '$index. ${row.productName}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 8,
            runSpacing: 0,
            children: <pw.Widget>[
              item('ID', row.id),
              item('Fecha', _formatDateTimeExport(row.createdAt)),
              item('Almacén', row.warehouseName),
              item('Producto', row.productName),
              item('SKU', row.sku),
              item('Tipo', _movementTypeLabel(row.movementType)),
              item('Cantidad', _formatQtyForExport(row.qty)),
              item('Motivo', row.reasonLabel),
              item('Código motivo', row.reasonCode),
              item('Origen', row.movementSource),
              item('Ref tipo', _safeText(row.refType)),
              item('Ref ID', _safeText(row.refId)),
              item('Nota', _safeText(row.note)),
              item('Usuario', row.username),
              item('Usuario ID', row.createdBy),
            ],
          ),
        ],
      ),
    );
  }

  String _movementTypeLabel(String movementType) {
    final String value = movementType.trim().toLowerCase();
    if (value == 'in') {
      return 'Entrada';
    }
    if (value == 'out') {
      return 'Salida';
    }
    return 'Ajuste';
  }

  String _safeText(String? value) {
    final String out = (value ?? '').trim();
    return out.isEmpty ? '-' : out;
  }

  String _formatDateTimeExport(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    final String ss = local.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  String _formatQtyForExport(double qty) {
    final double rounded = qty.roundToDouble();
    if ((qty - rounded).abs() <= 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return qty
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _csvCell(String value) {
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _ts(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String mo = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String h = local.hour.toString().padLeft(2, '0');
    final String mi = local.minute.toString().padLeft(2, '0');
    final String s = local.second.toString().padLeft(2, '0');
    return '$y$mo$d-$h$mi$s';
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
    if (normalizedRefType == 'consignment_sale' ||
        normalizedRefType == 'consignment_sale_pos' ||
        normalizedRefType == 'consignment_sale_direct') {
      return 'consignment_sale';
    }
    if (normalizedRefType == 'transfer_out' ||
        normalizedRefType == 'transfer_in') {
      return 'transfer';
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
    if (normalizedRefType == 'consignment_sale_pos' ||
        normalizedRefType == 'consignment_sale') {
      return 'pos_consignment';
    }
    if (normalizedRefType == 'consignment_sale_direct') {
      return 'direct_consignment';
    }
    if (normalizedRefType == 'transfer_out' ||
        normalizedRefType == 'transfer_in') {
      return 'transfer';
    }
    return 'manual';
  }

  bool _isSaleRefType(String refType) {
    return refType == 'sale' ||
        refType == 'sale_pos' ||
        refType == 'sale_direct' ||
        refType == 'consignment_sale' ||
        refType == 'consignment_sale_pos' ||
        refType == 'consignment_sale_direct';
  }

  double _signedMovementDelta(StockMovement movement) {
    final String safeType = movement.type.trim().toLowerCase();
    if (safeType == 'in') {
      return movement.qty.abs();
    }
    if (safeType == 'out') {
      return -movement.qty.abs();
    }
    if (safeType == 'adjust') {
      return movement.qty;
    }
    return movement.qty;
  }

  String _fallbackReasonLabel(String reasonCode) {
    switch (reasonCode) {
      case 'sale':
        return 'Venta';
      case 'consignment_sale':
        return 'Venta en consignacion';
      case 'purchase':
        return 'Compra';
      case 'breakage':
        return 'Rotura';
      case 'shrinkage':
        return 'Merma';
      case 'adjust':
        return 'Ajuste';
      case 'transfer':
        return 'Transferencia';
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

  String _appendAuditNote(String? current, String audit) {
    final String cleanCurrent = (current ?? '').trim();
    final String cleanAudit = audit.trim();
    if (cleanAudit.isEmpty) {
      return cleanCurrent;
    }
    if (cleanCurrent.isEmpty) {
      return cleanAudit;
    }
    return '$cleanCurrent\n$cleanAudit';
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class _ManualLotAllocation {
  const _ManualLotAllocation({
    required this.lotId,
    required this.qty,
    required this.unitCostCents,
    required this.lineCostCents,
    this.purchaseItemId,
  });

  final String lotId;
  final double qty;
  final int unitCostCents;
  final int lineCostCents;
  final String? purchaseItemId;

  Map<String, Object> toJson() {
    final Map<String, Object> out = <String, Object>{
      'lotId': lotId,
      'qty': qty,
      'unitCostCents': unitCostCents,
      'lineCostCents': lineCostCents,
    };
    final String? safePurchaseItemId = purchaseItemId?.trim();
    if (safePurchaseItemId != null && safePurchaseItemId.isNotEmpty) {
      out['purchaseItemId'] = safePurchaseItemId;
    }
    return out;
  }

  static _ManualLotAllocation? fromObject(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final String lotId = (raw['lotId'] ?? '').toString().trim();
    if (lotId.isEmpty) {
      return null;
    }
    final double qty = (raw['qty'] as num?)?.toDouble() ?? 0;
    if (qty <= 0.000001) {
      return null;
    }
    return _ManualLotAllocation(
      lotId: lotId,
      qty: qty,
      unitCostCents: (raw['unitCostCents'] as num?)?.toInt() ?? 0,
      lineCostCents: (raw['lineCostCents'] as num?)?.toInt() ?? 0,
      purchaseItemId: (raw['purchaseItemId'] ?? '').toString().trim().isEmpty
          ? null
          : (raw['purchaseItemId'] ?? '').toString().trim(),
    );
  }
}

class _ManualMovementLotState {
  const _ManualMovementLotState({
    required this.type,
    required this.allocations,
  });

  final String type;
  final List<_ManualLotAllocation> allocations;

  Map<String, Object> toJson() {
    return <String, Object>{
      'version': 1,
      'type': type,
      'allocations': allocations
          .map((_ManualLotAllocation row) => row.toJson())
          .toList(growable: false),
    };
  }

  static _ManualMovementLotState? fromJson(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        return null;
      }
      final String type = (decoded['type'] ?? '').toString().trim();
      if (type != 'in' && type != 'out') {
        return null;
      }
      final Object? rawAllocations = decoded['allocations'];
      final List<_ManualLotAllocation> allocations =
          rawAllocations is List<Object?>
              ? rawAllocations
                  .map(_ManualLotAllocation.fromObject)
                  .whereType<_ManualLotAllocation>()
                  .toList(growable: false)
              : const <_ManualLotAllocation>[];
      return _ManualMovementLotState(
        type: type,
        allocations: allocations,
      );
    } catch (_) {
      return null;
    }
  }
}
