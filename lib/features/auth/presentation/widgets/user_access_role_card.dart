import 'package:flutter/material.dart';

import '../../data/auth_local_datasource.dart';

class UserAccessRoleCard extends StatelessWidget {
  const UserAccessRoleCard({
    super.key,
    required this.role,
    required this.isAdminRole,
    required this.onTap,
    required this.onActionSelected,
  });

  final AuthRoleSummary role;
  final bool isAdminRole;
  final VoidCallback onTap;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = isAdminRole;
    final IconData roleIcon = _iconForRole(role);
    final String roleDescription = (role.description ?? '').trim().isEmpty
        ? _defaultDescription()
        : role.description!.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    roleIcon,
                    color: isPrimary
                        ? const Color(0xFF1152D4)
                        : const Color(0xFF5E6983),
                    size: 22,
                  ),
                  const Spacer(),
                  if (isAdminRole)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4EBFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MASTER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFF1B2D5D),
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: onActionSelected,
                    itemBuilder: (_) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      if (!isAdminRole)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                role.name,
                style: const TextStyle(
                  fontSize: 38 / 2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF11141B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                roleDescription,
                style: const TextStyle(
                  fontSize: 32 / 2,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2F3545),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForRole(AuthRoleSummary role) {
    final String roleName = role.name.trim().toLowerCase();
    if (roleName.contains('admin')) {
      return Icons.verified_user_rounded;
    }
    if (roleName.contains('caj')) {
      return Icons.point_of_sale_rounded;
    }
    return Icons.shield_outlined;
  }

  String _defaultDescription() {
    if (isAdminRole) {
      return 'Acceso total al sistema y configuraciones críticas.';
    }
    final String roleName = role.name.trim().toLowerCase();
    if (roleName.contains('caj')) {
      return 'Operaciones de venta y cierre de caja diario.';
    }
    return 'Gestión de inventario y operación del negocio.';
  }
}
