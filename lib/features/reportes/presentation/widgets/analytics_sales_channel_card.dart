import 'package:flutter/material.dart';

class AnalyticsSalesChannelCard extends StatelessWidget {
  const AnalyticsSalesChannelCard({
    super.key,
    required this.currencySymbol,
    required this.posOrdersCount,
    required this.posRevenueCents,
    required this.directOrdersCount,
    required this.directRevenueCents,
    this.onPosTap,
    this.onDirectTap,
  });

  final String currencySymbol;
  final int posOrdersCount;
  final int posRevenueCents;
  final int directOrdersCount;
  final int directRevenueCents;
  final VoidCallback? onPosTap;
  final VoidCallback? onDirectTap;

  String _moneyLabel(int cents) {
    return '$currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int totalRevenue = posRevenueCents + directRevenueCents;
    final int totalOrders = posOrdersCount + directOrdersCount;
    final double posRatio = totalRevenue > 0
        ? posRevenueCents / totalRevenue
        : (totalOrders > 0 ? posOrdersCount / totalOrders : 0);
    final int posPercent = (posRatio * 100).round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: onPosTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 98,
              height: 98,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFF253247)
                            : const Color(0xFFE7ECF3),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      value: posRatio,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1152D4)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$posPercent%',
                        style: TextStyle(
                          fontSize: 27 / 2,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'POS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: <Widget>[
                _ChannelRow(
                  label: 'Terminal POS',
                  ordersCount: posOrdersCount,
                  amount: _moneyLabel(posRevenueCents),
                  badgeColor: const Color(0xFF1152D4),
                  onTap: onPosTap,
                ),
                Divider(
                  height: 10,
                  color: isDark
                      ? const Color(0xFF263244)
                      : const Color(0xFFE7ECF3),
                ),
                _ChannelRow(
                  label: 'Venta directa',
                  ordersCount: directOrdersCount,
                  amount: _moneyLabel(directRevenueCents),
                  badgeColor: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFD1D5DB),
                  onTap: onDirectTap,
                ),
              ],
            ),
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
    required this.onTap,
  });

  final String label;
  final int ordersCount;
  final String amount;
  final Color badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$ordersCount vtas',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
