import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/app_result.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../almacenes/presentation/almacenes_providers.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../clientes/data/clientes_local_datasource.dart';
import '../../../clientes/presentation/clientes_providers.dart';
import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../../configuracion/presentation/configuracion_providers.dart';
import '../../../productos/presentation/productos_providers.dart';
import '../../../tpv/data/tpv_local_datasource.dart';
import '../../../tpv/presentation/tpv_providers.dart';
import '../../../ventas_pos/domain/sale_models.dart';
import '../../../ventas_pos/presentation/ventas_pos_providers.dart';

class ManualSaleEntryPage extends ConsumerStatefulWidget {
  const ManualSaleEntryPage({
    super.key,
    required this.currencySymbol,
  });

  final String currencySymbol;

  @override
  ConsumerState<ManualSaleEntryPage> createState() =>
      _ManualSaleEntryPageState();
}

class _ManualSaleEntryPageState extends ConsumerState<ManualSaleEntryPage> {
  bool _loading = true;
  bool _saving = false;
  bool _isConsignmentSale = false;
  bool _allowNegativeStock = false;

  DateTime _saleDateTime = DateTime.now();
  String _saleOrigin = 'direct';
  String _currencySymbol = '';

  String? _selectedWarehouseId;
  String? _selectedTerminalId;
  String? _selectedCustomerId;

  List<Product> _products = <Product>[];
  List<Warehouse> _warehouses = <Warehouse>[];
  List<TpvTerminalView> _terminalViews = <TpvTerminalView>[];
  List<ClienteListItem> _customers = <ClienteListItem>[];
  List<_PaymentMethodOption> _paymentMethodOptions =
      const <_PaymentMethodOption>[];

  final List<_EditableSaleLineForm> _lineForms = <_EditableSaleLineForm>[];
  final List<_EditableSalePaymentForm> _paymentForms =
      <_EditableSalePaymentForm>[];

  @override
  void initState() {
    super.initState();
    _currencySymbol = widget.currencySymbol;
    _bootstrap();
  }

