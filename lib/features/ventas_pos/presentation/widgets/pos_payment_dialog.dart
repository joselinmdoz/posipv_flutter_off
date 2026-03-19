import 'package:flutter/material.dart';

import 'pos_order_summary_line.dart';
import 'pos_payment_models.dart';

class PosPaymentDialog extends StatefulWidget {
  const PosPaymentDialog({
    super.key,
    required this.cartLines,
    required this.currencySymbol,
    required this.paymentMethods,
    required this.paymentMethodLabel,
    required this.stockByProductId,
    required this.allowNegativeStock,
  });

  final List<PosCartLine> cartLines;
  final String currencySymbol;
  final List<String> paymentMethods;
  final String Function(String) paymentMethodLabel;
  final Map<String, double> stockByProductId;
  final bool allowNegativeStock;

  @override
  State<PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class _PosPaymentDialogState extends State<PosPaymentDialog> {
  final List<_PaymentDraft> _payments = <_PaymentDraft>[];
  final TextEditingController _amountCtrl = TextEditingController();
  final List<PosCartLine> _editableLines = <PosCartLine>[];
  String _selectedMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.paymentMethods.contains('cash')
        ? 'cash'
        : (widget.paymentMethods.isNotEmpty
            ? widget.paymentMethods.first
            : 'cash');
    _editableLines
      ..clear()
      ..addAll(
        widget.cartLines
            .where((PosCartLine line) => line.qty > 0)
            .map((PosCartLine line) => line.copyWith()),
      );
    _amountCtrl.text = _total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    for (final _PaymentDraft p in _payments) {
      p.controller.dispose();
    }
    super.dispose();
  }

  int get _subtotalCents {
    return _editableLines.fold<int>(
      0,
      (int sum, PosCartLine line) =>
          sum + (line.qty * line.product.priceCents).round(),
    );
  }

  int get _taxCents {
    return _editableLines.fold<int>(0, (int sum, PosCartLine line) {
      final int lineSubtotal = (line.qty * line.product.priceCents).round();
      final int lineTax =
          (lineSubtotal * line.product.taxRateBps / 10000).round();
      return sum + lineTax;
    });
  }

  int get _totalCents => _subtotalCents + _taxCents;

  double get _subtotal => _subtotalCents / 100;
  double get _tax => _taxCents / 100;
  double get _total => _totalCents / 100;

