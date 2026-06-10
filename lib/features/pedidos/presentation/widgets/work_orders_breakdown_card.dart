import 'package:flutter/material.dart';

class WorkOrdersBreakdownCard extends StatelessWidget {
  const WorkOrdersBreakdownCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bool interactive = onTap != null;
    final Color accent =
        isSelected ? const Color(0xFF1152D4) : const Color(0xFFE2E8F0);
    final Color background =
        isSelected ? const Color(0xFFEFF6FF) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF334155)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (interactive) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        isSelected
                            ? 'Toca para quitar del filtro'
                            : 'Toca para sumar al filtro',
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1152D4)
                              : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Text(
                    value,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1152D4)
                          : const Color(0xFF1152D4),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkOrdersInsightGrid extends StatelessWidget {
  const WorkOrdersInsightGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = 10,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int safeColumns = columns < 1 ? 1 : columns;
        final int resolvedColumns =
            constraints.maxWidth < 560 && safeColumns > 2 ? 2 : safeColumns;
        final double itemWidth =
            (constraints.maxWidth - (spacing * (resolvedColumns - 1))) /
                resolvedColumns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (Widget child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
