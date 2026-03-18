import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/inventario_local_datasource.dart';

/// A single inventory product card following the modern compact design.
class InventoryProductCard extends StatelessWidget {
  final InventoryView row;
  final String Function(int cents, String currencyCode) moneyFromCents;
  final VoidCallback? onTap;

  const InventoryProductCard({
    super.key,
    required this.row,
    required this.moneyFromCents,
    this.onTap,
  });

  static const double _lowStockThreshold = 10;

  bool get _isOutOfStock => row.qty <= 0.000001;

  bool get _isLowStock => row.qty > 0 && row.qty <= _lowStockThreshold;

  String get _stockLabel {
    if (_isOutOfStock) return 'Agotado';
    if (_isLowStock) return '${_formatQty(row.qty)} en stock';
    return 'en stock';
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toStringAsFixed(0);
    return qty.toStringAsFixed(2);
  }

  Color _stockLabelColor(bool isDark) {
    if (_isOutOfStock) {
      return isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    }
    if (_isLowStock) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    }
    return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  }

  Color _stockBgColor(bool isDark) {
    if (_isOutOfStock) {
      return isDark
          ? const Color(0xFFE11D48).withValues(alpha: 0.12)
          : const Color(0xFFFFF1F2);
    }
    if (_isLowStock) {
      return isDark
          ? const Color(0xFFD97706).withValues(alpha: 0.12)
          : const Color(0xFFFEF3C7);
    }
    return isDark
        ? const Color(0xFF059669).withValues(alpha: 0.12)
        : const Color(0xFFECFDF5);
  }

  Widget _buildProductThumb(bool isDark) {
    final Color fallbackBg =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final String? path = row.imagePath;

    Widget fallback() {
      return Container(
        color: fallbackBg,
        child: Icon(
          Icons.inventory_2_rounded,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
          size: 24,
        ),
      );
    }

    if (path == null || path.trim().isEmpty) return fallback();

    final String resolved = path.trim();
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        cacheWidth: 200,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return Image.file(
      File(resolved),
      fit: BoxFit.cover,
      cacheWidth: 200,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: _buildProductThumb(isDark),
                ),
              ),
              const SizedBox(width: 14),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _stockBgColor(isDark),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _stockLabel,
                            style: TextStyle(
                              color: _stockLabelColor(isDark),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'SKU: ${row.sku}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Price + Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moneyFromCents(row.priceCents, row.currencyCode),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1152D4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
