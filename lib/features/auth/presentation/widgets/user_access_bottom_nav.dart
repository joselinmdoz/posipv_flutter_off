import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserAccessBottomNav extends StatelessWidget {
  const UserAccessBottomNav({
    super.key,
    required this.activeTab,
    required this.onUsersTap,
    required this.onRolesTap,
  });

  final UserAccessBottomTab activeTab;
  final VoidCallback onUsersTap;
  final VoidCallback onRolesTap;

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
              label: 'Dashboard',
              selected: false,
              onTap: () => context.go('/home'),
            ),
            _NavBtn(
              icon: Icons.group_rounded,
              label: 'Usuarios',
              selected: activeTab == UserAccessBottomTab.users,
              onTap: onUsersTap,
            ),
            _NavBtn(
              icon: Icons.verified_user_rounded,
              label: 'Roles',
              selected: activeTab == UserAccessBottomTab.roles,
              onTap: onRolesTap,
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

enum UserAccessBottomTab {
  users,
  roles,
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
          horizontal: selected ? 20 : 12,
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
                fontSize: 13,
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
