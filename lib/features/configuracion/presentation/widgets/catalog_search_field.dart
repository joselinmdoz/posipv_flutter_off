import 'package:flutter/material.dart';

class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, TextEditingValue value, __) {
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 14),
              Icon(
                Icons.search_rounded,
                size: 22,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (value.text.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar',
                  onPressed: controller.clear,
                  icon: Icon(
                    Icons.close_rounded,
                    color:
                        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
