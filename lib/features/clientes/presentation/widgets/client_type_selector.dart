import 'package:flutter/material.dart';

class ClientTypeSelector extends StatelessWidget {
  const ClientTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const List<_ClientTypeOption> _options = <_ClientTypeOption>[
    _ClientTypeOption(id: 'general', label: 'General'),
    _ClientTypeOption(id: 'frecuente', label: 'Frecuente'),
    _ClientTypeOption(id: 'mayorista', label: 'Mayorista'),
    _ClientTypeOption(id: 'nuevo', label: 'Nuevo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((_ClientTypeOption option) {
        final bool selected = option.id == value;
        return InkWell(
          onTap: () => onChanged(option.id),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:
                  selected ? const Color(0xFF1152D4) : const Color(0xFFE1E5EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              option.label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF30384A),
                fontWeight: FontWeight.w700,
                fontSize: 30 / 2,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ClientTypeOption {
  const _ClientTypeOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
