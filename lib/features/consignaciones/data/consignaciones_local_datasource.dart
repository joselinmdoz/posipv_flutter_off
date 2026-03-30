import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';
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
    required this.pendingPrimaryCents,
    required this.sales,
  });

  final String customerId;
  final String customerName;
  final String? customerPhone;
  final int pendingPrimaryCents;
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
      bucket.sales.add(sale);
      totalPendingPrimaryCents += pendingPrimaryCents;
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
        pendingPrimaryCents: row.pendingPrimaryCents,
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
      LEFT JOIN products p ON p.id = si.product_id
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
  int pendingPrimaryCents = 0;
  final List<ConsignmentSaleDebt> sales = <ConsignmentSaleDebt>[];
}
