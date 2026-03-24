import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/db/app_database.dart';
import '../../../../shared/widgets/qty_stepper_input.dart';

class PosProductCard extends StatelessWidget {
  const PosProductCard({
    super.key,
    required this.product,
    required this.qty,
    required this.stock,
    required this.currencySymbol,
    required this.isPosting,
    required this.onQtyChanged,
    required this.onQtySet,
  });

  final Product product;
  final double qty;
  final double stock;
  final String currencySymbol;
  final bool isPosting;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onQtySet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String imagePath = (product.imagePath ?? '').trim();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double naturalImageHeight =
            (constraints.maxWidth * 0.36).clamp(78.0, 132.0);
        double imageHeight = naturalImageHeight;
        if (constraints.maxHeight.isFinite) {
          // Reserve enough space for text + price + qty controls to avoid
          // vertical overflow in compact screens/tablets.
          const double minBodyHeight = 92.0;
          final double maxImageByHeight = constraints.maxHeight - minBodyHeight;
          if (maxImageByHeight > 52) {
            imageHeight = naturalImageHeight.clamp(52.0, maxImageByHeight);
          } else {
            imageHeight = 52.0;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: <BoxShadow>[
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
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 24,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 32,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFF1F5F9)
                                  .withValues(alpha: 0.5),
                            ),
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
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
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
                child: LayoutBuilder(
                  builder:
                      (BuildContext context, BoxConstraints bodyConstraints) {
                    final bool compact = bodyConstraints.maxHeight <= 106;
                    final bool ultraCompact = bodyConstraints.maxHeight <= 92;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        ultraCompact
                            ? 4
                            : compact
                                ? 5
                                : 8,
                        10,
                        ultraCompact
                            ? 4
                            : compact
                                ? 5
                                : 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.name,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: ultraCompact
                                  ? 12
                                  : compact
                                      ? 12.5
                                      : 13.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(
                              height: ultraCompact
                                  ? 1
                                  : compact
                                      ? 2
                                      : 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Text(
                                currencySymbol,
                                style: TextStyle(
                                  fontSize: ultraCompact
                                      ? 8.5
                                      : compact
                                          ? 9
                                          : 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  (product.priceCents / 100).toStringAsFixed(2),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: ultraCompact
                                        ? 14.5
                                        : compact
                                            ? 15.5
                                            : 17,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          QtyStepperInput(
                            value: qty,
                            enabled: !isPosting,
                            canDecrement: qty > 0,
                            onDecrement:
                                qty > 0 ? () => onQtyChanged(-1) : null,
                            onIncrement: () => onQtyChanged(1),
                            onSubmittedValue: onQtySet,
                            height: ultraCompact
                                ? 30
                                : compact
                                    ? 32
                                    : 38,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
