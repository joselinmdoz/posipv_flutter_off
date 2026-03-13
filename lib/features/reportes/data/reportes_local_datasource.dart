import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/db/app_database.dart';

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
    required this.lastDays,
    required this.topProducts,
    required this.recentSales,
    required this.recentSessionClosures,
    required this.recentIpvReports,
  });

  final SalesSummary today;
  final List<DailySalesPoint> lastDays;
  final List<TopProductStat> topProducts;
  final List<RecentSaleStat> recentSales;
  final List<RecentSessionClosureStat> recentSessionClosures;
  final List<IpvReportSummaryStat> recentIpvReports;
}

class ReportesLocalDataSource {
  ReportesLocalDataSource(this._db);

  final AppDatabase _db;

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
    final DateTime startLastDays =
        startToday.subtract(Duration(days: safeLastDays - 1));
    final DateTime startTopWindow =
        startToday.subtract(Duration(days: safeTopDays - 1));

    final List<Sale> todaySales = await _postedSalesSince(startToday);
    final List<Sale> lastSales = await _postedSalesSince(startLastDays);
    final List<TopProductStat> top =
        await _topProducts(startTopWindow, safeTopLimit);
    final List<RecentSaleStat> recent = await _recentSales(safeRecentLimit);
    final List<RecentSessionClosureStat> recentSessionClosures =
        await _recentSessionClosures(safeSessionClosureLimit);
    final List<IpvReportSummaryStat> recentIpvReports =
        await listIpvReports(limit: safeIpvLimit);

