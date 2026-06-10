import 'package:flutter/material.dart';

import '../../data/pedidos_local_datasource.dart';

class WorkOrderStatusBadge extends StatelessWidget {
  const WorkOrderStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final WorkOrderStatusColors colors = workOrderStatusColorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        WorkOrderStatusCatalog.label(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors.foreground,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

WorkOrderStatusColors workOrderStatusColorsFor(String value) {
  switch (value.trim()) {
    case WorkOrderStatusCatalog.inProgress:
      return const WorkOrderStatusColors(
        background: Color(0xFFFFF1D6),
        foreground: Color(0xFFB45309),
      );
    case WorkOrderStatusCatalog.ready:
      return const WorkOrderStatusColors(
        background: Color(0xFFEDE9FE),
        foreground: Color(0xFF6D28D9),
      );
    case WorkOrderStatusCatalog.delivered:
      return const WorkOrderStatusColors(
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF047857),
      );
    case WorkOrderStatusCatalog.cancelled:
      return const WorkOrderStatusColors(
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFFB91C1C),
      );
    case WorkOrderStatusCatalog.pending:
    default:
      return const WorkOrderStatusColors(
        background: Color(0xFFDBEAFE),
        foreground: Color(0xFF1152D4),
      );
  }
}

class WorkOrderStatusColors {
  const WorkOrderStatusColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
