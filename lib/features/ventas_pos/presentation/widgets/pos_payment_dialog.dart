import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/db/app_database.dart';

class PosPaymentDialog extends StatefulWidget {
  final List<PosCartLine> cartLines;
  final double subtotal;
  final double tax;
  final double total;
  final String currencySymbol;
  final List<String> paymentMethods;
  final String Function(String) paymentMethodLabel;

  const PosPaymentDialog({
    super.key,
    required this.cartLines,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.currencySymbol,
    required this.paymentMethods,
    required this.paymentMethodLabel,
  });

  @override
  State<PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class PosCartLine {
  final Product product;
  final double qty;

  const PosCartLine({required this.product, required this.qty});
}

class _PosPaymentDialogState extends State<PosPaymentDialog> {
  final List<_PaymentDraft> _payments = [];
  String _selectedMethod = 'cash';
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.paymentMethods.contains('cash')
        ? 'cash'
        : (widget.paymentMethods.isNotEmpty ? widget.paymentMethods.first : 'cash');
    
    // Default first line with total amount
    _amountCtrl.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    for (var p in _payments) {
      p.controller.dispose();
    }
    super.dispose();
  }

  double get _paidAmount {
    double total = 0;
    // Current input
    double current = double.tryParse(_amountCtrl.text) ?? 0;
    total += current;
    
    // Added lines
    for (var p in _payments) {
      total += double.tryParse(p.controller.text) ?? 0;
    }
    return total;
  }

  double get _pendingAmount {
    double pending = widget.total - _paidAmount;
    return pending > 0 ? pending : 0;
  }

  void _addPaymentLine() {
    double current = double.tryParse(_amountCtrl.text) ?? 0;
    if (current <= 0) return;

    setState(() {
      _payments.add(_PaymentDraft(
        method: _selectedMethod,
        controller: TextEditingController(text: current.toStringAsFixed(2)),
      ));
      _amountCtrl.text = '0.00';
      
      // Auto-fill next input with new pending balance if any
      double pending = _pendingAmount;
      if (pending > 0.005) {
        _amountCtrl.text = pending.toStringAsFixed(2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = const Color(0xFF1152D4);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 1000),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // AppBar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Finalizar Compra',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Icon(Icons.shopping_cart_outlined, color: Colors.grey[400]),
                ],
              ),
            ),

            // Progress Steps
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStep(
                    icon: Icons.receipt_long_rounded,
                    label: 'Resumen',
                    isActive: true,
                    isCompleted: true,
                    primaryColor: primaryColor,
                  ),
                  Container(
                    width: 60,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                  _buildStep(
                    icon: Icons.payments_rounded,
                    label: 'Pago',
                    isActive: true,
                    isCompleted: false,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            // Main Content: Two Columns
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildOrderSummary(isDark, primaryColor),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildPaymentForm(isDark, primaryColor, constraints),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildOrderSummary(isDark, primaryColor),
                          const SizedBox(height: 24),
                          _buildPaymentForm(isDark, primaryColor, constraints),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            
            // For mobile/narrow screens, show payment form below
            // Handled by Column if needed, but here I used Row with Expanded
            // Actually I should probably use a Wrap or different layout if not wide.
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required Color primaryColor,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? primaryColor : primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : primaryColor.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? primaryColor : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de pedido',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          // Product List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartLines.length,
            separatorBuilder: (_, __) => Divider(
              height: 24,
              color: isDark ? Colors.white10 : Colors.grey[100],
            ),
            itemBuilder: (context, index) {
              final item = widget.cartLines[index];
              return Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                      image: item.product.imagePath != null
                          ? DecorationImage(
                              image: FileImage(File(item.product.imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.product.imagePath == null
                        ? Icon(Icons.inventory_2_outlined, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.qty.toStringAsFixed(0)} x ${widget.currencySymbol}${(item.product.priceCents / 100).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.currencySymbol}${((item.product.priceCents * item.qty) / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          // Totals
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[100]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Column(
              children: [
                _buildSummaryLine('Subtotal', widget.subtotal, isDark),
                const SizedBox(height: 8),
                _buildSummaryLine('Impuesto (16%)', widget.tax, isDark),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.currencySymbol}${widget.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, double amount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${widget.currencySymbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(bool isDark, Color primaryColor, BoxConstraints constraints) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Procesar Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              // Payment Method Toggle
              const Text(
                'Método de Pago',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: widget.paymentMethods.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final String method = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index > 0 ? 8 : 0,
                      ),
                      child: _buildMethodBtn(
                        label: widget.paymentMethodLabel(method),
                        icon: _getMethodIcon(method),
                        isSelected: _selectedMethod == method,
                        primaryColor: primaryColor,
                        onTap: () => setState(() => _selectedMethod = method),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Amount Input
              const Text(
                'Monto Recibido',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: '${widget.currencySymbol} ',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                    ),
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // Add Line Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _addPaymentLine,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar linea'),
                  style: TextButton.styleFrom(
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              if (_payments.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Pagos Agregados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = _payments[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            p.method == 'cash' ? Icons.payments_outlined : Icons.credit_card_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.method == 'cash' ? 'Efectivo' : 'Tarjeta',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${widget.currencySymbol}${p.controller.text}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => setState(() => _payments.removeAt(index)),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Status Breakdown
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildBreakdownRow('Total a pagar', widget.total, Colors.grey, false),
                    const SizedBox(height: 12),
                    _buildBreakdownRow('Pagado', _paidAmount, Colors.green[600]!, true),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pendiente',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${widget.currencySymbol}${_pendingAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              // Validate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _pendingAmount <= 0.01 ? _validatePayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Validar pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Helper Message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Asegúrese de que el monto pendiente sea cero para finalizar.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? primaryColor : Colors.grey),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? primaryColor : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color amountColor, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${widget.currencySymbol}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: amountColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'cash': return Icons.payments_outlined;
      case 'card': return Icons.credit_card_rounded;
      case 'bank': return Icons.account_balance_rounded;
      case 'transfer': return Icons.swap_horiz_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }

  void _validatePayment() {
    // Return the payment results
    final Map<String, int> finalPayments = {};
    
    // Add main input
    double current = double.tryParse(_amountCtrl.text) ?? 0;
    if (current > 0) {
      finalPayments[_selectedMethod] = (current * 100).round();
    }
    
    // Add extra lines
    for (var p in _payments) {
      double amt = double.tryParse(p.controller.text) ?? 0;
      if (amt > 0) {
        finalPayments[p.method] = (finalPayments[p.method] ?? 0) + (amt * 100).round();
      }
    }

    Navigator.pop(context, finalPayments);
  }
}

class _PaymentDraft {
  String method;
  final TextEditingController controller;

  _PaymentDraft({required this.method, required this.controller});
}
