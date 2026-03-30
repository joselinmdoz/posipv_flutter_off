import 'package:flutter/material.dart';

import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../../ventas_pos/presentation/widgets/pos_order_summary_line.dart';
import '../../../ventas_pos/presentation/widgets/pos_payment_models.dart';

class DirectSalesPaymentResult {
  const DirectSalesPaymentResult({
    required this.discountCents,
    required this.paymentByMethodPrimaryCents,
    required this.paymentLines,
    required this.cartLines,
    required this.isConsignmentSale,
    this.cancelOrderRequested = false,
  });

  final int discountCents;
  final Map<String, int> paymentByMethodPrimaryCents;
  final List<DirectSalesPaymentLine> paymentLines;
  final List<PosCartLine> cartLines;
  final bool isConsignmentSale;
  final bool cancelOrderRequested;
}

class DirectSalesPaymentLine {
  const DirectSalesPaymentLine({
    required this.method,
    required this.currencyCode,
    required this.enteredAmountCents,
    required this.primaryAmountCents,
    this.transactionId,
  });

  final String method;
  final String currencyCode;
  final int enteredAmountCents;
  final int primaryAmountCents;
  final String? transactionId;

  DirectSalesPaymentLine copyWith({
    String? method,
    String? currencyCode,
    int? enteredAmountCents,
    int? primaryAmountCents,
    String? transactionId,
  }) {
    return DirectSalesPaymentLine(
      method: method ?? this.method,
      currencyCode: currencyCode ?? this.currencyCode,
      enteredAmountCents: enteredAmountCents ?? this.enteredAmountCents,
      primaryAmountCents: primaryAmountCents ?? this.primaryAmountCents,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

class DirectSalesPaymentDialog extends StatefulWidget {
  const DirectSalesPaymentDialog({
    super.key,
    required this.cartLines,
    required this.stockByProductId,
    required this.allowNegativeStock,
    required this.currencyConfig,
    required this.paymentMethods,
    required this.paymentMethodLabel,
    required this.onlinePaymentMethodCodes,
  });

  final List<PosCartLine> cartLines;
  final Map<String, double> stockByProductId;
  final bool allowNegativeStock;
  final AppCurrencyConfig currencyConfig;
  final List<String> paymentMethods;
  final String Function(String) paymentMethodLabel;
  final Set<String> onlinePaymentMethodCodes;

  @override
  State<DirectSalesPaymentDialog> createState() =>
      _DirectSalesPaymentDialogState();
}

class _DirectSalesPaymentDialogState extends State<DirectSalesPaymentDialog> {
  static const String _consignmentCode = 'consignment';

  final List<PosCartLine> _editableLines = <PosCartLine>[];
  final TextEditingController _discountCtrl = TextEditingController();
  final TextEditingController _lineAmountCtrl = TextEditingController();
  final TextEditingController _lineTransactionCtrl = TextEditingController();
  final List<_PaymentDraft> _payments = <_PaymentDraft>[];
  late String _selectedMethod;
  late String _selectedCurrencyCode;

  @override
  void initState() {
    super.initState();
    _editableLines
      ..clear()
      ..addAll(
        widget.cartLines
            .where((PosCartLine line) => line.qty > 0)
            .map((PosCartLine line) => line.copyWith()),
      );
    _discountCtrl.text = '0.00';
    _selectedMethod = _defaultPaymentMethod;
    _selectedCurrencyCode = widget.currencyConfig.primaryCurrencyCode;
    _syncSuggestedPaymentAmount();
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _lineAmountCtrl.dispose();
    _lineTransactionCtrl.dispose();
    super.dispose();
  }

  String get _defaultPaymentMethod {
    if (widget.paymentMethods.contains('cash')) {
      return 'cash';
    }
    if (widget.paymentMethods.isEmpty) {
      return 'cash';
    }
    return widget.paymentMethods.first;
  }

  int get _subtotalCents {
    return _editableLines.fold<int>(
      0,
      (int sum, PosCartLine line) =>
          sum + (line.qty * _unitPricePrimaryCents(line)).round(),
    );
  }

  int get _taxCents {
    return _editableLines.fold<int>(0, (int sum, PosCartLine line) {
      final int lineSubtotal =
          (line.qty * _unitPricePrimaryCents(line)).round();
      final int lineTax =
          (lineSubtotal * line.product.taxRateBps / 10000).round();
      return sum + lineTax;
    });
  }

  int get _grossCents => _subtotalCents + _taxCents;

  int get _discountCents {
    final int parsed = _moneyTextToCents(_discountCtrl.text) ?? 0;
    if (parsed < 0) {
      return 0;
    }
    return parsed > _grossCents ? _grossCents : parsed;
  }

  int get _totalCents => _grossCents - _discountCents;

  List<DirectSalesPaymentLine> get _paymentLines {
    return _payments
        .map(
          (_PaymentDraft draft) => DirectSalesPaymentLine(
            method: draft.method,
            currencyCode: draft.currencyCode,
            enteredAmountCents: draft.enteredAmountCents,
            primaryAmountCents: draft.primaryAmountCents,
            transactionId: draft.transactionId,
          ),
        )
        .toList();
  }

  bool _requiresTransactionId(String method) {
    return widget.onlinePaymentMethodCodes.contains(
      method.trim().toLowerCase(),
    );
  }

  bool _isConsignmentMethod(String method) {
    return method.trim().toLowerCase() == _consignmentCode;
  }

  int get _paidPrimaryCents {
    return _paymentLines.fold<int>(
      0,
      (int sum, DirectSalesPaymentLine line) => sum + line.primaryAmountCents,
    );
  }

  int get _deltaPrimaryCents => _paidPrimaryCents - _totalCents;

  bool get _settled => _deltaPrimaryCents.abs() <= 1;

  int _unitPricePrimaryCents(PosCartLine line) {
    return _toPrimaryCents(
      amountCents: line.product.priceCents,
      currencyCode: line.product.currencyCode,
    );
  }

  int _toPrimaryCents({
    required int amountCents,
    required String currencyCode,
  }) {
    final String code = currencyCode.trim().toUpperCase();
    if (code.isEmpty || code == widget.currencyConfig.primaryCurrencyCode) {
      return amountCents;
    }
    final AppCurrencySetting? currency = widget.currencyConfig.currencyByCode(
      code,
    );
    final double rateToPrimary = currency?.rateToPrimary ?? 1;
    if (!rateToPrimary.isFinite || rateToPrimary <= 0) {
      return amountCents;
    }
    return (amountCents / rateToPrimary).round();
  }

  int _fromPrimaryCents({
    required int amountCents,
    required String currencyCode,
  }) {
    final String code = currencyCode.trim().toUpperCase();
    if (code.isEmpty || code == widget.currencyConfig.primaryCurrencyCode) {
      return amountCents;
    }
    final AppCurrencySetting? currency = widget.currencyConfig.currencyByCode(
      code,
    );
    final double rateToPrimary = currency?.rateToPrimary ?? 1;
    if (!rateToPrimary.isFinite || rateToPrimary <= 0) {
      return amountCents;
    }
    return (amountCents * rateToPrimary).round();
  }

  int? _moneyTextToCents(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    final double? value = double.tryParse(normalized);
    if (value == null || value < 0) {
      return null;
    }
    return (value * 100).round();
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
    setState(() {
      if (nextQty <= 0) {
        _editableLines.removeAt(index);
      } else {
        _editableLines[index] = _editableLines[index].copyWith(qty: nextQty);
      }
      _syncSuggestedPaymentAmount();
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

  void _setLineQty(PosCartLine line, double nextQtyRaw) {
    if (!nextQtyRaw.isFinite) {
      return;
    }
    final double nextQty = nextQtyRaw < 0 ? 0 : nextQtyRaw;
    if (!widget.allowNegativeStock) {
      final double stock = widget.stockByProductId[line.product.id] ?? 0;
      if (nextQty > stock + 0.000001) {
        _show(
          'Stock insuficiente para ${line.product.name}. Disponible: ${stock.toStringAsFixed(0)}',
        );
        return;
      }
    }
    _updateLineQty(line.product.id, nextQty);
  }

  void _removeLine(PosCartLine line) {
    _updateLineQty(line.product.id, 0);
  }

  void _syncSuggestedPaymentAmount() {
    if (_payments.isNotEmpty) {
      return;
    }
    _prefillPendingAmount();
  }

  void _prefillPendingAmount() {
    final int pendingPrimary =
        (_totalCents - _paidPrimaryCents).clamp(0, _totalCents);
    final int displayedTotal = _fromPrimaryCents(
      amountCents: pendingPrimary,
      currencyCode: _selectedCurrencyCode,
    );
    final String next = (displayedTotal / 100).toStringAsFixed(2);
    if (_lineAmountCtrl.text == next) {
      return;
    }
    _lineAmountCtrl.text = next;
  }

  void _addPaymentLine() {
    if (_isConsignmentMethod(_selectedMethod)) {
      _show(
        'En consignación la venta se registra sin pagos iniciales.',
      );
      return;
    }
    final int enteredCents = _moneyTextToCents(_lineAmountCtrl.text) ?? 0;
    if (enteredCents <= 0) {
      _show('Ingresa un monto valido para agregar la linea de pago.');
      return;
    }
    final int primaryCents = _toPrimaryCents(
      amountCents: enteredCents,
      currencyCode: _selectedCurrencyCode,
    );
    if (primaryCents <= 0) {
      _show('No se pudo calcular la conversion de la linea de pago.');
      return;
    }
    final String transactionId = _lineTransactionCtrl.text.trim();
    if (_requiresTransactionId(_selectedMethod) && transactionId.isEmpty) {
      _show('Este metodo requiere ID de transaccion.');
      return;
    }

    setState(() {
      _payments.add(
        _PaymentDraft(
          method: _selectedMethod,
          currencyCode: _selectedCurrencyCode,
          enteredAmountCents: enteredCents,
          primaryAmountCents: primaryCents,
          transactionId: transactionId.isEmpty ? null : transactionId,
        ),
      );
      final int pendingPrimary =
          (_totalCents - _paidPrimaryCents).clamp(0, _totalCents);
      final int pendingInSelectedCurrency = _fromPrimaryCents(
        amountCents: pendingPrimary,
        currencyCode: _selectedCurrencyCode,
      );
      _lineAmountCtrl.text =
          (pendingInSelectedCurrency / 100).toStringAsFixed(2);
      _lineTransactionCtrl.clear();
    });
  }

  void _removePaymentLine(int index) {
    if (index < 0 || index >= _payments.length) {
      return;
    }
    setState(() {
      _payments.removeAt(index);
      final int pendingPrimary =
          (_totalCents - _paidPrimaryCents).clamp(0, _totalCents);
      final int pendingInSelectedCurrency = _fromPrimaryCents(
        amountCents: pendingPrimary,
        currencyCode: _selectedCurrencyCode,
      );
      _lineAmountCtrl.text =
          (pendingInSelectedCurrency / 100).toStringAsFixed(2);
    });
  }

  String _moneyPrimary(int cents) {
    final bool negative = cents < 0;
    final int abs = cents.abs();
    final String text =
        '${widget.currencyConfig.primaryCurrency.symbol}${(abs / 100).toStringAsFixed(2)}';
    return negative ? '-$text' : text;
  }

  String _moneyByCurrency(int cents, String currencyCode) {
    final bool negative = cents < 0;
    final int abs = cents.abs();
    final String symbol = widget.currencyConfig.symbolForCode(currencyCode);
    final String text = '$symbol${(abs / 100).toStringAsFixed(2)}';
    return negative ? '-$text' : text;
  }

  void _submit() {
    if (_editableLines.isEmpty) {
      _show('No hay productos en el resumen para cobrar.');
      return;
    }
    final bool isConsignmentSale = _isConsignmentMethod(_selectedMethod) ||
        _payments.any(
          (_PaymentDraft row) => _isConsignmentMethod(row.method),
        );
    if (!isConsignmentSale && _payments.isEmpty) {
      _show('Debes agregar al menos una linea de pago.');
      return;
    }
    if (!isConsignmentSale && !_settled) {
      _show('La suma de pagos debe coincidir con el total de la venta.');
      return;
    }
    if (isConsignmentSale && _paidPrimaryCents != 0) {
      _show('En consignación la venta se registra sin pagos iniciales.');
      return;
    }

    List<DirectSalesPaymentLine> paymentLines = _paymentLines;
    if (!isConsignmentSale && paymentLines.isEmpty) {
      _show('Debes ingresar al menos un pago valido.');
      return;
    }

    final int delta = _deltaPrimaryCents;
    if (!isConsignmentSale && delta != 0) {
      final DirectSalesPaymentLine firstLine = paymentLines.first;
      final int adjustedPrimary = firstLine.primaryAmountCents - delta;
      if (adjustedPrimary <= 0) {
        _show('Ajusta los montos de pago para cubrir el total de la venta.');
        return;
      }
      paymentLines = <DirectSalesPaymentLine>[
        firstLine.copyWith(primaryAmountCents: adjustedPrimary),
        ...paymentLines.skip(1),
      ];
    }

    final Map<String, int> byMethod = <String, int>{};
    for (final DirectSalesPaymentLine line in paymentLines) {
      if (_requiresTransactionId(line.method) &&
          (line.transactionId ?? '').trim().isEmpty) {
        _show('Una linea online no tiene ID de transaccion.');
        return;
      }
      byMethod[line.method] =
          (byMethod[line.method] ?? 0) + line.primaryAmountCents;
    }

    Navigator.of(context).pop(
      DirectSalesPaymentResult(
        discountCents: _discountCents,
        paymentByMethodPrimaryCents: byMethod,
        paymentLines: paymentLines,
        cartLines:
            _editableLines.map((PosCartLine line) => line.copyWith()).toList(),
        isConsignmentSale: isConsignmentSale,
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelOrderFromCheckout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar orden'),
          content: const Text(
            'Se eliminarán todos los productos de esta orden.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirm != true) {
      return;
    }
    Navigator.of(context).pop(
      const DirectSalesPaymentResult(
        discountCents: 0,
        paymentByMethodPrimaryCents: <String, int>{},
        paymentLines: <DirectSalesPaymentLine>[],
        cartLines: <PosCartLine>[],
        isConsignmentSale: false,
        cancelOrderRequested: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF1152D4);
    final int pending = _deltaPrimaryCents < 0 ? -_deltaPrimaryCents : 0;
    final int overpaid = _deltaPrimaryCents > 0 ? _deltaPrimaryCents : 0;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
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
                        'Pago Venta Directa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          final bool isWide = constraints.maxWidth > 760;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child:
                                      _buildOrderSummary(isDark, primaryColor),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildPaymentPanel(
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                    pending: pending,
                                    overpaid: overpaid,
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: <Widget>[
                              _buildOrderSummary(isDark, primaryColor),
                              const SizedBox(height: 16),
                              _buildPaymentPanel(
                                isDark: isDark,
                                primaryColor: primaryColor,
                                pending: pending,
                                overpaid: overpaid,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Resumen de pedido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    _editableLines.isEmpty ? null : _cancelOrderFromCheckout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB42318),
                  side: BorderSide(
                    color: const Color(0xFFB42318).withValues(alpha: 0.35),
                  ),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_editableLines.isEmpty)
            const Text('No hay productos en el resumen.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _editableLines.length,
              separatorBuilder: (_, __) => Divider(
                height: 22,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (BuildContext context, int index) {
                final PosCartLine line = _editableLines[index];
                final String productCurrencyCode =
                    line.product.currencyCode.trim().toUpperCase();
                final String productCurrencySymbol =
                    widget.currencyConfig.symbolForCode(productCurrencyCode);
                final int lineTotalNativeCents =
                    (line.qty * line.product.priceCents).round();
                final int lineTotalPrimaryCents =
                    (line.qty * _unitPricePrimaryCents(line)).round();
                final String lineTotalLabel = productCurrencyCode ==
                        widget.currencyConfig.primaryCurrencyCode
                    ? _moneyByCurrency(
                        lineTotalNativeCents, productCurrencyCode)
                    : '${_moneyByCurrency(lineTotalNativeCents, productCurrencyCode)} (${_moneyPrimary(lineTotalPrimaryCents)})';
                return PosOrderSummaryLine(
                  line: line,
                  currencySymbol: productCurrencySymbol,
                  unitPriceLabel:
                      '${_moneyByCurrency(line.product.priceCents, productCurrencyCode)} c/u',
                  lineTotalLabel: lineTotalLabel,
                  isDark: isDark,
                  canIncrease: _canIncreaseLine(line),
                  onIncrease: () => _increaseLine(line),
                  onDecrease: () => _decreaseLine(line),
                  onRemove: () => _removeLine(line),
                  onSetQty: (double qty) => _setLineQty(line, qty),
                );
              },
            ),
          const SizedBox(height: 18),
          TextField(
            controller: _discountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Descuento',
              prefixText: '${widget.currencyConfig.primaryCurrency.symbol} ',
            ),
            onChanged: (_) => setState(_syncSuggestedPaymentAmount),
          ),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', _moneyPrimary(_subtotalCents)),
          _summaryRow('Impuesto', _moneyPrimary(_taxCents)),
          _summaryRow('Descuento', _moneyPrimary(_discountCents)),
          _summaryRow(
            'Total',
            _moneyPrimary(_totalCents),
            isBold: true,
            valueColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPanel({
    required bool isDark,
    required Color primaryColor,
    required int pending,
    required int overpaid,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Lineas de pago',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget methodField = DropdownButtonFormField<String>(
                initialValue: _selectedMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Metodo',
                  isDense: true,
                ),
                items: widget.paymentMethods
                    .map(
                      (String method) => DropdownMenuItem<String>(
                        value: method,
                        child: Text(widget.paymentMethodLabel(method)),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedMethod = value;
                    if (_isConsignmentMethod(value)) {
                      _payments.clear();
                      _lineTransactionCtrl.clear();
                      _lineAmountCtrl.text = '0.00';
                    } else {
                      if (!_requiresTransactionId(value)) {
                        _lineTransactionCtrl.clear();
                      }
                      _prefillPendingAmount();
                    }
                  });
                },
              );

              final Widget currencyField = DropdownButtonFormField<String>(
                initialValue: _selectedCurrencyCode,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Moneda',
                  isDense: true,
                ),
                items: widget.currencyConfig.currencies
                    .map(
                      (AppCurrencySetting currency) => DropdownMenuItem<String>(
                        value: currency.code,
                        child: Text('${currency.code} (${currency.symbol})'),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCurrencyCode = value;
                    _prefillPendingAmount();
                  });
                },
              );

              if (constraints.maxWidth < 460) {
                return Column(
                  children: <Widget>[
                    methodField,
                    const SizedBox(height: 8),
                    currencyField,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: methodField),
                  const SizedBox(width: 8),
                  Expanded(child: currencyField),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          if (_isConsignmentMethod(_selectedMethod)) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1152D4).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1152D4).withValues(alpha: 0.2),
                ),
              ),
              child: const Text(
                'Modo consignación: la venta se valida sin pagos iniciales. El cliente debe seleccionarse antes de confirmar.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1152D4),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_requiresTransactionId(_selectedMethod)) ...<Widget>[
            TextField(
              controller: _lineTransactionCtrl,
              decoration: const InputDecoration(
                labelText: 'ID de transaccion',
                hintText: 'Ej. TX-123456',
              ),
            ),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget amountField = TextField(
                controller: _lineAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText:
                      '${widget.currencyConfig.symbolForCode(_selectedCurrencyCode)} ',
                ),
              );
              final Widget addButton = FilledButton.icon(
                onPressed: _addPaymentLine,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  children: <Widget>[
                    amountField,
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: addButton),
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(child: amountField),
                  const SizedBox(width: 8),
                  addButton,
                ],
              );
            },
          ),
          if (_payments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final _PaymentDraft draft = _payments[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${widget.paymentMethodLabel(draft.method)} • ${draft.currencyCode}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_moneyByCurrency(draft.enteredAmountCents, draft.currencyCode)} = ${_moneyPrimary(draft.primaryAmountCents)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((draft.transactionId ?? '')
                                .trim()
                                .isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                'TX: ${draft.transactionId!.trim()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removePaymentLine(index),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          _summaryRow('Total a pagar', _moneyPrimary(_totalCents)),
          _summaryRow('Pagado (equiv.)', _moneyPrimary(_paidPrimaryCents)),
          _summaryRow(
            'Pendiente',
            _moneyPrimary(pending),
            valueColor: pending == 0
                ? const Color(0xFF148A65)
                : const Color(0xFFB13B5A),
            isBold: true,
          ),
          if (overpaid > 0)
            _summaryRow(
              'Sobrepago',
              _moneyPrimary(overpaid),
              valueColor: const Color(0xFFB13B5A),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Validar pago'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total base: ${_moneyPrimary(_totalCents)} • Moneda principal: ${widget.currencyConfig.primaryCurrencyCode}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final TextStyle style = isBold
        ? const TextStyle(fontWeight: FontWeight.w800)
        : const TextStyle(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _PaymentDraft {
  _PaymentDraft({
    required this.method,
    required this.currencyCode,
    required this.enteredAmountCents,
    required this.primaryAmountCents,
    this.transactionId,
  });

  String method;
  String currencyCode;
  int enteredAmountCents;
  int primaryAmountCents;
  String? transactionId;
}
