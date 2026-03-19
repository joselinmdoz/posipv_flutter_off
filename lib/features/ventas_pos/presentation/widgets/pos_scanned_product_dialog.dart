import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/db/app_database.dart';

class PosScannedProductDialog extends StatefulWidget {
  const PosScannedProductDialog({
    super.key,
    required this.product,
    required this.currencySymbol,
    required this.availableToAdd,
    required this.allowNegativeStock,
  });

  final Product product;
  final String currencySymbol;
  final double availableToAdd;
  final bool allowNegativeStock;

  @override
  State<PosScannedProductDialog> createState() =>
      _PosScannedProductDialogState();
}

class _PosScannedProductDialogState extends State<PosScannedProductDialog> {
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');

  int get _maxQty {
    if (widget.allowNegativeStock) {
      return 999999;
    }
    final int computed = widget.availableToAdd.floor();
    return computed <= 0 ? 1 : computed;
  }

  int get _qty {
    final int parsed = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    if (parsed < 1) {
      return 1;
    }
    if (!widget.allowNegativeStock && parsed > _maxQty) {
      return _maxQty;
    }
    return parsed;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _setQty(int value) {
    final int normalized = value < 1 ? 1 : value;
    final int next =
        widget.allowNegativeStock ? normalized : normalized.clamp(1, _maxQty);
    _qtyCtrl.text = next.toString();
    _qtyCtrl.selection = TextSelection.collapsed(offset: _qtyCtrl.text.length);
    setState(() {});
  }

  void _confirm() {
    final int qty = _qty;
    if (!widget.allowNegativeStock && qty > _maxQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cantidad maxima disponible: $_maxQty'),
        ),
      );
      return;
    }
    Navigator.of(context).pop<double>(qty.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String imagePath = (widget.product.imagePath ?? '').trim();

    final Color surfaceLowest =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    final Color surfaceLow =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6); // surface-container-low
    final Color surfaceHighest =
        isDark ? const Color(0xFF334155) : const Color(0xFFE0E3E5); // surface-container-highest
    final Color onSurface =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF191C1E);
    final Color onSurfaceVariant =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF434654);
    final Color primaryContainer =
        isDark ? const Color(0xFF3B82F6) : const Color(0xFF1152D4);
    final Color btnBgCancel =
        isDark ? const Color(0xFF334155) : const Color(0xFFE6E8EA); // surface-container-high

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 384,
        decoration: BoxDecoration(
          color: surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF191C1E).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Producto encontrado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: onSurface,
                ),
              ),
            ),
            // Body: Product Card
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Image
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: surfaceHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imagePath.isEmpty
                                ? Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.grey[400],
                                    size: 32,
                                  )
                                : Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey[400],
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  height: 1.2,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${widget.product.sku}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${widget.currencySymbol}${(widget.product.priceCents / 100).toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800, // extrabold
                                  fontSize: 20,
                                  letterSpacing: -0.5,
                                  color: primaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Availability & Selection
                  if (!widget.allowNegativeStock)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Disponible para agregar: ${widget.availableToAdd.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surfaceHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: surfaceLowest,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _setQty(_qty - 1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.remove_rounded,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _qtyCtrl,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                            decoration: const InputDecoration(
                              hintText: '1',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        Material(
                          color: surfaceLowest,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _setQty(_qty + 1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add_rounded,
                                color: primaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: btnBgCancel,
                          foregroundColor: onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryContainer, // To keep simple without complex gradient, using solid primary container color, but it can be wrapped in DecoratedBox if gradient is strictly required, but solid looks great. Let's use simple blue as HTML did gradient to primary-container. 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Agregar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
