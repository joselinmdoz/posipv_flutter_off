import 'dart:io';

import 'package:flutter/material.dart';

class AnalyticsTopProductTile extends StatelessWidget {
  const AnalyticsTopProductTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.deltaPercent,
    required this.deltaText,
    this.imagePath,
  });

  final String name;
  final String subtitle;
  final String amount;
  final double deltaPercent;
  final String deltaText;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool positive = deltaPercent >= 0;
    final Color deltaColor = positive
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
        ),
      ),
      child: Row(
        children: <Widget>[
          _ProductImage(imagePath: imagePath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 29 / 2,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deltaText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String? rawPath = imagePath?.trim();
    final bool hasImage =
        rawPath != null && rawPath.isNotEmpty && File(rawPath).existsSync();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(
              File(rawPath),
              fit: BoxFit.cover,
            )
          : Icon(
              Icons.inventory_2_outlined,
              size: 24,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
            ),
    );
  }
}
