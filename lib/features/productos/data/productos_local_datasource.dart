import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_service.dart';

enum ProductCatalogKind { type, category, unit }

extension ProductCatalogKindX on ProductCatalogKind {
  String get key {
    switch (this) {
      case ProductCatalogKind.type:
        return 'type';
      case ProductCatalogKind.category:
        return 'category';
      case ProductCatalogKind.unit:
        return 'unit';
    }
  }

  List<String> get defaults {
    switch (this) {
      case ProductCatalogKind.type:
        return <String>['Fisico', 'Servicio', 'Digital'];
      case ProductCatalogKind.category:
        return <String>['General'];
      case ProductCatalogKind.unit:
        return <String>['Unidad', 'Caja', 'Kg', 'Litro', 'Metro', 'Paquete'];
    }
  }
}

class ProductFormInput {
  const ProductFormInput({
    required this.code,
    required this.name,
    required this.costPriceCents,
    required this.salePriceCents,
    required this.category,
    required this.productType,
    required this.unitMeasure,
    required this.currencyCode,
    this.barcode,
    this.imagePath,
    this.taxRateBps = 0,
  });

  final String code;
  final String name;
  final int costPriceCents;
  final int salePriceCents;
  final String category;
  final String productType;
  final String unitMeasure;
  final String currencyCode;
  final String? barcode;
  final String? imagePath;
  final int taxRateBps;
}

class ArchivedProductView {
  const ArchivedProductView({
    required this.id,
    required this.sku,
    required this.name,
    required this.priceCents,
    required this.currencyCode,
    required this.archivedAt,
    this.barcode,
    this.imagePath,
  });

  final String id;
  final String sku;
  final String name;
  final int priceCents;
  final String currencyCode;
  final DateTime archivedAt;
  final String? barcode;
  final String? imagePath;
}

class ProductCatalogEntry {
  const ProductCatalogEntry({
    required this.id,
    required this.kind,
    required this.value,
    required this.isActive,
    required this.isSystem,
    required this.usageCount,
  });

  final String id;
  final ProductCatalogKind kind;
  final String value;
  final bool isActive;
  final bool isSystem;
  final int usageCount;
}

class ProductPriceEditionCheck {
  const ProductPriceEditionCheck({
    required this.allowed,
    required this.hasPriceChanges,
    this.blockReason,
  });

  final bool allowed;
  final bool hasPriceChanges;
  final String? blockReason;
}

class MeasurementUnitTypeModel {
  const MeasurementUnitTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String description;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;

