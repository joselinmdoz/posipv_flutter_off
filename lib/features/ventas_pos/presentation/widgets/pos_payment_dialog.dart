import 'package:flutter/material.dart';

import '../../../clientes/data/clientes_local_datasource.dart';
import '../../../clientes/presentation/cliente_form_page.dart';
import '../../../clientes/presentation/widgets/sale_customer_picker_dialog.dart';
import '../../../clientes/presentation/widgets/sale_customer_selector_tile.dart';
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
    required this.customers,
    required this.onlinePaymentMethodCodes,
    this.selectedCustomer,
    this.canCreateCustomer = false,
    this.reloadCustomers,
  });

  final List<PosCartLine> cartLines;
  final String currencySymbol;
  final List<String> paymentMethods;
  final String Function(String) paymentMethodLabel;
  final Map<String, double> stockByProductId;
  final bool allowNegativeStock;
  final List<ClienteListItem> customers;
  final Set<String> onlinePaymentMethodCodes;
  final PosSelectedCustomer? selectedCustomer;
  final bool canCreateCustomer;
  final Future<List<ClienteListItem>> Function()? reloadCustomers;

  @override
  State<PosPaymentDialog> createState() => _PosPaymentDialogState();
}

class _PosPaymentDialogState extends State<PosPaymentDialog> {
  static const String _consignmentCode = 'consignment';

  final List<_PaymentDraft> _payments = <_PaymentDraft>[];
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _transactionCtrl = TextEditingController();
  final List<PosCartLine> _editableLines = <PosCartLine>[];
  late List<ClienteListItem> _customers;
  PosSelectedCustomer? _selectedCustomer;
  String _selectedMethod = 'cash';
  bool _reloadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _customers = List<ClienteListItem>.from(widget.customers);
    _selectedCustomer = widget.selectedCustomer;
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
    _transactionCtrl.dispose();
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

  bool _requiresTransactionId(String method) {
    return widget.onlinePaymentMethodCodes.contains(
      method.trim().toLowerCase(),
    );
  }

