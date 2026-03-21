import 'package:flutter/material.dart';

class ClientsFilterTabs extends StatelessWidget {
  const ClientsFilterTabs({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  static const List<_FilterTab> _tabs = <_FilterTab>[
    _FilterTab(id: 'todos', label: 'Todos'),
    _FilterTab(id: 'frecuente', label: 'Frecuente'),
    _FilterTab(id: 'mayorista', label: 'Mayorista'),
    _FilterTab(id: 'nuevo', label: 'Nuevo'),
    _FilterTab(id: 'vip', label: 'VIP'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((_FilterTab tab) {
          final bool selected = currentFilter == tab.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onFilterChanged(tab.id),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1152D4)
                      : const Color(0xFFE1E5EA),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color:
                                const Color(0xFF1152D4).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF30384A),
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

class _FilterTab {
  const _FilterTab({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
