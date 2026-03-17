import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';
import '../../productos/domain/product_qr_codec.dart';

class DataFileEntry {
  const DataFileEntry({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final DateTime modifiedAt;
  final int sizeBytes;
}

class BackupResult {
  const BackupResult({
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String path;
  final int sizeBytes;
  final DateTime createdAt;
}

class CsvExportResult {
  const CsvExportResult({
    required this.path,
    required this.count,
    required this.createdAt,
  });

  final String path;
  final int count;
  final DateTime createdAt;
}

class CsvImportResult {
  const CsvImportResult({
    required this.path,
    required this.created,
    required this.updated,
    required this.skipped,
    required this.warnings,
  });

  final String path;
  final int created;
  final int updated;
  final int skipped;
  final List<String> warnings;
}

class QrPdfExportResult {
  const QrPdfExportResult({
    required this.path,
    required this.count,
    required this.createdAt,
  });

  final String path;
  final int count;
  final DateTime createdAt;
}

class DataManagementLocalDataSource {
  DataManagementLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  Future<String> dataRootPath() async {
    final Directory root = await _resolvePosIpvRootDir();
    return root.path;
  }

  Future<BackupResult> createDatabaseBackup() async {
    final DateTime now = DateTime.now();
    final String stamp = _ts(now);
    final Directory dir = await _resolveBackupDir();
    final File target = File(p.join(dir.path, 'posipv-backup-$stamp.db'));
    if (target.existsSync()) {
      await target.delete();
    }
    final String escapedPath = target.path.replaceAll("'", "''");

    try {
      await _db.customStatement("VACUUM INTO '$escapedPath'");
    } catch (_) {
      await _copyDatabaseFile(target);
    }

    final int size = await target.length();
    return BackupResult(
      path: target.path,
      sizeBytes: size,
      createdAt: now,
    );
  }

  Future<List<DataFileEntry>> listBackupFiles() async {
    final Directory dir = await _resolveBackupDir();
    return _listFiles(dir, extension: '.db');
  }

  Future<CsvExportResult> exportProductsCsv() async {
    final DateTime now = DateTime.now();
    final String stamp = _ts(now);
    final Directory dir = await _resolveCsvExportDir();
    final File file = File(p.join(dir.path, 'productos-$stamp.csv'));
    final List<Product> products = await (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.isActive.equals(true) &
              tbl.id.isNotNull() &
              tbl.sku.isNotNull() &
              tbl.name.isNotNull())
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();

    final StringBuffer csv = StringBuffer()
      ..writeln(
          'code,barcode,name,cost_price,sale_price,category,product_type,unit_measure,currency_code,tax_rate_bps,image_path,is_active');

    for (final Product row in products) {
      csv.writeln(
        <String>[
          _cell(row.sku),
          _cell(row.barcode ?? ''),
          _cell(row.name),
          _cell((row.costPriceCents / 100).toStringAsFixed(2)),
          _cell((row.priceCents / 100).toStringAsFixed(2)),
          _cell(row.category),
          _cell(row.productType),
          _cell(row.unitMeasure),
          _cell(row.currencyCode),
          _cell(row.taxRateBps.toString()),
          _cell(row.imagePath ?? ''),
          '1',
        ].join(','),
      );
    }

    await file.writeAsString(csv.toString(), flush: true);
    return CsvExportResult(
      path: file.path,
      count: products.length,
      createdAt: now,
    );
  }

  Future<List<DataFileEntry>> listCsvFiles() async {
    final Directory exportDir = await _resolveCsvExportDir();
    final Directory importDir = await _resolveCsvImportDir();
    final List<DataFileEntry> out = <DataFileEntry>[
      ...await _listFiles(exportDir, extension: '.csv'),
      ...await _listFiles(importDir, extension: '.csv'),
    ];
    out.sort((DataFileEntry a, DataFileEntry b) {
      return b.modifiedAt.compareTo(a.modifiedAt);
    });
    return out;
  }

  Future<QrPdfExportResult> exportProductsQrPdf() async {
    final DateTime now = DateTime.now();
    final String stamp = _ts(now);
    final Directory dir = await _resolveQrExportDir();
    final File file = File(p.join(dir.path, 'productos-qr-$stamp.pdf'));

    final List<Product> products = await (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.isActive.equals(true) &
              tbl.id.isNotNull() &
              tbl.sku.isNotNull() &
              tbl.name.isNotNull() &
              tbl.currencyCode.isNotNull() &
              tbl.priceCents.isNotNull())
          ..orderBy(<OrderingTerm Function(Products)>[
            (Products tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
    if (products.isEmpty) {
      throw Exception('No hay productos activos para exportar.');
    }

    final pw.Document doc = pw.Document();
    const PdfPageFormat format = PdfPageFormat.a4;
    const double margin = 12;
    const double spacing = 6;
    const double qrSize = 58;
    const double labelHeight = 72;
    final double contentWidth = format.width - (margin * 2);
    final double widthForFourCols = (contentWidth - (spacing * 3)) / 4;
    final int columns = widthForFourCols >= 128 ? 4 : 3;
    final double labelWidth =
        (contentWidth - (spacing * (columns - 1))) / columns;

    pw.Widget label(Product product) {
      final String qrData = buildProductQrData(product);
      return pw.Container(
        width: labelWidth,
        height: labelHeight,
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blueGrey600, width: 0.6),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: <pw.Widget>[
            pw.Container(
              width: qrSize,
              height: qrSize,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(2.4),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrData,
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: <pw.Widget>[
                  pw.Text(
                    _clip(product.name, columns == 4 ? 16 : 22),
                    maxLines: 1,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: columns == 4 ? 8.2 : 8.8,
                    ),
                  ),
                  pw.SizedBox(height: 1.2),
                  pw.Text(
                    'Cod: ${_clip(product.sku, columns == 4 ? 10 : 14)}',
                    style: pw.TextStyle(
                      fontSize: columns == 4 ? 6.8 : 7.2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1.2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#EFFAF6'),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      '${product.currencyCode} ${(product.priceCents / 100).toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: columns == 4 ? 7.2 : 7.8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(margin),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: products.map(label).toList(),
            ),
          ];
        },
      ),
    );

    await file.writeAsBytes(await doc.save(), flush: true);
    return QrPdfExportResult(
      path: file.path,
      count: products.length,
      createdAt: now,
    );
  }

  Future<List<DataFileEntry>> listQrPdfFiles() async {
    final Directory dir = await _resolveQrExportDir();
    return _listFiles(dir, extension: '.pdf');
  }

  Future<CsvImportResult> importProductsCsv(String filePath) async {
    await _licenseService.requireWriteAccess();
    final File file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('El archivo no existe.');
    }

    final String raw = await file.readAsString();
    final List<List<String>> rows = _parseCsv(raw);
    if (rows.isEmpty) {
      throw Exception('El archivo CSV está vacío.');
    }

    final List<String> header = rows.first
        .map((String cell) => _normalizeHeader(cell))
        .toList(growable: false);
    final Map<String, int> indexByHeader = <String, int>{
      for (int i = 0; i < header.length; i++) header[i]: i,
    };

    final int? codeIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['code', 'codigo', 'sku'],
    );
    final int? nameIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['name', 'nombre'],
    );
    if (codeIndex == null || nameIndex == null) {
      throw Exception(
        'El CSV debe incluir columnas code/sku y name/nombre.',
      );
    }

    final int? barcodeIndex =
        _firstHeaderIndex(indexByHeader, <String>['barcode', 'bar_code']);
    final int? costIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['cost_price', 'cost', 'costo', 'precio_costo'],
    );
    final int? saleIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['sale_price', 'price', 'precio_venta', 'precio'],
    );
    final int? categoryIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['category', 'categoria'],
    );
    final int? typeIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['product_type', 'type', 'tipo_producto', 'tipo'],
    );
    final int? unitIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['unit_measure', 'unit', 'unidad_medida', 'unidad'],
    );
    final int? currencyIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['currency_code', 'currency', 'moneda'],
    );
    final int? taxIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['tax_rate_bps', 'tax_bps', 'impuesto_bps'],
    );
    final int? imageIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['image_path', 'image', 'imagen'],
    );
    final int? activeIndex = _firstHeaderIndex(
      indexByHeader,
      <String>['is_active', 'activo'],
    );

    final List<Product> existingProducts = await (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.id.isNotNull() & tbl.sku.isNotNull() & tbl.name.isNotNull()))
        .get();
    final Map<String, String> productIdByCode = <String, String>{
      for (final Product row in existingProducts) row.sku.toLowerCase(): row.id,
    };

    int created = 0;
    int updated = 0;
    int skipped = 0;
    final List<String> warnings = <String>[];

    await _db.transaction(() async {
      for (int line = 1; line < rows.length; line++) {
        final List<String> row = rows[line];
        final String code = _cellAt(row, codeIndex).trim();
        final String name = _cellAt(row, nameIndex).trim();
        if (code.isEmpty || name.isEmpty) {
          skipped += 1;
          warnings.add('Fila ${line + 1}: faltan code o name.');
          continue;
        }

        final String barcode = _cellAt(row, barcodeIndex).trim();
        final int costCents = _moneyToCents(_cellAt(row, costIndex));
        final int saleCents = _moneyToCents(_cellAt(row, saleIndex));
        final String category = _defaulted(
          _cellAt(row, categoryIndex),
          fallback: 'General',
        );
        final String productType = _defaulted(
          _cellAt(row, typeIndex),
          fallback: 'Fisico',
        );
        final String unitMeasure = _defaulted(
          _cellAt(row, unitIndex),
          fallback: 'Unidad',
        );
        final String currencyCode = _defaulted(
          _cellAt(row, currencyIndex),
          fallback: 'USD',
        ).toUpperCase();
        final int taxRateBps = _intValue(_cellAt(row, taxIndex), fallback: 0);
        final String imagePath = _cellAt(row, imageIndex).trim();
        final bool isActive = _boolValue(_cellAt(row, activeIndex));

        final String codeKey = code.toLowerCase();
        final String? existingId = productIdByCode[codeKey];

        if (existingId == null) {
          final String newId = _uuid.v4();
          await _db.into(_db.products).insert(
                ProductsCompanion.insert(
                  id: newId,
                  sku: code,
                  barcode: Value(barcode.isEmpty ? null : barcode),
                  name: name,
                  priceCents: Value(saleCents),
                  taxRateBps: Value(taxRateBps),
                  imagePath: Value(imagePath.isEmpty ? null : imagePath),
                  costPriceCents: Value(costCents),
                  category: Value(category),
                  productType: Value(productType),
                  unitMeasure: Value(unitMeasure),
                  currencyCode: Value(currencyCode),
                  isActive: Value(isActive),
                ),
              );
          productIdByCode[codeKey] = newId;
          created += 1;
          continue;
        }

        await (_db.update(_db.products)
              ..where((Products tbl) => tbl.id.equals(existingId)))
            .write(
          ProductsCompanion(
            sku: Value(code),
            barcode: Value(barcode.isEmpty ? null : barcode),
            name: Value(name),
            priceCents: Value(saleCents),
            taxRateBps: Value(taxRateBps),
            imagePath: Value(imagePath.isEmpty ? null : imagePath),
            costPriceCents: Value(costCents),
            category: Value(category),
            productType: Value(productType),
            unitMeasure: Value(unitMeasure),
            currencyCode: Value(currencyCode),
            isActive: Value(isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
        updated += 1;
      }
    });

    return CsvImportResult(
      path: file.path,
      created: created,
      updated: updated,
      skipped: skipped,
      warnings: warnings,
    );
  }

  Future<void> _copyDatabaseFile(File target) async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final File source = File(p.join(docs.path, 'app.db'));
    if (!source.existsSync()) {
      throw Exception('No se encontró la base de datos para respaldo.');
    }
    await source.copy(target.path);
  }

  Future<Directory> _resolvePosIpvRootDir() async {
    final Directory base = await _resolveDownloadsBaseDir();
    final Directory dir = Directory(p.join(base.path, 'POSIPV'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _resolveBackupDir() async {
    final Directory root = await _resolvePosIpvRootDir();
    final Directory dir = Directory(p.join(root.path, 'Backups'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _resolveCsvExportDir() async {
    final Directory root = await _resolvePosIpvRootDir();
    final Directory dir = Directory(p.join(root.path, 'CSV'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _resolveCsvImportDir() async {
    final Directory root = await _resolvePosIpvRootDir();
    final Directory dir = Directory(p.join(root.path, 'Import'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _resolveQrExportDir() async {
    final Directory root = await _resolvePosIpvRootDir();
    final Directory dir = Directory(p.join(root.path, 'QR'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
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

  Future<List<DataFileEntry>> _listFiles(
    Directory dir, {
    required String extension,
  }) async {
    if (!dir.existsSync()) {
      return const <DataFileEntry>[];
    }
    final List<DataFileEntry> out = <DataFileEntry>[];
    await for (final FileSystemEntity entity in dir.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!entity.path.toLowerCase().endsWith(extension)) {
        continue;
      }
      final FileStat stat = await entity.stat();
      out.add(
        DataFileEntry(
          path: entity.path,
          name: p.basename(entity.path),
          modifiedAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    out.sort((DataFileEntry a, DataFileEntry b) {
      return b.modifiedAt.compareTo(a.modifiedAt);
    });
    return out;
  }

  int? _firstHeaderIndex(Map<String, int> indexByHeader, List<String> names) {
    for (final String name in names) {
      final int? index = indexByHeader[_normalizeHeader(name)];
      if (index != null) {
        return index;
      }
    }
    return null;
  }

  String _normalizeHeader(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _cell(String value) {
    final String v = value;
    if (!v.contains(RegExp(r'["\n\r,]'))) {
      return v;
    }
    return '"${v.replaceAll('"', '""')}"';
  }

  String _cellAt(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  String _defaulted(String raw, {required String fallback}) {
    final String v = raw.trim();
    return v.isEmpty ? fallback : v;
  }

  int _moneyToCents(String raw) {
    final String cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) {
      return 0;
    }
    final double? asDouble = double.tryParse(cleaned);
    if (asDouble != null) {
      return (asDouble * 100).round();
    }
    final int? asInt = int.tryParse(cleaned);
    return asInt ?? 0;
  }

  int _intValue(String raw, {required int fallback}) {
    final String cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return fallback;
    }
    return int.tryParse(cleaned) ?? fallback;
  }

  bool _boolValue(String raw) {
    final String cleaned = raw.trim().toLowerCase();
    if (cleaned.isEmpty) {
      return true;
    }
    return cleaned == '1' ||
        cleaned == 'true' ||
        cleaned == 'yes' ||
        cleaned == 'si' ||
        cleaned == 'sí';
  }

  List<List<String>> _parseCsv(String input) {
    final List<List<String>> rows = <List<String>>[];
    final List<String> row = <String>[];
    final StringBuffer cell = StringBuffer();
    bool inQuotes = false;

    int i = 0;
    while (i < input.length) {
      final String ch = input[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i += 2;
          continue;
        }
        inQuotes = !inQuotes;
        i += 1;
        continue;
      }
      if (ch == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
        i += 1;
        continue;
      }
      if ((ch == '\n' || ch == '\r') && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
        if (row.any((String value) => value.trim().isNotEmpty)) {
          rows.add(<String>[...row]);
        }
        row.clear();
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i += 2;
        } else {
          i += 1;
        }
        continue;
      }
      cell.write(ch);
      i += 1;
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      if (row.any((String value) => value.trim().isNotEmpty)) {
        rows.add(<String>[...row]);
      }
    }
    return rows;
  }

  String _ts(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}-'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  String _clip(String raw, int max) {
    final String text = raw.trim();
    if (text.length <= max) {
      return text;
    }
    if (max <= 1) {
      return text.substring(0, max);
    }
    return '${text.substring(0, max - 1)}…';
  }
}
