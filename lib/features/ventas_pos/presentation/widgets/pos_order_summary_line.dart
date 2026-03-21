import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/widgets/qty_stepper_input.dart';
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
    required this.onSetQty,
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
  final ValueChanged<double> onSetQty;
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
        final bool compact = constraints.maxWidth < 380;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildImage(size: compact ? 54 : 58),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        line.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
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
            if (compact) ...<Widget>[
              _buildQtyControls(),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  itemTotalLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ] else
              Row(
                children: <Widget>[
                  Expanded(child: _buildQtyControls()),
                  const SizedBox(width: 10),
                  Expanded(
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
                    color: Colors.grey[400],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQtyControls() {
    return QtyStepperInput(
      value: line.qty,
      canDecrement: line.qty > 0,
      canIncrement: canIncrease,
      onDecrement: line.qty > 0 ? onDecrease : null,
      onIncrement: onIncrease,
      onSubmittedValue: onSetQty,
    );
  }
}
