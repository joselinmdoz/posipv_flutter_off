import 'package:flutter/material.dart';

import '../../../productos/data/productos_local_datasource.dart';

class MeasurementUnitCard extends StatelessWidget {
  const MeasurementUnitCard({
    super.key,
    required this.unit,
    required this.typeName,
    required this.onEdit,
    required this.onToggleActive,
  });

  final MeasurementUnitModel unit;
  final String typeName;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final bool isActive = unit.isActive;
    final Color accent = isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 5, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFDFF6EC)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unit.symbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          unit.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tipo: $typeName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            _statusPill(
                              label: isActive ? 'Activa' : 'Inactiva',
                              color: isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF6B7280),
                              bg: isActive
                                  ? const Color(0xFFDFF6EC)
                                  : const Color(0xFFE5E7EB),
                            ),
                            if (unit.isSystem) ...<Widget>[
                              const SizedBox(width: 8),
                              _statusPill(
                                label: 'Sistema',
                                color: const Color(0xFF1152D4),
                                bg: const Color(0xFFDEE9FF),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      Switch.adaptive(
                        value: isActive,
                        onChanged: onToggleActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}
