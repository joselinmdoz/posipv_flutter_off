import 'package:flutter/material.dart';

import '../../data/tpv_local_datasource.dart';
import 'tpv_employee_avatar.dart';

enum TpvEmployeeCardAction {
  edit,
  toggleActive,
  delete,
}

class TpvEmployeeListCard extends StatelessWidget {
  const TpvEmployeeListCard({
    super.key,
    required this.employee,
    required this.onTap,
    required this.onActionSelected,
  });

  final TpvEmployee employee;
  final VoidCallback onTap;
  final ValueChanged<TpvEmployeeCardAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isActive = employee.isActive;
    final Color accent =
        isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8);
    final Color badgeBg =
        isActive ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0);
    final Color badgeFg =
        isActive ? const Color(0xFF15803D) : const Color(0xFF475569);
    final String? genderText = _genderLabel(employee.sex);
    final String? ciText = _ciLabel(employee.identityNumber);
    final String? codeText =
        employee.code.trim().isEmpty ? null : 'Código: ${employee.code}';
    final String? userText = (employee.associatedUsername ?? '').trim().isEmpty
        ? null
        : '@${employee.associatedUsername}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isActive ? const Color(0xFFDCE7F5) : const Color(0xFFE5E7EB),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 5,
                  height: 150,
                  color: accent,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TpvEmployeeAvatar(
                          imagePath: employee.imagePath,
                          radius: 32,
                          backgroundColor: isActive
                              ? const Color(0xFFEAF2FF)
                              : const Color(0xFFF1F5F9),
                          iconColor: isActive
                              ? const Color(0xFF1152D4)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      employee.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isActive ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: badgeFg,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  if (genderText != null)
                                    _InfoPill(
                                      icon: Icons.wc_rounded,
                                      text: genderText,
                                    ),
                                  if (ciText != null)
                                    _InfoPill(
                                      icon: Icons.badge_outlined,
                                      text: ciText,
                                    ),
                                  if (codeText != null)
                                    _InfoPill(
                                      icon: Icons.qr_code_2_rounded,
                                      text: codeText,
                                    ),
                                ],
                              ),
                              if (userText != null) ...<Widget>[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.person_pin_circle_outlined,
                                        size: 15,
                                        color: Color(0xFF1152D4),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        userText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1152D4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<TpvEmployeeCardAction>(
                          tooltip: 'Opciones',
                          onSelected: onActionSelected,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<TpvEmployeeCardAction>>[
                            const PopupMenuItem<TpvEmployeeCardAction>(
                              value: TpvEmployeeCardAction.edit,
                              child: _MenuOptionRow(
                                icon: Icons.edit_outlined,
                                label: 'Editar',
                              ),
                            ),
                            PopupMenuItem<TpvEmployeeCardAction>(
                              value: TpvEmployeeCardAction.toggleActive,
                              child: _MenuOptionRow(
                                icon: isActive
                                    ? Icons.block_rounded
                                    : Icons.check_circle_outline_rounded,
                                label: isActive ? 'Desactivar' : 'Activar',
                              ),
                            ),
                            PopupMenuItem<TpvEmployeeCardAction>(
                              value: TpvEmployeeCardAction.delete,
                              child: _MenuOptionRow(
                                icon: Icons.delete_forever_rounded,
                                label: isActive
                                    ? 'Desactivar para eliminar'
                                    : 'Eliminar',
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _genderLabel(String? sex) {
    final String value = (sex ?? '').trim().toUpperCase();
    if (value.isEmpty) {
      return null;
    }
    switch (value) {
      case 'F':
        return 'Femenino';
      case 'M':
        return 'Masculino';
      case 'X':
        return 'Otro';
      default:
        return value;
    }
  }

  String? _ciLabel(String? identityNumber) {
    final String value = (identityNumber ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return 'CI: $value';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuOptionRow extends StatelessWidget {
  const _MenuOptionRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? const Color(0xFF334155);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: effectiveColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