  double _toAmount(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  int _toCents(String raw) {
    return (_toAmount(raw) * 100).round();
  }

  double get _paidAmount {
    double total = _toAmount(_amountCtrl.text);
    for (final _PaymentDraft p in _payments) {
      total += _toAmount(p.controller.text);
    }
    return total;
  }

  double get _pendingAmount {
    final double pending = _total - _paidAmount;
    return pending > 0 ? pending : 0;
  }

  void _syncMainAmount() {
    if (_payments.isNotEmpty) {
      return;
    }
    _amountCtrl.text = _total.toStringAsFixed(2);
  }

  bool _canIncreaseLine(PosCartLine line) {
    if (widget.allowNegativeStock) {
      return true;
    }
    final double stock = widget.stockByProductId[line.product.id] ?? 0;
    return line.qty + 1 <= stock + 0.000001;
  }

  void _updateLineQty(String productId, double nextQty) {
    final int index = _editableLines
        .indexWhere((PosCartLine line) => line.product.id == productId);
    if (index == -1) {
      return;
    }
    if (nextQty <= 0) {
      setState(() {
        _editableLines.removeAt(index);
        _syncMainAmount();
      });
      return;
    }
    setState(() {
      _editableLines[index] = _editableLines[index].copyWith(qty: nextQty);
      _syncMainAmount();
    });
  }

  void _increaseLine(PosCartLine line) {
    if (!_canIncreaseLine(line)) {
      final double stock = widget.stockByProductId[line.product.id] ?? 0;
      _show(
        'Stock insuficiente para ${line.product.name}. Disponible: ${stock.toStringAsFixed(0)}',
      );
      return;
    }
    _updateLineQty(line.product.id, line.qty + 1);
  }

  void _decreaseLine(PosCartLine line) {
    _updateLineQty(line.product.id, line.qty - 1);
  }

  void _removeLine(PosCartLine line) {
    _updateLineQty(line.product.id, 0);
  }

  void _addPaymentLine() {
    final double current = _toAmount(_amountCtrl.text);
    if (current <= 0) {
      return;
    }
    setState(() {
      _payments.add(
        _PaymentDraft(
          method: _selectedMethod,
          controller: TextEditingController(
            text: current.toStringAsFixed(2),
          ),
        ),
      );
      _amountCtrl.text =
          _pendingAmount > 0.005 ? _pendingAmount.toStringAsFixed(2) : '0.00';
    });
  }

  void _removePaymentLine(int index) {
    setState(() {
      final _PaymentDraft removed = _payments.removeAt(index);
      removed.controller.dispose();
      _syncMainAmount();
    });
  }

  void _validatePayment() {
    if (_editableLines.isEmpty) {
      _show('El resumen no tiene productos para cobrar.');
      return;
    }

    final Map<String, int> finalPayments = <String, int>{};
    final int mainCents = _toCents(_amountCtrl.text);
    if (mainCents > 0) {
      finalPayments[_selectedMethod] =
          (finalPayments[_selectedMethod] ?? 0) + mainCents;
    }
    for (final _PaymentDraft p in _payments) {
      final int cents = _toCents(p.controller.text);
      if (cents <= 0) {
        continue;
      }
      finalPayments[p.method] = (finalPayments[p.method] ?? 0) + cents;
    }

    final int paidCents = finalPayments.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    if (paidCents != _totalCents) {
      _show(
        'La suma de pagos debe ser exacta: ${widget.currencySymbol}${_total.toStringAsFixed(2)}',
      );
      return;
    }

    Navigator.pop(
      context,
      PosPaymentResult(
        paymentByMethod: finalPayments,
        cartLines:
            _editableLines.map((PosCartLine line) => line.copyWith()).toList(),
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF1152D4);

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
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: <Widget>[
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildStep(
                    icon: Icons.receipt_long_rounded,
                    label: 'Resumen',
                    isActive: true,
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
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: _buildOrderSummary(isDark, primaryColor),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: _buildPaymentForm(isDark, primaryColor),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: <Widget>[
                        _buildOrderSummary(isDark, primaryColor),
                        const SizedBox(height: 24),
                        _buildPaymentForm(isDark, primaryColor),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color primaryColor,
  }) {
    return Column(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isActive ? primaryColor : primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                isActive ? Colors.white : primaryColor.withValues(alpha: 0.5),
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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Resumen de pedido',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          if (_editableLines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No hay productos en el resumen.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _editableLines.length,
              separatorBuilder: (_, __) => Divider(
                height: 24,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (BuildContext context, int index) {
                final PosCartLine item = _editableLines[index];
                return PosOrderSummaryLine(
                  line: item,
                  currencySymbol: widget.currencySymbol,
                  isDark: isDark,
                  canIncrease: _canIncreaseLine(item),
                  onIncrease: () => _increaseLine(item),
                  onDecrease: () => _decreaseLine(item),
                  onRemove: () => _removeLine(item),
                );
              },
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: <Widget>[
                _buildSummaryLine('Subtotal', _subtotal, isDark),
                const SizedBox(height: 8),
                _buildSummaryLine('Impuesto', _tax, isDark),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.currencySymbol}${_total.toStringAsFixed(2)}',
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
      children: <Widget>[
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

  Widget _buildPaymentForm(bool isDark, Color primaryColor) {
    return Column(
      children: <Widget>[
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
            children: <Widget>[
              const Text(
                'Procesar Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
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
                      padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixText: '${widget.currencySymbol} ',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
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
              if (_payments.isNotEmpty) ...<Widget>[
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
                  itemBuilder: (BuildContext context, int index) {
                    final _PaymentDraft p = _payments[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _getMethodIcon(p.method),
                            size: 18,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.paymentMethodLabel(p.method),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${widget.currencySymbol}${p.controller.text}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removePaymentLine(index),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: <Widget>[
                    _buildBreakdownRow(
                      'Total a pagar',
                      _total,
                      Colors.grey,
                      false,
                    ),
                    const SizedBox(height: 12),
                    _buildBreakdownRow(
                      'Pagado',
                      _paidAmount,
                      Colors.green[600]!,
                      true,
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _pendingAmount <= 0.01 && _editableLines.isNotEmpty
                      ? _validatePayment
                      : null,
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puedes ajustar cantidades o quitar productos desde el resumen antes de validar.',
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
            color: isSelected ? primaryColor : const Color(0xFFD1D9E6),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? primaryColor.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon,
                size: 20, color: isSelected ? primaryColor : Colors.grey),
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

  Widget _buildBreakdownRow(
    String label,
    double amount,
    Color amountColor,
    bool isBold,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
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
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.more_horiz_rounded;
    }
  }
}

class _PaymentDraft {
  _PaymentDraft({
    required this.method,
    required this.controller,
  });

  String method;
  final TextEditingController controller;
}
