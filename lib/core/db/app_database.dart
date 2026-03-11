import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => <Column>{id};
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
    StockBalances,
    StockMovements,
    Sales,
    SaleItems,
    Payments,
    AppSettings,
    AuditLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedDefaultProductCatalogItems();
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
        },
      );

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
