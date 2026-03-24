import 'package:flutter/material.dart';

class AnalyticsSalesChannelCard extends StatelessWidget {
  const AnalyticsSalesChannelCard({
    super.key,
    required this.currencySymbol,
    required this.posOrdersCount,
    required this.posRevenueCents,
    required this.directOrdersCount,
    required this.directRevenueCents,
  });

  final String currencySymbol;
  final int posOrdersCount;
  final int posRevenueCents;
  final int directOrdersCount;
  final int directRevenueCents;

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
            'Canales de Venta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _ChannelRow(
            label: 'POS',
            ordersCount: posOrdersCount,
            amount:
                '$currencySymbol${(posRevenueCents / 100).toStringAsFixed(2)}',
            badgeColor: const Color(0xFF1152D4),
          ),
          const SizedBox(height: 8),
          _ChannelRow(
            label: 'Venta directa',
            ordersCount: directOrdersCount,
            amount:
                '$currencySymbol${(directRevenueCents / 100).toStringAsFixed(2)}',
            badgeColor: const Color(0xFF0D9488),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.label,
    required this.ordersCount,
    required this.amount,
    required this.badgeColor,
  });

  final String label;
  final int ordersCount;
  final String amount;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '$ordersCount ventas',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
