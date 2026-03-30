import 'package:flutter/material.dart';

import 'analytics_kpi_card.dart';

class TotalSalesKpiWidget extends StatelessWidget {
  const TotalSalesKpiWidget({
    super.key,
    required this.totalSales,
    this.onTap,
  });

  final int totalSales;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'TOTAL DE VENTAS',
      value: totalSales.toString(),
      onTap: onTap,
    );
  }
}

class SalesAmountKpiWidget extends StatelessWidget {
  const SalesAmountKpiWidget({
    super.key,
    required this.totalAmountCents,
    required this.moneyFormatter,
    this.onTap,
  });

  final int totalAmountCents;
  final String Function(int) moneyFormatter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'IMPORTE TOTAL DE VENTAS',
      value: moneyFormatter(totalAmountCents),
      onTap: onTap,
    );
  }
}

class ProfitKpiWidget extends StatelessWidget {
  const ProfitKpiWidget({
    super.key,
    required this.totalProfitCents,
    required this.moneyFormatter,
    this.onTap,
  });

  final int totalProfitCents;
  final String Function(int) moneyFormatter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnalyticsKpiCard(
      title: 'GANANCIA',
      value: moneyFormatter(totalProfitCents),
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
      title: 'TOTAL PRODUCTOS VENDIDOS',
      value: _format(totalProductsSold),
      onTap: onTap,
    );
  }
}
