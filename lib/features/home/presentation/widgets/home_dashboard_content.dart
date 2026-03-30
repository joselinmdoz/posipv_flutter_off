import 'package:flutter/material.dart';

import '../../../../shared/models/dashboard_widget_config.dart';
import '../../../reportes/data/reportes_local_datasource.dart';
import 'home_metric_cards.dart';
import 'home_quick_actions.dart';
import 'home_recent_activity.dart';

class HomeDashboardContent extends StatelessWidget {
  const HomeDashboardContent({
    super.key,
    required this.dashboard,
    required this.today,
    required this.lowStockCount,
    required this.layout,
    required this.moneyFormatter,
    required this.currencySymbol,
    required this.onNewSaleTap,
    required this.onAddStockTap,
    required this.onViewAllActivityTap,
  });

  final ReportesDashboard dashboard;
  final SalesSummary today;
  final int lowStockCount;
  final DashboardWidgetLayout layout;
  final String Function(int) moneyFormatter;
  final String currencySymbol;
  final VoidCallback onNewSaleTap;
  final VoidCallback onAddStockTap;
  final VoidCallback? onViewAllActivityTap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> sections = <Widget>[];
    final List<String> orderedVisible = layout.orderedVisibleKeys;

    for (final String key in orderedVisible) {
      final Widget? section = _buildSection(key);
      if (section == null) {
        continue;
      }
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 24));
      }
      sections.add(section);
    }

    if (sections.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No hay widgets visibles. Actívalos en Ajustes > Widgets Dashboard.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget? _buildSection(String key) {
    switch (key) {
      case DashboardWidgetKeys.metrics:
        return HomeMetricCards(
          today: today,
          yesterday: dashboard.yesterday,
          ordersCount: today.salesCount,
          lowStockCount: lowStockCount,
          moneyFormatter: moneyFormatter,
        );
      case DashboardWidgetKeys.quickActions:
        return HomeQuickActions(
          onNewSaleTap: onNewSaleTap,
          onAddStockTap: onAddStockTap,
        );
      case DashboardWidgetKeys.recentActivity:
        return HomeRecentActivity(
          recentSales: dashboard.recentSales,
          recentSessionClosures: dashboard.recentSessionClosures,
          recentIpvReports: dashboard.recentIpvReports,
          currencySymbol: currencySymbol,
          moneyFormatter: moneyFormatter,
          onViewAllTap: onViewAllActivityTap,
        );
      default:
        return null;
    }
  }
}
