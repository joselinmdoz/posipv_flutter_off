import 'package:flutter/material.dart';

class TpvSessionHistoryFilterTabs extends StatelessWidget {
  const TpvSessionHistoryFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = <String>[
    'Todos',
    'Abiertos',
    'Cerrados',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF111827) : Colors.white,
      child: Row(
        children: List<Widget>.generate(_labels.length, (int index) {
          final bool isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1152D4)
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _labels[index],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1152D4)
                      : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
