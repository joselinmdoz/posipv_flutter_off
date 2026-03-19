import 'package:flutter/material.dart';

class TpvSessionHistoryCompactCard extends StatelessWidget {
  const TpvSessionHistoryCompactCard({
    super.key,
    required this.sessionCode,
    required this.title,
    required this.amountText,
    required this.onTap,
  });

  final String sessionCode;
  final String title;
  final String amountText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFD8DEE9),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TURNO $sessionCode',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF94A3B8),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$title - $amountText',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text(
              'VER',
              style: TextStyle(
                color: Color(0xFF1152D4),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