  bool _isConsignmentMethod(String method) {
    return method.trim().toLowerCase() == _consignmentCode;
  }

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
      if (_isConsignmentMethod(method)) {
        for (final _PaymentDraft draft in _payments) {
          draft.controller.dispose();
        }
        _payments.clear();
        _transactionCtrl.clear();
        _amountCtrl.text = '0.00';
      } else {
        if (!_requiresTransactionId(method)) {
          _transactionCtrl.clear();
        }
        _syncMainAmount();
      }
    });
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

  void _addPaymentLine() {
    if (_isConsignmentMethod(_selectedMethod)) {
      _show(
        'En consignación la venta se registra sin pagos iniciales.',
      );
      return;
    }
    final double current = _toAmount(_amountCtrl.text);
    if (current <= 0) {
      return;
    }
    final bool requiresTx = _requiresTransactionId(_selectedMethod);
    final String txId = _transactionCtrl.text.trim();
    if (requiresTx && txId.isEmpty) {
      _show('Este metodo requiere ID de transaccion.');
      return;
    }
    setState(() {
      _payments.add(
        _PaymentDraft(
          method: _selectedMethod,
          controller: TextEditingController(
            text: current.toStringAsFixed(2),
          ),
          transactionId: txId.isEmpty ? null : txId,
        ),
      );
      _amountCtrl.text =
          _pendingAmount > 0.005 ? _pendingAmount.toStringAsFixed(2) : '0.00';
      _transactionCtrl.clear();
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

    final bool isConsignmentSale = _isConsignmentMethod(_selectedMethod) ||
        _payments.any(
          (_PaymentDraft row) => _isConsignmentMethod(row.method),
        );
    if (isConsignmentSale && _selectedCustomer == null) {
      _show('La venta en consignación requiere seleccionar un cliente.');
      return;
    }
    if (isConsignmentSale &&
        (_payments.isNotEmpty || _toCents(_amountCtrl.text) != 0)) {
      _show('En consignación la venta se registra sin pagos iniciales.');
      return;
    }

    final List<PosPaymentLine> paymentLines = <PosPaymentLine>[];
    final Map<String, int> finalPayments = <String, int>{};
    final int mainCents = _toCents(_amountCtrl.text);
    if (mainCents > 0) {
      if (_isConsignmentMethod(_selectedMethod)) {
        _show(
          'En consignación la venta se registra sin pagos iniciales.',
        );
        return;
      }
      final String txId = _transactionCtrl.text.trim();
      if (_requiresTransactionId(_selectedMethod) && txId.isEmpty) {
        _show('Debes ingresar el ID de transaccion para este metodo.');
        return;
      }
      finalPayments[_selectedMethod] =
          (finalPayments[_selectedMethod] ?? 0) + mainCents;
      paymentLines.add(
        PosPaymentLine(
          method: _selectedMethod,
          amountCents: mainCents,
          transactionId: txId.isEmpty ? null : txId,
        ),
      );
    }
    for (final _PaymentDraft p in _payments) {
      final int cents = _toCents(p.controller.text);
      if (cents <= 0) {
        continue;
      }
      if (_requiresTransactionId(p.method) &&
          (p.transactionId ?? '').trim().isEmpty) {
        _show('Una linea de pago online no tiene ID de transaccion.');
        return;
      }
      finalPayments[p.method] = (finalPayments[p.method] ?? 0) + cents;
      paymentLines.add(
        PosPaymentLine(
          method: p.method,
          amountCents: cents,
          transactionId: (p.transactionId ?? '').trim().isEmpty
              ? null
              : p.transactionId!.trim(),
        ),
      );
    }

    final int paidCents = finalPayments.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    if (!isConsignmentSale && paidCents != _totalCents) {
      _show(
        'La suma de pagos debe ser exacta: ${widget.currencySymbol}${_total.toStringAsFixed(2)}',
      );
      return;
    }
    if (isConsignmentSale && paidCents != 0) {
      _show('En consignación la venta se registra sin pagos iniciales.');
      return;
    }

    Navigator.pop(
      context,
      PosPaymentResult(
        paymentByMethod: finalPayments,
        paymentLines: paymentLines,
        cartLines:
            _editableLines.map((PosCartLine line) => line.copyWith()).toList(),
        isConsignmentSale: isConsignmentSale,
        selectedCustomer: _selectedCustomer,
      ),
    );
  }

  Future<void> _pickCustomer() async {
    if (_customers.isEmpty && widget.reloadCustomers != null) {
      await _refreshCustomers();
    }
    if (!mounted) {
      return;
    }
    if (_customers.isEmpty) {
      _show('No hay clientes registrados.');
      return;
    }
    final ClienteListItem? selected = await showDialog<ClienteListItem>(
      context: context,
      builder: (BuildContext context) {
        return SaleCustomerPickerDialog(
          customers: _customers,
          initialSelectedId: _selectedCustomer?.id,
        );
      },
    );
    if (!mounted || selected == null) {
      return;
    }
    setState(() => _selectedCustomer = _toSelectedCustomer(selected));
  }

  Future<void> _createCustomer() async {
    if (!widget.canCreateCustomer) {
      _show('No tienes permisos para crear clientes.');
      return;
    }
    final Object? created = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => const ClienteFormPage(
          returnCreatedClientIdOnCreate: true,
        ),
      ),
    );
    if (!mounted || created == null || created == false) {
      return;
    }

    final String? createdId = created is String ? created.trim() : null;
    await _refreshCustomers(selectId: createdId);
    if (!mounted) {
      return;
    }
    if (_selectedCustomer != null) {
      _show('Cliente creado y seleccionado.');
      return;
    }
    _show('Cliente creado.');
  }

  Future<void> _refreshCustomers({String? selectId}) async {
    if (widget.reloadCustomers == null || _reloadingCustomers) {
      return;
    }
    setState(() => _reloadingCustomers = true);
    try {
      final List<ClienteListItem> rows = await widget.reloadCustomers!.call();
      if (!mounted) {
        return;
      }
      PosSelectedCustomer? selected = _selectedCustomer;
      final String wantedId = (selectId ?? '').trim();
      if (wantedId.isNotEmpty) {
        ClienteListItem? created;
        for (final ClienteListItem row in rows) {
          if (row.id == wantedId) {
            created = row;
            break;
          }
        }
        if (created != null) {
          selected = _toSelectedCustomer(created);
        }
      } else if (selected != null &&
          rows.every(
            (ClienteListItem row) => row.id != selected!.id,
          )) {
        selected = null;
      }
      setState(() {
        _customers = rows;
        _selectedCustomer = selected;
      });
    } catch (e) {
      if (mounted) {
        _show('No se pudo actualizar la lista de clientes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _reloadingCustomers = false);
      }
    }
  }

  void _clearSelectedCustomer() {
    if (_selectedCustomer == null) {
      return;
    }
    setState(() => _selectedCustomer = null);
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
      const PosPaymentResult(
        paymentByMethod: <String, int>{},
        paymentLines: <PosPaymentLine>[],
        cartLines: <PosCartLine>[],
        isConsignmentSale: false,
        cancelOrderRequested: true,
      ),
    );
  }

  PosSelectedCustomer _toSelectedCustomer(ClienteListItem item) {
    return PosSelectedCustomer(
      id: item.id,
      fullName: item.fullName,
      code: item.code,
      phone: item.phone,
      email: item.email,
      avatarPath: item.avatarPath,
    );
  }

  ClienteListItem? _toListItem(PosSelectedCustomer? selected) {
    if (selected == null) {
      return null;
    }
    for (final ClienteListItem row in _customers) {
      if (row.id == selected.id) {
        return row;
      }
    }
    return ClienteListItem(
      id: selected.id,
      code: selected.code ?? '',
      fullName: selected.fullName,
      identityNumber: null,
      phone: selected.phone,
      email: selected.email,
      avatarPath: selected.avatarPath,
      customerType: 'general',
      isVip: false,
      creditAvailableCents: 0,
      discountBps: 0,
      lifetimeSpentCents: 0,
      lastPurchaseAt: null,
      lastPurchaseCents: null,
      createdAt: DateTime.now(),
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
                        'Finalizar Compra',
                        style: TextStyle(
                          fontSize: 20,
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
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                  flex: 1,
                                  child:
                                      _buildPaymentForm(isDark, primaryColor),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: <Widget>[
                              _buildOrderSummary(isDark, primaryColor),
                              const SizedBox(height: 16),
                              _buildPaymentForm(isDark, primaryColor),
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
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Resumen de pedido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
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
                  onSetQty: (double qty) => _setLineQty(item, qty),
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
    final bool isConsignmentSelected = _isConsignmentMethod(_selectedMethod);
    final bool canValidate = _editableLines.isNotEmpty &&
        (isConsignmentSelected || _pendingAmount <= 0.01);
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
              const SizedBox(height: 14),
              SaleCustomerSelectorTile(
                selectedCustomer: _toListItem(_selectedCustomer),
                enabled: !_reloadingCustomers,
                onSelect: _pickCustomer,
                onClear: _clearSelectedCustomer,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _reloadingCustomers ? null : _createCustomer,
                  icon: _reloadingCustomers
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: Text(
                    widget.canCreateCustomer
                        ? 'Añadir cliente rapido'
                        : 'Sin permisos para crear cliente',
                  ),
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
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.paymentMethods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final String method = widget.paymentMethods[index];
                    return SizedBox(
                      width: 156,
                      child: _buildMethodBtn(
                        label: widget.paymentMethodLabel(method),
                        icon: _getMethodIcon(method),
                        isSelected: _selectedMethod == method,
                        primaryColor: primaryColor,
                        onTap: () => _selectMethod(method),
                      ),
                    );
                  },
                ),
              ),
              if (isConsignmentSelected) ...<Widget>[
                const SizedBox(height: 10),
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
                    'Modo consignación: la venta se valida sin pagos iniciales. El cliente es obligatorio.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1152D4),
                    ),
                  ),
                ),
              ],
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
              if (_requiresTransactionId(_selectedMethod)) ...<Widget>[
                const SizedBox(height: 12),
                const Text(
                  'ID de Transaccion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _transactionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej. TX-123456',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ],
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
                          if ((p.transactionId ?? '')
                              .trim()
                              .isNotEmpty) ...<Widget>[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'TX: ${p.transactionId!.trim()}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
                  onPressed: canValidate ? _validatePayment : null,
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
      case 'consignment':
        return Icons.inventory_2_outlined;
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
    this.transactionId,
  });

  String method;
  final TextEditingController controller;
  final String? transactionId;
}
