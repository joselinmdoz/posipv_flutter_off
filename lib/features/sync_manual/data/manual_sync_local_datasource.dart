import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';

class ManualSyncExportResult {
  const ManualSyncExportResult({
    required this.filePath,
    required this.sessionId,
    required this.saleCount,
    required this.paymentCount,
    required this.movementCount,
    required this.totalCents,
    required this.checksum,
  });

  final String filePath;
  final String sessionId;
  final int saleCount;
  final int paymentCount;
  final int movementCount;
  final int totalCents;
  final String checksum;
}

class ManualSyncPackagePreview {
  const ManualSyncPackagePreview({
    required this.filePath,
    required this.isValid,
    required this.message,
    required this.sessionId,
    required this.sourceTerminal,
    required this.saleCount,
    required this.movementCount,
    required this.totalCents,
    required this.exportedAt,
  });

  final String filePath;
  final bool isValid;
  final String message;
  final String sessionId;
  final String sourceTerminal;
  final int saleCount;
  final int movementCount;
  final int totalCents;
  final DateTime? exportedAt;
}

class ManualSyncImportResult {
  const ManualSyncImportResult({
    required this.filePath,
    required this.sessionId,
    required this.saleCount,
    required this.paymentCount,
    required this.movementCount,
    required this.totalCents,
    required this.warnings,
  });

  final String filePath;
  final String sessionId;
  final int saleCount;
  final int paymentCount;
  final int movementCount;
  final int totalCents;
  final List<String> warnings;
}

class ManualSyncSessionOption {
  const ManualSyncSessionOption({
    required this.sessionId,
    required this.terminalName,
    required this.terminalCode,
    required this.closedAt,
    required this.saleCount,
    required this.totalCents,
  });

  final String sessionId;
  final String terminalName;
  final String terminalCode;
  final DateTime closedAt;
  final int saleCount;
  final int totalCents;
}

class ManualSyncPackageFileOption {
  const ManualSyncPackageFileOption({
    required this.filePath,
    required this.fileName,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  final String filePath;
  final String fileName;
  final DateTime modifiedAt;
  final int sizeBytes;
}

class ManualSyncLocalDataSource {
  ManualSyncLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
  }) : _licenseService = licenseService;

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  static const MethodChannel _nativeChannel =
      MethodChannel('com.example.posipv/device_identity');

  Future<String?> pickSyncPackageFileWithSystemExplorer() async {
    try {
      final String? selectedPath =
          await _nativeChannel.invokeMethod<String>('pickSyncFile');
      final String cleaned = (selectedPath ?? '').trim();
      if (cleaned.isEmpty) {
        return null;
      }
      return cleaned;
    } on PlatformException catch (e) {
      throw Exception(
        e.message ?? 'No se pudo abrir el explorador de archivos.',
      );
    }
  }

