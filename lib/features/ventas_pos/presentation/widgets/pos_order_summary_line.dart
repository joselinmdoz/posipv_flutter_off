import 'dart:io';

import 'package:flutter/material.dart';

import 'pos_payment_models.dart';

class PosOrderSummaryLine extends StatelessWidget {
  const PosOrderSummaryLine({
    super.key,
    required this.line,
    required this.currencySymbol,
    required this.isDark,
    required this.canIncrease,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    this.unitPriceLabel,
    this.lineTotalLabel,
  });

  final PosCartLine line;
  final String currencySymbol;
  final bool isDark;
  final bool canIncrease;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final String? unitPriceLabel;
  final String? lineTotalLabel;

  @override
  Widget build(BuildContext context) {
    final double lineTotal = (line.product.priceCents / 100) * line.qty;
    final String itemTotalLabel =
        lineTotalLabel ?? '$currencySymbol${lineTotal.toStringAsFixed(2)}';
    final String itemUnitLabel = unitPriceLabel ??
        '$currencySymbol${(line.product.priceCents / 100).toStringAsFixed(2)} c/u';

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 390;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildImage(size: 54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          line.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          itemUnitLabel,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar producto',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(child: _buildQtyControls()),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      itemTotalLabel,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    line.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    itemUnitLabel,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildQtyControls(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  itemTotalLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  tooltip: 'Quitar producto',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage({double size = 60}) {
    final String imagePath = (line.product.imagePath ?? '').trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: imagePath.isEmpty
            ? Icon(Icons.inventory_2_outlined, color: Colors.grey[400])
            : Padding(
                padding: const EdgeInsets.all(4),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey[400]),
                ),
              ),
      ),
    );
  }

  Widget _buildQtyControls() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget qtyValue = SizedBox(
            width: constraints.maxWidth < 96 ? 24 : 32,
            child: Text(
              line.qty.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          );

          final List<Widget> controls = <Widget>[
            _QtyButton(
              icon: Icons.remove,
              enabled: line.qty > 1,
              onTap: onDecrease,
              isDark: isDark,
            ),
            qtyValue,
            _QtyButton(
              icon: Icons.add,
              enabled: canIncrease,
              onTap: onIncrease,
              isDark: isDark,
              filled: true,
            ),
          ];

          if (constraints.maxWidth < 96) {
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: controls,
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: controls,
          );
        },
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.isDark,
    this.filled = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool isDark;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled
              ? const Color(0xFF1152D4)
              : (isDark ? Colors.transparent : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: filled
              ? null
              : Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled
              ? Colors.white
              : (enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}