    return ReportesDashboard(
      today: _buildTodaySummary(todaySales),
      lastDays: _buildLastDaysSeries(lastSales),
      topProducts: top,
      recentSales: recent,
      recentSessionClosures: recentSessionClosures,
      recentIpvReports: recentIpvReports,
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
    final List<Sale> sales = await _postedSalesSince(from);
    if (sales.isEmpty) {
      return <TopProductStat>[];
    }

    final Set<String> saleIds = sales.map((Sale sale) => sale.id).toSet();
    final List<SaleItem> saleItems = await (_db.select(_db.saleItems)
          ..where((SaleItems tbl) =>
              tbl.saleId.isIn(saleIds) &
              tbl.id.isNotNull() &
              tbl.saleId.isNotNull() &
              tbl.productId.isNotNull() &
              tbl.qty.isNotNull() &
              tbl.unitPriceCents.isNotNull() &
              tbl.taxRateBps.isNotNull() &
              tbl.lineSubtotalCents.isNotNull() &
              tbl.lineTaxCents.isNotNull() &
              tbl.lineTotalCents.isNotNull()))
        .get();
    if (saleItems.isEmpty) {
      return <TopProductStat>[];
    }

    final Set<String> productIds =
        saleItems.map((SaleItem item) => item.productId).toSet();
    final List<Product> products = await (_db.select(_db.products)
          ..where((Products tbl) =>
              tbl.id.isIn(productIds) &
              tbl.id.isNotNull() &
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
              tbl.createdAt.isNotNull()))
        .get();

    final Map<String, Product> productById = <String, Product>{
      for (final Product product in products) product.id: product,
    };

    final Map<String, _TopAccumulator> aggByProduct =
        <String, _TopAccumulator>{};
    for (final SaleItem item in saleItems) {
      final _TopAccumulator acc =
          aggByProduct.putIfAbsent(item.productId, _TopAccumulator.new);
      acc.qty += item.qty;
      acc.totalCents += item.lineTotalCents;
    }

    final List<TopProductStat> stats = aggByProduct.entries.map((entry) {
      final Product? product = productById[entry.key];
      final _TopAccumulator acc = entry.value;
      return TopProductStat(
        productName: product?.name ?? entry.key,
        sku: product?.sku ?? '-',
        qty: acc.qty,
        totalCents: acc.totalCents,
      );
    }).toList();

    stats.sort((TopProductStat a, TopProductStat b) {
      final int byQty = b.qty.compareTo(a.qty);
      if (byQty != 0) {
        return byQty;
      }
      return b.totalCents.compareTo(a.totalCents);
    });

    return stats.take(limit).toList();
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
        COALESCE(SUM(l.total_amount_cents), 0) AS total_amount_cents
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
        COALESCE(SUM(l.total_amount_cents), 0) AS total_amount_cents
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

    final String terminalId = header.read<String>('terminal_id');
    final String warehouseId = header.read<String>('warehouse_id');
    final DateTime openedAt = header.read<DateTime>('opened_at');
    final DateTime? closedAt = header.readNullable<DateTime>('closed_at');
    final String status =
        (header.readNullable<String>('status') ?? 'open').trim().toLowerCase();

    final DateTime movementStart = await _resolveIpvMovementStart(
      terminalId: terminalId,
      openedAt: openedAt,
      currentReportId: id,
    );
    final DateTime movementEnd = closedAt ?? DateTime.now();

    final List<IpvReportLine> baseLines = await (_db.select(_db.ipvReportLines)
          ..where((IpvReportLines tbl) => tbl.reportId.equals(id)))
        .get();
    final Map<String, _IpvAgg> byProduct = <String, _IpvAgg>{
      for (final IpvReportLine line in baseLines)
        line.productId: _IpvAgg(
          startQty: line.startQty,
          salePriceCents: line.salePriceCents,
        ),
    };

    final List<QueryRow> movementRows = await _db.customSelect(
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
              LOWER(COALESCE(sm.reason_code, '')) = 'sale'
              OR LOWER(COALESCE(sm.ref_type, '')) IN ('sale', 'sale_pos', 'sale_direct')
              OR LOWER(COALESCE(sm.movement_source, '')) IN ('pos', 'direct_sale')
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
              LOWER(COALESCE(sm.reason_code, '')) = 'sale'
              OR LOWER(COALESCE(sm.ref_type, '')) IN ('sale', 'sale_pos', 'sale_direct')
              OR LOWER(COALESCE(sm.movement_source, '')) IN ('pos', 'direct_sale')
            )
              THEN ABS(sm.qty)
            ELSE 0
          END
        ), 0) AS sales_qty
      FROM stock_movements sm
      WHERE sm.warehouse_id = ?
        AND sm.created_at > ?
        AND sm.created_at <= ?
      GROUP BY sm.product_id
      ''',
      variables: <Variable<Object>>[
        Variable<String>(warehouseId),
        Variable<DateTime>(movementStart),
        Variable<DateTime>(movementEnd),
      ],
    ).get();
    for (final QueryRow row in movementRows) {
      final String productId = row.read<String>('product_id');
      final _IpvAgg agg = byProduct.putIfAbsent(productId, () => _IpvAgg());
      agg.entriesQty = (row.data['entries_qty'] as num?)?.toDouble() ?? 0;
      agg.outputsQty = (row.data['outputs_qty'] as num?)?.toDouble() ?? 0;
      agg.salesQty = (row.data['sales_qty'] as num?)?.toDouble() ?? 0;
    }

    final Set<String> productIds = byProduct.keys.toSet();
    final Map<String, Product> productById = productIds.isEmpty
        ? <String, Product>{}
        : {
            for (final Product row in await (_db.select(_db.products)
                  ..where((Products tbl) => tbl.id.isIn(productIds)))
                .get())
              row.id: row,
          };

    int totalAmountCents = 0;
    final List<IpvReportLineStat> lines = <IpvReportLineStat>[];
    for (final String productId in byProduct.keys) {
      final _IpvAgg agg = byProduct[productId]!;
      final Product? product = productById[productId];
      final int salePriceCents = agg.salePriceCents ?? product?.priceCents ?? 0;
      final double finalQty =
          agg.startQty + agg.entriesQty - agg.outputsQty - agg.salesQty;
      final int amountCents = (finalQty * salePriceCents).round();
      totalAmountCents += amountCents;
      lines.add(
        IpvReportLineStat(
          productId: productId,
          productName: product?.name ?? '-',
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
      sessionId: header.read<String>('session_id'),
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

  Future<String> exportIpvReportCsv(String reportId) async {
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
      final int salesAmountCents = (row.salesQty * row.salePriceCents).round();
      csv.writeln(
        '${_csvCell(row.productName)},${_csvCell(row.sku)},${_formatQtyCsv(row.startQty)},${_formatQtyCsv(row.entriesQty)},${_formatQtyCsv(row.outputsQty)},${_formatQtyCsv(row.salesQty)},${_formatQtyCsv(totalBeforeSales)},${_formatQtyCsv(row.finalQty)},${(row.salePriceCents / 100).toStringAsFixed(2)},${(salesAmountCents / 100).toStringAsFixed(2)}',
      );
    }
    csv.writeln(
      ',,,,,,,,TOTAL IMPORTE,${(executive.totalSalesAmountCents / 100).toStringAsFixed(2)}',
    );

    await file.writeAsString(csv.toString(), encoding: utf8, flush: true);
    return file.path;
  }

  Future<String> exportIpvReportPdf(String reportId) async {
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

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 24),
        build: (pw.Context context) {
          return _buildIpvPdfContent(
            detail: detail,
            meta: meta,
            pageNumber: context.pageNumber,
          );
        },
      ),
    );

    await file.writeAsBytes(await doc.save(), flush: true);
    return file.path;
  }

  Future<Directory> _resolveExportDir(IpvReportSummaryStat summary) async {
    final String terminalFolder = _sanitizePathSegment(summary.terminalName);
    final Directory preferredBase = await _resolveDownloadsBaseDir();
    Directory dir = Directory(
      p.join(preferredBase.path, 'IPV', terminalFolder),
    );
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

    final String sessionId = header.read<String>('session_id');
    final List<QueryRow> employeeRows = await _db.customSelect(
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

    final List<QueryRow> paymentRows = await _db.customSelect(
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
      terminalId: header.read<String>('terminal_id'),
      terminalName:
          (header.readNullable<String>('terminal_name') ?? 'TPV').trim(),
      warehouseId: header.read<String>('warehouse_id'),
      warehouseName:
          (header.readNullable<String>('warehouse_name') ?? 'Almacen').trim(),
      employeesLabel: employeeNames.isEmpty ? '-' : employeeNames.join(', '),
      paymentTotalsByMethod: paymentTotalsByMethod,
    );
  }

  List<pw.Widget> _buildIpvPdfContent({
    required IpvReportDetailStat detail,
    required _IpvExportMeta meta,
    required int pageNumber,
  }) {
    final _IpvExecutiveSummary executive = _buildIpvExecutiveSummary(detail);
    final DateTime now = DateTime.now();
    final String generatedAt = _formatDateTimeHuman(now);

    final PdfColor pageBg = PdfColor.fromHex('#ECEDEF');
    final PdfColor navy = PdfColor.fromHex('#0F2E63');
    final PdfColor cardBg = PdfColor.fromHex('#E8EBF0');
    final PdfColor border = PdfColor.fromHex('#B6C1D1');
    final PdfColor headerCell = PdfColor.fromHex('#D2DAE6');
    final PdfColor totalBg = PdfColor.fromHex('#CFE0D7');
    final PdfColor bodyText = PdfColor.fromHex('#112D57');

    final List<MapEntry<String, String>> leftExecutive =
        <MapEntry<String, String>>[
      MapEntry<String, String>(
        'Total de ventas',
        _formatQtyPretty(executive.totalSalesQty),
      ),
      MapEntry<String, String>(
        'Total de entradas',
        _formatQtyPretty(executive.totalEntriesQty),
      ),
      MapEntry<String, String>(
        'Total de salidas',
        _formatQtyPretty(executive.totalOutputsQty),
      ),
    ];

    final List<MapEntry<String, int>> paymentEntries = meta
        .paymentTotalsByMethod.entries
        .toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        return _paymentMethodLabel(a.key).compareTo(_paymentMethodLabel(b.key));
      });
    final List<MapEntry<String, String>> rightExecutive =
        <MapEntry<String, String>>[
      for (final MapEntry<String, int> entry in paymentEntries)
        MapEntry<String, String>(
          'Total ${_paymentMethodLabel(entry.key).toLowerCase()}',
          _formatMoney(entry.value),
        ),
      MapEntry<String, String>(
        'Importe total',
        _formatMoney(executive.totalSalesAmountCents),
      ),
    ];

    pw.Widget executiveCard(List<MapEntry<String, String>> rows) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: cardBg,
          border: pw.Border.all(color: border, width: 1),
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
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: bodyText,
                          ),
                        ),
                      ),
                      pw.Text(
                        row.value,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: bodyText,
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

    pw.Widget infoLine(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              '$label: ',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: bodyText,
                fontSize: 11,
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  color: bodyText,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget th(String text, {pw.Alignment alignment = pw.Alignment.center}) {
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        color: headerCell,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: bodyText,
          ),
        ),
      );
    }

    pw.Widget td(
      String text, {
      required int index,
      pw.Alignment alignment = pw.Alignment.center,
    }) {
      return pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        color: index.isEven ? PdfColors.white : PdfColor.fromHex('#F6F8FB'),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9.2, color: bodyText),
        ),
      );
    }

    final List<pw.TableRow> tableRows = <pw.TableRow>[
      pw.TableRow(
        children: <pw.Widget>[
          th('Producto', alignment: pw.Alignment.centerLeft),
          th('Cod'),
          th('Ini'),
          th('Ent'),
          th('Sal'),
          th('Ven'),
          th('Tot'),
          th('Fin'),
          th('Precio', alignment: pw.Alignment.centerRight),
          th('Importe', alignment: pw.Alignment.centerRight),
        ],
      ),
    ];

    for (int i = 0; i < detail.lines.length; i++) {
      final IpvReportLineStat row = detail.lines[i];
      final double totalBeforeSales =
          row.startQty + row.entriesQty - row.outputsQty;
      final int salesAmountCents = (row.salesQty * row.salePriceCents).round();
      tableRows.add(
        pw.TableRow(
          children: <pw.Widget>[
            td(row.productName, index: i, alignment: pw.Alignment.centerLeft),
            td(row.sku, index: i),
            td(_formatQtyPretty(row.startQty), index: i),
            td(_formatQtyPretty(row.entriesQty), index: i),
            td(_formatQtyPretty(row.outputsQty), index: i),
            td(_formatQtyPretty(row.salesQty), index: i),
            td(_formatQtyPretty(totalBeforeSales), index: i),
            td(_formatQtyPretty(row.finalQty), index: i),
            td(_formatMoney(row.salePriceCents),
                index: i, alignment: pw.Alignment.centerRight),
            td(_formatMoney(salesAmountCents),
                index: i, alignment: pw.Alignment.centerRight),
          ],
        ),
      );
    }

    tableRows.add(
      pw.TableRow(
        children: <pw.Widget>[
          pw.Container(
            color: totalBg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(''),
          ),
          pw.Container(color: totalBg),
          pw.Container(color: totalBg),
          pw.Container(color: totalBg),
          pw.Container(color: totalBg),
          pw.Container(color: totalBg),
          pw.Container(color: totalBg),
          pw.Container(color: totalBg),
          pw.Container(
            color: totalBg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'TOTAL IMPORTE',
              style: pw.TextStyle(
                fontSize: 10,
                color: bodyText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            color: totalBg,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              _formatMoney(executive.totalSalesAmountCents),
              style: pw.TextStyle(
                fontSize: 10,
                color: bodyText,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return <pw.Widget>[
      pw.Container(
        width: double.infinity,
        color: pageBg,
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[
            pw.Container(
              color: navy,
              padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Expanded(
                    child: pw.Text(
                      'REPORTE IPV DE SESION',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 21,
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
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 8),
              decoration: pw.BoxDecoration(
                color: cardBg,
                border: pw.Border.all(color: border, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  infoLine(
                    'TPV',
                    '${meta.terminalName} (${meta.terminalId})',
                  ),
                  infoLine(
                    'Apertura',
                    _formatDateTimeHuman(detail.summary.openedAt),
                  ),
                  infoLine(
                    'Almacen',
                    '${meta.warehouseName} (${meta.warehouseId})',
                  ),
                  infoLine('Empleado', meta.employeesLabel),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Resumen Ejecutivo',
              style: pw.TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Expanded(child: executiveCard(leftExecutive)),
                pw.SizedBox(width: 16),
                pw.Expanded(child: executiveCard(rightExecutive)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: border, width: 0.7),
              columnWidths: const <int, pw.TableColumnWidth>{
                0: pw.FlexColumnWidth(3.6),
                1: pw.FlexColumnWidth(1.35),
                2: pw.FlexColumnWidth(0.78),
                3: pw.FlexColumnWidth(0.78),
                4: pw.FlexColumnWidth(0.78),
                5: pw.FlexColumnWidth(0.78),
                6: pw.FlexColumnWidth(0.78),
                7: pw.FlexColumnWidth(0.78),
                8: pw.FlexColumnWidth(1.45),
                9: pw.FlexColumnWidth(2.05),
              },
              children: tableRows,
            ),
          ],
        ),
      ),
    ];
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
      default:
        return method;
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

class _TopAccumulator {
  double qty = 0;
  int totalCents = 0;
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

class _DayAccumulator {
  int salesCount = 0;
  int totalCents = 0;
}
