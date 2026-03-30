import 'package:flutter/material.dart';

import '../../data/reportes_local_datasource.dart';

class AnalyticsBreakdownCard extends StatelessWidget {
  const AnalyticsBreakdownCard({
    super.key,
    required this.title,
    required this.currencySymbol,
    required this.totalBaseCents,
    required this.items,
    this.emptyLabel = 'Sin datos para el rango.',
    this.onItemTap,
  });

  final String title;
  final String currencySymbol;
  final int totalBaseCents;
  final List<SalesBreakdownStat> items;
  final String emptyLabel;
  final ValueChanged<SalesBreakdownStat>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            )
          else
            ...items.take(6).map(
                  (SalesBreakdownStat row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BreakdownRow(
                      currencySymbol: currencySymbol,
                      totalBaseCents: totalBaseCents,
                      row: row,
                      onTap: onItemTap == null ? null : () => onItemTap!(row),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.currencySymbol,
    required this.totalBaseCents,
    required this.row,
    required this.onTap,
  });

  final String currencySymbol;
  final int totalBaseCents;
  final SalesBreakdownStat row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double pct = totalBaseCents <= 0
        ? 0
        : ((row.totalCents / totalBaseCents) * 100).clamp(0, 100);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currencySymbol${(row.totalCents / 100).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${row.ordersCount} ventas · ${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                borderRadius: BorderRadius.circular(999),
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF1152D4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
