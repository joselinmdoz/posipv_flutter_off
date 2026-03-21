import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/db/app_database.dart';

class PosProductCard extends StatelessWidget {
  final Product product;
  final double qty;
  final double stock;
  final String currencySymbol;
  final bool isPosting;
  final Function(double delta) onQtyChanged;

  const PosProductCard({
    super.key,
    required this.product,
    required this.qty,
    required this.stock,
    required this.currencySymbol,
    required this.isPosting,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String imagePath = (product.imagePath ?? '').trim();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double imageHeight =
            (constraints.maxWidth * 0.48).clamp(96.0, 164.0);

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: imageHeight,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Container(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        child: imagePath.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.file(
                                  File(imagePath),
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        size: 24, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.inventory_2_outlined,
                                    size: 32, color: Color(0xFFCBD5E1)),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFFF1F5F9)
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            product.sku,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                stock.toStringAsFixed(0),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final Widget priceView = Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Text(
                                currencySymbol,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  (product.priceCents / 100).toStringAsFixed(2),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          );

                          final Widget qtyControls = Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _PosQtyRoundedBtn(
                                  icon: Icons.remove,
                                  filled: false,
                                  enabled: !isPosting && qty > 0,
                                  onTap:
                                      qty > 0 ? () => onQtyChanged(-1) : null,
                                  isDark: isDark,
                                ),
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    qty.toStringAsFixed(0),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                _PosQtyRoundedBtn(
                                  icon: Icons.add,
                                  filled: true,
                                  enabled: !isPosting,
                                  onTap: () => onQtyChanged(1),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          );

                          if (constraints.maxWidth < 190) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                priceView,
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: qtyControls,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: <Widget>[
                              Expanded(child: priceView),
                              qtyControls,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PosQtyRoundedBtn extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isDark;

  const _PosQtyRoundedBtn({
    required this.icon,
    required this.filled,
    required this.enabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF1152D4)
              : (isDark ? Colors.transparent : Colors.white),
          borderRadius: BorderRadius.circular(4),
          border: filled
              ? null
              : Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: const Color(0xFF1152D4).withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 14,
          color: filled
              ? Colors.white
              : (enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}
