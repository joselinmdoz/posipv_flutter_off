import 'package:flutter/material.dart';

class InventoryMovementTypeTabs extends StatelessWidget {
  const InventoryMovementTypeTabs({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _tabChip('Todos', 'all'),
          const SizedBox(width: 10),
          _tabChip('Entradas', 'in'),
          const SizedBox(width: 10),
          _tabChip('Salidas', 'out'),
          const SizedBox(width: 10),
          _tabChip('Ajustes', 'adjust'),
        ],
      ),
    );
  }

  Widget _tabChip(String label, String value) {
    final bool selected = selectedType == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