  Future<ManualSyncExportResult> exportClosedSessionPackage({
    required String sessionId,
    String sourceLabel = 'TPV',
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeSessionId = sessionId.trim();
    if (safeSessionId.isEmpty) {
      throw Exception('Debes indicar un turno válido.');
    }

    final PosSession? session = await (_db.select(_db.posSessions)
          ..where((PosSessions tbl) => tbl.id.equals(safeSessionId)))
        .getSingleOrNull();
    if (session == null) {
      throw Exception('El turno no existe.');
    }
    if (session.status.trim().toLowerCase() != 'closed') {
      throw Exception('Solo se pueden exportar turnos cerrados.');
    }

    final PosTerminal? terminal = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.equals(session.terminalId)))
        .getSingleOrNull();
    if (terminal == null) {
      throw Exception('El TPV asociado al turno no existe.');
    }
    final Warehouse? warehouse = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) => tbl.id.equals(terminal.warehouseId)))
        .getSingleOrNull();
    if (warehouse == null) {
      throw Exception('El almacén del TPV no existe.');
    }

    final List<Sale> sales = await (_db.select(_db.sales)
          ..where(
            (Sales tbl) =>
                tbl.terminalSessionId.equals(session.id) &
                tbl.status.equals('posted'),
          )
          ..orderBy(<OrderingTerm Function(Sales)>[
            (Sales tbl) => OrderingTerm.asc(tbl.createdAt),
          ]))
        .get();
    final Set<String> saleIds = sales.map((Sale row) => row.id).toSet();
    final Set<String> customerIds = sales
        .map((Sale row) => (row.customerId ?? '').trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    final List<SaleItem> saleItems = saleIds.isEmpty
        ? <SaleItem>[]
        : await (_db.select(_db.saleItems)
              ..where((SaleItems tbl) => tbl.saleId.isIn(saleIds))
              ..orderBy(<OrderingTerm Function(SaleItems)>[
                (SaleItems tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();

    final List<Payment> payments = saleIds.isEmpty
        ? <Payment>[]
        : await (_db.select(_db.payments)
              ..where((Payments tbl) => tbl.saleId.isIn(saleIds))
              ..orderBy(<OrderingTerm Function(Payments)>[
                (Payments tbl) => OrderingTerm.asc(tbl.createdAt),
              ]))
            .get();

    final List<PosSessionCashBreakdown> sessionBreakdowns =
        await (_db.select(_db.posSessionCashBreakdowns)
              ..where(
                (PosSessionCashBreakdowns tbl) =>
                    tbl.sessionId.equals(session.id),
              )
              ..orderBy(<OrderingTerm Function(PosSessionCashBreakdowns)>[
                (PosSessionCashBreakdowns tbl) =>
                    OrderingTerm.desc(tbl.denominationCents),
              ]))
            .get();

    final List<StockMovement> saleLinkedMovements = saleIds.isEmpty
        ? <StockMovement>[]
        : await (_db.select(_db.stockMovements)
              ..where((StockMovements tbl) => tbl.refId.isIn(saleIds))
              ..orderBy(<OrderingTerm Function(StockMovements)>[
                (StockMovements tbl) => OrderingTerm.asc(tbl.createdAt),
              ]))
            .get();
    final DateTime sessionClosedAt = session.closedAt ?? DateTime.now();
    final DateTime sessionEndExclusive =
        sessionClosedAt.add(const Duration(milliseconds: 1));
    final List<StockMovement> manualSessionMovements =
        await (_db.select(_db.stockMovements)
              ..where(
                (StockMovements tbl) =>
                    tbl.warehouseId.equals(warehouse.id) &
                    tbl.createdBy.equals(session.userId) &
                    tbl.movementSource.equals('manual') &
                    tbl.createdAt.isBiggerOrEqualValue(session.openedAt) &
                    tbl.createdAt.isSmallerThanValue(sessionEndExclusive),
              )
              ..orderBy(<OrderingTerm Function(StockMovements)>[
                (StockMovements tbl) => OrderingTerm.asc(tbl.createdAt),
              ]))
            .get();
    final Map<String, StockMovement> movementById = <String, StockMovement>{
      for (final StockMovement row in saleLinkedMovements) row.id: row,
    };
    for (final StockMovement row in manualSessionMovements) {
      final String refType = (row.refType ?? '').trim().toLowerCase();
      if (_isSaleRefType(refType)) {
        continue;
      }
      movementById.putIfAbsent(row.id, () => row);
    }
    final List<StockMovement> movements = movementById.values.toList()
      ..sort(
        (StockMovement a, StockMovement b) {
          final int byTime = a.createdAt.compareTo(b.createdAt);
          if (byTime != 0) {
            return byTime;
          }
          return a.id.compareTo(b.id);
        },
      );

    final Set<String> productIds = <String>{
      ...saleItems.map((SaleItem row) => row.productId),
      ...movements.map((StockMovement row) => row.productId),
    };
    final List<Product> products = productIds.isEmpty
        ? <Product>[]
        : await (_db.select(_db.products)
              ..where((Products tbl) => tbl.id.isIn(productIds)))
            .get();

    final List<Customer> customers = customerIds.isEmpty
        ? <Customer>[]
        : await (_db.select(_db.customers)
              ..where((Customers tbl) => tbl.id.isIn(customerIds)))
            .get();

    final Set<String> userIds = <String>{
      session.userId,
      ...sales.map((Sale row) => row.cashierId),
      ...movements.map((StockMovement row) => row.createdBy),
    };
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.isIn(userIds)))
        .get();

    final int totalCents = sales.fold<int>(
      0,
      (int sum, Sale row) => sum + row.totalCents,
    );
    final DateTime exportedAt = DateTime.now().toUtc();
    final Map<String, Object?> packageWithoutChecksum = <String, Object?>{
      'kind': 'posipv_manual_sync',
      'v': 1,
      'sourceLabel': sourceLabel.trim().isEmpty ? 'TPV' : sourceLabel.trim(),
      'exportedAt': exportedAt.toIso8601String(),
      'sessionId': session.id,
      'source': <String, Object?>{
        'terminalId': terminal.id,
        'terminalCode': terminal.code,
        'terminalName': terminal.name,
        'warehouseId': warehouse.id,
        'warehouseName': warehouse.name,
      },
      'summary': <String, Object?>{
        'saleCount': sales.length,
        'paymentCount': payments.length,
        'movementCount': movements.length,
        'totalCents': totalCents,
      },
      'data': <String, Object?>{
        'users': users.map(_mapUser).toList(growable: false),
        'warehouses': <Map<String, Object?>>[_mapWarehouse(warehouse)],
        'terminals': <Map<String, Object?>>[_mapTerminal(terminal)],
        'products': products.map(_mapProduct).toList(growable: false),
        'customers': customers.map(_mapCustomer).toList(growable: false),
        'posSessions': <Map<String, Object?>>[_mapPosSession(session)],
        'posSessionCashBreakdowns':
            sessionBreakdowns.map(_mapSessionCash).toList(growable: false),
        'sales': sales.map(_mapSale).toList(growable: false),
        'saleItems': saleItems.map(_mapSaleItem).toList(growable: false),
        'payments': payments.map(_mapPayment).toList(growable: false),
        'stockMovements': movements.map(_mapMovement).toList(growable: false),
      },
    };

    final String checksum = _checksumFor(packageWithoutChecksum);
    final Map<String, Object?> packageMap = <String, Object?>{
      ...packageWithoutChecksum,
      'checksum': checksum,
    };

    final Directory syncDir = await _resolveSyncDir();
    final String stamp = _stamp(exportedAt.toLocal());
    final String safeCode = _sanitizeSegment(terminal.code);
    final String fileName = 'sync_${safeCode}_${stamp}_${session.id}.json';
    final File file = File(p.join(syncDir.path, fileName));
    await file.writeAsString(jsonEncode(packageMap), flush: true);

    return ManualSyncExportResult(
      filePath: file.path,
      sessionId: session.id,
      saleCount: sales.length,
      paymentCount: payments.length,
      movementCount: movements.length,
      totalCents: totalCents,
      checksum: checksum,
    );
  }

  Future<ManualSyncPackagePreview> previewPackageFromFile(
      String filePath) async {
    final String safePath = filePath.trim();
    if (safePath.isEmpty) {
      return const ManualSyncPackagePreview(
        filePath: '',
        isValid: false,
        message: 'Ruta de archivo inválida.',
        sessionId: '',
        sourceTerminal: '',
        saleCount: 0,
        movementCount: 0,
        totalCents: 0,
        exportedAt: null,
      );
    }
    final File file = File(safePath);
    if (!file.existsSync()) {
      return ManualSyncPackagePreview(
        filePath: safePath,
        isValid: false,
        message: 'El archivo no existe.',
        sessionId: '',
        sourceTerminal: '',
        saleCount: 0,
        movementCount: 0,
        totalCents: 0,
        exportedAt: null,
      );
    }

    try {
      final String raw = await file.readAsString();
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return ManualSyncPackagePreview(
          filePath: safePath,
          isValid: false,
          message: 'Formato inválido.',
          sessionId: '',
          sourceTerminal: '',
          saleCount: 0,
          movementCount: 0,
          totalCents: 0,
          exportedAt: null,
        );
      }
      final String kind = (decoded['kind'] as String? ?? '').trim();
      final int version = (decoded['v'] as num?)?.toInt() ?? 0;
      if (kind != 'posipv_manual_sync' || version != 1) {
        return ManualSyncPackagePreview(
          filePath: safePath,
          isValid: false,
          message: 'Paquete de sincronización no reconocido.',
          sessionId: (decoded['sessionId'] as String? ?? '').trim(),
          sourceTerminal: '',
          saleCount: 0,
          movementCount: 0,
          totalCents: 0,
          exportedAt: null,
        );
      }

      final String providedChecksum =
          (decoded['checksum'] as String? ?? '').trim();
      final Map<String, dynamic> withoutChecksum = <String, dynamic>{
        ...decoded,
      }..remove('checksum');
      final String expectedChecksum = _checksumFor(withoutChecksum);
      final bool isValid = providedChecksum.isNotEmpty &&
          expectedChecksum.toLowerCase() == providedChecksum.toLowerCase();

      final Map<String, dynamic> source =
          (decoded['source'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};
      final Map<String, dynamic> summary =
          (decoded['summary'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};

      DateTime? exportedAt;
      try {
        exportedAt = DateTime.parse(
          (decoded['exportedAt'] as String? ?? '').trim(),
        );
      } catch (_) {}

      return ManualSyncPackagePreview(
        filePath: safePath,
        isValid: isValid,
        message: isValid
            ? 'Paquete válido. Listo para importación.'
            : 'Checksum inválido. El archivo pudo alterarse.',
        sessionId: (decoded['sessionId'] as String? ?? '').trim(),
        sourceTerminal: (source['terminalName'] as String? ?? '').trim(),
        saleCount: (summary['saleCount'] as num?)?.toInt() ?? 0,
        movementCount: (summary['movementCount'] as num?)?.toInt() ?? 0,
        totalCents: (summary['totalCents'] as num?)?.toInt() ?? 0,
        exportedAt: exportedAt,
      );
    } catch (e) {
      return ManualSyncPackagePreview(
        filePath: safePath,
        isValid: false,
        message: 'No se pudo leer el paquete: $e',
        sessionId: '',
        sourceTerminal: '',
        saleCount: 0,
        movementCount: 0,
        totalCents: 0,
        exportedAt: null,
      );
    }
  }

  Future<List<ManualSyncSessionOption>> listClosedSessionsForExport({
    int limit = 40,
  }) async {
    final int safeLimit = limit <= 0 ? 40 : limit;
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        s.id AS session_id,
        t.name AS terminal_name,
        t.code AS terminal_code,
        s.closed_at AS closed_at,
        COUNT(sa.id) AS sale_count,
        COALESCE(SUM(sa.total_cents), 0) AS total_cents
      FROM pos_sessions s
      INNER JOIN pos_terminals t
        ON t.id = s.terminal_id
      LEFT JOIN sales sa
        ON sa.terminal_session_id = s.id
       AND sa.status = 'posted'
      WHERE s.status = 'closed'
        AND s.closed_at IS NOT NULL
      GROUP BY s.id, t.name, t.code, s.closed_at
      ORDER BY s.closed_at DESC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[Variable<int>(safeLimit)],
    ).get();

    return rows.map((QueryRow row) {
      return ManualSyncSessionOption(
        sessionId: (row.readNullable<String>('session_id') ?? '').trim(),
        terminalName:
            (row.readNullable<String>('terminal_name') ?? 'TPV').trim(),
        terminalCode: (row.readNullable<String>('terminal_code') ?? '-').trim(),
        closedAt:
            row.readNullable<DateTime>('closed_at') ?? DateTime(1970, 1, 1),
        saleCount: (row.readNullable<int>('sale_count') ?? 0),
        totalCents: (row.readNullable<int>('total_cents') ?? 0),
      );
    }).toList(growable: false);
  }

  Future<List<ManualSyncPackageFileOption>> listPackageFiles({
    int limit = 80,
  }) async {
    final int safeLimit = limit <= 0 ? 80 : limit;
    final Set<String> visited = <String>{};
    final List<ManualSyncPackageFileOption> files =
        <ManualSyncPackageFileOption>[];

    final List<Directory> candidates = await _candidateSyncDirs();
    for (final Directory dir in candidates) {
      final String path = dir.path;
      if (visited.contains(path)) {
        continue;
      }
      visited.add(path);
      if (!dir.existsSync()) {
        continue;
      }
      try {
        await for (final FileSystemEntity entity in dir.list()) {
          if (entity is! File) {
            continue;
          }
          final String filePath = entity.path;
          if (!filePath.toLowerCase().endsWith('.json')) {
            continue;
          }
          final FileStat stat = await entity.stat();
          files.add(
            ManualSyncPackageFileOption(
              filePath: filePath,
              fileName: p.basename(filePath),
              modifiedAt: stat.modified,
              sizeBytes: stat.size,
            ),
          );
        }
      } catch (_) {}
    }

    files.sort(
      (ManualSyncPackageFileOption a, ManualSyncPackageFileOption b) =>
          b.modifiedAt.compareTo(a.modifiedAt),
    );
    if (files.length <= safeLimit) {
      return files;
    }
    return files.take(safeLimit).toList(growable: false);
  }

  Future<ManualSyncImportResult> importPackageFromFile(String filePath) async {
    await _licenseService.requireWriteAccess();
    final ManualSyncPackagePreview preview =
        await previewPackageFromFile(filePath);
    if (!preview.isValid) {
      throw Exception(preview.message);
    }

    final File file = File(preview.filePath);
    final Map<String, dynamic> decoded =
        (jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>();
    final Map<String, dynamic> data =
        ((decoded['data'] as Map?) ?? <String, dynamic>{})
            .cast<String, dynamic>();
    final List<Map<String, dynamic>> usersRaw = _asMapList(data['users']);
    final List<Map<String, dynamic>> warehousesRaw =
        _asMapList(data['warehouses']);
    final List<Map<String, dynamic>> terminalsRaw =
        _asMapList(data['terminals']);
    final List<Map<String, dynamic>> productsRaw = _asMapList(data['products']);
    final List<Map<String, dynamic>> customersRaw =
        _asMapList(data['customers']);
    final List<Map<String, dynamic>> sessionsRaw =
        _asMapList(data['posSessions']);
    final List<Map<String, dynamic>> sessionCashRaw =
        _asMapList(data['posSessionCashBreakdowns']);
    final List<Map<String, dynamic>> salesRaw = _asMapList(data['sales']);
    final List<Map<String, dynamic>> saleItemsRaw =
        _asMapList(data['saleItems']);
    final List<Map<String, dynamic>> paymentsRaw = _asMapList(data['payments']);
    final List<Map<String, dynamic>> movementsRaw =
        _asMapList(data['stockMovements']);

    final String packageSessionId =
        (decoded['sessionId'] as String? ?? '').trim();
    final int packageTotalCents = (((decoded['summary'] as Map?) ??
                const <String, Object?>{})['totalCents'] as num?)
            ?.toInt() ??
        0;

    int importedSales = 0;
    int importedPayments = 0;
    int importedMovements = 0;
    final List<String> warnings = <String>[];

    final Map<String, String> userIdMap = <String, String>{};
    final Map<String, String> warehouseIdMap = <String, String>{};
    final Map<String, String> terminalIdMap = <String, String>{};
    final Map<String, String> productIdMap = <String, String>{};
    final Map<String, String> customerIdMap = <String, String>{};
    final Map<String, String> sessionIdMap = <String, String>{};
    final Map<String, String> saleIdMap = <String, String>{};
    final Map<String, String> saleWarehouseById = <String, String>{};
    final Set<String> newlyImportedSaleIds = <String>{};

    await _db.transaction(() async {
      for (final Map<String, dynamic> row in warehousesRaw) {
        final String remoteId = _readString(row['id']);
        if (remoteId.isEmpty) {
          continue;
        }
        final String name = _readString(row['name'], fallback: 'Almacén');
        final String warehouseType =
            _readString(row['warehouseType'], fallback: 'Central');
        await _db.into(_db.warehouses).insertOnConflictUpdate(
              WarehousesCompanion.insert(
                id: remoteId,
                name: name,
                warehouseType: Value(warehouseType),
                isActive: Value(_readBool(row['isActive'], fallback: true)),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
              ),
            );
        warehouseIdMap[remoteId] = remoteId;
      }

      for (final Map<String, dynamic> row in usersRaw) {
        final String remoteId = _readString(row['id']);
        final String username = _readString(row['username']);
        if (remoteId.isEmpty || username.isEmpty) {
          continue;
        }

        final User? byId = await (_db.select(_db.users)
              ..where((Users tbl) => tbl.id.equals(remoteId)))
            .getSingleOrNull();
        if (byId != null) {
          userIdMap[remoteId] = byId.id;
          continue;
        }

        final User? byUsername = await (_db.select(_db.users)
              ..where((Users tbl) => tbl.username.equals(username)))
            .getSingleOrNull();
        if (byUsername != null) {
          userIdMap[remoteId] = byUsername.id;
          warnings.add(
            'Usuario "$username" ya existía con otro ID; se reutilizó.',
          );
          continue;
        }

        await _db.into(_db.users).insert(
              UsersCompanion.insert(
                id: remoteId,
                username: username,
                passwordHash: _readString(row['passwordHash']),
                salt: _readString(row['salt']),
                role: Value(_readString(row['role'], fallback: 'cajero')),
                isActive: Value(_readBool(row['isActive'], fallback: true)),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
                updatedAt: Value(_readDateTimeOrNull(row['updatedAt'])),
              ),
            );
        userIdMap[remoteId] = remoteId;
      }

      for (final Map<String, dynamic> row in productsRaw) {
        final String remoteId = _readString(row['id']);
        final String sku = _readString(row['sku']);
        if (remoteId.isEmpty || sku.isEmpty) {
          continue;
        }

        final Product? byId = await (_db.select(_db.products)
              ..where((Products tbl) => tbl.id.equals(remoteId)))
            .getSingleOrNull();
        if (byId != null) {
          productIdMap[remoteId] = byId.id;
          continue;
        }

        final Product? bySku = await (_db.select(_db.products)
              ..where((Products tbl) => tbl.sku.equals(sku)))
            .getSingleOrNull();
        if (bySku != null) {
          productIdMap[remoteId] = bySku.id;
          warnings.add(
            'Producto SKU "$sku" ya existía con otro ID; se reutilizó.',
          );
          continue;
        }

        await _db.into(_db.products).insert(
              ProductsCompanion.insert(
                id: remoteId,
                sku: sku,
                barcode: Value(_readStringOrNull(row['barcode'])),
                name: _readString(row['name'], fallback: sku),
                priceCents: Value(_readInt(row['priceCents'])),
                taxRateBps: Value(_readInt(row['taxRateBps'])),
                imagePath: Value(_readStringOrNull(row['imagePath'])),
                costPriceCents: Value(_readInt(row['costPriceCents'])),
                category:
                    Value(_readString(row['category'], fallback: 'General')),
                productType:
                    Value(_readString(row['productType'], fallback: 'Fisico')),
                unitMeasure:
                    Value(_readString(row['unitMeasure'], fallback: 'Unidad')),
                currencyCode:
                    Value(_readString(row['currencyCode'], fallback: 'USD')),
                isActive: Value(_readBool(row['isActive'], fallback: true)),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
                updatedAt: Value(_readDateTimeOrNull(row['updatedAt'])),
              ),
            );
        productIdMap[remoteId] = remoteId;
      }

      for (final Map<String, dynamic> row in customersRaw) {
        final String remoteId = _readString(row['id']);
        final String code = _readString(row['code']);
        if (remoteId.isEmpty || code.isEmpty) {
          continue;
        }

        final Customer? byId = await (_db.select(_db.customers)
              ..where((Customers tbl) => tbl.id.equals(remoteId)))
            .getSingleOrNull();
        if (byId != null) {
          customerIdMap[remoteId] = byId.id;
          continue;
        }

        final Customer? byCode = await (_db.select(_db.customers)
              ..where((Customers tbl) => tbl.code.equals(code)))
            .getSingleOrNull();
        if (byCode != null) {
          customerIdMap[remoteId] = byCode.id;
          warnings.add(
            'Cliente código "$code" ya existía con otro ID; se reutilizó.',
          );
          continue;
        }

        await _db.into(_db.customers).insert(
              CustomersCompanion.insert(
                id: remoteId,
                code: code,
                fullName: _readString(row['fullName'], fallback: code),
                identityNumber: Value(_readStringOrNull(row['identityNumber'])),
                phone: Value(_readStringOrNull(row['phone'])),
                email: Value(_readStringOrNull(row['email'])),
                address: Value(_readStringOrNull(row['address'])),
                company: Value(_readStringOrNull(row['company'])),
                avatarPath: Value(_readStringOrNull(row['avatarPath'])),
                customerType: Value(
                    _readString(row['customerType'], fallback: 'general')),
                isVip: Value(_readBool(row['isVip'])),
                creditAvailableCents:
                    Value(_readInt(row['creditAvailableCents'])),
                discountBps: Value(_readInt(row['discountBps'])),
                adminNote: Value(_readStringOrNull(row['adminNote'])),
                isActive: Value(_readBool(row['isActive'], fallback: true)),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
                updatedAt: Value(_readDateTimeOrNull(row['updatedAt'])),
              ),
            );
        customerIdMap[remoteId] = remoteId;
      }

      for (final Map<String, dynamic> row in terminalsRaw) {
        final String remoteId = _readString(row['id']);
        final String code = _readString(row['code']);
        final String remoteWarehouseId = _readString(row['warehouseId']);
        final String resolvedWarehouseId =
            warehouseIdMap[remoteWarehouseId] ?? remoteWarehouseId;
        if (remoteId.isEmpty || code.isEmpty || resolvedWarehouseId.isEmpty) {
          continue;
        }

        final PosTerminal? byId = await (_db.select(_db.posTerminals)
              ..where((PosTerminals tbl) => tbl.id.equals(remoteId)))
            .getSingleOrNull();
        if (byId != null) {
          terminalIdMap[remoteId] = byId.id;
          continue;
        }

        final PosTerminal? byCode = await (_db.select(_db.posTerminals)
              ..where((PosTerminals tbl) => tbl.code.equals(code)))
            .getSingleOrNull();
        if (byCode != null) {
          terminalIdMap[remoteId] = byCode.id;
          warnings.add(
            'TPV código "$code" ya existía con otro ID; se reutilizó.',
          );
          continue;
        }

        final PosTerminal? byWarehouse = await (_db.select(_db.posTerminals)
              ..where(
                (PosTerminals tbl) =>
                    tbl.warehouseId.equals(resolvedWarehouseId),
              ))
            .getSingleOrNull();
        if (byWarehouse != null) {
          terminalIdMap[remoteId] = byWarehouse.id;
          warnings.add(
            'El almacén del TPV ya estaba ligado a otro terminal; se reutilizó.',
          );
          continue;
        }

        await _db.into(_db.posTerminals).insert(
              PosTerminalsCompanion.insert(
                id: remoteId,
                code: code,
                name: _readString(row['name'], fallback: code),
                warehouseId: resolvedWarehouseId,
                currencyCode:
                    Value(_readString(row['currencyCode'], fallback: 'USD')),
                currencySymbol:
                    Value(_readString(row['currencySymbol'], fallback: r'$')),
                paymentMethodsJson: Value(
                    _readString(row['paymentMethodsJson'], fallback: '[]')),
                cashDenominationsJson: Value(
                  _readString(row['cashDenominationsJson'], fallback: '[]'),
                ),
                imagePath: Value(_readStringOrNull(row['imagePath'])),
                isActive: Value(_readBool(row['isActive'], fallback: true)),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
                updatedAt: Value(_readDateTimeOrNull(row['updatedAt'])),
              ),
            );
        terminalIdMap[remoteId] = remoteId;
      }

      for (final Map<String, dynamic> row in sessionsRaw) {
        final String remoteId = _readString(row['id']);
        if (remoteId.isEmpty) {
          continue;
        }
        final String resolvedTerminalId =
            terminalIdMap[_readString(row['terminalId'])] ??
                _readString(row['terminalId']);
        final String resolvedUserId =
            userIdMap[_readString(row['userId'])] ?? _readString(row['userId']);
        if (resolvedTerminalId.isEmpty || resolvedUserId.isEmpty) {
          continue;
        }

        await _db.into(_db.posSessions).insertOnConflictUpdate(
              PosSessionsCompanion.insert(
                id: remoteId,
                terminalId: resolvedTerminalId,
                userId: resolvedUserId,
                openedAt: Value(
                  _readDateTime(row['openedAt'], fallback: DateTime.now()),
                ),
                openingFloatCents: Value(_readInt(row['openingFloatCents'])),
                closedAt: Value(_readDateTimeOrNull(row['closedAt'])),
                closingCashCents:
                    Value(_readIntOrNull(row['closingCashCents'])),
                status: Value(_readString(row['status'], fallback: 'open')),
                note: Value(_readStringOrNull(row['note'])),
              ),
            );
        sessionIdMap[remoteId] = remoteId;
      }

      for (final Map<String, dynamic> row in sessionCashRaw) {
        final String remoteSessionId = _readString(row['sessionId']);
        final String resolvedSessionId =
            sessionIdMap[remoteSessionId] ?? remoteSessionId;
        if (resolvedSessionId.isEmpty) {
          continue;
        }
        await _db.into(_db.posSessionCashBreakdowns).insertOnConflictUpdate(
              PosSessionCashBreakdownsCompanion.insert(
                sessionId: resolvedSessionId,
                denominationCents: _readInt(row['denominationCents']),
                unitCount: Value(_readInt(row['unitCount'])),
                subtotalCents: Value(_readInt(row['subtotalCents'])),
              ),
            );
      }

      for (final Map<String, dynamic> row in salesRaw) {
        final String remoteId = _readString(row['id']);
        final String folio = _readString(row['folio']);
        if (remoteId.isEmpty || folio.isEmpty) {
          continue;
        }

        final Sale? byId = await (_db.select(_db.sales)
              ..where((Sales tbl) => tbl.id.equals(remoteId)))
            .getSingleOrNull();
        if (byId != null) {
          saleIdMap[remoteId] = byId.id;
          saleWarehouseById[byId.id] = byId.warehouseId;
          continue;
        }

        final String folioToInsert =
            await _nextAvailableImportedFolio(baseFolio: folio);
        if (folioToInsert != folio) {
          warnings.add(
            'Venta folio "$folio" ya existía; se importó como "$folioToInsert".',
          );
        }

        final String resolvedWarehouseId =
            warehouseIdMap[_readString(row['warehouseId'])] ??
                _readString(row['warehouseId']);
        final String resolvedCashierId =
            userIdMap[_readString(row['cashierId'])] ??
                _readString(row['cashierId']);
        final String? resolvedCustomerId = _resolveNullableMappedId(
          rawId: _readStringOrNull(row['customerId']),
          idMap: customerIdMap,
        );
        final String? resolvedTerminalId = _resolveNullableMappedId(
          rawId: _readStringOrNull(row['terminalId']),
          idMap: terminalIdMap,
        );
        final String? resolvedSessionId = _resolveNullableMappedId(
          rawId: _readStringOrNull(row['terminalSessionId']),
          idMap: sessionIdMap,
        );
        if (resolvedWarehouseId.isEmpty || resolvedCashierId.isEmpty) {
          continue;
        }

        await _db.into(_db.sales).insert(
              SalesCompanion.insert(
                id: remoteId,
                folio: folioToInsert,
                warehouseId: resolvedWarehouseId,
                cashierId: resolvedCashierId,
                customerId: Value(resolvedCustomerId),
                terminalId: Value(resolvedTerminalId),
                terminalSessionId: Value(resolvedSessionId),
                subtotalCents: _readInt(row['subtotalCents']),
                taxCents: _readInt(row['taxCents']),
                totalCents: _readInt(row['totalCents']),
                status: Value(_readString(row['status'], fallback: 'posted')),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
              ),
            );
        saleIdMap[remoteId] = remoteId;
        saleWarehouseById[remoteId] = resolvedWarehouseId;
        newlyImportedSaleIds.add(remoteId);
        importedSales += 1;
      }

      for (final Map<String, dynamic> row in saleItemsRaw) {
        final String remoteId = _readString(row['id']);
        if (remoteId.isEmpty) {
          continue;
        }
        final String resolvedSaleId =
            saleIdMap[_readString(row['saleId'])] ?? _readString(row['saleId']);
        final String resolvedProductId =
            productIdMap[_readString(row['productId'])] ??
                _readString(row['productId']);
        if (resolvedSaleId.isEmpty || resolvedProductId.isEmpty) {
          continue;
        }
        final double qty = _readDouble(row['qty']);
        if (qty <= 0) {
          continue;
        }

        final int incomingUnitCostCents =
            _readIntOrNull(row['unitCostCents']) ?? 0;
        final int incomingLineCostCents =
            _readIntOrNull(row['lineCostCents']) ??
                (qty * incomingUnitCostCents).round();
        final int fallbackUnitCostCents = incomingUnitCostCents > 0
            ? incomingUnitCostCents
            : (qty > 0 ? (incomingLineCostCents / qty).round() : 0);

        final String saleWarehouseId = saleWarehouseById[resolvedSaleId] ?? '';
        final bool shouldAllocateFifo = newlyImportedSaleIds.contains(
              resolvedSaleId,
            ) &&
            saleWarehouseId.isNotEmpty;

        final int inserted = await _db.into(_db.saleItems).insert(
              SaleItemsCompanion.insert(
                id: remoteId,
                saleId: resolvedSaleId,
                productId: resolvedProductId,
                qty: qty,
                unitPriceCents: _readInt(row['unitPriceCents']),
                unitCostCents: Value(fallbackUnitCostCents),
                taxRateBps: _readInt(row['taxRateBps']),
                lineSubtotalCents: _readInt(row['lineSubtotalCents']),
                lineTaxCents: _readInt(row['lineTaxCents']),
                lineCostCents: Value(incomingLineCostCents),
                lineTotalCents: _readInt(row['lineTotalCents']),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        if (inserted <= 0 || !shouldAllocateFifo) {
          continue;
        }

        final List<_ManualSyncFifoAllocation> allocations =
            await _reserveFifoAllocations(
          productId: resolvedProductId,
          warehouseId: saleWarehouseId,
          qty: qty,
          fallbackUnitCostCents: fallbackUnitCostCents,
        );
        if (allocations.isNotEmpty) {
          final int storedLineCostCents = allocations.fold<int>(
            0,
            (int sum, _ManualSyncFifoAllocation item) =>
                sum + item.lineCostCents,
          );
          final int storedUnitCostCents =
              qty > 0 ? (storedLineCostCents / qty).round() : 0;
          await (_db.update(_db.saleItems)
                ..where((SaleItems tbl) => tbl.id.equals(remoteId)))
              .write(
            SaleItemsCompanion(
              unitCostCents: Value(storedUnitCostCents),
              lineCostCents: Value(storedLineCostCents),
            ),
          );
          await _insertSaleItemAllocations(
            saleId: resolvedSaleId,
            saleItemId: remoteId,
            productId: resolvedProductId,
            warehouseId: saleWarehouseId,
            allocations: allocations,
          );
        }
      }

      for (final Map<String, dynamic> row in paymentsRaw) {
        final String remoteId = _readString(row['id']);
        if (remoteId.isEmpty) {
          continue;
        }
        final String resolvedSaleId =
            saleIdMap[_readString(row['saleId'])] ?? _readString(row['saleId']);
        if (resolvedSaleId.isEmpty) {
          continue;
        }
        final int inserted = await _db.into(_db.payments).insert(
              PaymentsCompanion.insert(
                id: remoteId,
                saleId: resolvedSaleId,
                method: _readString(row['method'], fallback: 'cash'),
                amountCents: _readInt(row['amountCents']),
                transactionId: Value(_readStringOrNull(row['transactionId'])),
                sourceCurrencyCode:
                    Value(_readStringOrNull(row['sourceCurrencyCode'])),
                sourceAmountCents:
                    Value(_readIntOrNull(row['sourceAmountCents'])),
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        if (inserted > 0) {
          importedPayments += 1;
        }
      }

      for (final Map<String, dynamic> row in movementsRaw) {
        final String movementId = _readString(row['id']);
        if (movementId.isEmpty) {
          continue;
        }
        final StockMovement? existing = await (_db.select(_db.stockMovements)
              ..where((StockMovements tbl) => tbl.id.equals(movementId)))
            .getSingleOrNull();
        if (existing != null) {
          continue;
        }

        final String resolvedProductId =
            productIdMap[_readString(row['productId'])] ??
                _readString(row['productId']);
        final String resolvedWarehouseId =
            warehouseIdMap[_readString(row['warehouseId'])] ??
                _readString(row['warehouseId']);
        final String resolvedUserId =
            userIdMap[_readString(row['createdBy'])] ??
                _readString(row['createdBy']);
        if (resolvedProductId.isEmpty ||
            resolvedWarehouseId.isEmpty ||
            resolvedUserId.isEmpty) {
          continue;
        }

        final String? resolvedRefId = _resolveMovementRefId(
          refType: _readStringOrNull(row['refType']),
          refId: _readStringOrNull(row['refId']),
          saleIdMap: saleIdMap,
        );
        final String type = _readString(row['type'], fallback: 'out');
        final double qty = _readDouble(row['qty']);
        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: movementId,
                productId: resolvedProductId,
                warehouseId: resolvedWarehouseId,
                type: type,
                qty: qty,
                reasonCode: Value(_readStringOrNull(row['reasonCode'])),
                movementSource: Value(
                    _readString(row['movementSource'], fallback: 'manual')),
                refType: Value(_readStringOrNull(row['refType'])),
                refId: Value(resolvedRefId),
                note: Value(_readStringOrNull(row['note'])),
                createdBy: resolvedUserId,
                createdAt: Value(
                  _readDateTime(row['createdAt'], fallback: DateTime.now()),
                ),
              ),
            );
        importedMovements += 1;

        final double delta = _movementDelta(type: type, qty: qty);
        if (delta.abs() > 0.0000001) {
          await _applyStockDelta(
            productId: resolvedProductId,
            warehouseId: resolvedWarehouseId,
            delta: delta,
          );
        }
      }
    });

    return ManualSyncImportResult(
      filePath: preview.filePath,
      sessionId: packageSessionId,
      saleCount: importedSales,
      paymentCount: importedPayments,
      movementCount: importedMovements,
      totalCents: packageTotalCents,
      warnings: warnings,
    );
  }

  Future<List<Directory>> _candidateSyncDirs() async {
    final List<Directory> dirs = <Directory>[];
    if (Platform.isAndroid) {
      const List<String> roots = <String>[
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Descargas',
      ];
      for (final String rootPath in roots) {
        dirs.add(Directory(p.join(rootPath, 'Sync', 'POSIPV')));
      }
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    dirs.add(Directory(p.join(docs.path, 'exports', 'sync')));
    return dirs;
  }

  Future<void> _applyStockDelta({
    required String productId,
    required String warehouseId,
    required double delta,
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
              qty: Value(delta),
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
        qty: Value(current.qty + delta),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<_ManualSyncFifoAllocation>> _reserveFifoAllocations({
    required String productId,
    required String warehouseId,
    required double qty,
    required int fallbackUnitCostCents,
  }) async {
    if (qty <= 0) {
      return const <_ManualSyncFifoAllocation>[];
    }

    const double epsilon = 0.000001;
    double remaining = qty;
    final List<_ManualSyncFifoAllocation> out = <_ManualSyncFifoAllocation>[];

    final List<QueryRow> lotRows = await _db.customSelect(
      '''
      SELECT
        l.id AS lot_id,
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
      final int lineCostCents = (take * unitCostCents).round();

      await (_db.update(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .write(
        StockLotsCompanion(
          qtyRemaining: Value(lotRemaining - take),
        ),
      );
      out.add(
        _ManualSyncFifoAllocation(
          lotId: lotId,
          qty: take,
          unitCostCents: unitCostCents,
          lineCostCents: lineCostCents,
        ),
      );
      remaining -= take;
    }

    if (remaining > epsilon) {
      out.add(
        _ManualSyncFifoAllocation(
          lotId: null,
          qty: remaining,
          unitCostCents: fallbackUnitCostCents,
          lineCostCents: (remaining * fallbackUnitCostCents).round(),
        ),
      );
    }
    return out;
  }

  Future<void> _insertSaleItemAllocations({
    required String saleId,
    required String saleItemId,
    required String productId,
    required String warehouseId,
    required List<_ManualSyncFifoAllocation> allocations,
  }) async {
    for (final _ManualSyncFifoAllocation allocation in allocations) {
      await _db.into(_db.saleItemLotAllocations).insert(
            SaleItemLotAllocationsCompanion.insert(
              id: const Uuid().v4(),
              saleId: saleId,
              saleItemId: saleItemId,
              productId: productId,
              warehouseId: warehouseId,
              lotId: Value(allocation.lotId),
              qty: Value(allocation.qty),
              unitCostCents: Value(allocation.unitCostCents),
              lineCostCents: Value(allocation.lineCostCents),
            ),
          );
    }
  }

  double _movementDelta({
    required String type,
    required double qty,
  }) {
    final String normalized = type.trim().toLowerCase();
    if (normalized == 'in') {
      return qty.abs();
    }
    if (normalized == 'out') {
      return -qty.abs();
    }
    return qty;
  }

  String? _resolveMovementRefId({
    required String? refType,
    required String? refId,
    required Map<String, String> saleIdMap,
  }) {
    final String cleanRefId = (refId ?? '').trim();
    if (cleanRefId.isEmpty) {
      return null;
    }
    final String cleanRefType = (refType ?? '').trim().toLowerCase();
    if (_isSaleRefType(cleanRefType)) {
      return saleIdMap[cleanRefId] ?? cleanRefId;
    }
    return cleanRefId;
  }

  bool _isSaleRefType(String refType) {
    final String cleanRefType = refType.trim().toLowerCase();
    return cleanRefType == 'sale' ||
        cleanRefType == 'sale_pos' ||
        cleanRefType == 'sale_direct' ||
        cleanRefType == 'consignment_sale' ||
        cleanRefType == 'consignment_sale_pos' ||
        cleanRefType == 'consignment_sale_direct';
  }

  Future<String> _nextAvailableImportedFolio({
    required String baseFolio,
  }) async {
    String candidate = baseFolio.trim();
    if (candidate.isEmpty) {
      return candidate;
    }

    int attempt = 1;
    while (true) {
      final Sale? existing = await (_db.select(_db.sales)
            ..where((Sales tbl) => tbl.folio.equals(candidate)))
          .getSingleOrNull();
      if (existing == null) {
        return candidate;
      }
      candidate = '$baseFolio-R$attempt';
      attempt += 1;
    }
  }

  String? _resolveNullableMappedId({
    required String? rawId,
    required Map<String, String> idMap,
  }) {
    final String cleanId = (rawId ?? '').trim();
    if (cleanId.isEmpty) {
      return null;
    }
    return idMap[cleanId] ?? cleanId;
  }

  List<Map<String, dynamic>> _asMapList(Object? raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final Object? item in raw) {
      if (item is! Map) {
        continue;
      }
      out.add(item.cast<String, dynamic>());
    }
    return out;
  }

  String _readString(Object? raw, {String fallback = ''}) {
    final String value = (raw == null ? '' : raw.toString()).trim();
    if (value.isEmpty) {
      return fallback;
    }
    return value;
  }

  String? _readStringOrNull(Object? raw) {
    final String value = (raw == null ? '' : raw.toString()).trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  int _readInt(Object? raw, {int fallback = 0}) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? fallback;
    }
    return fallback;
  }

  int? _readIntOrNull(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  double _readDouble(Object? raw, {double fallback = 0}) {
    if (raw is double) {
      return raw;
    }
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw.trim()) ?? fallback;
    }
    return fallback;
  }

  bool _readBool(Object? raw, {bool fallback = false}) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    if (raw is String) {
      final String value = raw.trim().toLowerCase();
      if (value == '1' || value == 'true' || value == 'yes' || value == 'si') {
        return true;
      }
      if (value == '0' ||
          value == 'false' ||
          value == 'no' ||
          value == 'null') {
        return false;
      }
    }
    return fallback;
  }

  DateTime _readDateTime(Object? raw, {required DateTime fallback}) {
    final DateTime? parsed = _readDateTimeOrNull(raw);
    return parsed ?? fallback;
  }

  DateTime? _readDateTimeOrNull(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      final String value = raw.trim();
      if (value.isEmpty) {
        return null;
      }
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<Directory> _resolveSyncDir() async {
    if (Platform.isAndroid) {
      const List<String> candidates = <String>[
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Descargas',
      ];
      for (final String path in candidates) {
        final Directory base = Directory(path);
        try {
          if (!base.existsSync()) {
            await base.create(recursive: true);
          }
          if (base.existsSync()) {
            final Directory dir =
                Directory(p.join(base.path, 'Sync', 'POSIPV'));
            if (!dir.existsSync()) {
              await dir.create(recursive: true);
            }
            return dir;
          }
        } catch (_) {}
      }
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(docs.path, 'exports', 'sync'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _checksumFor(Object data) {
    final String raw = jsonEncode(data);
    return sha256.convert(utf8.encode(raw)).toString();
  }

  String _stamp(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    final String ss = dt.second.toString().padLeft(2, '0');
    return '$y$m$d$hh$mm$ss';
  }

  String _sanitizeSegment(String raw) {
    final String cleaned = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isEmpty ? 'tpv' : cleaned;
  }

  Map<String, Object?> _mapUser(User row) {
    return <String, Object?>{
      'id': row.id,
      'username': row.username,
      'passwordHash': row.passwordHash,
      'salt': row.salt,
      'role': row.role,
      'isActive': row.isActive,
      'createdAt': row.createdAt.toIso8601String(),
      'updatedAt': row.updatedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> _mapWarehouse(Warehouse row) {
    return <String, Object?>{
      'id': row.id,
      'name': row.name,
      'warehouseType': row.warehouseType,
      'isActive': row.isActive,
      'createdAt': row.createdAt.toIso8601String(),
    };
  }

  Map<String, Object?> _mapTerminal(PosTerminal row) {
    return <String, Object?>{
      'id': row.id,
      'code': row.code,
      'name': row.name,
      'warehouseId': row.warehouseId,
      'currencyCode': row.currencyCode,
      'currencySymbol': row.currencySymbol,
      'paymentMethodsJson': row.paymentMethodsJson,
      'cashDenominationsJson': row.cashDenominationsJson,
      'imagePath': row.imagePath,
      'isActive': row.isActive,
      'createdAt': row.createdAt.toIso8601String(),
      'updatedAt': row.updatedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> _mapProduct(Product row) {
    return <String, Object?>{
      'id': row.id,
      'sku': row.sku,
      'barcode': row.barcode,
      'name': row.name,
      'priceCents': row.priceCents,
      'taxRateBps': row.taxRateBps,
      'imagePath': row.imagePath,
      'costPriceCents': row.costPriceCents,
      'category': row.category,
      'productType': row.productType,
      'unitMeasure': row.unitMeasure,
      'currencyCode': row.currencyCode,
      'isActive': row.isActive,
      'createdAt': row.createdAt.toIso8601String(),
      'updatedAt': row.updatedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> _mapCustomer(Customer row) {
    return <String, Object?>{
      'id': row.id,
      'code': row.code,
      'fullName': row.fullName,
      'identityNumber': row.identityNumber,
      'phone': row.phone,
      'email': row.email,
      'address': row.address,
      'company': row.company,
      'avatarPath': row.avatarPath,
      'customerType': row.customerType,
      'isVip': row.isVip,
      'creditAvailableCents': row.creditAvailableCents,
      'discountBps': row.discountBps,
      'adminNote': row.adminNote,
      'isActive': row.isActive,
      'createdAt': row.createdAt.toIso8601String(),
      'updatedAt': row.updatedAt?.toIso8601String(),
    };
  }

  Map<String, Object?> _mapPosSession(PosSession row) {
    return <String, Object?>{
      'id': row.id,
      'terminalId': row.terminalId,
      'userId': row.userId,
      'openedAt': row.openedAt.toIso8601String(),
      'openingFloatCents': row.openingFloatCents,
      'closedAt': row.closedAt?.toIso8601String(),
      'closingCashCents': row.closingCashCents,
      'status': row.status,
      'note': row.note,
    };
  }

  Map<String, Object?> _mapSessionCash(PosSessionCashBreakdown row) {
    return <String, Object?>{
      'sessionId': row.sessionId,
      'denominationCents': row.denominationCents,
      'unitCount': row.unitCount,
      'subtotalCents': row.subtotalCents,
    };
  }

  Map<String, Object?> _mapSale(Sale row) {
    return <String, Object?>{
      'id': row.id,
      'folio': row.folio,
      'warehouseId': row.warehouseId,
      'cashierId': row.cashierId,
      'customerId': row.customerId,
      'terminalId': row.terminalId,
      'terminalSessionId': row.terminalSessionId,
      'subtotalCents': row.subtotalCents,
      'taxCents': row.taxCents,
      'totalCents': row.totalCents,
      'status': row.status,
      'createdAt': row.createdAt.toIso8601String(),
    };
  }

  Map<String, Object?> _mapSaleItem(SaleItem row) {
    return <String, Object?>{
      'id': row.id,
      'saleId': row.saleId,
      'productId': row.productId,
      'qty': row.qty,
      'unitPriceCents': row.unitPriceCents,
      'unitCostCents': row.unitCostCents,
      'taxRateBps': row.taxRateBps,
      'lineSubtotalCents': row.lineSubtotalCents,
      'lineTaxCents': row.lineTaxCents,
      'lineCostCents': row.lineCostCents,
      'lineTotalCents': row.lineTotalCents,
    };
  }

  Map<String, Object?> _mapPayment(Payment row) {
    return <String, Object?>{
      'id': row.id,
      'saleId': row.saleId,
      'method': row.method,
      'amountCents': row.amountCents,
      'transactionId': row.transactionId,
      'sourceCurrencyCode': row.sourceCurrencyCode,
      'sourceAmountCents': row.sourceAmountCents,
      'createdAt': row.createdAt.toIso8601String(),
    };
  }

  Map<String, Object?> _mapMovement(StockMovement row) {
    return <String, Object?>{
      'id': row.id,
      'productId': row.productId,
      'warehouseId': row.warehouseId,
      'type': row.type,
      'qty': row.qty,
      'reasonCode': row.reasonCode,
      'movementSource': row.movementSource,
      'refType': row.refType,
      'refId': row.refId,
      'note': row.note,
      'createdBy': row.createdBy,
      'createdAt': row.createdAt.toIso8601String(),
    };
  }
}

class _ManualSyncFifoAllocation {
  const _ManualSyncFifoAllocation({
    required this.lotId,
    required this.qty,
    required this.unitCostCents,
    required this.lineCostCents,
  });

  final String? lotId;
  final double qty;
  final int unitCostCents;
  final int lineCostCents;
}
