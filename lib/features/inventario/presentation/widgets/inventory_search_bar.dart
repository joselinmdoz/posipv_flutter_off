import 'package:flutter/material.dart';

/// Modern search bar for the inventory page.
class InventorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterTap;

  const InventorySearchBar({
    super.key,
    required this.controller,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto o SKU...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              if (value.text.isNotEmpty)
                IconButton(
                  onPressed: controller.clear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                child: IconButton(
                  onPressed: onFilterTap,
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
