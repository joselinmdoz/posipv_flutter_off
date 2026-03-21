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
    _PeriodTabItem('Semana', SalesAnalyticsGranularity.week),
    _PeriodTabItem('Mes', SalesAnalyticsGranularity.month),
    _PeriodTabItem('Año', SalesAnalyticsGranularity.year),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _items.map((_PeriodTabItem item) {
          final bool active = item.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelected(item.value),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Column(
                  children: <Widget>[
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? const Color(0xFF1152D4)
                            : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 9),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: item.label.length * 7,
                      height: 3,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF1152D4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
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
