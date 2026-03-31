import 'dart:io';
import 'dart:ui';
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
    if (widget.allowNegativeStock) return 999999;
    final int computed = widget.availableToAdd.floor();
    return computed <= 0 ? 1 : computed;
  }

  int get _qty {
    final int parsed = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    if (parsed < 1) return 1;
    if (!widget.allowNegativeStock && parsed > _maxQty) return _maxQty;
    return parsed;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _setQty(int value) {
    final int next = widget.allowNegativeStock
        ? value.clamp(1, 999999)
        : value.clamp(1, _maxQty);
    _qtyCtrl.text = next.toString();
    _qtyCtrl.selection = TextSelection.collapsed(offset: _qtyCtrl.text.length);
    setState(() {});
  }

  void _confirm() {
    Navigator.of(context).pop<double>(_qty.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String imagePath = (widget.product.imagePath ?? '').trim();
    
    final Color primaryColor = const Color(0xFF1152D4);
    final Color accentColor = const Color(0xFF10B981); // Success/Add
    final Color cardBg = isDark ? const Color(0xFF1A202E) : Colors.white;
    final Color onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color mutedText = isDark ? Colors.white60 : const Color(0xFF64748B);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardBg.withValues(alpha: isDark ? 0.8 : 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image Header
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
                    child: imagePath.isEmpty
                        ? Icon(Icons.inventory_2_rounded, size: 64, color: mutedText.withValues(alpha: 0.5))
                        : Image.file(File(imagePath), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                      child: const Text('ENCONTRADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.product.name, style: TextStyle(color: onSurface, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
                    const SizedBox(height: 4),
                    Text('SKU: ${widget.product.sku}', style: TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                    const SizedBox(height: 20),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRECIO UNITARIO', style: TextStyle(color: mutedText, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            Text('${widget.currencySymbol}${(widget.product.priceCents / 100).toStringAsFixed(2)}', 
                                style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
                          ],
                        ),
                        if (!widget.allowNegativeStock)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text('STOCK', style: TextStyle(color: mutedText, fontSize: 9, fontWeight: FontWeight.w800)),
                                Text(widget.availableToAdd.toStringAsFixed(0), style: TextStyle(color: onSurface, fontWeight: FontWeight.w900, fontSize: 14)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    
                    // Quantity Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CANTIDAD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              _buildQtyBtn(Icons.remove_rounded, () => _setQty(_qty - 1), isDark),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _qtyCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              _buildQtyBtn(Icons.add_rounded, () => _setQty(_qty + 1), isDark, isPrimary: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                              boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: ElevatedButton(
                              onPressed: _confirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('AÑADIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap, bool isDark, {bool isPrimary = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: isPrimary ? const Color(0xFF1152D4) : (isDark ? Colors.white70 : Colors.black54)),
        ),
      ),
    );
  }
}
