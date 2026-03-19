import 'package:flutter/material.dart';

class TpvHistoryBottomNavigation extends StatelessWidget {
  const TpvHistoryBottomNavigation({
    super.key,
    required this.onRouteTap,
  });

  final ValueChanged<String> onRouteTap;

  static const List<_HistoryNavItem> _items = <_HistoryNavItem>[
    _HistoryNavItem(
      route: '/home',
      label: 'Inicio',
      icon: Icons.home_rounded,
    ),
    _HistoryNavItem(
      route: '/ventas-directas',
      label: 'Ventas',
      icon: Icons.point_of_sale_rounded,
    ),
    _HistoryNavItem(
      route: '/tpv-history',
      label: 'Historial',
      icon: Icons.history_rounded,
      active: true,
    ),
    _HistoryNavItem(
      route: '/tpv-empleados',
      label: 'Usuarios',
      icon: Icons.group_rounded,
    ),
    _HistoryNavItem(
      route: '/configuracion',
      label: 'Ajustes',
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFD8DEE9),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _items.map((item) {
          final Color color = item.active
              ? const Color(0xFF1152D4)
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8));
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!item.active) {
                  onRouteTap(item.route);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.icon, color: color, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            item.active ? FontWeight.w800 : FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryNavItem {
  const _HistoryNavItem({
    required this.route,
    required this.label,
    required this.icon,
    this.active = false,
  });

  final String route;
  final String label;
  final IconData icon;
  final bool active;
}
