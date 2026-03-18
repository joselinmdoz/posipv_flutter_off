import 'package:flutter/material.dart';

class PosSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onScanTap;
  final List<String> categories;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;

  const PosSearchBar({
    super.key,
    required this.controller,
    required this.onScanTap,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _ProductFilterField(
            controller: controller,
            onScanTap: onScanTap,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        _CategoryFilterButton(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategoryChanged: onCategoryChanged,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ProductFilterField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onScanTap;
  final bool isDark;

  const _ProductFilterField({
    required this.controller,
    required this.onScanTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? const <BoxShadow>[]
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Buscar productos por nombre o SKU...',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value.text.isNotEmpty)
                    IconButton(
                      onPressed: controller.clear,
                      icon: Icon(
                        Icons.clear_rounded,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  IconButton(
                    onPressed: onScanTap,
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Color(0xFF1152D4),
                    ),
                  ),
                ],
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;
  final bool isDark;

  const _CategoryFilterButton({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Categorías',
        icon: Icon(
          Icons.tune_rounded,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        onSelected: onCategoryChanged,
        itemBuilder: (context) => categories.map((cat) {
          final bool active = cat == selectedCategory;
          return PopupMenuItem<String>(
            value: cat,
            child: Row(
              children: [
                if (active) ...[
                  const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1152D4)),
                  const SizedBox(width: 8),
                ],
                Text(
                  cat,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? const Color(0xFF1152D4) : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
