import 'package:flutter/material.dart';

class AnalyticsKpiCard extends StatelessWidget {
  const AnalyticsKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.deltaPercent,
    this.deltaText,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final double? deltaPercent;
  final String? deltaText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasDelta = deltaPercent != null && deltaText != null;
    final bool positive = (deltaPercent ?? 0) >= 0;
    final Color deltaColor = positive
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48));
    final Color cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF263244) : const Color(0xFFDDE2EB);
    final Color tileColor =
        isDark ? const Color(0xFF1E293B) : const Color(0x1A1152D4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? null
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: const Color(0xFF1152D4)),
                  ),
                  const Spacer(),
                  if (hasDelta)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: positive
                            ? const Color(0x1A059669)
                            : const Color(0x1AE11D48),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        deltaText!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF5E6775),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 30 / 2,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
