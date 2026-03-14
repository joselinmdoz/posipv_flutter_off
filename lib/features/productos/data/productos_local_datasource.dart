import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
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

  Future<List<Product>> listActiveProducts() {
    return (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.isActive.equals(true) & _hasUsableProductFields(tbl))
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ]))
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

  Future<void> createProduct(ProductFormInput input) async {
    await _licenseService.requireWriteAccess();
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

  Future<void> updateProduct({
    required String productId,
    required ProductFormInput input,
  }) async {
    await _licenseService.requireWriteAccess();
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

  Future<void> updatePrice({
    required String productId,
    required int priceCents,
    required int taxRateBps,
  }) async {
    await _licenseService.requireWriteAccess();
    await (_db.update(_db.products)..where((tbl) => tbl.id.equals(productId)))
        .write(
      ProductsCompanion(
        priceCents: Value(priceCents),
        taxRateBps: Value(taxRateBps),
        updatedAt: Value(DateTime.now()),
      ),
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
}
