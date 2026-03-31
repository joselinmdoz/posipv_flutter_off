import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/db/app_database.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onQrTap,
    this.stockQuantity,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onQrTap;
  final double? stockQuantity;

  Widget _buildImageContent(BuildContext context, String? path, bool isDark) {
    final Color placeholder =
        isDark ? const Color(0xFF233044) : const Color(0xFFEAF0F7);
    final Color placeholderIcon =
        isDark ? const Color(0xFF9FB0C8) : const Color(0xFF6D809A);

    if (path == null || path.isEmpty) {
      return Container(
        color: placeholder,
        child: Icon(
          Icons.inventory_2_outlined,
          color: placeholderIcon,
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        cacheWidth: 480,
        errorBuilder: (_, __, ___) => Container(
          color: placeholder,
          child: Icon(Icons.broken_image_outlined, color: placeholderIcon),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: 480,
      errorBuilder: (_, __, ___) => Container(
        color: placeholder,
        child: Icon(Icons.broken_image_outlined, color: placeholderIcon),
      ),
    );
  }

  String _formatCents(int cents, String currency) {
    return '$currency ${(cents / 100).toStringAsFixed(2)}';
  }

  Widget _metaPill(BuildContext context, String text, bool isDark) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : const Color(0xFFF1F5F9), // slate-100
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B), // slate-400 / slate-500
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String barcode = (product.barcode ?? '').trim();

    // Determine badge color if stockQuantity is provided
    Color? badgeBg;
    Color? badgeBorder;
    Color? badgeText;
    if (stockQuantity != null) {
      if (stockQuantity! > 10) {
        badgeBg = isDark
            ? const Color(0x99064E3B)
            : const Color(0xE6D1FAE5); // emerald-900/60 : emerald-100/90
        badgeBorder =
            isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
        badgeText = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
      } else if (stockQuantity! > 0) {
        badgeBg = isDark
            ? const Color(0x9978350F)
            : const Color(0xE6FEF3C7); // amber-900/60 : amber-100/90
        badgeBorder =
            isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A);
        badgeText = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
      } else {
        badgeBg = isDark
            ? const Color(0xE6334155)
            : const Color(0xE6E2E8F0); // slate-700/90 : slate-200/90
        badgeBorder =
            isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
        badgeText = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Enforce aspect ratio visually by allowing children to expand
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white, // slate-800
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFF1F5F9), // slate-700 : slate-100
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Image and text row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Image container
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildImageContent(
                                context, product.imagePath, isDark),
                          ),
                          const SizedBox(width: 12),
                          // Text column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.sku,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                if (barcode.isNotEmpty)
                                  Text(
                                    barcode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tags in a single horizontal lane to avoid vertical overflow.
                      SizedBox(
                        height: 18,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: <Widget>[
                              _metaPill(context, product.category, isDark),
                              const SizedBox(width: 4),
                              _metaPill(context, product.productType, isDark),
                              const SizedBox(width: 4),
                              _metaPill(context, product.unitMeasure, isDark),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Prices
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? const Color(0x80334155)
                                  : const Color(0xFFF8FAFC),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _formatCents(
                                  product.priceCents, product.currencyCode),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Costo: ${_formatCents(product.costPriceCents, product.currencyCode)}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stock Badge (Optional)
                if (stockQuantity != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(12),
                        ),
                        border: Border(
                          left: BorderSide(color: badgeBorder!),
                          bottom: BorderSide(color: badgeBorder),
                        ),
                      ),
                      child: Text(
                        stockQuantity == stockQuantity!.roundToDouble()
                            ? stockQuantity!.toInt().toString()
                            : stockQuantity!.toStringAsFixed(2),
                        style: TextStyle(
                          color: badgeText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
