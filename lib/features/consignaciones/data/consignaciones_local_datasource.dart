import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';
import '../../../core/security/app_permissions.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';

class ConsignmentDebtOverview {
  const ConsignmentDebtOverview({
    required this.primaryCurrencyCode,
    required this.primaryCurrencySymbol,
    required this.totalPendingPrimaryCents,
    required this.customers,
  });

  final String primaryCurrencyCode;
  final String primaryCurrencySymbol;
  final int totalPendingPrimaryCents;
  final List<ConsignmentCustomerDebt> customers;

  int get customersCount => customers.length;

  int get pendingSalesCount => customers.fold<int>(
        0,
        (int sum, ConsignmentCustomerDebt row) => sum + row.sales.length,
      );
}

class ConsignmentCustomerDebt {
  const ConsignmentCustomerDebt({
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.totalConsignedPrimaryCents,
    required this.totalPaidPrimaryCents,
    required this.pendingPrimaryCents,
    required this.paymentSummary,
    required this.sales,
  });

  final String customerId;
  final String customerName;
  final String? customerPhone;
  final int totalConsignedPrimaryCents;
  final int totalPaidPrimaryCents;
  final int pendingPrimaryCents;
  final List<ConsignmentCustomerPaymentRecord> paymentSummary;
  final List<ConsignmentSaleDebt> sales;

  DateTime? get lastSaleAt {
    if (sales.isEmpty) {
      return null;
    }
    DateTime newest = sales.first.createdAt;
    for (final ConsignmentSaleDebt row in sales.skip(1)) {
      if (row.createdAt.isAfter(newest)) {
        newest = row.createdAt;
      }
    }
    return newest;
  }
}

class ConsignmentCustomerPaymentRecord {
  const ConsignmentCustomerPaymentRecord({
    required this.method,
    required this.amountCents,
    required this.currencySymbol,
    required this.createdAt,
    this.transactionId,
  });

  final String method;
  final int amountCents;
  final String currencySymbol;
  final DateTime createdAt;
  final String? transactionId;
}

class ConsignmentSaleDebt {
  const ConsignmentSaleDebt({
    required this.saleId,
    required this.folio,
    required this.createdAt,
    required this.warehouseName,
    required this.cashierUsername,
    required this.channel,
    this.terminalName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.totalCents,
    required this.paidCents,
    required this.pendingCents,
    required this.pendingPrimaryCents,
  });

  final String saleId;
  final String folio;
  final DateTime createdAt;
  final String warehouseName;
  final String cashierUsername;
  final String channel;
  final String? terminalName;
  final String currencyCode;
  final String currencySymbol;
  final int totalCents;
  final int paidCents;
  final int pendingCents;
  final int pendingPrimaryCents;
}

class ConsignmentSaleLine {
  const ConsignmentSaleLine({
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitPriceCents,
    required this.lineTotalCents,
  });

  final String productName;
  final String sku;
  final double qty;
  final int unitPriceCents;
  final int lineTotalCents;
}

class ConsignmentPaymentRecord {
  const ConsignmentPaymentRecord({
    required this.method,
    required this.amountCents,
    required this.createdAt,
    this.transactionId,
  });

  final String method;
  final int amountCents;
  final DateTime createdAt;
  final String? transactionId;
}

class ConsignmentSaleDebtDetail {
  const ConsignmentSaleDebtDetail({
    required this.sale,
    required this.customerName,
    required this.customerCode,
    required this.customerPhone,
    required this.lines,
    required this.payments,
  });

  final ConsignmentSaleDebt sale;
  final String customerName;
  final String? customerCode;
  final String? customerPhone;
  final List<ConsignmentSaleLine> lines;
  final List<ConsignmentPaymentRecord> payments;
}

class ConsignmentPaymentMethodsConfig {
  const ConsignmentPaymentMethodsConfig({
    required this.methodCodes,
    required this.onlineMethodCodes,
  });

  final List<String> methodCodes;
  final Set<String> onlineMethodCodes;
}

