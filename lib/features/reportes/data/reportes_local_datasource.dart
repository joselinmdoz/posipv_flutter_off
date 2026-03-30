import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_service.dart';

class SalesSummary {
  const SalesSummary({
    required this.salesCount,
    required this.totalCents,
    required this.taxCents,
  });

  final int salesCount;
  final int totalCents;
  final int taxCents;
}

class DailySalesPoint {
  const DailySalesPoint({
    required this.day,
    required this.salesCount,
    required this.totalCents,
  });

  final String day;
  final int salesCount;
  final int totalCents;
}

class TopProductStat {
  const TopProductStat({
    required this.productName,
    required this.sku,
    required this.qty,
    required this.totalCents,
  });

  final String productName;
  final String sku;
  final double qty;
  final int totalCents;
}

enum SalesAnalyticsGranularity { day, week, month, year }

class SalesTrendPointStat {
  const SalesTrendPointStat({
    required this.bucketStart,
    required this.label,
    required this.totalCents,
    required this.ordersCount,
  });

  final DateTime bucketStart;
  final String label;
  final int totalCents;
  final int ordersCount;
}

class AnalyticsTopProductStat {
  const AnalyticsTopProductStat({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.imagePath,
    required this.qty,
    required this.totalCents,
    required this.deltaPercent,
  });

  final String productId;
  final String productName;
  final String sku;
  final String? imagePath;
  final double qty;
  final int totalCents;
  final double deltaPercent;
}

class SalesBreakdownStat {
  const SalesBreakdownStat({
    required this.key,
    required this.label,
    required this.ordersCount,
    required this.totalCents,
  });

  final String key;
  final String label;
  final int ordersCount;
  final int totalCents;
}

class AnalyticsTopCustomerStat {
  const AnalyticsTopCustomerStat({
    required this.customerId,
    required this.name,
    required this.customerType,
    required this.ordersCount,
    required this.totalCents,
    required this.lastSaleAt,
  });

  final String customerId;
  final String name;
  final String customerType;
  final int ordersCount;
  final int totalCents;
  final DateTime? lastSaleAt;
}

class SalesAnalyticsSaleStat {
  const SalesAnalyticsSaleStat({
    required this.saleId,
    required this.folio,
    required this.createdAt,
    required this.warehouseName,
    required this.cashierUsername,
    required this.customerName,
    required this.terminalName,
    required this.totalCents,
    required this.itemsCount,
    required this.channel,
  });

  final String saleId;
  final String folio;
  final DateTime createdAt;
  final String warehouseName;
  final String cashierUsername;
  final String? customerName;
  final String? terminalName;
  final int totalCents;
  final int itemsCount;
  final String channel;
}

