import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientsBottomNav extends StatelessWidget {
  const ClientsBottomNav({
    super.key,
    required this.activeTab,
  });

  final ClientsBottomTab activeTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _NavBtn(
              icon: Icons.dashboard_rounded,
              label: 'Principal',
              selected: false,
              onTap: () => context.go('/home'),
            ),
            _NavBtn(
              icon: Icons.point_of_sale_rounded,
              label: 'TPV',
              selected: false,
              onTap: () => context.go('/tpv'),
            ),
            _NavBtn(
              icon: Icons.group_rounded,
              label: 'Clientes',
              selected: activeTab == ClientsBottomTab.clientes,
              onTap: () => context.go('/clientes'),
            ),
            _NavBtn(
              icon: Icons.inventory_2_outlined,
              label: 'Inventario',
              selected: false,
              onTap: () => context.go('/inventario'),
            ),
            _NavBtn(
              icon: Icons.settings_rounded,
              label: 'Ajustes',
              selected: false,
              onTap: () => context.go('/configuracion'),
            ),
          ],
        ),
      ),
    );
  }
}

enum ClientsBottomTab {
  clientes,
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : const Color(0xFF3F4658);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1152D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 22, color: fg),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
