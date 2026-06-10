import 'package:flutter/material.dart';

import '../../data/pedidos_local_datasource.dart';

class WorkOrdersStatusTabs extends StatelessWidget {
  const WorkOrdersStatusTabs({
    super.key,
    required this.currentFilter,
    required this.onChanged,
  });

  final String currentFilter;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<_StatusTab> tabs = <_StatusTab>[
      _StatusTab(value: 'all', label: 'Todos'),
      _StatusTab(value: WorkOrderStatusCatalog.pending, label: 'Pendientes'),
      _StatusTab(
        value: WorkOrderStatusCatalog.inProgress,
        label: 'Producción',
      ),
      _StatusTab(value: WorkOrderStatusCatalog.ready, label: 'Por entregar'),
      _StatusTab(value: WorkOrderStatusCatalog.delivered, label: 'Finalizados'),
      _StatusTab(value: WorkOrderStatusCatalog.cancelled, label: 'Cancelados'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((_StatusTab tab) {
          final bool active = currentFilter == tab.value;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(tab.value),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1152D4)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: active
                        ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF1152D4)
                                  .withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w700,
                    ),
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

class _StatusTab {
  const _StatusTab({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}