class SalesAnalyticsSaleLineStat {
  const SalesAnalyticsSaleLineStat({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
    required this.unitPriceCents,
    required this.lineTotalCents,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
  final int unitPriceCents;
  final int lineTotalCents;
}

class SalesAnalyticsSalePaymentStat {
  const SalesAnalyticsSalePaymentStat({
    required this.method,
    required this.amountCents,
    required this.transactionId,
    required this.sourceCurrencyCode,
    required this.sourceAmountCents,
    required this.createdAt,
  });

  final String method;
  final int amountCents;
  final String? transactionId;
  final String? sourceCurrencyCode;
  final int? sourceAmountCents;
  final DateTime createdAt;
}

class SalesAnalyticsSaleDetailStat {
  const SalesAnalyticsSaleDetailStat({
    required this.sale,
    required this.lines,
    required this.payments,
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
  });

  final SalesAnalyticsSaleStat sale;
  final List<SalesAnalyticsSaleLineStat> lines;
  final List<SalesAnalyticsSalePaymentStat> payments;
  final int subtotalCents;
  final int taxCents;
  final int totalCents;
}

class SalesAnalyticsSnapshot {
  const SalesAnalyticsSnapshot({
    required this.fromDate,
    required this.toDate,
    required this.granularity,
    required this.totalRevenueCents,
    required this.totalProfitCents,
    required this.avgOrderCents,
    required this.totalRevenueDeltaPercent,
    required this.avgOrderDeltaPercent,
    required this.trend,
    required this.topProducts,
    required this.ordersCount,
    required this.itemsSoldQty,
    required this.uniqueCustomersCount,
    required this.salesWithoutCustomerCount,
    required this.posRevenueCents,
    required this.posOrdersCount,
    required this.directRevenueCents,
    required this.directOrdersCount,
    required this.paymentMethods,
    required this.byCashier,
    required this.byWarehouse,
    required this.topCustomers,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final SalesAnalyticsGranularity granularity;
  final int totalRevenueCents;
  final int totalProfitCents;
  final int avgOrderCents;
  final double totalRevenueDeltaPercent;
  final double avgOrderDeltaPercent;
  final List<SalesTrendPointStat> trend;
  final List<AnalyticsTopProductStat> topProducts;
  final int ordersCount;
  final double itemsSoldQty;
  final int uniqueCustomersCount;
  final int salesWithoutCustomerCount;
  final int posRevenueCents;
  final int posOrdersCount;
  final int directRevenueCents;
  final int directOrdersCount;
  final List<SalesBreakdownStat> paymentMethods;
  final List<SalesBreakdownStat> byCashier;
  final List<SalesBreakdownStat> byWarehouse;
  final List<AnalyticsTopCustomerStat> topCustomers;
}

class RecentSaleStat {
  const RecentSaleStat({
    required this.saleId,
    required this.folio,
    required this.warehouseName,
    required this.cashierUsername,
    required this.totalCents,
    required this.createdAt,
  });

  final String saleId;
  final String folio;
  final String warehouseName;
  final String cashierUsername;
  final int totalCents;
  final DateTime createdAt;
}

class SessionClosureBreakdownStat {
  const SessionClosureBreakdownStat({
    required this.denominationCents,
    required this.unitCount,
    required this.subtotalCents,
  });

  final int denominationCents;
  final int unitCount;
  final int subtotalCents;
}

class RecentSessionClosureStat {
  const RecentSessionClosureStat({
    required this.sessionId,
    required this.terminalName,
    required this.cashierUsername,
    required this.currencySymbol,
    required this.closedAt,
    required this.closingCashCents,
    required this.breakdown,
  });

  final String sessionId;
  final String terminalName;
  final String cashierUsername;
  final String currencySymbol;
  final DateTime closedAt;
  final int closingCashCents;
  final List<SessionClosureBreakdownStat> breakdown;
}

class IpvReportSummaryStat {
  const IpvReportSummaryStat({
    required this.reportId,
    required this.sessionId,
    required this.terminalName,
    required this.currencySymbol,
    required this.openedAt,
    required this.closedAt,
    required this.status,
    required this.openingSource,
    required this.lineCount,
    required this.totalAmountCents,
  });

  final String reportId;
  final String sessionId;
  final String terminalName;
  final String currencySymbol;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String status;
  final String openingSource;
  final int lineCount;
  final int totalAmountCents;
}

class IpvReportLineStat {
  const IpvReportLineStat({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.startQty,
    required this.entriesQty,
    required this.outputsQty,
    required this.salesQty,
    required this.finalQty,
    required this.salePriceCents,
    required this.totalAmountCents,
  });

  final String productId;
  final String productName;
  final String sku;
  final double startQty;
  final double entriesQty;
  final double outputsQty;
  final double salesQty;
  final double finalQty;
  final int salePriceCents;
  final int totalAmountCents;
}

class IpvReportDetailStat {
  const IpvReportDetailStat({
    required this.summary,
    required this.lines,
  });

  final IpvReportSummaryStat summary;
  final List<IpvReportLineStat> lines;
}

class ReportesDashboard {
  const ReportesDashboard({
    required this.today,
    required this.yesterday,
    required this.lastDays,
    required this.topProducts,
    required this.recentSales,
    required this.recentSessionClosures,
    required this.recentIpvReports,
  });

  final SalesSummary today;
  final SalesSummary yesterday;
  final List<DailySalesPoint> lastDays;
  final List<TopProductStat> topProducts;
  final List<RecentSaleStat> recentSales;
  final List<RecentSessionClosureStat> recentSessionClosures;
  final List<IpvReportSummaryStat> recentIpvReports;
}

class StockAlertStat {
  const StockAlertStat({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.qty,
  });

  final String productId;
  final String productName;
  final String sku;
  final double qty;
}

class HomeOperationalInsight {
  const HomeOperationalInsight({
    required this.activeTerminals,
    required this.openSessions,
    required this.openIpvReports,
    required this.zeroStockProducts,
    required this.lowStockProducts,
    required this.movementsToday,
    required this.lastMovementAt,
    required this.lowStockPreview,
  });

  const HomeOperationalInsight.empty()
      : activeTerminals = 0,
        openSessions = 0,
        openIpvReports = 0,
        zeroStockProducts = 0,
        lowStockProducts = 0,
        movementsToday = 0,
        lastMovementAt = null,
        lowStockPreview = const <StockAlertStat>[];

  final int activeTerminals;
  final int openSessions;
  final int openIpvReports;
  final int zeroStockProducts;
  final int lowStockProducts;
  final int movementsToday;
  final DateTime? lastMovementAt;
  final List<StockAlertStat> lowStockPreview;
}

class ReportesLocalDataSource {
  ReportesLocalDataSource(
    this._db, {
    required OfflineLicenseService licenseService,
  }) : _licenseService = licenseService;

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  static const String _demoIpvExportBlockedMessage =
      'Modo demo: la exportacion de IPV (CSV/PDF) esta disponible solo con licencia activa.';
  static const String _demoAnalyticsExportBlockedMessage =
      'Modo demo: la exportacion de analiticas esta disponible solo con licencia activa.';

  Future<HomeOperationalInsight> loadHomeOperationalInsight({
    double lowStockThreshold = 5,
    int previewLimit = 5,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime startToday = _startOfDay(now);
    final double safeLowStockThreshold =
        lowStockThreshold <= 0 ? 1 : lowStockThreshold;
    final int safePreviewLimit = previewLimit < 1 ? 1 : previewLimit;

    final Future<int> activeTerminalsFuture = _countScalar(
      '''
      SELECT COUNT(*) AS value
      FROM pos_terminals
      WHERE is_active = 1
      ''',
    );
    final Future<int> openSessionsFuture = _countScalar(
      '''
      SELECT COUNT(*) AS value
      FROM pos_sessions
      WHERE status = 'open'
      ''',
    );
    final Future<int> openIpvFuture = _countScalar(
      '''
      SELECT COUNT(*) AS value
      FROM ipv_reports
      WHERE status = 'open'
      ''',
    );
    final Future<int> movementsTodayFuture = _countScalar(
      '''
      SELECT COUNT(*) AS value
      FROM stock_movements
      WHERE created_at >= ?
        AND COALESCE(is_voided, 0) = 0
      ''',
      variables: <Variable<Object>>[Variable<DateTime>(startToday)],
    );
    final Future<DateTime?> lastMovementFuture = _lastMovementAt();
    final Future<int> zeroStockFuture = _countStockByCondition(
      '''
      HAVING total_qty <= 0
      ''',
    );
    final Future<int> lowStockFuture = _countStockByCondition(
      '''
      HAVING total_qty > 0
         AND total_qty <= ?
      ''',
      variables: <Variable<Object>>[Variable<double>(safeLowStockThreshold)],
    );
    final Future<List<StockAlertStat>> lowStockPreviewFuture =
        _loadLowStockPreview(
      safeLowStockThreshold,
      safePreviewLimit,
    );

    return HomeOperationalInsight(
      activeTerminals: await activeTerminalsFuture,
      openSessions: await openSessionsFuture,
      openIpvReports: await openIpvFuture,
      zeroStockProducts: await zeroStockFuture,
      lowStockProducts: await lowStockFuture,
      movementsToday: await movementsTodayFuture,
      lastMovementAt: await lastMovementFuture,
      lowStockPreview: await lowStockPreviewFuture,
    );
  }

  Future<ReportesDashboard> loadDashboard({
    int lastDays = 7,
    int topProductsDays = 30,
    int topLimit = 5,
    int recentLimit = 15,
    int sessionClosureLimit = 12,
    int ipvLimit = 12,
  }) async {
    final DateTime now = DateTime.now();
    final int safeLastDays = lastDays < 1 ? 1 : lastDays;
    final int safeTopDays = topProductsDays < 1 ? 1 : topProductsDays;
    final int safeTopLimit = topLimit < 1 ? 1 : topLimit;
    final int safeRecentLimit = recentLimit < 1 ? 1 : recentLimit;
    final int safeSessionClosureLimit =
        sessionClosureLimit < 1 ? 1 : sessionClosureLimit;
    final int safeIpvLimit = ipvLimit < 1 ? 1 : ipvLimit;

    final DateTime startToday = _startOfDay(now);
    final DateTime startYesterday =
        startToday.subtract(const Duration(days: 1));
    final DateTime startLastDays =
        startToday.subtract(Duration(days: safeLastDays - 1));
    final DateTime startTopWindow =
        startToday.subtract(Duration(days: safeTopDays - 1));

    final Future<List<Sale>> todaySalesFuture = _postedSalesSince(startToday);
    final Future<List<Sale>> yesterdaySalesFuture =
        _postedSalesBetween(startYesterday, startToday);
    final Future<List<Sale>> lastSalesFuture = _postedSalesSince(startLastDays);
    final Future<List<TopProductStat>> topFuture =
        _topProducts(startTopWindow, safeTopLimit);
    final Future<List<RecentSaleStat>> recentFuture =
        _recentSales(safeRecentLimit);
    final Future<List<RecentSessionClosureStat>> recentSessionClosuresFuture =
        _recentSessionClosures(safeSessionClosureLimit);
    final Future<List<IpvReportSummaryStat>> recentIpvReportsFuture =
        listIpvReports(limit: safeIpvLimit);

    final List<Sale> todaySales = await todaySalesFuture;
    final List<Sale> yesterdaySales = await yesterdaySalesFuture;
    final List<Sale> lastSales = await lastSalesFuture;
    final List<TopProductStat> top = await topFuture;
    final List<RecentSaleStat> recent = await recentFuture;
    final List<RecentSessionClosureStat> recentSessionClosures =
        await recentSessionClosuresFuture;
    final List<IpvReportSummaryStat> recentIpvReports =
        await recentIpvReportsFuture;

    return ReportesDashboard(
      today: _buildTodaySummary(todaySales),
      yesterday: _buildTodaySummary(yesterdaySales),
      lastDays: _buildLastDaysSeries(lastSales),
      topProducts: top,
      recentSales: recent,
      recentSessionClosures: recentSessionClosures,
      recentIpvReports: recentIpvReports,
    );
  }

  Future<SalesAnalyticsSnapshot> loadSalesAnalytics({
    required DateTime fromDate,
    required DateTime toDate,
    required SalesAnalyticsGranularity granularity,
    int topLimit = 5,
  }) async {
    final DateTime from = _startOfDay(fromDate);
    DateTime toExclusive = _startOfDay(toDate).add(const Duration(days: 1));
    if (!toExclusive.isAfter(from)) {
      toExclusive = from.add(const Duration(days: 1));
    }
    final Duration span = toExclusive.difference(from);
    final DateTime prevFrom = from.subtract(span);
    final DateTime prevToExclusive = from;

    final List<Sale> currentSales =
        await _postedSalesBetween(from, toExclusive);
    final List<Sale> previousSales =
        await _postedSalesBetween(prevFrom, prevToExclusive);
    final int currentTotal = currentSales.fold<int>(
      0,
      (int sum, Sale row) => sum + row.totalCents,
    );
    final int previousTotal = previousSales.fold<int>(
      0,
      (int sum, Sale row) => sum + row.totalCents,
    );
    final int currentAvg =
        currentSales.isEmpty ? 0 : (currentTotal / currentSales.length).round();
    final int previousAvg = previousSales.isEmpty
        ? 0
        : (previousTotal / previousSales.length).round();
    final int ordersCount = currentSales.length;
    final double itemsSoldQty = await _itemsSoldQtyForRange(
      from: from,
      toExclusive: toExclusive,
    );
    final int totalProfitCents = await _profitCentsForRange(
      from: from,
      toExclusive: toExclusive,
    );
    int posRevenueCents = 0;
    int posOrdersCount = 0;
    int directRevenueCents = 0;
    int directOrdersCount = 0;
    int salesWithoutCustomerCount = 0;
    final Set<String> uniqueCustomers = <String>{};
    for (final Sale sale in currentSales) {
      final bool isPosSale = (sale.terminalId ?? '').trim().isNotEmpty;
      if (isPosSale) {
        posOrdersCount += 1;
        posRevenueCents += sale.totalCents;
      } else {
        directOrdersCount += 1;
        directRevenueCents += sale.totalCents;
      }
      final String customerId = (sale.customerId ?? '').trim();
      if (customerId.isEmpty) {
        salesWithoutCustomerCount += 1;
      } else {
        uniqueCustomers.add(customerId);
      }
    }

    final List<SalesTrendPointStat> trend = _buildTrend(
      sales: currentSales,
      granularity: granularity,
      from: from,
      toExclusive: toExclusive,
    );
    final List<AnalyticsTopProductStat> topProducts =
        await _topProductsForRange(
      from: from,
      toExclusive: toExclusive,
      prevFrom: prevFrom,
      prevToExclusive: prevToExclusive,
      limit: topLimit < 1 ? 1 : topLimit,
    );
    final List<SalesBreakdownStat> paymentMethods =
        await _paymentMethodBreakdownForRange(
      from: from,
      toExclusive: toExclusive,
    );
    final List<SalesBreakdownStat> byCashier = await _cashierBreakdownForRange(
      from: from,
      toExclusive: toExclusive,
    );
    final List<SalesBreakdownStat> byWarehouse =
        await _warehouseBreakdownForRange(
      from: from,
      toExclusive: toExclusive,
    );
    final List<AnalyticsTopCustomerStat> topCustomers =
        await _topCustomersForRange(
      from: from,
      toExclusive: toExclusive,
      limit: 8,
    );

    return SalesAnalyticsSnapshot(
      fromDate: from,
      toDate: toExclusive.subtract(const Duration(days: 1)),
      granularity: granularity,
      totalRevenueCents: currentTotal,
      totalProfitCents: totalProfitCents,
      avgOrderCents: currentAvg,
      totalRevenueDeltaPercent: _pctChange(currentTotal, previousTotal),
      avgOrderDeltaPercent: _pctChange(currentAvg, previousAvg),
      trend: trend,
      topProducts: topProducts,
      ordersCount: ordersCount,
      itemsSoldQty: itemsSoldQty,
      uniqueCustomersCount: uniqueCustomers.length,
      salesWithoutCustomerCount: salesWithoutCustomerCount,
      posRevenueCents: posRevenueCents,
      posOrdersCount: posOrdersCount,
      directRevenueCents: directRevenueCents,
      directOrdersCount: directOrdersCount,
      paymentMethods: paymentMethods,
      byCashier: byCashier,
      byWarehouse: byWarehouse,
      topCustomers: topCustomers,
    );
  }

  Future<List<SalesAnalyticsSaleStat>> listSalesForAnalyticsRange({
    required DateTime fromDate,
    required DateTime toDate,
    int limit = 500,
    String? channel,
    String? paymentMethodKey,
    String? dependentKey,
  }) async {
    final DateTime from = _startOfDay(fromDate);
    DateTime toExclusive = _startOfDay(toDate).add(const Duration(days: 1));
    if (!toExclusive.isAfter(from)) {
      toExclusive = from.add(const Duration(days: 1));
    }
    final String? normalizedChannel = _normalizeChannelFilter(channel);
    final String? normalizedPaymentMethod =
        _normalizePaymentMethodKey(paymentMethodKey);
    final String? normalizedDependentKey = _normalizeDependentKey(dependentKey);
    final int safeLimit = limit < 1 ? 1 : limit;

    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS folio,
        s.created_at AS created_at,
        s.total_cents AS total_cents,
        s.terminal_id AS terminal_id,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(
          NULLIF(TRIM(MIN(e.name)), ''),
          COALESCE(u.username, 'Sin usuario')
        ) AS cashier_username,
        c.full_name AS customer_name,
        t.name AS terminal_name,
        CAST(
          COALESCE(
            (
              SELECT COUNT(*)
              FROM sale_items si
              WHERE si.sale_id = s.id
            ),
            0
          ) AS INTEGER
        ) AS items_count
      FROM sales s
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      LEFT JOIN users u ON u.id = s.cashier_id
      LEFT JOIN customers c ON c.id = s.customer_id
      LEFT JOIN pos_terminals t ON t.id = s.terminal_id
      LEFT JOIN pos_session_employees se ON se.session_id = s.terminal_session_id
      LEFT JOIN employees e ON e.id = se.employee_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[
      Variable<DateTime>(from),
      Variable<DateTime>(toExclusive),
    ];
    if (normalizedChannel == 'pos') {
      sql.write(" AND COALESCE(TRIM(s.terminal_id), '') <> ''");
    } else if (normalizedChannel == 'directa') {
      sql.write(" AND COALESCE(TRIM(s.terminal_id), '') = ''");
    }
    if (normalizedPaymentMethod != null) {
      sql.write(
        '''
        AND EXISTS (
          SELECT 1
          FROM payments p_filter
          WHERE p_filter.sale_id = s.id
            AND LOWER(COALESCE(NULLIF(TRIM(p_filter.method), ''), 'unknown')) = ?
        )
        ''',
      );
      variables.add(Variable<String>(normalizedPaymentMethod));
    }
    sql.write(
      '''
      GROUP BY
        s.id,
        s.folio,
        s.created_at,
        s.total_cents,
        s.terminal_id,
        s.cashier_id,
        w.name,
        u.username,
        c.full_name,
        t.name
      ''',
    );
    if (normalizedDependentKey != null) {
      sql.write(
        '''
        HAVING (
          CASE
            WHEN MIN(e.id) IS NOT NULL AND TRIM(MIN(e.id)) <> ''
              THEN 'emp:' || MIN(e.id)
            ELSE 'usr:' || COALESCE(s.cashier_id, '')
          END
        ) = ?
        ''',
      );
      variables.add(Variable<String>(normalizedDependentKey));
    }
    sql.write(
      '''
      ORDER BY s.created_at DESC
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
      final String terminalId =
          (row.readNullable<String>('terminal_id') ?? '').trim();
      return SalesAnalyticsSaleStat(
        saleId: _readTextCell(row, 'sale_id', fallback: ''),
        folio: _readTextCell(row, 'folio', fallback: '-'),
        createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        warehouseName: _readTextCell(
          row,
          'warehouse_name',
          fallback: 'Sin almacén',
        ),
        cashierUsername: _readTextCell(
          row,
          'cashier_username',
          fallback: 'Sin usuario',
        ),
        customerName: _nullableTextCell(row, 'customer_name'),
        terminalName: _nullableTextCell(row, 'terminal_name'),
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
        itemsCount: (row.data['items_count'] as num?)?.toInt() ?? 0,
        channel: terminalId.isEmpty ? 'directa' : 'pos',
      );
    }).toList(growable: false);
  }

  Future<SalesAnalyticsSaleDetailStat?> getSaleDetailForAnalytics(
    String saleId,
  ) async {
    final String id = saleId.trim();
    if (id.isEmpty) {
      return null;
    }
    final List<QueryRow> headerRows = await _db.customSelect(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS folio,
        s.created_at AS created_at,
        s.total_cents AS total_cents,
        s.subtotal_cents AS subtotal_cents,
        s.tax_cents AS tax_cents,
        s.terminal_id AS terminal_id,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(
          NULLIF(TRIM(MIN(e.name)), ''),
          COALESCE(u.username, 'Sin usuario')
        ) AS cashier_username,
        c.full_name AS customer_name,
        t.name AS terminal_name,
        CAST(
          COALESCE(
            (
              SELECT COUNT(*)
              FROM sale_items si
              WHERE si.sale_id = s.id
            ),
            0
          ) AS INTEGER
        ) AS items_count
      FROM sales s
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      LEFT JOIN users u ON u.id = s.cashier_id
      LEFT JOIN customers c ON c.id = s.customer_id
      LEFT JOIN pos_terminals t ON t.id = s.terminal_id
      LEFT JOIN pos_session_employees se ON se.session_id = s.terminal_session_id
      LEFT JOIN employees e ON e.id = se.employee_id
      WHERE s.id = ?
      GROUP BY
        s.id, s.folio, s.created_at, s.total_cents, s.subtotal_cents,
        s.tax_cents, s.terminal_id, s.cashier_id, w.name, u.username,
        c.full_name, t.name
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();
    if (headerRows.isEmpty) {
      return null;
    }
    final QueryRow header = headerRows.first;
    final String terminalId =
        (header.readNullable<String>('terminal_id') ?? '').trim();
    final SalesAnalyticsSaleStat sale = SalesAnalyticsSaleStat(
      saleId: _readTextCell(header, 'sale_id', fallback: id),
      folio: _readTextCell(header, 'folio', fallback: '-'),
      createdAt: header.readNullable<DateTime>('created_at') ?? DateTime.now(),
      warehouseName: _readTextCell(header, 'warehouse_name', fallback: '-'),
      cashierUsername: _readTextCell(header, 'cashier_username', fallback: '-'),
      customerName: _nullableTextCell(header, 'customer_name'),
      terminalName: _nullableTextCell(header, 'terminal_name'),
      totalCents: (header.data['total_cents'] as num?)?.toInt() ?? 0,
      itemsCount: (header.data['items_count'] as num?)?.toInt() ?? 0,
      channel: terminalId.isEmpty ? 'directa' : 'pos',
    );

    final List<QueryRow> lineRows = await _db.customSelect(
      '''
      SELECT
        si.product_id AS product_id,
        COALESCE(p.name, si.product_id, 'Producto') AS product_name,
        COALESCE(p.sku, '-') AS sku,
        COALESCE(si.qty, 0) AS qty,
        COALESCE(si.unit_price_cents, 0) AS unit_price_cents,
        COALESCE(si.line_total_cents, 0) AS line_total_cents
      FROM sale_items si
      LEFT JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
      ORDER BY product_name ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();
    final List<SalesAnalyticsSaleLineStat> lines = lineRows.map((QueryRow row) {
      return SalesAnalyticsSaleLineStat(
        productId: _readTextCell(row, 'product_id', fallback: '-'),
        productName: _readTextCell(row, 'product_name', fallback: 'Producto'),
        sku: _readTextCell(row, 'sku', fallback: '-'),
        qty: (row.data['qty'] as num?)?.toDouble() ?? 0,
        unitPriceCents: (row.data['unit_price_cents'] as num?)?.toInt() ?? 0,
        lineTotalCents: (row.data['line_total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);

    final List<QueryRow> paymentRows = await _db.customSelect(
      '''
      SELECT
        p.method AS method,
        p.amount_cents AS amount_cents,
        p.transaction_id AS transaction_id,
        p.source_currency_code AS source_currency_code,
        p.source_amount_cents AS source_amount_cents,
        p.created_at AS created_at
      FROM payments p
      WHERE p.sale_id = ?
      ORDER BY p.created_at ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();
    final List<SalesAnalyticsSalePaymentStat> payments =
        paymentRows.map((QueryRow row) {
      return SalesAnalyticsSalePaymentStat(
        method: _readTextCell(row, 'method', fallback: 'Pago'),
        amountCents: (row.data['amount_cents'] as num?)?.toInt() ?? 0,
        transactionId: _nullableTextCell(row, 'transaction_id'),
        sourceCurrencyCode: _nullableTextCell(row, 'source_currency_code'),
        sourceAmountCents: (row.data['source_amount_cents'] as num?)?.toInt(),
        createdAt: row.readNullable<DateTime>('created_at') ?? sale.createdAt,
      );
    }).toList(growable: false);

    return SalesAnalyticsSaleDetailStat(
      sale: sale,
      lines: lines,
      payments: payments,
      subtotalCents: (header.data['subtotal_cents'] as num?)?.toInt() ?? 0,
      taxCents: (header.data['tax_cents'] as num?)?.toInt() ?? 0,
      totalCents: (header.data['total_cents'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<Sale>> _postedSalesSince(DateTime from) {
    return (_db.select(_db.sales)
          ..where(
            (Sales tbl) =>
                tbl.status.equals('posted') &
                tbl.id.isNotNull() &
                tbl.folio.isNotNull() &
                tbl.warehouseId.isNotNull() &
                tbl.cashierId.isNotNull() &
                tbl.subtotalCents.isNotNull() &
                tbl.taxCents.isNotNull() &
                tbl.totalCents.isNotNull() &
                tbl.createdAt.isNotNull() &
                tbl.createdAt.isBiggerOrEqualValue(from),
          ))
        .get();
  }

  Future<List<Sale>> _postedSalesBetween(DateTime from, DateTime toExclusive) {
    return (_db.select(_db.sales)
          ..where(
            (Sales tbl) =>
                tbl.status.equals('posted') &
                tbl.id.isNotNull() &
                tbl.folio.isNotNull() &
                tbl.warehouseId.isNotNull() &
                tbl.cashierId.isNotNull() &
                tbl.subtotalCents.isNotNull() &
                tbl.taxCents.isNotNull() &
                tbl.totalCents.isNotNull() &
                tbl.createdAt.isNotNull() &
                tbl.createdAt.isBiggerOrEqualValue(from) &
                tbl.createdAt.isSmallerThanValue(toExclusive),
          ))
        .get();
  }

  Future<List<RecentSaleStat>> _recentSales(int limit) async {
    final List<Sale> sales = await (_db.select(_db.sales)
          ..where((Sales tbl) =>
              tbl.status.equals('posted') &
              tbl.id.isNotNull() &
              tbl.folio.isNotNull() &
              tbl.warehouseId.isNotNull() &
              tbl.cashierId.isNotNull() &
              tbl.subtotalCents.isNotNull() &
              tbl.taxCents.isNotNull() &
              tbl.totalCents.isNotNull() &
              tbl.createdAt.isNotNull())
          ..orderBy(<OrderingTerm Function(Sales)>[
            (Sales tbl) => OrderingTerm.desc(tbl.createdAt),
          ])
          ..limit(limit))
        .get();

    if (sales.isEmpty) {
      return <RecentSaleStat>[];
    }

    final Set<String> warehouseIds =
        sales.map((Sale sale) => sale.warehouseId).toSet();
    final Set<String> cashierIds =
        sales.map((Sale sale) => sale.cashierId).toSet();

    final List<Warehouse> warehouses = await (_db.select(_db.warehouses)
          ..where((Warehouses tbl) =>
              tbl.id.isIn(warehouseIds) &
              tbl.id.isNotNull() &
              tbl.name.isNotNull() &
              tbl.warehouseType.isNotNull() &
              tbl.isActive.isNotNull() &
              tbl.createdAt.isNotNull()))
        .get();
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) =>
              tbl.id.isIn(cashierIds) &
              tbl.id.isNotNull() &
              tbl.username.isNotNull() &
              tbl.passwordHash.isNotNull() &
              tbl.salt.isNotNull() &
              tbl.role.isNotNull() &
              tbl.isActive.isNotNull() &
              tbl.createdAt.isNotNull()))
        .get();

    final Map<String, Warehouse> whById = <String, Warehouse>{
      for (final Warehouse wh in warehouses) wh.id: wh,
    };
    final Map<String, User> userById = <String, User>{
      for (final User user in users) user.id: user,
    };

    return sales
        .map(
          (Sale sale) => RecentSaleStat(
            saleId: sale.id,
            folio: sale.folio,
            warehouseName: whById[sale.warehouseId]?.name ?? 'Sin almacen',
            cashierUsername:
                userById[sale.cashierId]?.username ?? 'Sin usuario',
            totalCents: sale.totalCents,
            createdAt: sale.createdAt,
          ),
        )
        .toList();
  }

  Future<List<TopProductStat>> _topProducts(DateTime from, int limit) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        COALESCE(p.name, si.product_id) AS product_name,
        COALESCE(p.sku, '-') AS sku,
        COALESCE(SUM(si.qty), 0) AS qty,
        COALESCE(SUM(si.line_total_cents), 0) AS total_cents
      FROM sale_items si
      INNER JOIN sales s
        ON s.id = si.sale_id
      LEFT JOIN products p
        ON p.id = si.product_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
      GROUP BY si.product_id, p.name, p.sku
      ORDER BY qty DESC, total_cents DESC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<int>(limit),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return TopProductStat(
        productName: (row.readNullable<String>('product_name') ?? '-').trim(),
        sku: (row.readNullable<String>('sku') ?? '-').trim(),
        qty: (row.data['qty'] as num?)?.toDouble() ?? 0,
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<AnalyticsTopProductStat>> _topProductsForRange({
    required DateTime from,
    required DateTime toExclusive,
    required DateTime prevFrom,
    required DateTime prevToExclusive,
    required int limit,
  }) async {
    final List<QueryRow> currentRows = await _db.customSelect(
      '''
      SELECT
        si.product_id AS product_id,
        COALESCE(p.name, si.product_id) AS product_name,
        COALESCE(p.sku, '-') AS sku,
        p.image_path AS image_path,
        COALESCE(SUM(si.qty), 0) AS qty,
        COALESCE(SUM(si.line_total_cents), 0) AS total_cents
      FROM sale_items si
      INNER JOIN sales s
        ON s.id = si.sale_id
      LEFT JOIN products p
        ON p.id = si.product_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
      GROUP BY si.product_id, p.name, p.sku, p.image_path
      ORDER BY total_cents DESC, qty DESC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
        Variable<int>(limit),
      ],
    ).get();
    if (currentRows.isEmpty) {
      return <AnalyticsTopProductStat>[];
    }

    final List<String> productIds = currentRows
        .map((QueryRow row) => _readTextCell(row, 'product_id', fallback: ''))
        .where((String id) => id.isNotEmpty)
        .toList(growable: false);
    final Map<String, int> previousTotalsByProduct = <String, int>{};
    if (productIds.isNotEmpty) {
      final List<QueryRow> previousRows = await _db.customSelect(
        '''
        SELECT
          si.product_id AS product_id,
          COALESCE(SUM(si.line_total_cents), 0) AS total_cents
        FROM sale_items si
        INNER JOIN sales s
          ON s.id = si.sale_id
        WHERE s.status = 'posted'
          AND s.created_at >= ?
          AND s.created_at < ?
          AND si.product_id IN (${List<String>.filled(productIds.length, '?').join(', ')})
        GROUP BY si.product_id
        ''',
        variables: <Variable<Object>>[
          Variable<DateTime>(prevFrom),
          Variable<DateTime>(prevToExclusive),
          ...productIds.map((String id) => Variable<String>(id)),
        ],
      ).get();
      for (final QueryRow row in previousRows) {
        final String productId = _readTextCell(row, 'product_id', fallback: '');
        if (productId.isEmpty) {
          continue;
        }
        previousTotalsByProduct[productId] =
            (row.data['total_cents'] as num?)?.toInt() ?? 0;
      }
    }

    return currentRows.map((QueryRow row) {
      final String productId = _readTextCell(row, 'product_id', fallback: '');
      final int total = (row.data['total_cents'] as num?)?.toInt() ?? 0;
      final int previous = previousTotalsByProduct[productId] ?? 0;
      return AnalyticsTopProductStat(
        productId: productId,
        productName: _readTextCell(row, 'product_name', fallback: 'Producto'),
        sku: _readTextCell(row, 'sku', fallback: '-'),
        imagePath: row.readNullable<String>('image_path'),
        qty: (row.data['qty'] as num?)?.toDouble() ?? 0,
        totalCents: total,
        deltaPercent: _pctChange(total, previous),
      );
    }).toList(growable: false);
  }

  Future<double> _itemsSoldQtyForRange({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT COALESCE(SUM(si.qty), 0) AS qty
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
      ],
    ).getSingleOrNull();
    return (row?.data['qty'] as num?)?.toDouble() ?? 0;
  }

  Future<int> _profitCentsForRange({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(si.line_total_cents), 0) AS revenue_cents,
        COALESCE(
          SUM(CAST(ROUND(COALESCE(si.qty, 0) * COALESCE(p.cost_price_cents, 0)) AS INTEGER)),
          0
        ) AS cost_cents
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      LEFT JOIN products p ON p.id = si.product_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
      ],
    ).getSingleOrNull();
    final int revenue = (row?.data['revenue_cents'] as num?)?.toInt() ?? 0;
    final int cost = (row?.data['cost_cents'] as num?)?.toInt() ?? 0;
    return revenue - cost;
  }

  Future<List<SalesBreakdownStat>> _paymentMethodBreakdownForRange({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        LOWER(COALESCE(NULLIF(TRIM(p.method), ''), 'unknown')) AS key,
        COUNT(DISTINCT p.sale_id) AS orders_count,
        COALESCE(SUM(p.amount_cents), 0) AS total_cents
      FROM payments p
      INNER JOIN sales s ON s.id = p.sale_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
      GROUP BY key
      ORDER BY total_cents DESC, orders_count DESC
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
      ],
    ).get();

    return rows.map((QueryRow row) {
      final String key = _readTextCell(row, 'key', fallback: 'unknown');
      return SalesBreakdownStat(
        key: key,
        label: _paymentMethodLabel(key),
        ordersCount: (row.data['orders_count'] as num?)?.toInt() ?? 0,
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);
  }

  Future<List<SalesBreakdownStat>> _cashierBreakdownForRange({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      WITH sale_dependent AS (
        SELECT
          s.id AS sale_id,
          s.total_cents AS total_cents,
          CASE
            WHEN MIN(e.id) IS NOT NULL AND TRIM(MIN(e.id)) <> ''
              THEN 'emp:' || MIN(e.id)
            ELSE 'usr:' || COALESCE(s.cashier_id, '')
          END AS dependent_key,
          COALESCE(
            NULLIF(TRIM(MIN(e.name)), ''),
            COALESCE(u.username, 'Sin usuario')
          ) AS dependent_label
        FROM sales s
        LEFT JOIN users u ON u.id = s.cashier_id
        LEFT JOIN pos_session_employees se ON se.session_id = s.terminal_session_id
        LEFT JOIN employees e ON e.id = se.employee_id
        WHERE s.status = 'posted'
          AND s.created_at >= ?
          AND s.created_at < ?
        GROUP BY s.id, s.total_cents, s.cashier_id, u.username
      )
      SELECT
        sd.dependent_key AS key,
        sd.dependent_label AS label,
        COUNT(*) AS orders_count,
        COALESCE(SUM(sd.total_cents), 0) AS total_cents
      FROM sale_dependent sd
      GROUP BY sd.dependent_key, sd.dependent_label
      ORDER BY total_cents DESC, orders_count DESC
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return SalesBreakdownStat(
        key: _readTextCell(row, 'key', fallback: '-'),
        label: _readTextCell(row, 'label', fallback: 'Sin usuario'),
        ordersCount: (row.data['orders_count'] as num?)?.toInt() ?? 0,
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);
  }

  Future<List<SalesBreakdownStat>> _warehouseBreakdownForRange({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        s.warehouse_id AS key,
        COALESCE(w.name, 'Sin almacén') AS label,
        COUNT(*) AS orders_count,
        COALESCE(SUM(s.total_cents), 0) AS total_cents
      FROM sales s
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
      GROUP BY s.warehouse_id, w.name
      ORDER BY total_cents DESC, orders_count DESC
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return SalesBreakdownStat(
        key: _readTextCell(row, 'key', fallback: '-'),
        label: _readTextCell(row, 'label', fallback: 'Sin almacén'),
        ordersCount: (row.data['orders_count'] as num?)?.toInt() ?? 0,
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);
  }

  Future<List<AnalyticsTopCustomerStat>> _topCustomersForRange({
    required DateTime from,
    required DateTime toExclusive,
    required int limit,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        s.customer_id AS customer_id,
        COALESCE(c.full_name, 'Cliente') AS customer_name,
        COALESCE(c.customer_type, 'general') AS customer_type,
        COUNT(*) AS orders_count,
        COALESCE(SUM(s.total_cents), 0) AS total_cents,
        MAX(s.created_at) AS last_sale_at
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE s.status = 'posted'
        AND s.created_at >= ?
        AND s.created_at < ?
        AND s.customer_id IS NOT NULL
        AND TRIM(s.customer_id) <> ''
      GROUP BY s.customer_id, c.full_name, c.customer_type
      ORDER BY total_cents DESC, orders_count DESC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[
        Variable<DateTime>(from),
        Variable<DateTime>(toExclusive),
        Variable<int>(limit),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return AnalyticsTopCustomerStat(
        customerId: _readTextCell(row, 'customer_id', fallback: '-'),
        name: _readTextCell(row, 'customer_name', fallback: 'Cliente'),
        customerType: _readTextCell(row, 'customer_type', fallback: 'general'),
        ordersCount: (row.data['orders_count'] as num?)?.toInt() ?? 0,
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
        lastSaleAt: _readDateCell(row.data['last_sale_at']),
      );
    }).toList(growable: false);
  }

  List<SalesTrendPointStat> _buildTrend({
    required List<Sale> sales,
    required SalesAnalyticsGranularity granularity,
    required DateTime from,
    required DateTime toExclusive,
  }) {
    if (!toExclusive.isAfter(from)) {
      return <SalesTrendPointStat>[];
    }
    final _TrendGrouping grouping = _trendGroupingFor(granularity);
    final DateTime start = _normalizeTrendBucketStart(from, grouping);
    final DateTime end = _normalizeTrendBucketStart(
      toExclusive.subtract(const Duration(milliseconds: 1)),
      grouping,
    );

    final Map<String, _TrendBucket> byKey = <String, _TrendBucket>{};
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      final String key = cursor.toIso8601String();
      byKey[key] = _TrendBucket(
        bucketStart: cursor,
        label: _bucketLabel(cursor, grouping),
      );
      cursor = _nextTrendBucket(cursor, grouping);
    }

    for (final Sale sale in sales) {
      final DateTime dt = sale.createdAt.toLocal();
      final DateTime bucketStart = _normalizeTrendBucketStart(dt, grouping);
      final String key = bucketStart.toIso8601String();
      final _TrendBucket? bucket = byKey[key];
      if (bucket == null) {
        continue;
      }
      bucket.totalCents += sale.totalCents;
      bucket.ordersCount += 1;
    }

    final List<_TrendBucket> rows = byKey.values.toList()
      ..sort((_TrendBucket a, _TrendBucket b) {
        return a.bucketStart.compareTo(b.bucketStart);
      });
    return rows
        .map(
          (_TrendBucket row) => SalesTrendPointStat(
            bucketStart: row.bucketStart,
            label: row.label,
            totalCents: row.totalCents,
            ordersCount: row.ordersCount,
          ),
        )
        .toList(growable: false);
  }

  _TrendGrouping _trendGroupingFor(SalesAnalyticsGranularity granularity) {
    switch (granularity) {
      case SalesAnalyticsGranularity.day:
        return _TrendGrouping.hour;
      case SalesAnalyticsGranularity.week:
      case SalesAnalyticsGranularity.month:
        return _TrendGrouping.day;
      case SalesAnalyticsGranularity.year:
        return _TrendGrouping.month;
    }
  }

  DateTime _normalizeTrendBucketStart(DateTime dt, _TrendGrouping grouping) {
    switch (grouping) {
      case _TrendGrouping.hour:
        return DateTime(dt.year, dt.month, dt.day, dt.hour);
      case _TrendGrouping.day:
        return DateTime(dt.year, dt.month, dt.day);
      case _TrendGrouping.month:
        return DateTime(dt.year, dt.month, 1);
    }
  }

  DateTime _nextTrendBucket(DateTime start, _TrendGrouping grouping) {
    switch (grouping) {
      case _TrendGrouping.hour:
        return start.add(const Duration(hours: 1));
      case _TrendGrouping.day:
        return start.add(const Duration(days: 1));
      case _TrendGrouping.month:
        return DateTime(start.year, start.month + 1, 1);
    }
  }

  String _bucketLabel(DateTime dt, _TrendGrouping grouping) {
    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    switch (grouping) {
      case _TrendGrouping.hour:
        final String hour = dt.hour.toString().padLeft(2, '0');
        return '$hour:00';
      case _TrendGrouping.day:
        final String day = dt.day.toString().padLeft(2, '0');
        return '$day ${months[dt.month - 1]}';
      case _TrendGrouping.month:
        return months[dt.month - 1];
    }
  }

  double _pctChange(int current, int previous) {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }

  Future<List<RecentSessionClosureStat>> _recentSessionClosures(
      int limit) async {
    final List<PosSession> sessions = await (_db.select(_db.posSessions)
          ..where((PosSessions tbl) =>
              tbl.status.equals('closed') &
              tbl.id.isNotNull() &
              tbl.terminalId.isNotNull() &
              tbl.userId.isNotNull() &
              tbl.openedAt.isNotNull() &
              tbl.closedAt.isNotNull())
          ..orderBy(<OrderingTerm Function(PosSessions)>[
            (PosSessions tbl) => OrderingTerm.desc(tbl.closedAt),
          ])
          ..limit(limit))
        .get();
    if (sessions.isEmpty) {
      return <RecentSessionClosureStat>[];
    }

    final Set<String> terminalIds =
        sessions.map((PosSession session) => session.terminalId).toSet();
    final Set<String> userIds =
        sessions.map((PosSession session) => session.userId).toSet();
    final Set<String> sessionIds =
        sessions.map((PosSession session) => session.id).toSet();

    final List<PosTerminal> terminals = await (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.id.isIn(terminalIds)))
        .get();
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.isIn(userIds)))
        .get();
    final List<PosSessionCashBreakdown> breakdownRows =
        await (_db.select(_db.posSessionCashBreakdowns)
              ..where((PosSessionCashBreakdowns tbl) =>
                  tbl.sessionId.isIn(sessionIds))
              ..orderBy(<OrderingTerm Function(PosSessionCashBreakdowns)>[
                (PosSessionCashBreakdowns tbl) =>
                    OrderingTerm.desc(tbl.denominationCents),
              ]))
            .get();

    final Map<String, PosTerminal> terminalById = <String, PosTerminal>{
      for (final PosTerminal terminal in terminals) terminal.id: terminal,
    };
    final Map<String, User> userById = <String, User>{
      for (final User user in users) user.id: user,
    };
    final Map<String, List<SessionClosureBreakdownStat>> breakdownBySessionId =
        <String, List<SessionClosureBreakdownStat>>{};
    for (final PosSessionCashBreakdown row in breakdownRows) {
      breakdownBySessionId
          .putIfAbsent(row.sessionId, () => <SessionClosureBreakdownStat>[])
          .add(
            SessionClosureBreakdownStat(
              denominationCents: row.denominationCents,
              unitCount: row.unitCount,
              subtotalCents: row.subtotalCents,
            ),
          );
    }

    final List<RecentSessionClosureStat> result = <RecentSessionClosureStat>[];
    for (final PosSession session in sessions) {
      final DateTime? closedAt = session.closedAt;
      if (closedAt == null) {
        continue;
      }

      final PosTerminal? terminal = terminalById[session.terminalId];
      final User? user = userById[session.userId];
      final List<SessionClosureBreakdownStat> breakdown =
          breakdownBySessionId[session.id] ?? <SessionClosureBreakdownStat>[];
      final int breakdownTotal = breakdown.fold<int>(
        0,
        (int sum, SessionClosureBreakdownStat item) => sum + item.subtotalCents,
      );

      result.add(
        RecentSessionClosureStat(
          sessionId: session.id,
          terminalName: terminal?.name ?? 'TPV',
          cashierUsername: user?.username ?? 'Usuario',
          currencySymbol: terminal?.currencySymbol ?? r'$',
          closedAt: closedAt,
          closingCashCents: session.closingCashCents ?? breakdownTotal,
          breakdown: breakdown,
        ),
      );
    }
    return result;
  }

  Future<List<PosTerminal>> listIpvTerminalOptions() {
    return (_db.select(_db.posTerminals)
          ..where((PosTerminals tbl) => tbl.isActive.equals(true))
          ..orderBy(<OrderingTerm Function(PosTerminals)>[
            (PosTerminals tbl) => OrderingTerm.asc(tbl.name),
          ]))
        .get();
  }

  Future<List<IpvReportSummaryStat>> listIpvReports({
    String? terminalId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
    bool includeOpen = false,
  }) async {
    final String? safeTerminalId =
        (terminalId ?? '').trim().isEmpty ? null : terminalId!.trim();
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        r.id AS report_id,
        r.session_id AS session_id,
        r.opened_at AS opened_at,
        r.closed_at AS closed_at,
        r.status AS status,
        r.opening_source AS opening_source,
        t.name AS terminal_name,
        t.currency_symbol AS currency_symbol,
        COUNT(l.product_id) AS line_count,
        COALESCE(
          SUM(CAST(ROUND(COALESCE(l.sales_qty, 0) * COALESCE(l.sale_price_cents, 0)) AS INTEGER)),
          0
        ) AS total_amount_cents
      FROM ipv_reports r
      LEFT JOIN pos_terminals t
        ON t.id = r.terminal_id
      LEFT JOIN ipv_report_lines l
        ON l.report_id = r.id
      WHERE 1 = 1
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (!includeOpen) {
      sql.write(' AND r.status = \'closed\' AND r.closed_at IS NOT NULL');
    }
    if (safeTerminalId != null) {
      sql.write(' AND r.terminal_id = ?');
      variables.add(Variable<String>(safeTerminalId));
    }
    if (fromDate != null) {
      final DateTime from =
          DateTime(fromDate.year, fromDate.month, fromDate.day);
      sql.write(' AND COALESCE(r.closed_at, r.opened_at) >= ?');
      variables.add(Variable<DateTime>(from));
    }
    if (toDate != null) {
      final DateTime toExclusive = DateTime(
        toDate.year,
        toDate.month,
        toDate.day + 1,
      );
      sql.write(' AND COALESCE(r.closed_at, r.opened_at) < ?');
      variables.add(Variable<DateTime>(toExclusive));
    }
    sql.write(
      '''
      GROUP BY
        r.id,
        r.session_id,
        r.opened_at,
        r.closed_at,
        r.status,
        r.opening_source,
        t.name,
        t.currency_symbol
      ORDER BY COALESCE(r.closed_at, r.opened_at) DESC
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

    return rows.map((QueryRow row) {
      return IpvReportSummaryStat(
        reportId: row.read<String>('report_id'),
        sessionId: row.read<String>('session_id'),
        terminalName:
            (row.readNullable<String>('terminal_name') ?? 'TPV').trim(),
        currencySymbol:
            (row.readNullable<String>('currency_symbol') ?? r'$').trim(),
        openedAt: row.read<DateTime>('opened_at'),
        closedAt: row.readNullable<DateTime>('closed_at'),
        status: (row.readNullable<String>('status') ?? 'open').trim(),
        openingSource:
            (row.readNullable<String>('opening_source') ?? '').trim(),
        lineCount: (row.data['line_count'] as num?)?.toInt() ?? 0,
        totalAmountCents:
            (row.data['total_amount_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<IpvReportSummaryStat?> findIpvReportBySessionId(
    String sessionId, {
    bool includeOpen = true,
  }) async {
    final String id = sessionId.trim();
    if (id.isEmpty) {
      return null;
    }
    final List<IpvReportSummaryStat> exact = await _listIpvReportsBySessionId(
      id,
      includeOpen: includeOpen,
    );
    if (exact.isEmpty) {
      return null;
    }
    return exact.first;
  }

  Future<List<IpvReportSummaryStat>> _listIpvReportsBySessionId(
    String sessionId, {
    bool includeOpen = true,
  }) async {
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        r.id AS report_id,
        r.session_id AS session_id,
        r.opened_at AS opened_at,
        r.closed_at AS closed_at,
        r.status AS status,
        r.opening_source AS opening_source,
        t.name AS terminal_name,
        t.currency_symbol AS currency_symbol,
        COUNT(l.product_id) AS line_count,
        COALESCE(
          SUM(CAST(ROUND(COALESCE(l.sales_qty, 0) * COALESCE(l.sale_price_cents, 0)) AS INTEGER)),
          0
        ) AS total_amount_cents
      FROM ipv_reports r
      LEFT JOIN pos_terminals t
        ON t.id = r.terminal_id
      LEFT JOIN ipv_report_lines l
        ON l.report_id = r.id
      WHERE r.session_id = ?
      ''',
    );
    if (!includeOpen) {
      sql.write(' AND r.status = \'closed\'');
    }
    sql.write(
      '''
      GROUP BY
        r.id,
        r.session_id,
        r.opened_at,
        r.closed_at,
        r.status,
        r.opening_source,
        t.name,
        t.currency_symbol
      ORDER BY COALESCE(r.closed_at, r.opened_at) DESC
      LIMIT 1
      ''',
    );
    final List<QueryRow> rows = await _db.customSelect(
      sql.toString(),
      variables: <Variable<Object>>[Variable<String>(sessionId)],
    ).get();

    return rows.map((QueryRow row) {
      return IpvReportSummaryStat(
        reportId: row.read<String>('report_id'),
        sessionId: row.read<String>('session_id'),
        terminalName:
            (row.readNullable<String>('terminal_name') ?? 'TPV').trim(),
        currencySymbol:
            (row.readNullable<String>('currency_symbol') ?? r'$').trim(),
        openedAt: row.read<DateTime>('opened_at'),
        closedAt: row.readNullable<DateTime>('closed_at'),
        status: (row.readNullable<String>('status') ?? 'open').trim(),
        openingSource:
            (row.readNullable<String>('opening_source') ?? '').trim(),
        lineCount: (row.data['line_count'] as num?)?.toInt() ?? 0,
        totalAmountCents:
            (row.data['total_amount_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<IpvReportDetailStat?> loadIpvReportDetail(String reportId) async {
    final String id = reportId.trim();
    if (id.isEmpty) {
      return null;
    }
    final QueryRow? header = await _db.customSelect(
      '''
      SELECT
        r.id AS report_id,
        r.session_id AS session_id,
        r.terminal_id AS terminal_id,
        r.warehouse_id AS warehouse_id,
        r.opened_at AS opened_at,
        r.closed_at AS closed_at,
        r.status AS status,
        r.opening_source AS opening_source,
        t.name AS terminal_name,
        t.currency_symbol AS currency_symbol
      FROM ipv_reports r
      LEFT JOIN pos_terminals t
        ON t.id = r.terminal_id
      WHERE r.id = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).getSingleOrNull();
    if (header == null) {
      return null;
    }

    final DateTime openedAt = header.read<DateTime>('opened_at');
    final DateTime? closedAt = header.readNullable<DateTime>('closed_at');
    final String status =
        (header.readNullable<String>('status') ?? 'open').trim().toLowerCase();

    final List<QueryRow> baseLineRows = await _db.customSelect(
      '''
      SELECT
        report_id,
        product_id,
        COALESCE(product_name_snapshot, '') AS product_name_snapshot,
        COALESCE(product_sku_snapshot, '') AS product_sku_snapshot,
        COALESCE(start_qty, 0) AS start_qty,
        COALESCE(entries_qty, 0) AS entries_qty,
        COALESCE(outputs_qty, 0) AS outputs_qty,
        COALESCE(sales_qty, 0) AS sales_qty,
        COALESCE(final_qty, 0) AS final_qty,
        COALESCE(sale_price_cents, 0) AS sale_price_cents,
        COALESCE(total_amount_cents, 0) AS total_amount_cents
      FROM ipv_report_lines
      WHERE report_id = ?
      ''',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();

    // Closed IPV reports are immutable snapshots.
    // They must always reflect persisted lines, regardless of later stock changes.
    if (status == 'closed') {
      return _buildClosedIpvDetailFromSnapshot(
        header: header,
        reportId: id,
        openedAt: openedAt,
        closedAt: closedAt,
        status: status,
        baseLineRows: baseLineRows,
      );
    }

    final String terminalId = _readTextCell(
      header,
      'terminal_id',
      fallback: '',
    );
    final String warehouseId = _readTextCell(
      header,
      'warehouse_id',
      fallback: '',
    );
    final DateTime movementStart = terminalId.isEmpty
        ? openedAt
        : await _resolveIpvMovementStart(
            terminalId: terminalId,
            openedAt: openedAt,
            currentReportId: id,
          );
    final DateTime movementEnd = closedAt ?? DateTime.now();
    final Map<String, _IpvAgg> byProduct = <String, _IpvAgg>{
      for (final QueryRow row in baseLineRows)
        if (_readTextCell(row, 'product_id', fallback: '').isNotEmpty)
          _readTextCell(row, 'product_id', fallback: ''): _IpvAgg(
            startQty: (row.data['start_qty'] as num?)?.toDouble() ?? 0,
            salePriceCents:
                (row.data['sale_price_cents'] as num?)?.toInt() ?? 0,
          ),
    };

    final bool includeStartBoundary = movementStart.isAtSameMomentAs(openedAt);

    final List<QueryRow> movementRows = warehouseId.isEmpty
        ? <QueryRow>[]
        : await _db.customSelect(
            '''
            SELECT
              sm.product_id AS product_id,
              COALESCE(SUM(
                CASE
                  WHEN (
                    (sm.type = 'in')
                    OR (sm.type = 'adjust' AND sm.qty >= 0)
                  )
                  AND LOWER(COALESCE(sm.reason_code, '')) <> 'sale'
                    THEN ABS(sm.qty)
                  ELSE 0
                END
              ), 0) AS entries_qty,
              COALESCE(SUM(
                CASE
                  WHEN (
                    (sm.type = 'out')
                    OR (sm.type = 'adjust' AND sm.qty < 0)
                  )
                  AND NOT (
                    (
                      LOWER(COALESCE(sm.reason_code, '')) = 'sale'
                      OR LOWER(COALESCE(sm.ref_type, '')) IN ('sale', 'sale_pos', 'sale_direct')
                      OR LOWER(COALESCE(sm.movement_source, '')) IN ('pos', 'direct_sale')
                    )
                    AND LOWER(COALESCE(sm.reason_code, '')) <> 'consignment_sale'
                    AND LOWER(COALESCE(sm.ref_type, '')) NOT IN (
                      'consignment_sale',
                      'consignment_sale_pos',
                      'consignment_sale_direct'
                    )
                    AND LOWER(COALESCE(sm.movement_source, '')) NOT IN (
                      'pos_consignment',
                      'direct_consignment'
                    )
                  )
                    THEN ABS(sm.qty)
                  ELSE 0
                END
              ), 0) AS outputs_qty,
              COALESCE(SUM(
                CASE
                  WHEN (
                    (sm.type = 'out')
                    OR (sm.type = 'adjust' AND sm.qty < 0)
                  )
                  AND (
                    (
                      LOWER(COALESCE(sm.reason_code, '')) = 'sale'
                      OR LOWER(COALESCE(sm.ref_type, '')) IN ('sale', 'sale_pos', 'sale_direct')
                      OR LOWER(COALESCE(sm.movement_source, '')) IN ('pos', 'direct_sale')
                    )
                    AND LOWER(COALESCE(sm.reason_code, '')) <> 'consignment_sale'
                    AND LOWER(COALESCE(sm.ref_type, '')) NOT IN (
                      'consignment_sale',
                      'consignment_sale_pos',
                      'consignment_sale_direct'
                    )
                    AND LOWER(COALESCE(sm.movement_source, '')) NOT IN (
                      'pos_consignment',
                      'direct_consignment'
                    )
                  )
                    THEN ABS(sm.qty)
                  ELSE 0
                END
              ), 0) AS sales_qty
            FROM stock_movements sm
            WHERE sm.warehouse_id = ?
              AND sm.created_at ${includeStartBoundary ? '>=' : '>'} ?
              AND sm.created_at <= ?
              AND COALESCE(sm.is_voided, 0) = 0
            GROUP BY sm.product_id
            ''',
            variables: <Variable<Object>>[
              Variable<String>(warehouseId),
              Variable<DateTime>(movementStart),
              Variable<DateTime>(movementEnd),
            ],
          ).get();
    for (final QueryRow row in movementRows) {
      final String productId = _readTextCell(row, 'product_id', fallback: '');
      if (productId.isEmpty) {
        continue;
      }
      final _IpvAgg agg = byProduct.putIfAbsent(productId, () => _IpvAgg());
      agg.entriesQty = (row.data['entries_qty'] as num?)?.toDouble() ?? 0;
      agg.outputsQty = (row.data['outputs_qty'] as num?)?.toDouble() ?? 0;
      agg.salesQty = (row.data['sales_qty'] as num?)?.toDouble() ?? 0;
    }
    final Map<String, _IpvProductSnapshot> productById =
        await _loadIpvProductSnapshots(byProduct.keys.toSet());

    int totalAmountCents = 0;
    final List<IpvReportLineStat> lines = <IpvReportLineStat>[];
    for (final String productId in byProduct.keys) {
      final _IpvAgg agg = byProduct[productId]!;
      final _IpvProductSnapshot? product = productById[productId];
      final int salePriceCents = agg.salePriceCents ?? product?.priceCents ?? 0;
      final double finalQty =
          agg.startQty + agg.entriesQty - agg.outputsQty - agg.salesQty;
      final int amountCents = (agg.salesQty * salePriceCents).round();
      totalAmountCents += amountCents;
      lines.add(
        IpvReportLineStat(
          productId: productId,
          productName: product?.name ?? 'Producto',
          sku: product?.sku ?? '-',
          startQty: agg.startQty,
          entriesQty: agg.entriesQty,
          outputsQty: agg.outputsQty,
          salesQty: agg.salesQty,
          finalQty: finalQty,
          salePriceCents: salePriceCents,
          totalAmountCents: amountCents,
        ),
      );
    }
    lines.sort((IpvReportLineStat a, IpvReportLineStat b) {
      return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
    });

    final IpvReportSummaryStat summary = IpvReportSummaryStat(
      reportId: id,
      sessionId: _readTextCell(header, 'session_id', fallback: '-'),
      terminalName:
          (header.readNullable<String>('terminal_name') ?? 'TPV').trim(),
      currencySymbol:
          (header.readNullable<String>('currency_symbol') ?? r'$').trim(),
      openedAt: openedAt,
      closedAt: closedAt,
      status: status,
      openingSource:
          (header.readNullable<String>('opening_source') ?? '').trim(),
      lineCount: lines.length,
      totalAmountCents: totalAmountCents,
    );
    return IpvReportDetailStat(summary: summary, lines: lines);
  }

  Future<IpvReportDetailStat> _buildClosedIpvDetailFromSnapshot({
    required QueryRow header,
    required String reportId,
    required DateTime openedAt,
    required DateTime? closedAt,
    required String status,
    required List<QueryRow> baseLineRows,
  }) async {
    int totalAmountCents = 0;
    final List<IpvReportLineStat> lines = <IpvReportLineStat>[];
    for (final QueryRow row in baseLineRows) {
      final String productId = _readTextCell(row, 'product_id', fallback: '');
      if (productId.isEmpty) {
        continue;
      }
      final double startQty = (row.data['start_qty'] as num?)?.toDouble() ?? 0;
      final double entriesQty =
          (row.data['entries_qty'] as num?)?.toDouble() ?? 0;
      final double outputsQty =
          (row.data['outputs_qty'] as num?)?.toDouble() ?? 0;
      final double salesQty = (row.data['sales_qty'] as num?)?.toDouble() ?? 0;
      final double finalQty = (row.data['final_qty'] as num?)?.toDouble() ??
          (startQty + entriesQty - outputsQty - salesQty);
      final int salePriceCents =
          (row.data['sale_price_cents'] as num?)?.toInt() ?? 0;
      final int amountCents =
          (row.data['total_amount_cents'] as num?)?.toInt() ??
              (salesQty * salePriceCents).round();
      totalAmountCents += amountCents;

      final String snapshotName =
          _readTextCell(row, 'product_name_snapshot', fallback: '');
      final String snapshotSku =
          _readTextCell(row, 'product_sku_snapshot', fallback: '');
      lines.add(
        IpvReportLineStat(
          productId: productId,
          productName: snapshotName.isNotEmpty ? snapshotName : 'Producto',
          sku: snapshotSku.isNotEmpty ? snapshotSku : '-',
          startQty: startQty,
          entriesQty: entriesQty,
          outputsQty: outputsQty,
          salesQty: salesQty,
          finalQty: finalQty,
          salePriceCents: salePriceCents,
          totalAmountCents: amountCents,
        ),
      );
    }
    lines.sort((IpvReportLineStat a, IpvReportLineStat b) {
      return a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
    });

    final IpvReportSummaryStat summary = IpvReportSummaryStat(
      reportId: reportId,
      sessionId: _readTextCell(header, 'session_id', fallback: '-'),
      terminalName:
          (header.readNullable<String>('terminal_name') ?? 'TPV').trim(),
      currencySymbol:
          (header.readNullable<String>('currency_symbol') ?? r'$').trim(),
      openedAt: openedAt,
      closedAt: closedAt,
      status: status,
      openingSource:
          (header.readNullable<String>('opening_source') ?? '').trim(),
      lineCount: lines.length,
      totalAmountCents: totalAmountCents,
    );
    return IpvReportDetailStat(summary: summary, lines: lines);
  }

  Future<DateTime> _resolveIpvMovementStart({
    required String terminalId,
    required DateTime openedAt,
    required String currentReportId,
  }) async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT r.closed_at AS closed_at
      FROM ipv_reports r
      WHERE r.terminal_id = ?
        AND r.status = 'closed'
        AND r.closed_at IS NOT NULL
        AND r.id <> ?
        AND r.closed_at <= ?
      ORDER BY r.closed_at DESC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(terminalId),
        Variable<String>(currentReportId),
        Variable<DateTime>(openedAt),
      ],
    ).getSingleOrNull();
    return row?.read<DateTime>('closed_at') ?? openedAt;
  }

  Future<String> exportSalesAnalyticsCsv({
    required DateTime fromDate,
    required DateTime toDate,
    required SalesAnalyticsGranularity granularity,
    required String currencySymbol,
    int topLimit = 20,
  }) async {
    await _licenseService.requireFullAccess(
      message: _demoAnalyticsExportBlockedMessage,
    );
    final SalesAnalyticsSnapshot snapshot = await loadSalesAnalytics(
      fromDate: fromDate,
      toDate: toDate,
      granularity: granularity,
      topLimit: topLimit,
    );
    final DateTime now = DateTime.now();
    final Directory preferredBase = await _resolveDownloadsBaseDir();
    Directory dir =
        Directory(p.join(preferredBase.path, 'Reportes', 'Analiticas'));
    try {
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    } catch (_) {
      final Directory docs = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docs.path, 'exports', 'Reportes', 'Analiticas'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }

    final String fromTag = _dayKey(snapshot.fromDate).replaceAll('-', '');
    final String toTag = _dayKey(snapshot.toDate).replaceAll('-', '');
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    final String ss = now.second.toString().padLeft(2, '0');
    final String fileName =
        'analiticas_${fromTag}_${toTag}_${granularity.name}_$hh$mm$ss.csv';
    final File file = File(p.join(dir.path, fileName));

    final StringBuffer csv = StringBuffer()
      ..writeln('Reporte,Analitica de Ventas')
      ..writeln('Generado,${_csvCell(_formatDateTimeHuman(now))}')
      ..writeln('Periodo,${_csvCell(_analyticsGranularityLabel(granularity))}')
      ..writeln(
        'Rango,${_csvCell('${_dayKey(snapshot.fromDate)} - ${_dayKey(snapshot.toDate)}')}',
      )
      ..writeln('Moneda,${_csvCell(currencySymbol)}')
      ..writeln('Ventas (órdenes),${snapshot.ordersCount}')
      ..writeln('Unidades vendidas,${snapshot.itemsSoldQty.toStringAsFixed(2)}')
      ..writeln('Clientes únicos,${snapshot.uniqueCustomersCount}')
      ..writeln('Ventas sin cliente,${snapshot.salesWithoutCustomerCount}')
      ..writeln(
        'Ingresos totales,${(snapshot.totalRevenueCents / 100).toStringAsFixed(2)}',
      )
      ..writeln(
        'Ganancia total,${(snapshot.totalProfitCents / 100).toStringAsFixed(2)}',
      )
      ..writeln(
        'Pedido promedio,${(snapshot.avgOrderCents / 100).toStringAsFixed(2)}',
      )
      ..writeln(
        'Variacion ingresos (%),${snapshot.totalRevenueDeltaPercent.toStringAsFixed(2)}',
      )
      ..writeln(
        'Variacion ticket promedio (%),${snapshot.avgOrderDeltaPercent.toStringAsFixed(2)}',
      )
      ..writeln(
        'Canal POS (ventas),${snapshot.posOrdersCount}',
      )
      ..writeln(
        'Canal POS (importe),${(snapshot.posRevenueCents / 100).toStringAsFixed(2)}',
      )
      ..writeln(
        'Canal Directa (ventas),${snapshot.directOrdersCount}',
      )
      ..writeln(
        'Canal Directa (importe),${(snapshot.directRevenueCents / 100).toStringAsFixed(2)}',
      )
      ..writeln('')
      ..writeln('Tendencia (${_analyticsGranularityLabel(granularity)})')
      ..writeln('Etiqueta,Pedidos,Importe');

    for (final SalesTrendPointStat point in snapshot.trend) {
      csv.writeln(
        '${_csvCell(point.label)},${point.ordersCount},${(point.totalCents / 100).toStringAsFixed(2)}',
      );
    }

    csv
      ..writeln('')
      ..writeln('Productos destacados')
      ..writeln('Producto,SKU,Cantidad,Importe,Variacion (%)');
    for (final AnalyticsTopProductStat product in snapshot.topProducts) {
      csv.writeln(
        '${_csvCell(product.productName)},${_csvCell(product.sku)},${product.qty.toStringAsFixed(2)},${(product.totalCents / 100).toStringAsFixed(2)},${product.deltaPercent.toStringAsFixed(2)}',
      );
    }

    csv
      ..writeln('')
      ..writeln('Metodo de pago')
      ..writeln('Metodo,Ventas,Importe');
    for (final SalesBreakdownStat row in snapshot.paymentMethods) {
      csv.writeln(
        '${_csvCell(row.label)},${row.ordersCount},${(row.totalCents / 100).toStringAsFixed(2)}',
      );
    }

    csv
      ..writeln('')
      ..writeln('Ventas por Cajero')
      ..writeln('Cajero,Ventas,Importe');
    for (final SalesBreakdownStat row in snapshot.byCashier) {
      csv.writeln(
        '${_csvCell(row.label)},${row.ordersCount},${(row.totalCents / 100).toStringAsFixed(2)}',
      );
    }

    csv
      ..writeln('')
      ..writeln('Ventas por Almacen')
      ..writeln('Almacen,Ventas,Importe');
    for (final SalesBreakdownStat row in snapshot.byWarehouse) {
      csv.writeln(
        '${_csvCell(row.label)},${row.ordersCount},${(row.totalCents / 100).toStringAsFixed(2)}',
      );
    }

    csv
      ..writeln('')
      ..writeln('Top Clientes')
      ..writeln('Cliente,Tipo,Ventas,Importe,Ultima compra');
    for (final AnalyticsTopCustomerStat row in snapshot.topCustomers) {
      csv.writeln(
        '${_csvCell(row.name)},${_csvCell(row.customerType)},${row.ordersCount},${(row.totalCents / 100).toStringAsFixed(2)},${_csvCell(row.lastSaleAt == null ? "-" : _formatDateTimeHuman(row.lastSaleAt!))}',
      );
    }

    await file.writeAsString(csv.toString(), encoding: utf8, flush: true);
    return file.path;
  }

  Future<String> exportIpvReportCsv(String reportId) async {
    await _licenseService.requireFullAccess(
      message: _demoIpvExportBlockedMessage,
    );
    try {
      final IpvReportDetailStat? detail = await loadIpvReportDetail(reportId);
      if (detail == null) {
        throw Exception('No se encontro el IPV solicitado.');
      }
      final _IpvExportMeta meta = await _loadIpvExportMeta(reportId);
      final Directory baseDir = await _resolveExportDir(detail.summary);
      final String fileName = _buildIpvExportFileName(
        detail.summary,
        extension: 'csv',
      );
      final File file = File(p.join(baseDir.path, fileName));

      final _IpvExecutiveSummary executive = _buildIpvExecutiveSummary(detail);
      final StringBuffer csv = StringBuffer()
        ..writeln('Reporte,IPV')
        ..writeln('TPV,${_csvCell(detail.summary.terminalName)}')
        ..writeln('TPV ID,${_csvCell(meta.terminalId)}')
        ..writeln('Almacen,${_csvCell(meta.warehouseName)}')
        ..writeln('Almacen ID,${_csvCell(meta.warehouseId)}')
        ..writeln('Sesion,${_csvCell(detail.summary.sessionId)}')
        ..writeln('Empleado,${_csvCell(meta.employeesLabel)}')
        ..writeln('Estado,${_csvCell(detail.summary.status)}')
        ..writeln(
            'Apertura,${_csvCell(_formatDateTimeHuman(detail.summary.openedAt))}')
        ..writeln(
          'Cierre,${_csvCell(detail.summary.closedAt == null ? '-' : _formatDateTimeHuman(detail.summary.closedAt!))}',
        )
        ..writeln('Moneda,${_csvCell(detail.summary.currencySymbol)}')
        ..writeln('Total ventas,${_formatQtyCsv(executive.totalSalesQty)}')
        ..writeln('Total entradas,${_formatQtyCsv(executive.totalEntriesQty)}')
        ..writeln('Total salidas,${_formatQtyCsv(executive.totalOutputsQty)}')
        ..writeln(
          'Importe total,${(executive.totalSalesAmountCents / 100).toStringAsFixed(2)}',
        )
        ..writeln('');
      if (meta.paymentTotalsByMethod.isNotEmpty) {
        csv.writeln('Metodo,Monto');
        for (final MapEntry<String, int> entry
            in meta.paymentTotalsByMethod.entries) {
          csv.writeln(
            '${_csvCell(_paymentMethodLabel(entry.key))},${(entry.value / 100).toStringAsFixed(2)}',
          );
        }
        csv.writeln('');
      }
      csv.writeln(
        'Producto,Cod,Ini,Ent,Sal,Ven,Tot,Fin,Precio,Importe',
      );
      for (final IpvReportLineStat row in detail.lines) {
        final double totalBeforeSales =
            row.startQty + row.entriesQty - row.outputsQty;
        final int salesAmountCents =
            (row.salesQty * row.salePriceCents).round();
        csv.writeln(
          '${_csvCell(row.productName)},${_csvCell(row.sku)},${_formatQtyCsv(row.startQty)},${_formatQtyCsv(row.entriesQty)},${_formatQtyCsv(row.outputsQty)},${_formatQtyCsv(row.salesQty)},${_formatQtyCsv(totalBeforeSales)},${_formatQtyCsv(row.finalQty)},${(row.salePriceCents / 100).toStringAsFixed(2)},${(salesAmountCents / 100).toStringAsFixed(2)}',
        );
      }
      csv.writeln(
        ',,,,,,,,TOTAL IMPORTE,${(executive.totalSalesAmountCents / 100).toStringAsFixed(2)}',
      );

      await file.writeAsString(csv.toString(), encoding: utf8, flush: true);
      return file.path;
    } catch (e, st) {
      await _writeIpvExportDiagnostic(
        reportId: reportId,
        format: 'csv',
        error: e,
        stackTrace: st,
      );
      stderr.writeln('IPV CSV export failed. reportId=$reportId error=$e');
      stderr.writeln(st);
      rethrow;
    }
  }

  Future<String> exportIpvReportPdf(String reportId) async {
    await _licenseService.requireFullAccess(
      message: _demoIpvExportBlockedMessage,
    );
    try {
      final IpvReportDetailStat? loaded = await loadIpvReportDetail(reportId);
      if (loaded == null) {
        throw Exception('No se encontro el IPV solicitado.');
      }
      final IpvReportDetailStat detail = loaded;
      final _IpvExportMeta meta = await _loadIpvExportMeta(reportId);
      final Directory baseDir = await _resolveExportDir(detail.summary);
      final String fileName = _buildIpvExportFileName(
        detail.summary,
        extension: 'pdf',
      );
      final File file = File(p.join(baseDir.path, fileName));
      final String generatedAt = _formatDateTimeHuman(DateTime.now());

      final pw.Document doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
          header: (pw.Context context) => _buildIpvPdfHeader(
            generatedAt: generatedAt,
            pageNumber: context.pageNumber,
          ),
          build: (pw.Context context) {
            return _buildIpvPdfContent(
              detail: detail,
              meta: meta,
              generatedAt: generatedAt,
            );
          },
        ),
      );

      await file.writeAsBytes(await doc.save(), flush: true);
      return file.path;
    } catch (e, st) {
      await _writeIpvExportDiagnostic(
        reportId: reportId,
        format: 'pdf',
        error: e,
        stackTrace: st,
      );
      stderr.writeln('IPV PDF export failed. reportId=$reportId error=$e');
      stderr.writeln(st);
      rethrow;
    }
  }

  Future<Directory> _resolveExportDir(IpvReportSummaryStat summary) async {
    final String terminalFolder = _sanitizePathSegment(summary.terminalName);
    final Directory preferredBase = await _resolveDownloadsBaseDir();
    Directory dir =
        Directory(p.join(preferredBase.path, 'IPV', terminalFolder));
    try {
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      final Directory docs = await getApplicationDocumentsDirectory();
      dir = Directory(
        p.join(docs.path, 'exports', 'IPV', terminalFolder),
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

  String _sanitizePathSegment(String raw) {
    final String clean = raw
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) {
      return 'TPV';
    }
    return clean.length > 80 ? clean.substring(0, 80) : clean;
  }

  String _buildIpvExportFileName(
    IpvReportSummaryStat summary, {
    required String extension,
  }) {
    final DateTime ref = summary.closedAt ?? summary.openedAt;
    final String y = ref.year.toString().padLeft(4, '0');
    final String m = ref.month.toString().padLeft(2, '0');
    final String d = ref.day.toString().padLeft(2, '0');
    final String hh = ref.hour.toString().padLeft(2, '0');
    final String mm = ref.minute.toString().padLeft(2, '0');
    final String seed = '${summary.terminalName}-$y$m$d-$hh$mm';
    final String safe = seed
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'ipv_${safe.isEmpty ? summary.reportId : safe}.$extension';
  }

  String _csvCell(String value) {
    final String escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _formatQtyCsv(double qty) {
    return qty.toStringAsFixed(2);
  }

  String _formatDateTimeHuman(DateTime date) {
    final DateTime local = date.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString().padLeft(4, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y, $hh:$mm';
  }

  _IpvExecutiveSummary _buildIpvExecutiveSummary(IpvReportDetailStat detail) {
    double totalSalesQty = 0;
    double totalEntriesQty = 0;
    double totalOutputsQty = 0;
    int totalSalesAmountCents = 0;
    for (final IpvReportLineStat row in detail.lines) {
      totalSalesQty += row.salesQty;
      totalEntriesQty += row.entriesQty;
      totalOutputsQty += row.outputsQty;
      totalSalesAmountCents += (row.salesQty * row.salePriceCents).round();
    }
    return _IpvExecutiveSummary(
      totalSalesQty: totalSalesQty,
      totalEntriesQty: totalEntriesQty,
      totalOutputsQty: totalOutputsQty,
      totalSalesAmountCents: totalSalesAmountCents,
    );
  }

  Future<_IpvExportMeta> _loadIpvExportMeta(String reportId) async {
    final QueryRow? header = await _db.customSelect(
      '''
      SELECT
        r.id AS report_id,
        r.terminal_id AS terminal_id,
        r.warehouse_id AS warehouse_id,
        t.name AS terminal_name,
        w.name AS warehouse_name,
        r.session_id AS session_id
      FROM ipv_reports r
      LEFT JOIN pos_terminals t ON t.id = r.terminal_id
      LEFT JOIN warehouses w ON w.id = r.warehouse_id
      WHERE r.id = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(reportId)],
    ).getSingleOrNull();
    if (header == null) {
      throw Exception('No se encontro el IPV solicitado.');
    }

    final String sessionId = _readTextCell(header, 'session_id', fallback: '');
    final List<QueryRow> employeeRows = sessionId.isEmpty
        ? <QueryRow>[]
        : await _db.customSelect(
            '''
            SELECT e.name AS employee_name
            FROM pos_session_employees se
            INNER JOIN employees e ON e.id = se.employee_id
            WHERE se.session_id = ?
            ORDER BY e.name ASC
            ''',
            variables: <Variable<Object>>[Variable<String>(sessionId)],
          ).get();
    final List<String> employeeNames = employeeRows
        .map((QueryRow row) =>
            (row.readNullable<String>('employee_name') ?? '').trim())
        .where((String value) => value.isNotEmpty)
        .toList();

    final List<QueryRow> paymentRows = sessionId.isEmpty
        ? <QueryRow>[]
        : await _db.customSelect(
            '''
            SELECT
              p.method AS method,
              COALESCE(SUM(p.amount_cents), 0) AS amount_cents
            FROM payments p
            INNER JOIN sales s ON s.id = p.sale_id
            WHERE s.terminal_session_id = ?
              AND s.status = 'posted'
            GROUP BY p.method
            ''',
            variables: <Variable<Object>>[Variable<String>(sessionId)],
          ).get();

    final Map<String, int> paymentTotalsByMethod = <String, int>{};
    for (final QueryRow row in paymentRows) {
      final String method = (row.readNullable<String>('method') ?? '').trim();
      if (method.isEmpty) {
        continue;
      }
      final int amount = (row.data['amount_cents'] as num?)?.toInt() ?? 0;
      paymentTotalsByMethod[method] = amount;
    }

    return _IpvExportMeta(
      terminalId: _readTextCell(header, 'terminal_id', fallback: '-'),
      terminalName:
          (header.readNullable<String>('terminal_name') ?? 'TPV').trim(),
      warehouseId: _readTextCell(header, 'warehouse_id', fallback: '-'),
      warehouseName:
          (header.readNullable<String>('warehouse_name') ?? 'Almacen').trim(),
      employeesLabel: employeeNames.isEmpty ? '-' : employeeNames.join(', '),
      paymentTotalsByMethod: paymentTotalsByMethod,
    );
  }

  String _readTextCell(
    QueryRow row,
    String column, {
    required String fallback,
  }) {
    final String value = (row.readNullable<String>(column) ?? '').trim();
    return value.isEmpty ? fallback : value;
  }

  String? _nullableTextCell(QueryRow row, String column) {
    final String value = (row.readNullable<String>(column) ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  DateTime? _readDateCell(Object? raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Future<Map<String, _IpvProductSnapshot>> _loadIpvProductSnapshots(
    Set<String> productIds,
  ) async {
    if (productIds.isEmpty) {
      return <String, _IpvProductSnapshot>{};
    }
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        id,
        COALESCE(name, '-') AS name,
        COALESCE(sku, '-') AS sku,
        COALESCE(price_cents, 0) AS price_cents
      FROM products
      WHERE id IN (${List<String>.filled(productIds.length, '?').join(', ')})
      ''',
      variables: productIds
          .map((String productId) => Variable<String>(productId))
          .toList(),
    ).get();
    final Map<String, _IpvProductSnapshot> mapped =
        <String, _IpvProductSnapshot>{
      for (final QueryRow row in rows)
        _readTextCell(row, 'id', fallback: ''): _IpvProductSnapshot(
          name: _readTextCell(row, 'name', fallback: '-'),
          sku: _readTextCell(row, 'sku', fallback: '-'),
          priceCents: (row.data['price_cents'] as num?)?.toInt() ?? 0,
        ),
    };
    mapped.remove('');
    return mapped;
  }

  Future<void> _writeIpvExportDiagnostic({
    required String reportId,
    required String format,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory dir = Directory(p.join(docs.path, 'exports', 'IPV'));
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      final File file = File(p.join(dir.path, 'last_ipv_export_error.txt'));
      final IpvReportDetailStat? detail = await loadIpvReportDetail(reportId);
      final StringBuffer out = StringBuffer()
        ..writeln('format=$format')
        ..writeln('reportId=$reportId')
        ..writeln('error=$error')
        ..writeln('timestamp=${DateTime.now().toIso8601String()}');
      if (detail != null) {
        out
          ..writeln('summary.sessionId=${detail.summary.sessionId}')
          ..writeln('summary.terminalName=${detail.summary.terminalName}')
          ..writeln('summary.status=${detail.summary.status}')
          ..writeln(
              'summary.openedAt=${detail.summary.openedAt.toIso8601String()}')
          ..writeln(
            'summary.closedAt=${detail.summary.closedAt?.toIso8601String() ?? '-'}',
          )
          ..writeln('lines.count=${detail.lines.length}');
        for (int i = 0; i < detail.lines.length; i++) {
          final IpvReportLineStat row = detail.lines[i];
          out
            ..writeln('line[$i].productId=${row.productId}')
            ..writeln('line[$i].productName=${row.productName}')
            ..writeln('line[$i].sku=${row.sku}')
            ..writeln('line[$i].startQty=${row.startQty}')
            ..writeln('line[$i].entriesQty=${row.entriesQty}')
            ..writeln('line[$i].outputsQty=${row.outputsQty}')
            ..writeln('line[$i].salesQty=${row.salesQty}')
            ..writeln('line[$i].finalQty=${row.finalQty}')
            ..writeln('line[$i].salePriceCents=${row.salePriceCents}');
        }
      }
      out
        ..writeln('stacktrace.begin')
        ..writeln(stackTrace)
        ..writeln('stacktrace.end');
      await file.writeAsString(out.toString(), flush: true);
    } catch (_) {
      // Best effort only: we do not want diagnostics to mask the original export error.
    }
  }

  List<pw.Widget> _buildIpvPdfContent({
    required IpvReportDetailStat detail,
    required _IpvExportMeta meta,
    required String generatedAt,
  }) {
    final _IpvExecutiveSummary executive = _buildIpvExecutiveSummary(detail);
    final List<MapEntry<String, int>> paymentEntries = meta
        .paymentTotalsByMethod.entries
        .toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        return _paymentMethodLabel(a.key).compareTo(_paymentMethodLabel(b.key));
      });

    final PdfColor sectionBlue = PdfColor.fromHex('#12306B');
    final PdfColor infoBg = PdfColor.fromHex('#EFF2F6');
    final PdfColor infoBorder = PdfColor.fromHex('#C9D1DB');
    final PdfColor headerBg = PdfColor.fromHex('#D8E0EC');
    final PdfColor totalBg = PdfColor.fromHex('#D7E6DB');
    final PdfColor stripeBg = PdfColor.fromHex('#F4F6F9');

    pw.Widget sectionTitle(String text) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: sectionBlue,
          ),
        ),
      );
    }

    pw.Widget infoLine(String label, String value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 11),
            children: <pw.InlineSpan>[
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(
                text: value,
                style:
                    bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
              ),
            ],
          ),
        ),
      );
    }

    pw.Widget summaryCard(List<MapEntry<String, String>> rows) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: infoBorder, width: 1),
        ),
        child: pw.Column(
          children: rows
              .map(
                (MapEntry<String, String> row) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: <pw.Widget>[
                      pw.Expanded(
                        child: pw.Text(
                          row.key,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Text(
                        row.value,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    pw.Widget cell(
      String text, {
      required pw.Alignment alignment,
      required bool header,
      PdfColor? bg,
      bool bold = false,
    }) {
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        color: bg,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: header ? 9.5 : 9.2,
            fontWeight:
                bold || header ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    final List<MapEntry<String, String>> leftExecutive =
        <MapEntry<String, String>>[
      MapEntry<String, String>(
          'Total de ventas', _formatQtyPretty(executive.totalSalesQty)),
      MapEntry<String, String>(
          'Total de entradas', _formatQtyPretty(executive.totalEntriesQty)),
      MapEntry<String, String>(
          'Total de salidas', _formatQtyPretty(executive.totalOutputsQty)),
    ];
    final List<MapEntry<String, String>> rightExecutive =
        <MapEntry<String, String>>[
      for (final MapEntry<String, int> entry in paymentEntries)
        MapEntry<String, String>(
          'Total ${_paymentMethodLabel(entry.key).toLowerCase()}',
          _formatMoney(entry.value),
        ),
      MapEntry<String, String>(
          'Importe total', _formatMoney(executive.totalSalesAmountCents)),
    ];

    final List<pw.TableRow> tableRows = <pw.TableRow>[
      pw.TableRow(
        children: <pw.Widget>[
          cell('Producto',
              alignment: pw.Alignment.centerLeft, header: true, bg: headerBg),
          cell('Cod',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Ini',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Ent',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Sal',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Ven',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Tot',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Fin',
              alignment: pw.Alignment.center, header: true, bg: headerBg),
          cell('Precio',
              alignment: pw.Alignment.centerRight, header: true, bg: headerBg),
          cell('Importe',
              alignment: pw.Alignment.centerRight, header: true, bg: headerBg),
        ],
      ),
    ];

    for (int i = 0; i < detail.lines.length; i++) {
      final IpvReportLineStat row = detail.lines[i];
      final double totalBeforeSales =
          row.startQty + row.entriesQty - row.outputsQty;
      final int salesAmountCents = (row.salesQty * row.salePriceCents).round();
      final PdfColor? rowBg = i.isEven ? stripeBg : null;
      tableRows.add(
        pw.TableRow(
          children: <pw.Widget>[
            cell(row.productName,
                alignment: pw.Alignment.centerLeft, header: false, bg: rowBg),
            cell(row.sku,
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatQtyPretty(row.startQty),
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatQtyPretty(row.entriesQty),
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatQtyPretty(row.outputsQty),
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatQtyPretty(row.salesQty),
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatQtyPretty(totalBeforeSales),
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatQtyPretty(row.finalQty),
                alignment: pw.Alignment.center, header: false, bg: rowBg),
            cell(_formatMoney(row.salePriceCents),
                alignment: pw.Alignment.centerRight, header: false, bg: rowBg),
            cell(_formatMoney(salesAmountCents),
                alignment: pw.Alignment.centerRight, header: false, bg: rowBg),
          ],
        ),
      );
    }

    tableRows.add(
      pw.TableRow(
        children: <pw.Widget>[
          cell('',
              alignment: pw.Alignment.centerLeft, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('', alignment: pw.Alignment.center, header: false, bg: totalBg),
          cell('TOTAL IMPORTE',
              alignment: pw.Alignment.centerRight,
              header: false,
              bg: totalBg,
              bold: true),
          cell(_formatMoney(executive.totalSalesAmountCents),
              alignment: pw.Alignment.centerRight,
              header: false,
              bg: totalBg,
              bold: true),
        ],
      ),
    );

    return <pw.Widget>[
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: pw.BoxDecoration(
          color: infoBg,
          border: pw.Border.all(color: infoBorder, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            infoLine('TPV', meta.terminalName, bold: true),
            infoLine('Apertura', _formatDateTimeHuman(detail.summary.openedAt)),
            if (detail.summary.closedAt != null)
              infoLine(
                'Cierre',
                _formatDateTimeHuman(detail.summary.closedAt!),
              ),
            infoLine('Almacen', meta.warehouseName),
            infoLine('Empleado(s)', meta.employeesLabel),
          ],
        ),
      ),
      sectionTitle('Resumen Ejecutivo'),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(child: summaryCard(leftExecutive)),
          pw.SizedBox(width: 16),
          pw.Expanded(child: summaryCard(rightExecutive)),
        ],
      ),
      pw.SizedBox(height: 16),
      if (detail.lines.isEmpty)
        pw.Text(
          'Sin lineas de productos.',
          style: const pw.TextStyle(fontSize: 11),
        ),
      if (detail.lines.isNotEmpty)
        pw.Table(
          border: pw.TableBorder.all(color: infoBorder, width: 0.7),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(3.3),
            1: pw.FlexColumnWidth(1.2),
            2: pw.FlexColumnWidth(0.72),
            3: pw.FlexColumnWidth(0.72),
            4: pw.FlexColumnWidth(0.72),
            5: pw.FlexColumnWidth(0.72),
            6: pw.FlexColumnWidth(0.85),
            7: pw.FlexColumnWidth(0.72),
            8: pw.FlexColumnWidth(1.45),
            9: pw.FlexColumnWidth(1.9),
          },
          children: tableRows,
        ),
      pw.SizedBox(height: 8),
      pw.Text(
        'Reporte IPV | Estado ${detail.summary.status.toUpperCase()}',
        style: const pw.TextStyle(fontSize: 9),
      ),
    ];
  }

  pw.Widget _buildIpvPdfHeader({
    required String generatedAt,
    required int pageNumber,
  }) {
    final PdfColor navy = PdfColor.fromHex('#12306B');
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 8),
      color: navy,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              'REPORTE IPV',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                'Generado: $generatedAt',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10.5,
                ),
              ),
              pw.Text(
                'Pagina $pageNumber',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method.trim().toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'wallet':
        return 'Billetera';
      case 'consignment':
        return 'Consignación';
      default:
        return method;
    }
  }

  String? _normalizeChannelFilter(String? channel) {
    final String clean = (channel ?? '').trim().toLowerCase();
    if (clean == 'pos') {
      return 'pos';
    }
    if (clean == 'directa' || clean == 'direct' || clean == 'venta_directa') {
      return 'directa';
    }
    return null;
  }

  String? _normalizePaymentMethodKey(String? paymentMethodKey) {
    final String clean = (paymentMethodKey ?? '').trim().toLowerCase();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }

  String? _normalizeDependentKey(String? dependentKey) {
    final String clean = (dependentKey ?? '').trim().toLowerCase();
    if (clean.isEmpty) {
      return null;
    }
    if (clean.startsWith('emp:') || clean.startsWith('usr:')) {
      return clean;
    }
    return 'usr:$clean';
  }

  String _analyticsGranularityLabel(SalesAnalyticsGranularity granularity) {
    switch (granularity) {
      case SalesAnalyticsGranularity.day:
        return 'Dia';
      case SalesAnalyticsGranularity.week:
        return 'Semana';
      case SalesAnalyticsGranularity.month:
        return 'Mes';
      case SalesAnalyticsGranularity.year:
        return 'Ano';
    }
  }

  String _formatMoney(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  String _formatQtyPretty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.000001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  Future<List<IpvReportLineStat>> listIpvReportLines(String reportId) async {
    final IpvReportDetailStat? detail = await loadIpvReportDetail(reportId);
    return detail?.lines ?? <IpvReportLineStat>[];
  }

  Future<int> _countScalar(
    String sql, {
    List<Variable<Object>> variables = const <Variable<Object>>[],
  }) async {
    final QueryRow? row = await _db
        .customSelect(
          sql,
          variables: variables,
        )
        .getSingleOrNull();
    if (row == null) {
      return 0;
    }
    return (row.data['value'] as num?)?.toInt() ?? 0;
  }

  Future<int> _countStockByCondition(
    String havingClause, {
    List<Variable<Object>> variables = const <Variable<Object>>[],
  }) async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT COUNT(*) AS value
      FROM (
        SELECT
          p.id AS product_id,
          COALESCE(SUM(sb.qty), 0) AS total_qty
        FROM products p
        LEFT JOIN stock_balances sb
          ON sb.product_id = p.id
        WHERE p.is_active = 1
        GROUP BY p.id
        $havingClause
      ) x
      ''',
      variables: variables,
    ).getSingleOrNull();
    if (row == null) {
      return 0;
    }
    return (row.data['value'] as num?)?.toInt() ?? 0;
  }

  Future<DateTime?> _lastMovementAt() async {
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT MAX(created_at) AS value
      FROM stock_movements
      WHERE COALESCE(is_voided, 0) = 0
      ''',
    ).getSingleOrNull();
    final Object? value = row?.data['value'];
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  Future<List<StockAlertStat>> _loadLowStockPreview(
    double threshold,
    int limit,
  ) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        p.id AS product_id,
        p.name AS product_name,
        p.sku AS sku,
        COALESCE(SUM(sb.qty), 0) AS total_qty
      FROM products p
      LEFT JOIN stock_balances sb
        ON sb.product_id = p.id
      WHERE p.is_active = 1
      GROUP BY p.id, p.name, p.sku
      HAVING total_qty > 0
         AND total_qty <= ?
      ORDER BY total_qty ASC, p.name ASC
      LIMIT ?
      ''',
      variables: <Variable<Object>>[
        Variable<double>(threshold),
        Variable<int>(limit),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return StockAlertStat(
        productId: (row.readNullable<String>('product_id') ?? '').trim(),
        productName: (row.readNullable<String>('product_name') ?? '-').trim(),
        sku: (row.readNullable<String>('sku') ?? '-').trim(),
        qty: (row.data['total_qty'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  SalesSummary _buildTodaySummary(List<Sale> sales) {
    int totalCents = 0;
    int taxCents = 0;

    for (final Sale sale in sales) {
      totalCents += sale.totalCents;
      taxCents += sale.taxCents;
    }

    return SalesSummary(
      salesCount: sales.length,
      totalCents: totalCents,
      taxCents: taxCents,
    );
  }

  List<DailySalesPoint> _buildLastDaysSeries(List<Sale> sales) {
    final Map<String, _DayAccumulator> byDay = <String, _DayAccumulator>{};

    for (final Sale sale in sales) {
      final String key = _dayKey(sale.createdAt);
      final _DayAccumulator acc = byDay.putIfAbsent(key, _DayAccumulator.new);
      acc.salesCount += 1;
      acc.totalCents += sale.totalCents;
    }

    final List<DailySalesPoint> points = byDay.entries
        .map(
          (MapEntry<String, _DayAccumulator> entry) => DailySalesPoint(
            day: entry.key,
            salesCount: entry.value.salesCount,
            totalCents: entry.value.totalCents,
          ),
        )
        .toList();

    points
        .sort((DailySalesPoint a, DailySalesPoint b) => b.day.compareTo(a.day));
    return points;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dayKey(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _IpvAgg {
  _IpvAgg({
    this.startQty = 0,
    this.salePriceCents,
  });

  double startQty;
  double entriesQty = 0;
  double outputsQty = 0;
  double salesQty = 0;
  int? salePriceCents;
}

class _IpvExecutiveSummary {
  const _IpvExecutiveSummary({
    required this.totalSalesQty,
    required this.totalEntriesQty,
    required this.totalOutputsQty,
    required this.totalSalesAmountCents,
  });

  final double totalSalesQty;
  final double totalEntriesQty;
  final double totalOutputsQty;
  final int totalSalesAmountCents;
}

class _IpvExportMeta {
  const _IpvExportMeta({
    required this.terminalId,
    required this.terminalName,
    required this.warehouseId,
    required this.warehouseName,
    required this.employeesLabel,
    required this.paymentTotalsByMethod,
  });

  final String terminalId;
  final String terminalName;
  final String warehouseId;
  final String warehouseName;
  final String employeesLabel;
  final Map<String, int> paymentTotalsByMethod;
}

class _IpvProductSnapshot {
  const _IpvProductSnapshot({
    required this.name,
    required this.sku,
    required this.priceCents,
  });

  final String name;
  final String sku;
  final int priceCents;
}

class _DayAccumulator {
  int salesCount = 0;
  int totalCents = 0;
}

enum _TrendGrouping { hour, day, month }

class _TrendBucket {
  _TrendBucket({
    required this.bucketStart,
    required this.label,
  });

  final DateTime bucketStart;
  final String label;
  int totalCents = 0;
  int ordersCount = 0;
}
