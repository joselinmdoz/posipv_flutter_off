import 'package:drift/drift.dart';

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

class ReportesDashboard {
  const ReportesDashboard({
    required this.today,
    required this.lastDays,
    required this.topProducts,
    required this.recentSales,
  });

  final SalesSummary today;
  final List<DailySalesPoint> lastDays;
  final List<TopProductStat> topProducts;
  final List<RecentSaleStat> recentSales;
}

class ReportesLocalDataSource {
  ReportesLocalDataSource(this._db);

  final AppDatabase _db;

  Future<ReportesDashboard> loadDashboard({
    int lastDays = 7,
    int topProductsDays = 30,
    int topLimit = 5,
    int recentLimit = 15,
  }) async {
    final DateTime now = DateTime.now();
    final int safeLastDays = lastDays < 1 ? 1 : lastDays;
    final int safeTopDays = topProductsDays < 1 ? 1 : topProductsDays;
    final int safeTopLimit = topLimit < 1 ? 1 : topLimit;
    final int safeRecentLimit = recentLimit < 1 ? 1 : recentLimit;

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

    return ReportesDashboard(
      today: _buildTodaySummary(todaySales),
      lastDays: _buildLastDaysSeries(lastSales),
      topProducts: top,
      recentSales: recent,
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
          ..where((Warehouses tbl) => tbl.id.isIn(warehouseIds)))
        .get();
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.isIn(cashierIds)))
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

class _DayAccumulator {
  int salesCount = 0;
  int totalCents = 0;
}
