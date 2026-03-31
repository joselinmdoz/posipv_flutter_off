import 'package:flutter/material.dart';

import 'analytics_kpi_card.dart';

class TotalSalesKpiWidget extends StatelessWidget {
  const TotalSalesKpiWidget({
    super.key,
    required this.totalSales,
    this.deltaPercent,
    this.deltaText,
    this.onTap,
  });

  final int totalSales;
  final double? deltaPercent;
  final String? deltaText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'Ventas',
      value: totalSales.toString(),
      icon: Icons.shopping_bag_outlined,
      deltaPercent: deltaPercent,
      deltaText: deltaText,
      onTap: onTap,
    );
  }
}

class SalesAmountKpiWidget extends StatelessWidget {
  const SalesAmountKpiWidget({
    super.key,
    required this.totalAmountCents,
    required this.moneyFormatter,
    this.deltaPercent,
    this.deltaText,
    this.onTap,
  });

  final int totalAmountCents;
  final String Function(int) moneyFormatter;
  final double? deltaPercent;
  final String? deltaText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'Importe',
      value: moneyFormatter(totalAmountCents),
      icon: Icons.payments_outlined,
      deltaPercent: deltaPercent,
      deltaText: deltaText,
      onTap: onTap,
    );
  }
}

class ProfitKpiWidget extends StatelessWidget {
  const ProfitKpiWidget({
    super.key,
    required this.totalProfitCents,
    required this.moneyFormatter,
    this.deltaPercent,
    this.deltaText,
    this.onTap,
  });

  final int totalProfitCents;
  final String Function(int) moneyFormatter;
  final double? deltaPercent;
  final String? deltaText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'Ganancia',
      value: moneyFormatter(totalProfitCents),
      icon: Icons.trending_up_rounded,
      deltaPercent: deltaPercent,
      deltaText: deltaText,
      onTap: onTap,
    );
  }
}

class SoldProductsKpiWidget extends StatelessWidget {
  const SoldProductsKpiWidget({
    super.key,
    required this.totalProductsSold,
    this.onTap,
  });

  final double totalProductsSold;
  final VoidCallback? onTap;

  String _format(double value) {
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'Productos',
      value: _format(totalProductsSold),
      icon: Icons.inventory_2_outlined,
      onTap: onTap,
    );
  }
}
