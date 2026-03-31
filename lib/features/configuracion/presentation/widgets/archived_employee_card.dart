import 'package:flutter/material.dart';

import '../../../tpv/data/tpv_local_datasource.dart';
import '../../../tpv/presentation/widgets/tpv_employee_avatar.dart';

class ArchivedEmployeeCard extends StatelessWidget {
  const ArchivedEmployeeCard({
    super.key,
    required this.employee,
    this.onRestore,
    this.onDeletePermanently,
  });

  final TpvEmployee employee;
  final VoidCallback? onRestore;
  final VoidCallback? onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    final String identity = (employee.identityNumber ?? '').trim();
    final String user = (employee.associatedUsername ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 50,
            height: 50,
            child: TpvEmployeeAvatar(
              imagePath: employee.imagePath,
              radius: 25,
              backgroundColor: const Color(0xFFF3F4F6),
              iconColor: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Código: ${employee.code}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (identity.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    'CI: $identity',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (user.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    '@$user',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1152D4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ARCHIVADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFBE123C),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (onRestore != null) ...<Widget>[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Restaurar'),
                ),
              ],
              if (onDeletePermanently != null) ...<Widget>[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onDeletePermanently,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('Eliminar definitivo'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
