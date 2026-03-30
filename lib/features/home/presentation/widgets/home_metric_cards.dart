import 'package:flutter/material.dart';

import '../../../reportes/data/reportes_local_datasource.dart';

class HomeMetricCards extends StatelessWidget {
  final SalesSummary today;
  final SalesSummary yesterday;
  final int ordersCount; // Usualmente hoy.salesCount
  final int lowStockCount; // Obtenido del insight
  final String Function(int) moneyFormatter;

  const HomeMetricCards({
    super.key,
    required this.today,
    required this.yesterday,
    required this.ordersCount,
    required this.lowStockCount,
    required this.moneyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeroCard(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildOrdersCard(context)),
            const SizedBox(width: 16),
            Expanded(child: _buildStockCard(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final _MetricDelta delta = _calculateDelta(
      current: today.totalCents,
      previous: yesterday.totalCents,
    );
    final Color deltaColor = _deltaColor(delta, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1152D4).withValues(alpha: 0.2)
                      : const Color(0xFF1152D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF1152D4),
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _deltaIcon(delta),
                      color: deltaColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _deltaLabel(delta),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: deltaColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ventas del día',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            moneyFormatter(today.totalCents),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ayer: ${moneyFormatter(yesterday.totalCents)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final _MetricDelta delta = _calculateDelta(
      current: ordersCount,
      previous: yesterday.salesCount,
    );
    final Color deltaColor = _deltaColor(delta, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                size: 24,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _deltaIcon(delta),
                    size: 13,
                    color: deltaColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _deltaLabel(delta),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: deltaColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PEDIDOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ordersCount.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ayer: ${yesterday.salesCount}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final _StockStatus stockStatus = _resolveStockStatus(lowStockCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color:
                    isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                size: 24,
              ),
              Text(
                stockStatus.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: stockStatus.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'STOCK BAJO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$lowStockCount ítem${lowStockCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lowStockCount == 0 ? 'Sin alertas críticas' : 'Revisar reposición',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  _MetricDelta _calculateDelta({
    required int current,
    required int previous,
  }) {
    if (previous == 0) {
      if (current == 0) {
        return const _MetricDelta(percent: 0, hasBaseline: true);
      }
      return const _MetricDelta(percent: 100, hasBaseline: false);
    }
    return _MetricDelta(
      percent: ((current - previous) / previous) * 100,
      hasBaseline: true,
    );
  }

  String _deltaLabel(_MetricDelta delta) {
    if (!delta.hasBaseline) {
      return 'NUEVO';
    }
    final String sign = delta.percent > 0 ? '+' : '';
    return '$sign${delta.percent.toStringAsFixed(1)}%';
  }

  IconData _deltaIcon(_MetricDelta delta) {
    if (delta.percent > 0) {
      return Icons.trending_up_rounded;
    }
    if (delta.percent < 0) {
      return Icons.trending_down_rounded;
    }
    return Icons.remove_rounded;
  }

  Color _deltaColor(_MetricDelta delta, {required bool isDark}) {
    if (delta.percent > 0) {
      return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    }
    if (delta.percent < 0) {
      return isDark ? const Color(0xFFFB7185) : const Color(0xFFDC2626);
    }
    return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }

  _StockStatus _resolveStockStatus(int count) {
    if (count <= 0) {
      return const _StockStatus(label: 'OK', color: Color(0xFF059669));
    }
    if (count <= 5) {
      return const _StockStatus(label: 'Atención', color: Color(0xFFD97706));
    }
    return const _StockStatus(label: 'Crítico', color: Color(0xFFDC2626));
  }
}

class _MetricDelta {
  const _MetricDelta({
    required this.percent,
    required this.hasBaseline,
  });

  final double percent;
  final bool hasBaseline;
}

class _StockStatus {
  const _StockStatus({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}