  factory MeasurementUnitTypeModel.fromJson(Map<String, Object?> json) {
    return MeasurementUnitTypeModel(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      isSystem: json['isSystem'] == true,
      isActive: json['isActive'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
      'isSystem': isSystem,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  MeasurementUnitTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSystem,
    bool? isActive,
    int? sortOrder,
  }) {
    return MeasurementUnitTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class MeasurementUnitModel {
  const MeasurementUnitModel({
    required this.id,
    required this.typeId,
    required this.symbol,
    required this.name,
    required this.isSystem,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String typeId;
  final String symbol;
  final String name;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;

  factory MeasurementUnitModel.fromJson(Map<String, Object?> json) {
    return MeasurementUnitModel(
      id: (json['id'] as String? ?? '').trim(),
      typeId: (json['typeId'] as String? ?? '').trim(),
      symbol: (json['symbol'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      isSystem: json['isSystem'] == true,
      isActive: json['isActive'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'typeId': typeId,
      'symbol': symbol,
      'name': name,
      'isSystem': isSystem,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  MeasurementUnitModel copyWith({
    String? id,
    String? typeId,
    String? symbol,
    String? name,
    bool? isSystem,
    bool? isActive,
    int? sortOrder,
  }) {
    return MeasurementUnitModel(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class MeasurementUnitCatalog {
  const MeasurementUnitCatalog({
    required this.types,
    required this.units,
  });

  final List<MeasurementUnitTypeModel> types;
  final List<MeasurementUnitModel> units;

  factory MeasurementUnitCatalog.fromJson(Map<String, Object?> json) {
    final List<MeasurementUnitTypeModel> parsedTypes =
        <MeasurementUnitTypeModel>[];
    final Object? rawTypes = json['types'];
    if (rawTypes is List) {
      for (final Object? raw in rawTypes) {
        if (raw is Map) {
          parsedTypes.add(
            MeasurementUnitTypeModel.fromJson(raw.cast<String, Object?>()),
          );
        }
      }
    }

    final List<MeasurementUnitModel> parsedUnits = <MeasurementUnitModel>[];
    final Object? rawUnits = json['units'];
    if (rawUnits is List) {
      for (final Object? raw in rawUnits) {
        if (raw is Map) {
          parsedUnits.add(
            MeasurementUnitModel.fromJson(raw.cast<String, Object?>()),
          );
        }
      }
    }

    return MeasurementUnitCatalog(
      types: parsedTypes,
      units: parsedUnits,
    ).normalized();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'types': types.map((MeasurementUnitTypeModel row) => row.toJson()).toList(
            growable: false,
          ),
      'units': units.map((MeasurementUnitModel row) => row.toJson()).toList(
            growable: false,
          ),
    };
  }

  MeasurementUnitCatalog normalized() {
    final List<MeasurementUnitTypeModel> normalizedTypes =
        <MeasurementUnitTypeModel>[];
    final Set<String> seenTypeIds = <String>{};
    for (final MeasurementUnitTypeModel row in types) {
      final String cleanId = row.id.trim();
      final String cleanName = row.name.trim();
      if (cleanId.isEmpty || cleanName.isEmpty || !seenTypeIds.add(cleanId)) {
        continue;
      }
      normalizedTypes.add(
        row.copyWith(
          id: cleanId,
          name: cleanName,
          description: row.description.trim(),
        ),
      );
    }
    normalizedTypes
        .sort((MeasurementUnitTypeModel a, MeasurementUnitTypeModel b) {
      final int byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.name.compareTo(b.name);
    });
    final Set<String> validTypeIds =
        normalizedTypes.map((MeasurementUnitTypeModel row) => row.id).toSet();

    final List<MeasurementUnitModel> normalizedUnits = <MeasurementUnitModel>[];
    final Set<String> seenUnitIds = <String>{};
    final Set<String> seenSymbols = <String>{};
    for (final MeasurementUnitModel row in units) {
      final String cleanId = row.id.trim();
      final String cleanTypeId = row.typeId.trim();
      final String cleanSymbol = row.symbol.trim();
      final String cleanName = row.name.trim();
      if (cleanId.isEmpty ||
          cleanTypeId.isEmpty ||
          cleanSymbol.isEmpty ||
          cleanName.isEmpty ||
          !validTypeIds.contains(cleanTypeId) ||
          !seenUnitIds.add(cleanId)) {
        continue;
      }
      final String key = cleanSymbol.toLowerCase();
      if (!seenSymbols.add(key)) {
        continue;
      }
      normalizedUnits.add(
        row.copyWith(
          id: cleanId,
          typeId: cleanTypeId,
          symbol: cleanSymbol,
          name: cleanName,
        ),
      );
    }
    normalizedUnits.sort((MeasurementUnitModel a, MeasurementUnitModel b) {
      final int byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.symbol.compareTo(b.symbol);
    });

    return MeasurementUnitCatalog(
      types: normalizedTypes,
      units: normalizedUnits,
    );
  }
}

class ProductosLocalDataSource {
  ProductosLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;
  static const String _measurementCatalogKey = 'measurement_units_catalog_v1';

  Future<List<Product>> listActiveProducts() {
    return (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.isActive.equals(true) & _hasUsableProductFields(tbl))
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
  }

  Future<List<ArchivedProductView>> listArchivedProducts({
    String? search,
    int limit = 250,
  }) async {
    final int safeLimit = limit < 1 ? 1 : limit;
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        id,
        sku,
        name,
        barcode,
        image_path,
        price_cents,
        currency_code,
        updated_at,
        created_at
      FROM products
      WHERE is_active = 0
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];

    if (cleanedSearch.isNotEmpty) {
      sql.write(
        '''
        AND (
          LOWER(name) LIKE ?
          OR LOWER(sku) LIKE ?
          OR LOWER(COALESCE(barcode, '')) LIKE ?
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
      ORDER BY COALESCE(updated_at, created_at) DESC, name ASC
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
      final DateTime archivedAt = row.readNullable<DateTime>('updated_at') ??
          row.read<DateTime>('created_at');
      return ArchivedProductView(
        id: row.read<String>('id'),
        sku: (row.readNullable<String>('sku') ?? '-').trim(),
        name: (row.readNullable<String>('name') ?? '-').trim(),
        barcode: row.readNullable<String>('barcode'),
        imagePath: row.readNullable<String>('image_path'),
        priceCents: row.readNullable<int>('price_cents') ?? 0,
        currencyCode:
            (row.readNullable<String>('currency_code') ?? 'USD').trim(),
        archivedAt: archivedAt,
      );
    }).toList(growable: false);
  }

  Future<List<Product>> listActiveProductsPage({
    int limit = 40,
    int offset = 0,
  }) {
    final int safeLimit = limit < 1 ? 1 : limit;
    final int safeOffset = offset < 0 ? 0 : offset;
    return (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.isActive.equals(true) & _hasUsableProductFields(tbl))
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ])
          ..limit(safeLimit, offset: safeOffset))
        .get();
  }

  Future<List<Product>> listActiveProductsByIds(Set<String> productIds) {
    if (productIds.isEmpty) {
      return Future<List<Product>>.value(const <Product>[]);
    }
    return (_db.select(_db.products)
          ..where(
            (Products tbl) =>
                tbl.id.isIn(productIds) &
                tbl.isActive.equals(true) &
                _hasUsableProductFields(tbl),
          )
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
  }

  Future<Product?> findActiveProductById(String productId) {
    return (_db.select(_db.products)
          ..where(
            (Products tbl) =>
                tbl.id.equals(productId) &
                tbl.isActive.equals(true) &
                _hasUsableProductFields(tbl),
          ))
        .getSingleOrNull();
  }

  Future<Product?> findActiveProductByCode(String code) {
    final String cleaned = code.trim();
    return (_db.select(_db.products)
          ..where(
            (Products tbl) =>
                tbl.sku.equals(cleaned) &
                tbl.isActive.equals(true) &
                _hasUsableProductFields(tbl),
          ))
        .getSingleOrNull();
  }

  Future<Product?> findActiveProductByBarcode(String barcode) {
    final String cleaned = barcode.trim();
    return (_db.select(_db.products)
          ..where(
            (Products tbl) =>
                tbl.barcode.equals(cleaned) &
                tbl.isActive.equals(true) &
                _hasUsableProductFields(tbl),
          ))
        .getSingleOrNull();
  }

  Future<bool> isCodeTaken(
    String code, {
    String? excludeProductId,
  }) async {
    final String cleaned = code.trim();
    if (cleaned.isEmpty) {
      return false;
    }

    final TypedResult? row = await (_db.selectOnly(_db.products)
          ..addColumns(<Expression<Object>>[_db.products.id])
          ..where(_db.products.sku.equals(cleaned))
          ..limit(1))
        .getSingleOrNull();

    final String? foundId = row?.read(_db.products.id);
    if (foundId == null) {
      return false;
    }
    if (excludeProductId != null && foundId == excludeProductId) {
      return false;
    }
    return true;
  }

  Future<bool> isBarcodeTaken(
    String barcode, {
    String? excludeProductId,
  }) async {
    final String cleaned = barcode.trim();
    if (cleaned.isEmpty) {
      return false;
    }

    final TypedResult? row = await (_db.selectOnly(_db.products)
          ..addColumns(<Expression<Object>>[_db.products.id])
          ..where(_db.products.barcode.equals(cleaned))
          ..limit(1))
        .getSingleOrNull();

    final String? foundId = row?.read(_db.products.id);
    if (foundId == null) {
      return false;
    }
    if (excludeProductId != null && foundId == excludeProductId) {
      return false;
    }
    return true;
  }

  Expression<bool> _hasUsableProductFields(Products tbl) {
    return tbl.id.isNotNull() &
        tbl.sku.isNotNull() &
        tbl.name.isNotNull() &
        tbl.priceCents.isNotNull() &
        tbl.taxRateBps.isNotNull() &
        tbl.costPriceCents.isNotNull() &
        tbl.category.isNotNull() &
        tbl.productType.isNotNull() &
        tbl.unitMeasure.isNotNull() &
        tbl.currencyCode.isNotNull() &
        tbl.isActive.isNotNull() &
        tbl.createdAt.isNotNull();
  }

  Future<List<String>> listCatalogValues(ProductCatalogKind kind) async {
    await _ensureCatalogDefaultsForKind(kind);
    final List<ProductCatalogItem> items =
        await (_db.select(_db.productCatalogItems)
              ..where(
                (ProductCatalogItems tbl) =>
                    tbl.kind.equals(kind.key) & tbl.isActive.equals(true),
              )
              ..orderBy(<OrderingTerm Function(ProductCatalogItems)>[
                (ProductCatalogItems tbl) => OrderingTerm.asc(tbl.value),
              ]))
            .get();

    if (items.isEmpty) {
      return kind.defaults;
    }

    return items.map((ProductCatalogItem item) => item.value).toList();
  }

  Future<List<ProductCatalogEntry>> listCatalogEntries(
    ProductCatalogKind kind, {
    bool includeInactive = true,
  }) async {
    await _ensureCatalogDefaultsForKind(kind);
    final List<ProductCatalogItem> items =
        await (_db.select(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) {
                final Expression<bool> base = tbl.kind.equals(kind.key);
                if (includeInactive) {
                  return base;
                }
                return base & tbl.isActive.equals(true);
              })
              ..orderBy(<OrderingTerm Function(ProductCatalogItems)>[
                (ProductCatalogItems tbl) => OrderingTerm.asc(tbl.value),
              ]))
            .get();
    final Map<String, int> usageByValue =
        await _usageCountByCatalogValue(kind: kind);
    final Set<String> defaults =
        kind.defaults.map((String row) => row.trim().toLowerCase()).toSet();
    return items.map((ProductCatalogItem row) {
      final String normalized = row.value.trim().toLowerCase();
      return ProductCatalogEntry(
        id: row.id,
        kind: kind,
        value: row.value,
        isActive: row.isActive,
        isSystem: defaults.contains(normalized),
        usageCount: usageByValue[normalized] ?? 0,
      );
    }).toList(growable: false);
  }

  Future<void> addCatalogValue({
    required ProductCatalogKind kind,
    required String value,
  }) async {
    await _licenseService.requireWriteAccess();
    final String cleaned = _normalizeCatalogValue(value);
    if (cleaned.isEmpty) {
      throw Exception('El valor no puede estar vacio.');
    }

    final List<ProductCatalogItem> sameKind =
        await (_db.select(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) => tbl.kind.equals(kind.key)))
            .get();

    ProductCatalogItem? existing;
    for (final ProductCatalogItem item in sameKind) {
      if (item.value.toLowerCase() == cleaned.toLowerCase()) {
        existing = item;
        break;
      }
    }

    if (existing != null) {
      if (!existing.isActive) {
        await (_db.update(_db.productCatalogItems)
              ..where((tbl) => tbl.id.equals(existing!.id)))
            .write(
          ProductCatalogItemsCompanion(
            isActive: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      return;
    }

    await _db.into(_db.productCatalogItems).insert(
          ProductCatalogItemsCompanion.insert(
            id: _uuid.v4(),
            kind: kind.key,
            value: cleaned,
          ),
        );
  }

  Future<void> renameCatalogValue({
    required ProductCatalogKind kind,
    required String itemId,
    required String nextValue,
  }) async {
    await _licenseService.requireWriteAccess();
    final String cleaned = _normalizeCatalogValue(nextValue);
    if (cleaned.isEmpty) {
      throw Exception('El valor no puede estar vacio.');
    }

    final ProductCatalogItem? existing =
        await (_db.select(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) => tbl.id.equals(itemId)))
            .getSingleOrNull();
    if (existing == null || existing.kind != kind.key) {
      throw Exception('El elemento seleccionado no existe.');
    }
    final String oldValue = existing.value.trim();
    if (oldValue.toLowerCase() == cleaned.toLowerCase()) {
      return;
    }

    final List<ProductCatalogItem> sameKind =
        await (_db.select(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) =>
                  tbl.kind.equals(kind.key) & tbl.id.isNotValue(itemId)))
            .get();
    for (final ProductCatalogItem row in sameKind) {
      if (row.value.trim().toLowerCase() == cleaned.toLowerCase()) {
        throw Exception('Ya existe un valor igual en este catálogo.');
      }
    }

    await _db.transaction(() async {
      await (_db.update(_db.productCatalogItems)
            ..where((ProductCatalogItems tbl) => tbl.id.equals(itemId)))
          .write(
        ProductCatalogItemsCompanion(
          value: Value(cleaned),
          updatedAt: Value(DateTime.now()),
        ),
      );

      switch (kind) {
        case ProductCatalogKind.type:
          await (_db.update(_db.products)
                ..where((Products tbl) => tbl.productType.equals(oldValue)))
              .write(
            ProductsCompanion(
              productType: Value(cleaned),
              updatedAt: Value(DateTime.now()),
            ),
          );
        case ProductCatalogKind.category:
          await (_db.update(_db.products)
                ..where((Products tbl) => tbl.category.equals(oldValue)))
              .write(
            ProductsCompanion(
              category: Value(cleaned),
              updatedAt: Value(DateTime.now()),
            ),
          );
        case ProductCatalogKind.unit:
          await (_db.update(_db.products)
                ..where((Products tbl) => tbl.unitMeasure.equals(oldValue)))
              .write(
            ProductsCompanion(
              unitMeasure: Value(cleaned),
              updatedAt: Value(DateTime.now()),
            ),
          );
      }
    });
  }

  Future<void> setCatalogValueActive({
    required ProductCatalogKind kind,
    required String itemId,
    required bool isActive,
  }) async {
    await _licenseService.requireWriteAccess();
    final ProductCatalogItem? existing =
        await (_db.select(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) => tbl.id.equals(itemId)))
            .getSingleOrNull();
    if (existing == null || existing.kind != kind.key) {
      throw Exception('El elemento seleccionado no existe.');
    }
    if (existing.isActive == isActive) {
      return;
    }

    if (!isActive) {
      final int usage = await _countProductsByCatalogValue(
        kind: kind,
        value: existing.value,
      );
      if (usage > 0) {
        throw Exception(
          'No se puede desactivar porque está en uso por $usage producto(s).',
        );
      }
    } else {
      final List<ProductCatalogItem> sameKind =
          await (_db.select(_db.productCatalogItems)
                ..where((ProductCatalogItems tbl) =>
                    tbl.kind.equals(kind.key) & tbl.id.isNotValue(itemId)))
              .get();
      for (final ProductCatalogItem row in sameKind) {
        if (row.isActive &&
            row.value.trim().toLowerCase() ==
                existing.value.trim().toLowerCase()) {
          throw Exception('Ya existe un valor activo igual en el catálogo.');
        }
      }
    }

    if (isActive) {
      final int activeCount = await _countActiveCatalogItems(kind);
      if (activeCount == 0) {
        // allowed
      }
    } else {
      final int activeCount = await _countActiveCatalogItems(kind);
      if (activeCount <= 1) {
        throw Exception(
          'Debe existir al menos un valor activo en el catálogo.',
        );
      }
    }

    await (_db.update(_db.productCatalogItems)
          ..where((ProductCatalogItems tbl) => tbl.id.equals(itemId)))
        .write(
      ProductCatalogItemsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<MeasurementUnitCatalog> loadMeasurementUnitCatalog() async {
    final AppSetting? setting = await (_db.select(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(_measurementCatalogKey)))
        .getSingleOrNull();

    MeasurementUnitCatalog catalog;
    if (setting == null) {
      catalog = _defaultMeasurementCatalog();
      await _saveMeasurementUnitCatalog(catalog);
    } else {
      try {
        final Object? decoded = jsonDecode(setting.value);
        if (decoded is Map<String, Object?>) {
          catalog = MeasurementUnitCatalog.fromJson(decoded);
        } else if (decoded is Map) {
          catalog = MeasurementUnitCatalog.fromJson(
            decoded.cast<String, Object?>(),
          );
        } else {
          catalog = _defaultMeasurementCatalog();
        }
      } catch (_) {
        catalog = _defaultMeasurementCatalog();
      }
      catalog = catalog.normalized();
      await _saveMeasurementUnitCatalog(catalog);
    }
    await _syncMeasurementUnitsWithProductCatalog(catalog.units);
    return catalog;
  }

  Future<void> upsertMeasurementUnitType({
    String? typeId,
    required String name,
    String? description,
    bool? isActive,
  }) async {
    await _licenseService.requireWriteAccess();
    final MeasurementUnitCatalog catalog = await loadMeasurementUnitCatalog();
    final List<MeasurementUnitTypeModel> types =
        catalog.types.toList(growable: true);
    List<MeasurementUnitModel> units = catalog.units.toList(growable: true);

    final String cleanName = _normalizeCatalogValue(name);
    final String cleanDescription = (description ?? '').trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del tipo de unidad es obligatorio.');
    }

    final String? editingId = typeId?.trim().isEmpty ?? true ? null : typeId;
    for (final MeasurementUnitTypeModel row in types) {
      if (editingId != null && row.id == editingId) {
        continue;
      }
      if (row.name.trim().toLowerCase() == cleanName.toLowerCase()) {
        throw Exception('Ya existe un tipo de unidad con ese nombre.');
      }
    }

    if (editingId == null) {
      final int nextSort = types.isEmpty
          ? 0
          : types
                  .map((MeasurementUnitTypeModel row) => row.sortOrder)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;
      types.add(
        MeasurementUnitTypeModel(
          id: _uuid.v4(),
          name: cleanName,
          description: cleanDescription,
          isSystem: false,
          isActive: isActive ?? true,
          sortOrder: nextSort,
        ),
      );
    } else {
      final int index = types.indexWhere((MeasurementUnitTypeModel row) {
        return row.id == editingId;
      });
      if (index < 0) {
        throw Exception('El tipo de unidad seleccionado no existe.');
      }
      final MeasurementUnitTypeModel current = types[index];
      types[index] = current.copyWith(
        name: cleanName,
        description: cleanDescription,
        isActive: isActive ?? current.isActive,
      );
      if ((isActive ?? current.isActive) == false) {
        final Set<String> unitIdsToDeactivate = catalog.units
            .where((MeasurementUnitModel row) => row.typeId == editingId)
            .map((MeasurementUnitModel row) => row.id)
            .toSet();
        final MeasurementUnitCatalog patched = await _setMeasurementUnitsActive(
          catalog: catalog,
          unitIds: unitIdsToDeactivate,
          isActive: false,
        );
        units = patched.units.toList(growable: true);
      }
    }

    final MeasurementUnitCatalog next = MeasurementUnitCatalog(
      types: types,
      units: units,
    ).normalized();
    await _saveMeasurementUnitCatalog(next);
  }

  Future<void> setMeasurementUnitTypeActive({
    required String typeId,
    required bool isActive,
  }) async {
    await _licenseService.requireWriteAccess();
    final MeasurementUnitCatalog catalog = await loadMeasurementUnitCatalog();
    final List<MeasurementUnitTypeModel> types =
        catalog.types.toList(growable: true);
    final int index = types.indexWhere((MeasurementUnitTypeModel row) {
      return row.id == typeId;
    });
    if (index < 0) {
      throw Exception('El tipo de unidad no existe.');
    }
    if (types[index].isActive == isActive) {
      return;
    }
    if (!isActive) {
      final int activeCount =
          types.where((MeasurementUnitTypeModel row) => row.isActive).length;
      if (activeCount <= 1) {
        throw Exception('Debe existir al menos un tipo de unidad activo.');
      }
    }
    types[index] = types[index].copyWith(isActive: isActive);
    MeasurementUnitCatalog next = MeasurementUnitCatalog(
      types: types,
      units: catalog.units,
    ).normalized();
    if (!isActive) {
      final Set<String> unitIdsToDeactivate = next.units
          .where((MeasurementUnitModel row) => row.typeId == typeId)
          .map((MeasurementUnitModel row) => row.id)
          .toSet();
      next = await _setMeasurementUnitsActive(
        catalog: next,
        unitIds: unitIdsToDeactivate,
        isActive: false,
      );
    }
    await _saveMeasurementUnitCatalog(next);
  }

  Future<void> upsertMeasurementUnit({
    String? unitId,
    required String typeId,
    required String symbol,
    required String name,
    bool? isActive,
  }) async {
    await _licenseService.requireWriteAccess();
    final MeasurementUnitCatalog catalog = await loadMeasurementUnitCatalog();
    final List<MeasurementUnitTypeModel> types = catalog.types;
    final List<MeasurementUnitModel> units =
        catalog.units.toList(growable: true);

    if (!types.any((MeasurementUnitTypeModel row) => row.id == typeId)) {
      throw Exception('Selecciona un tipo de unidad válido.');
    }
    final String cleanSymbol = _normalizeUnitSymbol(symbol);
    final String cleanName = _normalizeCatalogValue(name);
    if (cleanSymbol.isEmpty || cleanName.isEmpty) {
      throw Exception('Símbolo y nombre de unidad son obligatorios.');
    }

    final String? editingId = unitId?.trim().isEmpty ?? true ? null : unitId;
    for (final MeasurementUnitModel row in units) {
      if (editingId != null && row.id == editingId) {
        continue;
      }
      if (row.symbol.trim().toLowerCase() == cleanSymbol.toLowerCase()) {
        throw Exception('Ya existe una unidad con ese símbolo.');
      }
    }

    if (editingId == null) {
      final int nextSort = units.isEmpty
          ? 0
          : units
                  .map((MeasurementUnitModel row) => row.sortOrder)
                  .reduce((int a, int b) => a > b ? a : b) +
              1;
      units.add(
        MeasurementUnitModel(
          id: _uuid.v4(),
          typeId: typeId,
          symbol: cleanSymbol,
          name: cleanName,
          isSystem: false,
          isActive: isActive ?? true,
          sortOrder: nextSort,
        ),
      );
    } else {
      final int index = units.indexWhere((MeasurementUnitModel row) {
        return row.id == editingId;
      });
      if (index < 0) {
        throw Exception('La unidad seleccionada no existe.');
      }
      final MeasurementUnitModel current = units[index];
      units[index] = current.copyWith(
        typeId: typeId,
        symbol: cleanSymbol,
        name: cleanName,
        isActive: isActive ?? current.isActive,
      );
    }

    final MeasurementUnitCatalog next = MeasurementUnitCatalog(
      types: types,
      units: units,
    ).normalized();
    await _saveMeasurementUnitCatalog(next);
    await _syncMeasurementUnitsWithProductCatalog(next.units);
  }

  Future<void> setMeasurementUnitActive({
    required String unitId,
    required bool isActive,
  }) async {
    await _licenseService.requireWriteAccess();
    final MeasurementUnitCatalog catalog = await loadMeasurementUnitCatalog();
    final MeasurementUnitCatalog next = await _setMeasurementUnitsActive(
      catalog: catalog,
      unitIds: <String>{unitId},
      isActive: isActive,
    );
    await _saveMeasurementUnitCatalog(next);
    await _syncMeasurementUnitsWithProductCatalog(next.units);
  }

  Future<void> createProduct(ProductFormInput input) async {
    await _licenseService.requireWriteAccess();
    final LicenseStatus licenseStatus = await _licenseService.current();
    if (!licenseStatus.isFull) {
      final int activeProducts = await _countActiveProducts();
      if (activeProducts >= DemoLicenseLimits.maxActiveProducts) {
        throw const LicenseException(
          'Modo demo: alcanzaste el maximo de 5 productos activos.',
        );
      }
    }
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: _uuid.v4(),
            sku: input.code,
            barcode: Value(_normalizeBarcode(input.barcode)),
            name: input.name,
            priceCents: Value(input.salePriceCents),
            taxRateBps: Value(input.taxRateBps),
            imagePath: Value(_normalizeImagePath(input.imagePath)),
            costPriceCents: Value(input.costPriceCents),
            category: Value(input.category),
            productType: Value(input.productType),
            unitMeasure: Value(input.unitMeasure),
            currencyCode: Value(input.currencyCode),
          ),
        );
  }

  Future<int> _countActiveProducts() async {
    final Expression<int> countExp = _db.products.id.count();
    final TypedResult row = await (_db.selectOnly(_db.products)
          ..addColumns(<Expression<Object>>[countExp])
          ..where(_db.products.isActive.equals(true)))
        .getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> updateProduct({
    required String productId,
    required ProductFormInput input,
  }) async {
    await _licenseService.requireWriteAccess();
    await _assertPriceEditionAllowed(
      productId: productId,
      nextSalePriceCents: input.salePriceCents,
      nextCostPriceCents: input.costPriceCents,
    );
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId)))
        .write(
      ProductsCompanion(
        sku: Value(input.code),
        barcode: Value(_normalizeBarcode(input.barcode)),
        name: Value(input.name),
        priceCents: Value(input.salePriceCents),
        taxRateBps: Value(input.taxRateBps),
        imagePath: Value(_normalizeImagePath(input.imagePath)),
        costPriceCents: Value(input.costPriceCents),
        category: Value(input.category),
        productType: Value(input.productType),
        unitMeasure: Value(input.unitMeasure),
        currencyCode: Value(input.currencyCode),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deactivateProduct(String productId) async {
    await _licenseService.requireWriteAccess();
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId)))
        .write(
      ProductsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> reactivateProduct(String productId) async {
    await _licenseService.requireWriteAccess();
    final String safeProductId = productId.trim();
    if (safeProductId.isEmpty) {
      throw Exception('Producto inválido.');
    }
    await (_db.update(_db.products)
          ..where((Products tbl) => tbl.id.equals(safeProductId)))
        .write(
      ProductsCompanion(
        isActive: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> permanentlyDeleteArchivedProduct({
    required String productId,
    required String userId,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeProductId = productId.trim();
    final String safeUserId = userId.trim();
    if (safeProductId.isEmpty) {
      throw Exception('Producto inválido.');
    }
    if (safeUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }

    await _db.transaction(() async {
      final Product? product = await (_db.select(_db.products)
            ..where((Products tbl) => tbl.id.equals(safeProductId)))
          .getSingleOrNull();
      if (product == null) {
        return;
      }
      if (product.isActive) {
        throw Exception(
          'Solo puedes eliminar definitivamente productos archivados.',
        );
      }

      final QueryRow? refs = await _db.customSelect(
        '''
        SELECT
          CAST((SELECT COUNT(*) FROM sale_items WHERE product_id = ?) AS INTEGER) AS sale_items_count,
          CAST((SELECT COUNT(*) FROM ipv_report_lines WHERE product_id = ?) AS INTEGER) AS ipv_lines_count,
          CAST((SELECT COUNT(*) FROM stock_movements WHERE product_id = ?) AS INTEGER) AS movements_count,
          CAST((SELECT COUNT(*) FROM stock_balances WHERE product_id = ?) AS INTEGER) AS balances_count,
          CAST((SELECT COUNT(*) FROM purchase_items WHERE product_id = ?) AS INTEGER) AS purchase_items_count,
          CAST((SELECT COUNT(*) FROM stock_lots WHERE product_id = ?) AS INTEGER) AS stock_lots_count,
          CAST((SELECT COUNT(*) FROM sale_item_lot_allocations WHERE product_id = ?) AS INTEGER) AS allocations_count
        ''',
        variables: <Variable<Object>>[
          Variable<String>(safeProductId),
          Variable<String>(safeProductId),
          Variable<String>(safeProductId),
          Variable<String>(safeProductId),
          Variable<String>(safeProductId),
          Variable<String>(safeProductId),
          Variable<String>(safeProductId),
        ],
      ).getSingleOrNull();

      final int saleItemsCount =
          (refs?.data['sale_items_count'] as num?)?.toInt() ?? 0;
      if (saleItemsCount > 0) {
        throw Exception(
          'Este producto tiene historial en ventas. '
          'Primero archiva y elimina definitivamente esas ventas.',
        );
      }
      final int purchaseItemsCount =
          (refs?.data['purchase_items_count'] as num?)?.toInt() ?? 0;
      if (purchaseItemsCount > 0) {
        throw Exception(
          'Este producto tiene historial en compras. '
          'No se puede eliminar para conservar la trazabilidad de costos.',
        );
      }

      final int ipvLinesCount =
          (refs?.data['ipv_lines_count'] as num?)?.toInt() ?? 0;
      final int movementsCount =
          (refs?.data['movements_count'] as num?)?.toInt() ?? 0;
      final int balancesCount =
          (refs?.data['balances_count'] as num?)?.toInt() ?? 0;
      final int stockLotsCount =
          (refs?.data['stock_lots_count'] as num?)?.toInt() ?? 0;
      final int allocationsCount =
          (refs?.data['allocations_count'] as num?)?.toInt() ?? 0;

      await (_db.delete(_db.ipvReportLines)
            ..where(
                (IpvReportLines tbl) => tbl.productId.equals(safeProductId)))
          .go();
      await (_db.delete(_db.saleItemLotAllocations)
            ..where((SaleItemLotAllocations tbl) =>
                tbl.productId.equals(safeProductId)))
          .go();
      await (_db.delete(_db.stockLots)
            ..where((StockLots tbl) => tbl.productId.equals(safeProductId)))
          .go();
      await (_db.delete(_db.stockMovements)
            ..where(
                (StockMovements tbl) => tbl.productId.equals(safeProductId)))
          .go();
      await (_db.delete(_db.stockBalances)
            ..where((StockBalances tbl) => tbl.productId.equals(safeProductId)))
          .go();
      await (_db.delete(_db.products)
            ..where((Products tbl) => tbl.id.equals(safeProductId)))
          .go();

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'PRODUCT_PURGED',
              entity: 'product',
              entityId: safeProductId,
              payloadJson: jsonEncode(<String, Object?>{
                'sku': product.sku,
                'name': product.name,
                'ipvLinesDeleted': ipvLinesCount,
                'movementsDeleted': movementsCount,
                'balancesDeleted': balancesCount,
                'stockLotsDeleted': stockLotsCount,
                'allocationsDeleted': allocationsCount,
              }),
            ),
          );
    });
  }

  Future<void> updatePrice({
    required String productId,
    required int priceCents,
    required int taxRateBps,
  }) async {
    await _licenseService.requireWriteAccess();
    await _assertPriceEditionAllowed(
      productId: productId,
      nextSalePriceCents: priceCents,
      nextCostPriceCents: null,
    );
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId)))
        .write(
      ProductsCompanion(
        priceCents: Value(priceCents),
        taxRateBps: Value(taxRateBps),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<ProductPriceEditionCheck> checkPriceEditionAllowed({
    required String productId,
    required int? nextSalePriceCents,
    required int? nextCostPriceCents,
  }) async {
    final String safeProductId = productId.trim();
    if (safeProductId.isEmpty) {
      throw Exception('Producto inválido.');
    }
    final Product? existing = await (_db.select(_db.products)
          ..where((Products tbl) => tbl.id.equals(safeProductId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El producto no existe.');
    }

    final int targetSale = nextSalePriceCents ?? existing.priceCents;
    final int targetCost = nextCostPriceCents ?? existing.costPriceCents;
    final bool salePriceChanged = existing.priceCents != targetSale;
    final bool costPriceChanged = existing.costPriceCents != targetCost;
    final bool hasPriceChanges = salePriceChanged || costPriceChanged;
    if (!hasPriceChanges) {
      return const ProductPriceEditionCheck(
        allowed: true,
        hasPriceChanges: false,
      );
    }

    final QueryRow? row = await _db.customSelect(
      '''
      SELECT CAST(COUNT(*) AS INTEGER) AS total
      FROM pos_sessions s
      INNER JOIN pos_terminals t
        ON t.id = s.terminal_id
      INNER JOIN stock_balances sb
        ON sb.warehouse_id = t.warehouse_id
      WHERE s.status = 'open'
        AND sb.product_id = ?
        AND COALESCE(sb.qty, 0) > 0
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeProductId),
      ],
    ).getSingleOrNull();

    final int openSessionsWithStock =
        (row?.data['total'] as num?)?.toInt() ?? 0;
    if (openSessionsWithStock > 0) {
      return const ProductPriceEditionCheck(
        allowed: false,
        hasPriceChanges: true,
        blockReason:
            'No se puede modificar el precio mientras haya un turno TPV abierto '
            'donde este producto tenga stock.',
      );
    }

    if (costPriceChanged) {
      final QueryRow? activeLotsRow = await _db.customSelect(
        '''
        SELECT CAST(COUNT(*) AS INTEGER) AS total
        FROM stock_lots l
        WHERE l.product_id = ?
          AND COALESCE(l.qty_remaining, 0) > 0
        LIMIT 1
        ''',
        variables: <Variable<Object>>[
          Variable<String>(safeProductId),
        ],
      ).getSingleOrNull();
      final int activeLots =
          (activeLotsRow?.data['total'] as num?)?.toInt() ?? 0;
      if (activeLots > 0) {
        return const ProductPriceEditionCheck(
          allowed: false,
          hasPriceChanges: true,
          blockReason:
              'No se puede modificar manualmente el costo mientras existan lotes activos. '
              'El costo se toma del lote FIFO vigente.',
        );
      }
    }

    return const ProductPriceEditionCheck(
      allowed: true,
      hasPriceChanges: true,
    );
  }

  String? _normalizeImagePath(String? value) {
    final String cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  String? _normalizeBarcode(String? value) {
    final String cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  String _normalizeCatalogValue(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.length == 1) {
      return trimmed.toUpperCase();
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  String _normalizeUnitSymbol(String value) {
    final String trimmed = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.length <= 4) {
      return trimmed.toLowerCase();
    }
    return _normalizeCatalogValue(trimmed);
  }

  Future<void> _assertPriceEditionAllowed({
    required String productId,
    required int nextSalePriceCents,
    required int? nextCostPriceCents,
  }) async {
    final ProductPriceEditionCheck check = await checkPriceEditionAllowed(
      productId: productId,
      nextSalePriceCents: nextSalePriceCents,
      nextCostPriceCents: nextCostPriceCents,
    );
    if (!check.allowed) {
      throw Exception(
        check.blockReason ?? 'No se puede modificar el precio en este momento.',
      );
    }
  }

  Future<void> _ensureCatalogDefaultsForKind(ProductCatalogKind kind) async {
    for (final String value in kind.defaults) {
      final String cleaned = _normalizeCatalogValue(value);
      if (cleaned.isEmpty) {
        continue;
      }
      final ProductCatalogItem? existing =
          await (_db.select(_db.productCatalogItems)
                ..where((ProductCatalogItems tbl) =>
                    tbl.kind.equals(kind.key) & tbl.value.equals(cleaned)))
              .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.productCatalogItems).insert(
              ProductCatalogItemsCompanion.insert(
                id: _uuid.v4(),
                kind: kind.key,
                value: cleaned,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      } else if (!existing.isActive) {
        await (_db.update(_db.productCatalogItems)
              ..where((ProductCatalogItems tbl) => tbl.id.equals(existing.id)))
            .write(
          ProductCatalogItemsCompanion(
            isActive: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<Map<String, int>> _usageCountByCatalogValue({
    required ProductCatalogKind kind,
  }) async {
    final String column = switch (kind) {
      ProductCatalogKind.type => 'product_type',
      ProductCatalogKind.category => 'category',
      ProductCatalogKind.unit => 'unit_measure',
    };
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT LOWER(TRIM($column)) AS value_key, COUNT(*) AS usage_count
      FROM products
      WHERE is_active = 1
      GROUP BY LOWER(TRIM($column))
      ''',
    ).get();
    return <String, int>{
      for (final QueryRow row in rows)
        (row.readNullable<String>('value_key') ?? '').trim():
            (row.data['usage_count'] as num?)?.toInt() ?? 0,
    };
  }

  Future<int> _countProductsByCatalogValue({
    required ProductCatalogKind kind,
    required String value,
  }) async {
    final String column = switch (kind) {
      ProductCatalogKind.type => 'product_type',
      ProductCatalogKind.category => 'category',
      ProductCatalogKind.unit => 'unit_measure',
    };
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS total
      FROM products
      WHERE is_active = 1
        AND LOWER(TRIM($column)) = LOWER(TRIM(?))
      ''',
      variables: <Variable<Object>>[Variable<String>(value)],
    ).getSingleOrNull();
    return (row?.data['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> _countActiveCatalogItems(ProductCatalogKind kind) async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS total
      FROM product_catalog_items
      WHERE kind = ?
        AND is_active = 1
      ''',
      variables: <Variable<Object>>[Variable<String>(kind.key)],
    ).getSingleOrNull();
    return (row?.data['total'] as num?)?.toInt() ?? 0;
  }

  MeasurementUnitCatalog _defaultMeasurementCatalog() {
    final List<MeasurementUnitTypeModel> types = <MeasurementUnitTypeModel>[
      MeasurementUnitTypeModel(
        id: 'unit-type-length',
        name: 'Longitud',
        description: 'Unidades para distancia y tamaño.',
        isSystem: true,
        isActive: true,
        sortOrder: 0,
      ),
      MeasurementUnitTypeModel(
        id: 'unit-type-mass',
        name: 'Masa',
        description: 'Unidades para peso y masa.',
        isSystem: true,
        isActive: true,
        sortOrder: 1,
      ),
      MeasurementUnitTypeModel(
        id: 'unit-type-volume',
        name: 'Volumen',
        description: 'Unidades para capacidad y líquidos.',
        isSystem: true,
        isActive: true,
        sortOrder: 2,
      ),
      MeasurementUnitTypeModel(
        id: 'unit-type-count',
        name: 'Unidades',
        description: 'Unidades de conteo para productos.',
        isSystem: true,
        isActive: true,
        sortOrder: 3,
      ),
    ];

    final List<MeasurementUnitModel> units = <MeasurementUnitModel>[
      MeasurementUnitModel(
        id: 'unit-m',
        typeId: 'unit-type-length',
        symbol: 'm',
        name: 'Metro',
        isSystem: true,
        isActive: true,
        sortOrder: 0,
      ),
      MeasurementUnitModel(
        id: 'unit-km',
        typeId: 'unit-type-length',
        symbol: 'km',
        name: 'Kilometro',
        isSystem: true,
        isActive: true,
        sortOrder: 1,
      ),
      MeasurementUnitModel(
        id: 'unit-cm',
        typeId: 'unit-type-length',
        symbol: 'cm',
        name: 'Centimetro',
        isSystem: true,
        isActive: true,
        sortOrder: 2,
      ),
      MeasurementUnitModel(
        id: 'unit-mm',
        typeId: 'unit-type-length',
        symbol: 'mm',
        name: 'Milimetro',
        isSystem: true,
        isActive: true,
        sortOrder: 3,
      ),
      MeasurementUnitModel(
        id: 'unit-g',
        typeId: 'unit-type-mass',
        symbol: 'g',
        name: 'Gramo',
        isSystem: true,
        isActive: true,
        sortOrder: 10,
      ),
      MeasurementUnitModel(
        id: 'unit-kg',
        typeId: 'unit-type-mass',
        symbol: 'kg',
        name: 'Kilogramo',
        isSystem: true,
        isActive: true,
        sortOrder: 11,
      ),
      MeasurementUnitModel(
        id: 'unit-lb',
        typeId: 'unit-type-mass',
        symbol: 'lb',
        name: 'Libra',
        isSystem: true,
        isActive: true,
        sortOrder: 12,
      ),
      MeasurementUnitModel(
        id: 'unit-ml',
        typeId: 'unit-type-volume',
        symbol: 'ml',
        name: 'Mililitro',
        isSystem: true,
        isActive: true,
        sortOrder: 20,
      ),
      MeasurementUnitModel(
        id: 'unit-l',
        typeId: 'unit-type-volume',
        symbol: 'l',
        name: 'Litro',
        isSystem: true,
        isActive: true,
        sortOrder: 21,
      ),
      MeasurementUnitModel(
        id: 'unit-ud',
        typeId: 'unit-type-count',
        symbol: 'ud',
        name: 'Unidad',
        isSystem: true,
        isActive: true,
        sortOrder: 30,
      ),
      MeasurementUnitModel(
        id: 'unit-caja',
        typeId: 'unit-type-count',
        symbol: 'caja',
        name: 'Caja',
        isSystem: true,
        isActive: true,
        sortOrder: 31,
      ),
      MeasurementUnitModel(
        id: 'unit-paquete',
        typeId: 'unit-type-count',
        symbol: 'paquete',
        name: 'Paquete',
        isSystem: true,
        isActive: true,
        sortOrder: 32,
      ),
    ];

    return MeasurementUnitCatalog(types: types, units: units).normalized();
  }

  Future<void> _saveMeasurementUnitCatalog(
      MeasurementUnitCatalog catalog) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _measurementCatalogKey,
            value: jsonEncode(catalog.toJson()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<MeasurementUnitCatalog> _setMeasurementUnitsActive({
    required MeasurementUnitCatalog catalog,
    required Set<String> unitIds,
    required bool isActive,
  }) async {
    final List<MeasurementUnitModel> units =
        catalog.units.toList(growable: true);
    for (int i = 0; i < units.length; i++) {
      final MeasurementUnitModel row = units[i];
      if (!unitIds.contains(row.id)) {
        continue;
      }
      if (!isActive) {
        final int usage = await _countProductsByCatalogValue(
          kind: ProductCatalogKind.unit,
          value: row.symbol,
        );
        if (usage > 0) {
          throw Exception(
            'No se puede desactivar ${row.symbol}: está en uso por $usage producto(s).',
          );
        }
      }
      units[i] = row.copyWith(isActive: isActive);
    }
    return MeasurementUnitCatalog(types: catalog.types, units: units)
        .normalized();
  }

  Future<void> _syncMeasurementUnitsWithProductCatalog(
    List<MeasurementUnitModel> units,
  ) async {
    final List<ProductCatalogItem> catalogUnits =
        await (_db.select(_db.productCatalogItems)
              ..where(
                (ProductCatalogItems tbl) => tbl.kind.equals(
                  ProductCatalogKind.unit.key,
                ),
              ))
            .get();

    for (final MeasurementUnitModel unit in units) {
      ProductCatalogItem? existing;
      for (final ProductCatalogItem row in catalogUnits) {
        if (row.value.trim().toLowerCase() == unit.symbol.toLowerCase()) {
          existing = row;
          break;
        }
      }
      if (existing == null) {
        if (unit.isActive) {
          await _db.into(_db.productCatalogItems).insert(
                ProductCatalogItemsCompanion.insert(
                  id: _uuid.v4(),
                  kind: ProductCatalogKind.unit.key,
                  value: unit.symbol,
                ),
              );
        }
        continue;
      }
      final ProductCatalogItem catalogItem = existing;
      if (catalogItem.value != unit.symbol ||
          catalogItem.isActive != unit.isActive) {
        await (_db.update(_db.productCatalogItems)
              ..where(
                (ProductCatalogItems tbl) => tbl.id.equals(catalogItem.id),
              ))
            .write(
          ProductCatalogItemsCompanion(
            value: Value(unit.symbol),
            isActive: Value(unit.isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }
}
