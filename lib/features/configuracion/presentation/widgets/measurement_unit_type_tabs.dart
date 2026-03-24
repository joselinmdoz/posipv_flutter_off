import 'package:flutter/material.dart';

import '../../../productos/data/productos_local_datasource.dart';

class MeasurementUnitTypeTabs extends StatelessWidget {
  const MeasurementUnitTypeTabs({
    super.key,
    required this.types,
    required this.selectedTypeId,
    required this.onChanged,
  });

  final List<MeasurementUnitTypeModel> types;
  final String selectedTypeId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _chip(label: 'Todas', value: 'all'),
          for (final MeasurementUnitTypeModel type in types) ...<Widget>[
            const SizedBox(width: 10),
            _chip(label: type.name, value: type.id),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required String value,
  }) {
    final bool selected = selectedTypeId == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1152D4) : const Color(0xFFE6E9EE),
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x331152D4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}
