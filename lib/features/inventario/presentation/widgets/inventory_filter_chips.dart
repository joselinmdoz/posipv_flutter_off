import 'package:flutter/material.dart';
import '../../data/inventario_local_datasource.dart';

/// Horizontal scrollable filter chips for inventory stock status.
class InventoryFilterChips extends StatelessWidget {
  final InventoryListFilter currentFilter;
  final ValueChanged<InventoryListFilter> onFilterChanged;

  const InventoryFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Todos', InventoryListFilter.all, isDark),
          const SizedBox(width: 8),
          _chip('En stock', InventoryListFilter.inStock, isDark),
          const SizedBox(width: 8),
          _chip('Stock bajo', InventoryListFilter.lowStock, isDark),
          const SizedBox(width: 8),
          _chip('Agotado', InventoryListFilter.outOfStock, isDark),
        ],
      ),
    );
  }

  Widget _chip(String label, InventoryListFilter filter, bool isDark) {
    final bool isSelected = currentFilter == filter;

    final Color bgColor = isSelected
        ? const Color(0xFF1152D4)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final Color textColor = isSelected
        ? Colors.white
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
    final Color borderColor = isSelected
        ? const Color(0xFF1152D4)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return GestureDetector(
      onTap: () => onFilterChanged(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF1152D4).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