  @override
  void dispose() {
    for (final _EditableSaleLineForm row in _lineForms) {
      row.dispose();
    }
    for (final _EditableSalePaymentForm row in _paymentForms) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final Future<List<Product>> productsFuture =
          ref.read(allProductsProvider.future);
      final Future<List<Warehouse>> warehousesFuture =
          ref.read(almacenesLocalDataSourceProvider).listActiveWarehouses();
      final Future<List<TpvTerminalView>> terminalsFuture =
          ref.read(tpvLocalDataSourceProvider).listActiveTerminalViews();
      final Future<List<ClienteListItem>> customersFuture = ref
          .read(clientesLocalDataSourceProvider)
          .listClients(limit: 500, typeFilter: 'todos');
      final Future<List<AppPaymentMethodSetting>> methodsFuture = ref
          .read(configuracionLocalDataSourceProvider)
          .loadPaymentMethodSettings();
      final Future<bool> allowNegativeFuture = ref
          .read(configuracionLocalDataSourceProvider)
          .isNegativeStockAllowed();
      final Future<AppConfig> configFuture =
          ref.read(configuracionLocalDataSourceProvider).loadConfig();

      final List<dynamic> loaded = await Future.wait<dynamic>(<Future<dynamic>>[
        productsFuture,
        warehousesFuture,
        terminalsFuture,
        customersFuture,
        methodsFuture,
        allowNegativeFuture,
        configFuture,
      ]);

      final List<Product> products = loaded[0] as List<Product>;
      final List<Warehouse> warehouses = loaded[1] as List<Warehouse>;
      final List<TpvTerminalView> terminals =
          loaded[2] as List<TpvTerminalView>;
      final List<ClienteListItem> customers =
          loaded[3] as List<ClienteListItem>;
      final List<AppPaymentMethodSetting> methodSettings =
          loaded[4] as List<AppPaymentMethodSetting>;
      final bool allowNegative = loaded[5] as bool;
      final AppConfig config = loaded[6] as AppConfig;

      final List<_PaymentMethodOption> paymentOptions = methodSettings
          .map(
            (AppPaymentMethodSetting row) => _PaymentMethodOption(
              key: row.code.trim().toLowerCase(),
              label: row.label,
            ),
          )
          .where((_PaymentMethodOption row) =>
              row.key.isNotEmpty && row.key != 'consignment')
          .toList(growable: false);

      _products = products;
      _warehouses = warehouses;
      _terminalViews = terminals;
      _customers = customers;
      _allowNegativeStock = allowNegative;
      _currencySymbol = config.currencySymbol.trim().isEmpty
          ? (_currencySymbol.trim().isEmpty ? r'$' : _currencySymbol)
          : config.currencySymbol;

      _paymentMethodOptions = paymentOptions.isEmpty
          ? const <_PaymentMethodOption>[
              _PaymentMethodOption(key: 'cash', label: 'Efectivo'),
            ]
          : paymentOptions;

      _selectedWarehouseId = warehouses.isEmpty ? null : warehouses.first.id;
      final List<TpvTerminalView> openTerminals = _terminalViews
          .where((TpvTerminalView row) => row.openSession != null)
          .toList(growable: false);
      _selectedTerminalId =
          openTerminals.isEmpty ? null : openTerminals.first.terminal.id;

      for (final _EditableSaleLineForm row in _lineForms) {
        row.dispose();
      }
      _lineForms
        ..clear()
        ..addAll(_buildInitialLines());

      for (final _EditableSalePaymentForm row in _paymentForms) {
        row.dispose();
      }
      _paymentForms
        ..clear()
        ..add(
          _EditableSalePaymentForm(
            method: _paymentMethodOptions.first.key,
            amountText: _formatCents(_totalCents()),
          ),
        );

      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar el formulario: $e');
    }
  }

  List<_EditableSaleLineForm> _buildInitialLines() {
    if (_products.isEmpty) {
      return <_EditableSaleLineForm>[];
    }
    final Product first = _products.first;
    return <_EditableSaleLineForm>[
      _EditableSaleLineForm(
        productId: first.id,
        qtyText: '1',
        unitPriceText: _formatCents(first.priceCents),
        taxRateBps: first.taxRateBps,
      ),
    ];
  }

  TpvTerminalView? _selectedTerminalView() {
    final String target = (_selectedTerminalId ?? '').trim();
    if (target.isEmpty) {
      return null;
    }
    for (final TpvTerminalView row in _terminalViews) {
      if (row.terminal.id == target) {
        return row;
      }
    }
    return null;
  }

  Map<String, Product> _productsById() {
    return <String, Product>{
      for (final Product row in _products) row.id: row,
    };
  }

  String _money(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatCents(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  int? _parseMoneyToCents(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    final double? value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    return (value * 100).round();
  }

  double? _parseQty(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    final double? value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    return value;
  }

  int _lineSubtotalCents(_EditableSaleLineForm row) {
    final double qty = _parseQty(row.qtyCtrl.text) ?? 0;
    final int unitPriceCents = _parseMoneyToCents(row.unitPriceCtrl.text) ?? 0;
    return (qty * unitPriceCents).round();
  }

  int _lineTaxCents(_EditableSaleLineForm row) {
    final int subtotal = _lineSubtotalCents(row);
    return (subtotal * row.taxRateBps / 10000).round();
  }

  int _subtotalCents() {
    int total = 0;
    for (final _EditableSaleLineForm row in _lineForms) {
      total += _lineSubtotalCents(row);
    }
    return total;
  }

  int _taxCents() {
    int total = 0;
    for (final _EditableSaleLineForm row in _lineForms) {
      total += _lineTaxCents(row);
    }
    return total;
  }

  int _totalCents() {
    return _subtotalCents() + _taxCents();
  }

  int _paymentsTotalCents() {
    int total = 0;
    for (final _EditableSalePaymentForm row in _paymentForms) {
      total += _parseMoneyToCents(row.amountCtrl.text) ?? 0;
    }
    return total;
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _saleDateTime,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _saleDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _saleDateTime.hour,
        _saleDateTime.minute,
        _saleDateTime.second,
      );
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay initial = TimeOfDay.fromDateTime(_saleDateTime);
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) {
      return;
    }
    setState(() {
      _saleDateTime = DateTime(
        _saleDateTime.year,
        _saleDateTime.month,
        _saleDateTime.day,
        picked.hour,
        picked.minute,
      );
      final DateTime now = DateTime.now();
      if (_saleDateTime.isAfter(now)) {
        _saleDateTime = now;
      }
    });
  }

  void _onChangeOrigin(String value) {
    if (_saleOrigin == value) {
      return;
    }
    setState(() {
      _saleOrigin = value;
    });
  }

  void _addLine() {
    if (_products.isEmpty) {
      _show('No hay productos activos para agregar.');
      return;
    }
    final Product product = _products.first;
    setState(() {
      _lineForms.add(
        _EditableSaleLineForm(
          productId: product.id,
          qtyText: '1',
          unitPriceText: _formatCents(product.priceCents),
          taxRateBps: product.taxRateBps,
        ),
      );
    });
  }

  void _removeLine(int index) {
    if (_lineForms.length <= 1) {
      return;
    }
    setState(() {
      final _EditableSaleLineForm row = _lineForms.removeAt(index);
      row.dispose();
    });
  }

  void _addPayment() {
    setState(() {
      _paymentForms.add(
        _EditableSalePaymentForm(
          method: _paymentMethodOptions.first.key,
          amountText: _formatCents(_totalCents()),
        ),
      );
    });
  }

  void _removePayment(int index) {
    if (_paymentForms.length <= 1) {
      return;
    }
    setState(() {
      final _EditableSalePaymentForm row = _paymentForms.removeAt(index);
      row.dispose();
    });
  }

  void _toggleConsignment(bool value) {
    setState(() {
      _isConsignmentSale = value;
      if (_isConsignmentSale) {
        for (final _EditableSalePaymentForm row in _paymentForms) {
          row.dispose();
        }
        _paymentForms.clear();
      } else if (_paymentForms.isEmpty) {
        _paymentForms.add(
          _EditableSalePaymentForm(
            method: _paymentMethodOptions.first.key,
            amountText: _formatCents(_totalCents()),
          ),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final session = ref.read(currentSessionProvider);
    final String userId = session?.userId.trim() ?? '';
    if (userId.isEmpty) {
      _show('No hay un usuario autenticado.');
      return;
    }
    if (!(session?.isAdmin ?? false)) {
      _show(
          'Solo el administrador puede registrar ventas manuales históricas.');
      return;
    }
    if (_lineForms.isEmpty || _products.isEmpty) {
      _show('Debes agregar al menos un producto.');
      return;
    }

    final Map<String, Product> productsById = _productsById();
    final List<SaleItemInput> items = <SaleItemInput>[];
    for (final _EditableSaleLineForm row in _lineForms) {
      final String productId = row.productId.trim();
      final Product? product = productsById[productId];
      if (product == null) {
        _show('Selecciona un producto válido en cada línea.');
        return;
      }
      final double? qty = _parseQty(row.qtyCtrl.text);
      if (qty == null || qty <= 0) {
        _show('La cantidad debe ser mayor que 0 en todas las líneas.');
        return;
      }
      final int? unitPriceCents = _parseMoneyToCents(row.unitPriceCtrl.text);
      if (unitPriceCents == null || unitPriceCents < 0) {
        _show('El precio de una línea es inválido.');
        return;
      }
      items.add(
        SaleItemInput(
          productId: productId,
          qty: qty,
          unitPriceCents: unitPriceCents,
          taxRateBps: row.taxRateBps,
        ),
      );
    }

    final List<PaymentInput> payments = <PaymentInput>[];
    if (!_isConsignmentSale) {
      if (_paymentForms.isEmpty) {
        _show('Debes registrar al menos un pago.');
        return;
      }
      for (final _EditableSalePaymentForm row in _paymentForms) {
        final String method = row.method.trim().toLowerCase();
        if (method.isEmpty || method == 'consignment') {
          _show('Selecciona un método de pago válido.');
          return;
        }
        final int? amountCents = _parseMoneyToCents(row.amountCtrl.text);
        if (amountCents == null || amountCents < 0) {
          _show('El importe de pago es inválido.');
          return;
        }
        payments.add(
          PaymentInput(
            method: method,
            amountCents: amountCents,
            transactionId: row.transactionCtrl.text.trim().isEmpty
                ? null
                : row.transactionCtrl.text.trim(),
          ),
        );
      }
    }

    final DateTime now = DateTime.now();
    if (_saleDateTime.isAfter(now)) {
      _show('La fecha de la venta no puede estar en el futuro.');
      return;
    }

    String? warehouseId;
    String? terminalId;
    String? terminalSessionId;

    if (_saleOrigin == 'pos') {
      final TpvTerminalView? selectedTerminal = _selectedTerminalView();
      if (selectedTerminal == null) {
        _show('Selecciona un TPV válido.');
        return;
      }
      final TpvSessionWithUser? openSession = selectedTerminal.openSession;
      if (openSession == null || openSession.session.status != 'open') {
        _show('El TPV seleccionado no tiene turno abierto.');
        return;
      }
      warehouseId = selectedTerminal.warehouse.id;
      terminalId = selectedTerminal.terminal.id;
      terminalSessionId = openSession.session.id;
    } else {
      warehouseId = (_selectedWarehouseId ?? '').trim();
      if (warehouseId.isEmpty) {
        _show('Selecciona un almacén para la venta directa.');
        return;
      }
    }

    if (_isConsignmentSale &&
        (_selectedCustomerId == null || _selectedCustomerId!.trim().isEmpty)) {
      _show('La venta en consignación requiere seleccionar un cliente.');
      return;
    }

    final int totalCents = _totalCents();
    final int paidCents = _paymentsTotalCents();
    if (!_isConsignmentSale && paidCents < totalCents) {
      _show('Los pagos deben cubrir al menos el total de la venta.');
      return;
    }

    setState(() => _saving = true);
    try {
      final AppResult<CreateSaleResult> result =
          await ref.read(ventasPosLocalDataSourceProvider).createSale(
                CreateSaleInput(
                  warehouseId: warehouseId,
                  cashierId: userId,
                  customerId: (_selectedCustomerId ?? '').trim().isEmpty
                      ? null
                      : _selectedCustomerId,
                  terminalId: terminalId,
                  terminalSessionId: terminalSessionId,
                  createdAt: _saleDateTime,
                  items: items,
                  payments: payments,
                  allowNegativeStock: _allowNegativeStock,
                  saleOrigin: _saleOrigin,
                  isConsignmentSale: _isConsignmentSale,
                ),
              );

      if (!mounted) {
        return;
      }
      switch (result) {
        case AppSuccess<CreateSaleResult>(:final data):
          _show('Venta ${data.folio} registrada correctamente.');
          Navigator.of(context).pop(true);
        case AppFailure<CreateSaleResult>(:final message):
          _show(message);
      }
    } catch (e) {
      if (mounted) {
        _show('No se pudo registrar la venta manual: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  BoxDecoration _cardDecoration({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: isDark
          ? null
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final int subtotal = _subtotalCents();
    final int tax = _taxCents();
    final int total = subtotal + tax;
    final int paymentsTotal = _paymentsTotalCents();
    final int pending = total - paymentsTotal;

    final Color pageBg =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFF7F9FB);
    final Color cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF263244) : const Color(0xFFE2E8F0);
    final Color textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6472);

    final List<TpvTerminalView> openTerminals = _terminalViews
        .where((TpvTerminalView row) => row.openSession != null)
        .toList(growable: false);

    return AppScaffold(
      title: 'Venta manual histórica',
      currentRoute: '/reportes',
      showDrawer: false,
      onRefresh: _bootstrap,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.of(context).pop(false),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _saving ? 'Guardando...' : 'Guardar venta',
          onPressed: _loading || _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
        ),
      ],
      body: ColoredBox(
        color: pageBg,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos activos para registrar una venta manual.',
                    ),
                  )
                : LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      final bool compact = constraints.maxWidth < 920;

                      Widget sectionTitle(String value) {
                        return Text(
                          value,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textMuted,
                          ),
                        );
                      }

                      Widget metaCard() {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _cardDecoration(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              sectionTitle('METADATOS DE LA VENTA'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  OutlinedButton.icon(
                                    onPressed: _pickDate,
                                    icon: const Icon(
                                        Icons.calendar_today_outlined),
                                    label: Text(_formatDateTime(_saleDateTime)
                                        .split(' ')
                                        .first),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _pickTime,
                                    icon: const Icon(Icons.schedule_outlined),
                                    label: Text(
                                      _formatDateTime(_saleDateTime)
                                          .split(' ')
                                          .last,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<String>(
                                segments: const <ButtonSegment<String>>[
                                  ButtonSegment<String>(
                                    value: 'direct',
                                    label: Text('Directa'),
                                    icon: Icon(Icons.receipt_long_rounded),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'pos',
                                    label: Text('POS'),
                                    icon: Icon(Icons.point_of_sale_rounded),
                                  ),
                                ],
                                selected: <String>{_saleOrigin},
                                onSelectionChanged: (Set<String> selection) {
                                  final String value = selection.first;
                                  _onChangeOrigin(value);
                                },
                              ),
                              const SizedBox(height: 10),
                              if (_saleOrigin == 'direct')
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedWarehouseId,
                                  decoration: const InputDecoration(
                                    labelText: 'Almacén',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _warehouses
                                      .map(
                                        (Warehouse row) =>
                                            DropdownMenuItem<String>(
                                          value: row.id,
                                          child: Text(
                                            '${row.name} (${row.warehouseType})',
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (String? value) {
                                    setState(
                                        () => _selectedWarehouseId = value);
                                  },
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedTerminalId,
                                      decoration: const InputDecoration(
                                        labelText: 'TPV con turno abierto',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: openTerminals
                                          .map(
                                            (TpvTerminalView row) =>
                                                DropdownMenuItem<String>(
                                              value: row.terminal.id,
                                              child: Text(
                                                '${row.terminal.name} • ${row.warehouse.name}',
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) {
                                        setState(
                                            () => _selectedTerminalId = value);
                                      },
                                    ),
                                    if (openTerminals.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'No hay TPV con turno abierto en este momento.',
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                initialValue: _selectedCustomerId,
                                decoration: InputDecoration(
                                  labelText: _isConsignmentSale
                                      ? 'Cliente (requerido)'
                                      : 'Cliente (opcional)',
                                  border: const OutlineInputBorder(),
                                ),
                                items: <DropdownMenuItem<String?>>[
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Sin cliente'),
                                  ),
                                  ..._customers.map(
                                    (ClienteListItem row) =>
                                        DropdownMenuItem<String?>(
                                      value: row.id,
                                      child: Text(
                                        '${row.fullName} (${row.code})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  setState(() => _selectedCustomerId = value);
                                },
                              ),
                              const SizedBox(height: 6),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _isConsignmentSale,
                                onChanged: _toggleConsignment,
                                title: const Text('Venta en consignación'),
                                subtitle: const Text(
                                  'No registra pagos iniciales, solo deuda del cliente.',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      Widget productsEditorCard() {
                        final Map<String, Product> productsById =
                            _productsById();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _cardDecoration(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              sectionTitle('PRODUCTOS'),
                              const SizedBox(height: 10),
                              ...List<Widget>.generate(_lineForms.length,
                                  (int index) {
                                final _EditableSaleLineForm row =
                                    _lineForms[index];
                                final bool hasProduct =
                                    productsById.containsKey(row.productId);

                                final Widget productSelector =
                                    DropdownButtonFormField<String>(
                                  initialValue:
                                      hasProduct ? row.productId : null,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Producto',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _products
                                      .map(
                                        (Product product) =>
                                            DropdownMenuItem<String>(
                                          value: product.id,
                                          child: Text(
                                            '${product.name} (${product.sku})',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (String? value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return;
                                    }
                                    final Product selected =
                                        productsById[value]!;
                                    setState(() {
                                      row.productId = value;
                                      row.taxRateBps = selected.taxRateBps;
                                      row.unitPriceCtrl.text =
                                          _formatCents(selected.priceCents);
                                    });
                                  },
                                );

                                final Widget qtyField = TextFormField(
                                  controller: row.qtyCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                );

                                final Widget priceField = TextFormField(
                                  controller: row.unitPriceCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Precio',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                );

                                final Widget removeBtn = IconButton(
                                  tooltip: 'Eliminar línea',
                                  onPressed: _lineForms.length > 1
                                      ? () => _removeLine(index)
                                      : null,
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: compact
                                      ? Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF162133)
                                                : const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: borderColor,
                                            ),
                                          ),
                                          child: Column(
                                            children: <Widget>[
                                              productSelector,
                                              const SizedBox(height: 8),
                                              Row(
                                                children: <Widget>[
                                                  Expanded(child: qtyField),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: priceField),
                                                  const SizedBox(width: 2),
                                                  removeBtn,
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Expanded(
                                              flex: 5,
                                              child: productSelector,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(flex: 2, child: qtyField),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              flex: 2,
                                              child: priceField,
                                            ),
                                            const SizedBox(width: 4),
                                            removeBtn,
                                          ],
                                        ),
                                );
                              }),
                              TextButton.icon(
                                onPressed: _addLine,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Agregar producto'),
                              ),
                            ],
                          ),
                        );
                      }

                      Widget paymentsEditorCard() {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _cardDecoration(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              sectionTitle('PAGOS'),
                              const SizedBox(height: 8),
                              if (!_isConsignmentSale) ...<Widget>[
                                ...List<Widget>.generate(_paymentForms.length,
                                    (int index) {
                                  final _EditableSalePaymentForm row =
                                      _paymentForms[index];

                                  final Widget methodSelector =
                                      DropdownButtonFormField<String>(
                                    initialValue: row.method,
                                    decoration: const InputDecoration(
                                      labelText: 'Método',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _paymentMethodOptions
                                        .map(
                                          (_PaymentMethodOption option) =>
                                              DropdownMenuItem<String>(
                                            value: option.key,
                                            child: Text(option.label),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (String? value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return;
                                      }
                                      setState(() => row.method = value);
                                    },
                                  );

                                  final Widget amountField = TextFormField(
                                    controller: row.amountCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Importe',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  );

                                  final Widget codeField = TextFormField(
                                    controller: row.transactionCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Código',
                                      border: OutlineInputBorder(),
                                    ),
                                  );

                                  final Widget removeBtn = IconButton(
                                    tooltip: 'Eliminar pago',
                                    onPressed: _paymentForms.length > 1
                                        ? () => _removePayment(index)
                                        : null,
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: compact
                                        ? Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF162133)
                                                  : const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: borderColor,
                                              ),
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                methodSelector,
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: amountField,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: codeField,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    removeBtn,
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        : Row(
                                            children: <Widget>[
                                              Expanded(
                                                flex: 3,
                                                child: methodSelector,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 2,
                                                child: amountField,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                flex: 3,
                                                child: codeField,
                                              ),
                                              const SizedBox(width: 4),
                                              removeBtn,
                                            ],
                                          ),
                                  );
                                }),
                                TextButton.icon(
                                  onPressed: _addPayment,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Agregar pago'),
                                ),
                              ] else
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'En consignación no se registran pagos iniciales.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      Widget summaryCard() {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: _cardDecoration(
                            isDark: isDark,
                            cardBg: cardBg,
                            borderColor: borderColor,
                          ).copyWith(
                            border: Border(
                              top: const BorderSide(
                                color: Color(0xFF1152D4),
                                width: 3,
                              ),
                              left: BorderSide(color: borderColor),
                              right: BorderSide(color: borderColor),
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              _TotalRow(
                                  label: 'Subtotal', value: _money(subtotal)),
                              _TotalRow(label: 'Impuesto', value: _money(tax)),
                              const Divider(height: 14),
                              _TotalRow(
                                label: 'Total',
                                value: _money(total),
                                highlight: true,
                              ),
                              if (!_isConsignmentSale) ...<Widget>[
                                _TotalRow(
                                  label: 'Pagado',
                                  value: _money(paymentsTotal),
                                ),
                                _TotalRow(
                                  label: 'Diferencia',
                                  value: _money(pending),
                                  highlight: pending == 0,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.event_note_rounded,
                                    size: 16,
                                    color: Color(0xFF1152D4),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Se registrará con fecha: ${_formatDateTime(_saleDateTime)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 12 : 20,
                          10,
                          compact ? 12 : 20,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            metaCard(),
                            const SizedBox(height: 12),
                            productsEditorCard(),
                            const SizedBox(height: 12),
                            if (compact) ...<Widget>[
                              paymentsEditorCard(),
                              const SizedBox(height: 12),
                              summaryCard(),
                            ] else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(child: paymentsEditorCard()),
                                  const SizedBox(width: 12),
                                  Expanded(child: summaryCard()),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

class _EditableSaleLineForm {
  _EditableSaleLineForm({
    required this.productId,
    required String qtyText,
    required String unitPriceText,
    required this.taxRateBps,
  })  : qtyCtrl = TextEditingController(text: qtyText),
        unitPriceCtrl = TextEditingController(text: unitPriceText);

  String productId;
  int taxRateBps;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;

  void dispose() {
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }
}

class _EditableSalePaymentForm {
  _EditableSalePaymentForm({
    required this.method,
    String amountText = '0.00',
    String transactionId = '',
  })  : amountCtrl = TextEditingController(text: amountText),
        transactionCtrl = TextEditingController(text: transactionId);

  String method;
  final TextEditingController amountCtrl;
  final TextEditingController transactionCtrl;

  void dispose() {
    amountCtrl.dispose();
    transactionCtrl.dispose();
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color valueColor = highlight
        ? const Color(0xFF1152D4)
        : Theme.of(context).textTheme.bodyMedium?.color ??
            const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
