import 'package:flutter/material.dart';

import '../../../productos/data/productos_local_datasource.dart';

class MeasurementUnitTypeCard extends StatelessWidget {
  const MeasurementUnitTypeCard({
    super.key,
    required this.type,
    required this.unitsCount,
    required this.activeUnitsCount,
    required this.onEdit,
    required this.onToggleActive,
  });

  final MeasurementUnitTypeModel type;
  final int unitsCount;
  final int activeUnitsCount;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final bool isActive = type.isActive;
    final Color accent =
        isActive ? const Color(0xFF1152D4) : const Color(0xFF94A3B8);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          type.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (type.description.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            type.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '$activeUnitsCount activas de $unitsCount unidades',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            _statusPill(
                              label: isActive ? 'Activo' : 'Inactivo',
                              color: isActive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF6B7280),
                              bg: isActive
                                  ? const Color(0xFFDFF6EC)
                                  : const Color(0xFFE5E7EB),
                            ),
                            if (type.isSystem) ...<Widget>[
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