class ConsignacionesLocalDataSource {
  ConsignacionesLocalDataSource(
    this._db,
    this._configDs, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final ConfiguracionLocalDataSource _configDs;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  static const String _consignmentMethodCode = 'consignment';

  Future<ConsignmentPaymentMethodsConfig> loadPaymentMethodsConfig() async {
    final List<AppPaymentMethodSetting> settings =
        await _configDs.loadPaymentMethodSettings();
    final List<String> methodCodes = settings
        .map((AppPaymentMethodSetting row) => row.code.trim().toLowerCase())
        .where(
            (String code) => code.isNotEmpty && code != _consignmentMethodCode)
        .toList(growable: false);
    final Set<String> onlineCodes = settings
        .where((AppPaymentMethodSetting row) => row.isOnline)
        .map((AppPaymentMethodSetting row) => row.code.trim().toLowerCase())
        .where((String code) => code.isNotEmpty)
        .toSet();
    return ConsignmentPaymentMethodsConfig(
      methodCodes: methodCodes,
      onlineMethodCodes: onlineCodes,
    );
  }

  Future<ConsignmentDebtOverview> loadDebtOverview() async {
    final AppCurrencyConfig currencyConfig =
        (await _configDs.loadCurrencyConfig()).normalized();
    final String primaryCode = currencyConfig.primaryCurrencyCode;
    final String primarySymbol = currencyConfig.primaryCurrency.symbol;

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS folio,
        s.created_at AS created_at,
        s.total_cents AS total_cents,
        s.terminal_id AS terminal_id,
        COALESCE(paid.total_paid_cents, 0) AS paid_cents,
        s.customer_id AS customer_id,
        COALESCE(c.full_name, 'Cliente') AS customer_name,
        c.code AS customer_code,
        c.phone AS customer_phone,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(u.username, 'Sin usuario') AS cashier_username,
        t.name AS terminal_name,
        t.currency_code AS terminal_currency_code,
        t.currency_symbol AS terminal_currency_symbol
      FROM sales s
      LEFT JOIN (
        SELECT sale_id, SUM(amount_cents) AS total_paid_cents
        FROM payments
        GROUP BY sale_id
      ) paid ON paid.sale_id = s.id
      LEFT JOIN customers c ON c.id = s.customer_id
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      LEFT JOIN users u ON u.id = s.cashier_id
      LEFT JOIN pos_terminals t ON t.id = s.terminal_id
      WHERE s.status = 'posted'
        AND s.customer_id IS NOT NULL
      ORDER BY s.created_at DESC
      ''',
    ).get();

    final Map<String, _MutableCustomerDebt> byCustomer =
        <String, _MutableCustomerDebt>{};
    int totalPendingPrimaryCents = 0;

    for (final QueryRow row in rows) {
      final int totalCents = (row.data['total_cents'] as num?)?.toInt() ?? 0;
      final int paidCents = (row.data['paid_cents'] as num?)?.toInt() ?? 0;
      final int pendingCents = totalCents - paidCents;
      if (pendingCents <= 0) {
        continue;
      }

      final String saleId = _readText(row, 'sale_id', fallback: '');
      final String customerId = _readText(row, 'customer_id', fallback: '');
      if (saleId.isEmpty || customerId.isEmpty) {
        continue;
      }

      final String terminalId =
          (row.readNullable<String>('terminal_id') ?? '').trim();
      final bool isPos = terminalId.isNotEmpty;
      final String saleCurrencyCode = isPos
          ? _sanitizeCode(
              row.readNullable<String>('terminal_currency_code'),
              fallback: primaryCode,
            )
          : primaryCode;
      final String saleCurrencySymbol = isPos
          ? _sanitizeSymbol(
              row.readNullable<String>('terminal_currency_symbol'),
              fallback: currencyConfig.symbolForCode(saleCurrencyCode),
            )
          : primarySymbol;
      final int pendingPrimaryCents = _toPrimaryCents(
        amountCents: pendingCents,
        currencyCode: saleCurrencyCode,
        currencyConfig: currencyConfig,
      );
      final int totalPrimaryCents = _toPrimaryCents(
        amountCents: totalCents,
        currencyCode: saleCurrencyCode,
        currencyConfig: currencyConfig,
      );
      final int paidPrimaryCents = _toPrimaryCents(
        amountCents: paidCents,
        currencyCode: saleCurrencyCode,
        currencyConfig: currencyConfig,
      );

      final ConsignmentSaleDebt sale = ConsignmentSaleDebt(
        saleId: saleId,
        folio: _readText(row, 'folio', fallback: '-'),
        createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        warehouseName:
            _readText(row, 'warehouse_name', fallback: 'Sin almacén'),
        cashierUsername:
            _readText(row, 'cashier_username', fallback: 'Sin usuario'),
        channel: isPos ? 'pos' : 'directa',
        terminalName: _nullableText(row, 'terminal_name'),
        currencyCode: saleCurrencyCode,
        currencySymbol: saleCurrencySymbol,
        totalCents: totalCents,
        paidCents: paidCents,
        pendingCents: pendingCents,
        pendingPrimaryCents: pendingPrimaryCents,
      );

      final _MutableCustomerDebt bucket = byCustomer.putIfAbsent(
        customerId,
        () => _MutableCustomerDebt(
          customerId: customerId,
          customerName: _readText(row, 'customer_name', fallback: 'Cliente'),
          customerPhone: _nullableText(row, 'customer_phone'),
          customerCode: _nullableText(row, 'customer_code'),
        ),
      );
      bucket.pendingPrimaryCents += pendingPrimaryCents;
      bucket.totalConsignedPrimaryCents += totalPrimaryCents;
      bucket.totalPaidPrimaryCents += paidPrimaryCents;
      bucket.sales.add(sale);
      totalPendingPrimaryCents += pendingPrimaryCents;
    }

    final List<QueryRow> paymentRows = await _db.customSelect(
      '''
      SELECT
        s.customer_id AS customer_id,
        p.method AS method,
        p.amount_cents AS amount_cents,
        p.transaction_id AS transaction_id,
        p.created_at AS created_at,
        s.terminal_id AS terminal_id,
        t.currency_code AS terminal_currency_code,
        t.currency_symbol AS terminal_currency_symbol
      FROM payments p
      INNER JOIN sales s
        ON s.id = p.sale_id
      LEFT JOIN pos_terminals t
        ON t.id = s.terminal_id
      WHERE s.status = 'posted'
        AND s.customer_id IS NOT NULL
      ORDER BY p.created_at DESC
      ''',
    ).get();
    for (final QueryRow row in paymentRows) {
      final String customerId = _readText(row, 'customer_id', fallback: '');
      if (customerId.isEmpty) {
        continue;
      }
      final _MutableCustomerDebt? bucket = byCustomer[customerId];
      if (bucket == null) {
        continue;
      }
      if (bucket.paymentSummary.length >= 12) {
        continue;
      }
      final String terminalId =
          (row.readNullable<String>('terminal_id') ?? '').trim();
      final bool isPos = terminalId.isNotEmpty;
      final String currencyCode = isPos
          ? _sanitizeCode(
              row.readNullable<String>('terminal_currency_code'),
              fallback: primaryCode,
            )
          : primaryCode;
      final String currencySymbol = isPos
          ? _sanitizeSymbol(
              row.readNullable<String>('terminal_currency_symbol'),
              fallback: currencyConfig.symbolForCode(currencyCode),
            )
          : primarySymbol;
      bucket.paymentSummary.add(
        ConsignmentCustomerPaymentRecord(
          method: _readText(row, 'method', fallback: 'pago'),
          amountCents: (row.data['amount_cents'] as num?)?.toInt() ?? 0,
          currencySymbol: currencySymbol,
          transactionId: _nullableText(row, 'transaction_id'),
          createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        ),
      );
    }

    final List<ConsignmentCustomerDebt> customers =
        byCustomer.values.map((_MutableCustomerDebt row) {
      row.sales.sort(
        (ConsignmentSaleDebt a, ConsignmentSaleDebt b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      return ConsignmentCustomerDebt(
        customerId: row.customerId,
        customerName: row.customerName,
        customerPhone: row.customerPhone,
        totalConsignedPrimaryCents: row.totalConsignedPrimaryCents,
        totalPaidPrimaryCents: row.totalPaidPrimaryCents,
        pendingPrimaryCents: row.pendingPrimaryCents,
        paymentSummary: row.paymentSummary.toList(growable: false),
        sales: row.sales.toList(growable: false),
      );
    }).toList(growable: false)
          ..sort((ConsignmentCustomerDebt a, ConsignmentCustomerDebt b) {
            return b.pendingPrimaryCents.compareTo(a.pendingPrimaryCents);
          });

    return ConsignmentDebtOverview(
      primaryCurrencyCode: primaryCode,
      primaryCurrencySymbol: primarySymbol,
      totalPendingPrimaryCents: totalPendingPrimaryCents,
      customers: customers,
    );
  }

  Future<ConsignmentSaleDebtDetail?> loadSaleDebtDetail(String saleId) async {
    final AppCurrencyConfig currencyConfig =
        (await _configDs.loadCurrencyConfig()).normalized();
    final String primaryCode = currencyConfig.primaryCurrencyCode;
    final String primarySymbol = currencyConfig.primaryCurrency.symbol;
    final String cleanSaleId = saleId.trim();
    if (cleanSaleId.isEmpty) {
      return null;
    }

    final List<QueryRow> headerRows = await _db.customSelect(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS folio,
        s.created_at AS created_at,
        s.total_cents AS total_cents,
        s.terminal_id AS terminal_id,
        COALESCE(paid.total_paid_cents, 0) AS paid_cents,
        s.customer_id AS customer_id,
        COALESCE(c.full_name, 'Cliente') AS customer_name,
        c.code AS customer_code,
        c.phone AS customer_phone,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(u.username, 'Sin usuario') AS cashier_username,
        t.name AS terminal_name,
        t.currency_code AS terminal_currency_code,
        t.currency_symbol AS terminal_currency_symbol
      FROM sales s
      LEFT JOIN (
        SELECT sale_id, SUM(amount_cents) AS total_paid_cents
        FROM payments
        GROUP BY sale_id
      ) paid ON paid.sale_id = s.id
      LEFT JOIN customers c ON c.id = s.customer_id
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      LEFT JOIN users u ON u.id = s.cashier_id
      LEFT JOIN pos_terminals t ON t.id = s.terminal_id
      WHERE s.id = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanSaleId)],
    ).get();
    if (headerRows.isEmpty) {
      return null;
    }
    final QueryRow header = headerRows.first;
    final int totalCents = (header.data['total_cents'] as num?)?.toInt() ?? 0;
    final int paidCents = (header.data['paid_cents'] as num?)?.toInt() ?? 0;
    final int pendingCents = (totalCents - paidCents).clamp(0, totalCents);

    final String terminalId =
        (header.readNullable<String>('terminal_id') ?? '').trim();
    final bool isPos = terminalId.isNotEmpty;
    final String saleCurrencyCode = isPos
        ? _sanitizeCode(
            header.readNullable<String>('terminal_currency_code'),
            fallback: primaryCode,
          )
        : primaryCode;
    final String saleCurrencySymbol = isPos
        ? _sanitizeSymbol(
            header.readNullable<String>('terminal_currency_symbol'),
            fallback: currencyConfig.symbolForCode(saleCurrencyCode),
          )
        : primarySymbol;

    final ConsignmentSaleDebt sale = ConsignmentSaleDebt(
      saleId: _readText(header, 'sale_id', fallback: cleanSaleId),
      folio: _readText(header, 'folio', fallback: '-'),
      createdAt: header.readNullable<DateTime>('created_at') ?? DateTime.now(),
      warehouseName:
          _readText(header, 'warehouse_name', fallback: 'Sin almacén'),
      cashierUsername:
          _readText(header, 'cashier_username', fallback: 'Sin usuario'),
      channel: isPos ? 'pos' : 'directa',
      terminalName: _nullableText(header, 'terminal_name'),
      currencyCode: saleCurrencyCode,
      currencySymbol: saleCurrencySymbol,
      totalCents: totalCents,
      paidCents: paidCents,
      pendingCents: pendingCents,
      pendingPrimaryCents: _toPrimaryCents(
        amountCents: pendingCents,
        currencyCode: saleCurrencyCode,
        currencyConfig: currencyConfig,
      ),
    );

    final List<QueryRow> lineRows = await _db.customSelect(
      '''
      SELECT
        COALESCE(p.name, 'Producto') AS product_name,
        COALESCE(p.sku, '-') AS sku,
        COALESCE(si.qty, 0) AS qty,
        COALESCE(si.unit_price_cents, 0) AS unit_price_cents,
        COALESCE(si.line_total_cents, 0) AS line_total_cents
      FROM sale_items si
      INNER JOIN products p
        ON p.id = si.product_id
       AND p.is_active = 1
      WHERE si.sale_id = ?
      ORDER BY product_name ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanSaleId)],
    ).get();
    final List<ConsignmentSaleLine> lines = lineRows.map((QueryRow row) {
      return ConsignmentSaleLine(
        productName: _readText(row, 'product_name', fallback: 'Producto'),
        sku: _readText(row, 'sku', fallback: '-'),
        qty: (row.data['qty'] as num?)?.toDouble() ?? 0,
        unitPriceCents: (row.data['unit_price_cents'] as num?)?.toInt() ?? 0,
        lineTotalCents: (row.data['line_total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);

    final List<QueryRow> paymentRows = await _db.customSelect(
      '''
      SELECT
        method,
        amount_cents,
        transaction_id,
        created_at
      FROM payments
      WHERE sale_id = ?
      ORDER BY created_at ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanSaleId)],
    ).get();
    final List<ConsignmentPaymentRecord> payments =
        paymentRows.map((QueryRow row) {
      return ConsignmentPaymentRecord(
        method: _readText(row, 'method', fallback: 'pago'),
        amountCents: (row.data['amount_cents'] as num?)?.toInt() ?? 0,
        transactionId: _nullableText(row, 'transaction_id'),
        createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
      );
    }).toList(growable: false);

    return ConsignmentSaleDebtDetail(
      sale: sale,
      customerName: _readText(header, 'customer_name', fallback: 'Cliente'),
      customerCode: _nullableText(header, 'customer_code'),
      customerPhone: _nullableText(header, 'customer_phone'),
      lines: lines,
      payments: payments,
    );
  }

  Future<int> registerDebtPayment({
    required String saleId,
    required String userId,
    required String method,
    required int amountCents,
    String? transactionId,
    Set<String> onlineMethodCodes = const <String>{},
  }) async {
    await _licenseService.requireWriteAccess();

    final String cleanSaleId = saleId.trim();
    final String cleanUserId = userId.trim();
    final String cleanMethod = method.trim().toLowerCase();
    final String cleanTx = (transactionId ?? '').trim();
    if (cleanSaleId.isEmpty) {
      throw Exception('Venta inválida para registrar pago.');
    }
    if (cleanUserId.isEmpty) {
      throw Exception('Usuario inválido para registrar pago.');
    }
    final bool canReconcile = await _userHasPermission(
      userId: cleanUserId,
      permissionKey: AppPermissionKeys.consignmentsReconcile,
    );
    if (!canReconcile) {
      throw Exception('No tienes permisos para conciliar consignaciones.');
    }
    if (cleanMethod.isEmpty) {
      throw Exception('Debes seleccionar un método de pago.');
    }
    if (cleanMethod == _consignmentMethodCode) {
      throw Exception('Consignación no es válido para registrar abonos.');
    }
    if (amountCents <= 0) {
      throw Exception('El monto debe ser mayor que cero.');
    }
    if (onlineMethodCodes.contains(cleanMethod) && cleanTx.isEmpty) {
      throw Exception('Este método requiere ID de transacción.');
    }

    return _db.transaction(() async {
      final List<QueryRow> rows = await _db.customSelect(
        '''
        SELECT
          s.id AS sale_id,
          s.folio AS folio,
          s.total_cents AS total_cents,
          COALESCE(paid.total_paid_cents, 0) AS paid_cents
        FROM sales s
        LEFT JOIN (
          SELECT sale_id, SUM(amount_cents) AS total_paid_cents
          FROM payments
          GROUP BY sale_id
        ) paid ON paid.sale_id = s.id
        WHERE s.id = ?
          AND s.status = 'posted'
          AND s.customer_id IS NOT NULL
        LIMIT 1
        ''',
        variables: <Variable<Object>>[Variable<String>(cleanSaleId)],
      ).get();
      if (rows.isEmpty) {
        throw Exception('La venta no existe o no tiene cliente asociado.');
      }
      final QueryRow row = rows.first;
      final int totalCents = (row.data['total_cents'] as num?)?.toInt() ?? 0;
      final int paidCents = (row.data['paid_cents'] as num?)?.toInt() ?? 0;
      final int pendingCents = totalCents - paidCents;
      if (pendingCents <= 0) {
        throw Exception('La venta ya está conciliada.');
      }
      if (amountCents > pendingCents) {
        throw Exception(
          'El abono supera el saldo pendiente de la venta.',
        );
      }

      await _db.into(_db.payments).insert(
            PaymentsCompanion.insert(
              id: _uuid.v4(),
              saleId: cleanSaleId,
              method: cleanMethod,
              amountCents: amountCents,
              transactionId: Value(cleanTx.isEmpty ? null : cleanTx),
            ),
          );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(cleanUserId),
              action: 'SALE_DEBT_PAYMENT_REGISTERED',
              entity: 'sale',
              entityId: cleanSaleId,
              payloadJson: jsonEncode(<String, Object?>{
                'method': cleanMethod,
                'amountCents': amountCents,
                'transactionId': cleanTx.isEmpty ? null : cleanTx,
                'pendingBeforeCents': pendingCents,
                'pendingAfterCents': pendingCents - amountCents,
              }),
            ),
          );

      return pendingCents - amountCents;
    });
  }

  Future<int> registerCustomerDebtPayment({
    required String customerId,
    required String userId,
    required String method,
    required int amountPrimaryCents,
    String? transactionId,
    Set<String> onlineMethodCodes = const <String>{},
  }) async {
    await _licenseService.requireWriteAccess();

    final String cleanCustomerId = customerId.trim();
    final String cleanUserId = userId.trim();
    final String cleanMethod = method.trim().toLowerCase();
    final String cleanTx = (transactionId ?? '').trim();
    if (cleanCustomerId.isEmpty) {
      throw Exception('Cliente inválido para registrar pago.');
    }
    if (cleanUserId.isEmpty) {
      throw Exception('Usuario inválido para registrar pago.');
    }
    final bool canReconcile = await _userHasPermission(
      userId: cleanUserId,
      permissionKey: AppPermissionKeys.consignmentsReconcile,
    );
    if (!canReconcile) {
      throw Exception('No tienes permisos para conciliar consignaciones.');
    }
    if (cleanMethod.isEmpty) {
      throw Exception('Debes seleccionar un método de pago.');
    }
    if (cleanMethod == _consignmentMethodCode) {
      throw Exception('Consignación no es válido para registrar abonos.');
    }
    if (amountPrimaryCents <= 0) {
      throw Exception('El monto debe ser mayor que cero.');
    }
    if (onlineMethodCodes.contains(cleanMethod) && cleanTx.isEmpty) {
      throw Exception('Este método requiere ID de transacción.');
    }

    final AppCurrencyConfig currencyConfig =
        (await _configDs.loadCurrencyConfig()).normalized();
    final String primaryCode = currencyConfig.primaryCurrencyCode;

    return _db.transaction(() async {
      final List<QueryRow> rows = await _db.customSelect(
        '''
        SELECT
          s.id AS sale_id,
          s.created_at AS created_at,
          s.total_cents AS total_cents,
          COALESCE(paid.total_paid_cents, 0) AS paid_cents,
          s.terminal_id AS terminal_id,
          t.currency_code AS terminal_currency_code
        FROM sales s
        LEFT JOIN (
          SELECT sale_id, SUM(amount_cents) AS total_paid_cents
          FROM payments
          GROUP BY sale_id
        ) paid ON paid.sale_id = s.id
        LEFT JOIN pos_terminals t ON t.id = s.terminal_id
        WHERE s.status = 'posted'
          AND s.customer_id = ?
        ORDER BY s.created_at ASC
        ''',
        variables: <Variable<Object>>[Variable<String>(cleanCustomerId)],
      ).get();
      if (rows.isEmpty) {
        throw Exception('No hay ventas en consignación para este cliente.');
      }

      final List<_PendingCustomerSaleDebt> pendingSales =
          <_PendingCustomerSaleDebt>[];
      int totalPendingPrimaryCents = 0;
      for (final QueryRow row in rows) {
        final int totalCents = (row.data['total_cents'] as num?)?.toInt() ?? 0;
        final int paidCents = (row.data['paid_cents'] as num?)?.toInt() ?? 0;
        final int pendingCents = totalCents - paidCents;
        if (pendingCents <= 0) {
          continue;
        }
        final String saleId = _readText(row, 'sale_id', fallback: '');
        if (saleId.isEmpty) {
          continue;
        }
        final String terminalId =
            (row.readNullable<String>('terminal_id') ?? '').trim();
        final String saleCurrencyCode = terminalId.isNotEmpty
            ? _sanitizeCode(
                row.readNullable<String>('terminal_currency_code'),
                fallback: primaryCode,
              )
            : primaryCode;
        final int pendingPrimaryCents = _toPrimaryCents(
          amountCents: pendingCents,
          currencyCode: saleCurrencyCode,
          currencyConfig: currencyConfig,
        );
        if (pendingPrimaryCents <= 0) {
          continue;
        }
        pendingSales.add(
          _PendingCustomerSaleDebt(
            saleId: saleId,
            pendingSaleCents: pendingCents,
            pendingPrimaryCents: pendingPrimaryCents,
            currencyCode: saleCurrencyCode,
          ),
        );
        totalPendingPrimaryCents += pendingPrimaryCents;
      }

      if (pendingSales.isEmpty) {
        throw Exception('El cliente no tiene saldo pendiente.');
      }
      if (amountPrimaryCents > totalPendingPrimaryCents) {
        throw Exception('El abono supera el saldo pendiente del cliente.');
      }

      int remainingPrimaryCents = amountPrimaryCents;
      int appliedPrimaryCents = 0;
      final List<Map<String, Object?>> allocations = <Map<String, Object?>>[];

      for (final _PendingCustomerSaleDebt sale in pendingSales) {
        if (remainingPrimaryCents <= 0) {
          break;
        }
        int allocatePrimaryCents =
            remainingPrimaryCents.clamp(0, sale.pendingPrimaryCents);
        if (allocatePrimaryCents <= 0) {
          continue;
        }

        int allocateSaleCents = _fromPrimaryCents(
          amountPrimaryCents: allocatePrimaryCents,
          targetCurrencyCode: sale.currencyCode,
          currencyConfig: currencyConfig,
        );
        if (allocateSaleCents <= 0) {
          allocateSaleCents = 1;
        }
        if (allocateSaleCents > sale.pendingSaleCents) {
          allocateSaleCents = sale.pendingSaleCents;
        }
        allocatePrimaryCents = _toPrimaryCents(
          amountCents: allocateSaleCents,
          currencyCode: sale.currencyCode,
          currencyConfig: currencyConfig,
        );
        if (allocateSaleCents <= 0 || allocatePrimaryCents <= 0) {
          continue;
        }

        await _db.into(_db.payments).insert(
              PaymentsCompanion.insert(
                id: _uuid.v4(),
                saleId: sale.saleId,
                method: cleanMethod,
                amountCents: allocateSaleCents,
                transactionId: Value(cleanTx.isEmpty ? null : cleanTx),
              ),
            );

        allocations.add(<String, Object?>{
          'saleId': sale.saleId,
          'amountCents': allocateSaleCents,
          'currencyCode': sale.currencyCode,
          'amountPrimaryCents': allocatePrimaryCents,
        });
        remainingPrimaryCents -= allocatePrimaryCents;
        appliedPrimaryCents += allocatePrimaryCents;
      }

      if (appliedPrimaryCents <= 0) {
        throw Exception(
            'No se pudo aplicar el abono a las deudas del cliente.');
      }

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(cleanUserId),
              action: 'CUSTOMER_DEBT_PAYMENT_REGISTERED',
              entity: 'customer',
              entityId: cleanCustomerId,
              payloadJson: jsonEncode(<String, Object?>{
                'method': cleanMethod,
                'amountPrimaryCentsRequested': amountPrimaryCents,
                'amountPrimaryCentsApplied': appliedPrimaryCents,
                'transactionId': cleanTx.isEmpty ? null : cleanTx,
                'pendingBeforePrimaryCents': totalPendingPrimaryCents,
                'pendingAfterPrimaryCents':
                    (totalPendingPrimaryCents - appliedPrimaryCents)
                        .clamp(0, totalPendingPrimaryCents),
                'allocations': allocations,
              }),
            ),
          );

      return (totalPendingPrimaryCents - appliedPrimaryCents)
          .clamp(0, totalPendingPrimaryCents);
    });
  }

  Future<void> reassignConsignmentSaleCustomer({
    required String saleId,
    required String newCustomerId,
    required String userId,
  }) async {
    await _licenseService.requireWriteAccess();

    final String cleanSaleId = saleId.trim();
    final String cleanCustomerId = newCustomerId.trim();
    final String cleanUserId = userId.trim();
    if (cleanSaleId.isEmpty) {
      throw Exception('Venta inválida.');
    }
    if (cleanCustomerId.isEmpty) {
      throw Exception('Cliente inválido.');
    }
    if (cleanUserId.isEmpty) {
      throw Exception('Usuario inválido.');
    }
    final bool canReconcile = await _userHasPermission(
      userId: cleanUserId,
      permissionKey: AppPermissionKeys.consignmentsReconcile,
    );
    if (!canReconcile) {
      throw Exception('No tienes permisos para editar consignaciones.');
    }

    await _db.transaction(() async {
      final QueryRow? saleRow = await _db.customSelect(
        '''
        SELECT
          s.id AS sale_id,
          s.folio AS folio,
          s.customer_id AS customer_id,
          s.total_cents AS total_cents,
          COALESCE(paid.total_paid_cents, 0) AS paid_cents
        FROM sales s
        LEFT JOIN (
          SELECT sale_id, SUM(amount_cents) AS total_paid_cents
          FROM payments
          GROUP BY sale_id
        ) paid ON paid.sale_id = s.id
        WHERE s.id = ?
          AND s.status = 'posted'
          AND s.customer_id IS NOT NULL
        LIMIT 1
        ''',
        variables: <Variable<Object>>[Variable<String>(cleanSaleId)],
      ).getSingleOrNull();
      if (saleRow == null) {
        throw Exception('La venta no existe o no corresponde a consignación.');
      }
      final int totalCents =
          (saleRow.data['total_cents'] as num?)?.toInt() ?? 0;
      final int paidCents = (saleRow.data['paid_cents'] as num?)?.toInt() ?? 0;
      final int pendingCents = totalCents - paidCents;
      if (pendingCents <= 0) {
        throw Exception('La venta ya está conciliada.');
      }

      final String previousCustomerId =
          _readText(saleRow, 'customer_id', fallback: '');
      if (previousCustomerId.isEmpty) {
        throw Exception('La venta no tiene cliente asociado.');
      }
      if (previousCustomerId == cleanCustomerId) {
        return;
      }

      final QueryRow? newCustomer = await _db.customSelect(
        '''
        SELECT
          c.id AS customer_id,
          COALESCE(c.full_name, 'Cliente') AS customer_name
        FROM customers c
        WHERE c.id = ?
          AND c.is_active = 1
        LIMIT 1
        ''',
        variables: <Variable<Object>>[Variable<String>(cleanCustomerId)],
      ).getSingleOrNull();
      if (newCustomer == null) {
        throw Exception(
            'El cliente seleccionado no es válido o está inactivo.');
      }
      final QueryRow? oldCustomer = await _db.customSelect(
        '''
        SELECT
          c.id AS customer_id,
          COALESCE(c.full_name, 'Cliente') AS customer_name
        FROM customers c
        WHERE c.id = ?
        LIMIT 1
        ''',
        variables: <Variable<Object>>[Variable<String>(previousCustomerId)],
      ).getSingleOrNull();

      await (_db.update(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(cleanSaleId)))
          .write(
        SalesCompanion(
          customerId: Value(cleanCustomerId),
        ),
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(cleanUserId),
              action: 'SALE_CONSIGNMENT_CUSTOMER_REASSIGNED',
              entity: 'sale',
              entityId: cleanSaleId,
              payloadJson: jsonEncode(<String, Object?>{
                'saleId': cleanSaleId,
                'folio': _readText(saleRow, 'folio', fallback: '-'),
                'pendingCents': pendingCents,
                'fromCustomerId': previousCustomerId,
                'fromCustomerName': _readText(
                    oldCustomer ?? saleRow, 'customer_name',
                    fallback: 'Cliente'),
                'toCustomerId': cleanCustomerId,
                'toCustomerName': _readText(newCustomer, 'customer_name',
                    fallback: 'Cliente'),
              }),
            ),
          );
    });
  }

  int _toPrimaryCents({
    required int amountCents,
    required String currencyCode,
    required AppCurrencyConfig currencyConfig,
  }) {
    final String code = currencyCode.trim().toUpperCase();
    if (code.isEmpty || code == currencyConfig.primaryCurrencyCode) {
      return amountCents;
    }
    final AppCurrencySetting? row = currencyConfig.currencyByCode(code);
    final double rateToPrimary = row?.rateToPrimary ?? 1;
    if (!rateToPrimary.isFinite || rateToPrimary <= 0) {
      return amountCents;
    }
    return (amountCents / rateToPrimary).round();
  }

  int _fromPrimaryCents({
    required int amountPrimaryCents,
    required String targetCurrencyCode,
    required AppCurrencyConfig currencyConfig,
  }) {
    final String code = targetCurrencyCode.trim().toUpperCase();
    if (code.isEmpty || code == currencyConfig.primaryCurrencyCode) {
      return amountPrimaryCents;
    }
    final AppCurrencySetting? row = currencyConfig.currencyByCode(code);
    final double rateToPrimary = row?.rateToPrimary ?? 1;
    if (!rateToPrimary.isFinite || rateToPrimary <= 0) {
      return amountPrimaryCents;
    }
    return (amountPrimaryCents * rateToPrimary).round();
  }

  String _readText(QueryRow row, String key, {required String fallback}) {
    final String value = (row.readNullable<String>(key) ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  String? _nullableText(QueryRow row, String key) {
    final String value = (row.readNullable<String>(key) ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  String _sanitizeCode(String? raw, {required String fallback}) {
    final String value = (raw ?? '').trim().toUpperCase();
    if (value.isEmpty) {
      return fallback;
    }
    return value;
  }

  String _sanitizeSymbol(String? raw, {required String fallback}) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) {
      return fallback;
    }
    return value;
  }

  Future<bool> _userHasPermission({
    required String userId,
    required String permissionKey,
  }) async {
    final String safeUserId = userId.trim();
    final String safePermissionKey = permissionKey.trim();
    if (safeUserId.isEmpty || safePermissionKey.isEmpty) {
      return false;
    }
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(safeUserId)))
        .getSingleOrNull();
    if (user != null && user.role.trim().toLowerCase() == 'admin') {
      return true;
    }
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT 1 AS ok
      FROM user_roles ur
      INNER JOIN role_permissions rp
        ON rp.role_id = ur.role_id
      WHERE ur.user_id = ?
        AND rp.permission_key = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeUserId),
        Variable<String>(safePermissionKey),
      ],
    ).getSingleOrNull();
    if (row != null) {
      return true;
    }
    if (user != null &&
        user.role.trim().toLowerCase() == 'cajero' &&
        AppPermissionsCatalog.defaultCashierPermissions
            .contains(safePermissionKey)) {
      return true;
    }
    return false;
  }
}

class _MutableCustomerDebt {
  _MutableCustomerDebt({
    required this.customerId,
    required this.customerName,
    required this.customerCode,
    required this.customerPhone,
  });

  final String customerId;
  final String customerName;
  final String? customerCode;
  final String? customerPhone;
  int totalConsignedPrimaryCents = 0;
  int totalPaidPrimaryCents = 0;
  int pendingPrimaryCents = 0;
  final List<ConsignmentCustomerPaymentRecord> paymentSummary =
      <ConsignmentCustomerPaymentRecord>[];
  final List<ConsignmentSaleDebt> sales = <ConsignmentSaleDebt>[];
}

class _PendingCustomerSaleDebt {
  const _PendingCustomerSaleDebt({
    required this.saleId,
    required this.pendingSaleCents,
    required this.pendingPrimaryCents,
    required this.currencyCode,
  });

  final String saleId;
  final int pendingSaleCents;
  final int pendingPrimaryCents;
  final String currencyCode;
}
