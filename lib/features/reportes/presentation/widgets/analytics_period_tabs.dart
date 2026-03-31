import 'package:flutter/material.dart';

import '../../data/reportes_local_datasource.dart';

class AnalyticsPeriodTabs extends StatelessWidget {
  const AnalyticsPeriodTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SalesAnalyticsGranularity selected;
  final ValueChanged<SalesAnalyticsGranularity> onSelected;

  static const List<_PeriodTabItem> _items = <_PeriodTabItem>[
    _PeriodTabItem('Día', SalesAnalyticsGranularity.day),
    _PeriodTabItem('Sem.', SalesAnalyticsGranularity.week),
    _PeriodTabItem('Mes', SalesAnalyticsGranularity.month),
    _PeriodTabItem('Año', SalesAnalyticsGranularity.year),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF2F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.map((_PeriodTabItem item) {
          final bool active = item.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onSelected(item.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? (isDark ? const Color(0xFF1F2937) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active && !isDark
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? const Color(0xFF1152D4)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _PeriodTabItem {
  const _PeriodTabItem(this.label, this.value);

  final String label;
  final SalesAnalyticsGranularity value;
}
