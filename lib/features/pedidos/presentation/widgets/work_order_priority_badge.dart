import 'package:flutter/material.dart';

import '../../data/pedidos_local_datasource.dart';

class WorkOrderPriorityBadge extends StatelessWidget {
  const WorkOrderPriorityBadge({
    super.key,
    required this.priority,
  });

  final String priority;

  @override
  Widget build(BuildContext context) {
    final _PriorityColors colors = _colorsFor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        WorkOrderPriorityCatalog.label(priority),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colors.foreground,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  _PriorityColors _colorsFor(String value) {
    switch (value.trim()) {
      case WorkOrderPriorityCatalog.low:
        return const _PriorityColors(
          background: Color(0xFFF1F5F9),
          foreground: Color(0xFF475569),
        );
      case WorkOrderPriorityCatalog.urgent:
        return const _PriorityColors(
          background: Color(0xFFFEE2E2),
          foreground: Color(0xFFB91C1C),
        );
      case WorkOrderPriorityCatalog.normal:
      default:
        return const _PriorityColors(
          background: Color(0xFFFFF1D6),
          foreground: Color(0xFFB45309),
        );
    }
  }
}

class _PriorityColors {
  const _PriorityColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
