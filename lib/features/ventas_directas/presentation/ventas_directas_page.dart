import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/app_result.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../inventario/data/inventario_local_datasource.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../productos/domain/product_qr_codec.dart';
import '../../productos/presentation/productos_providers.dart';
import '../../ventas_pos/domain/sale_models.dart';
import '../../ventas_pos/presentation/ventas_pos_providers.dart';

class VentasDirectasPage extends ConsumerStatefulWidget {
  const VentasDirectasPage({super.key});

  @override
  ConsumerState<VentasDirectasPage> createState() => _VentasDirectasPageState();
}

class _VentasDirectasPageState extends ConsumerState<VentasDirectasPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Warehouse> _warehouses = <Warehouse>[];
  List<Product> _products = <Product>[];
  List<Product> _visibleProducts = <Product>[];
  String? _selectedWarehouseId;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _allowNegativeStock = false;
  bool _loading = true;
  bool _posting = false;

  final Map<String, double> _qtyByProductId = <String, double>{};
  final Map<String, double> _stockByProductId = <String, double>{};
  final Set<String> _warehouseProductIds = <String>{};

  static const List<String> _paymentMethods = <String>[
    'cash',
    'card',
    'transfer',
    'wallet',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _visibleProducts = _filterProducts(_products, _searchCtrl.text);
      });
    });
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final session = ref.read(currentSessionProvider);
      if (session == null) {
        if (!mounted) {
          return;
        }
        setState(() => _loading = false);
        _show('Debes iniciar sesion.');
        return;
      }

      final whDs = ref.read(almacenesLocalDataSourceProvider);
      await whDs.ensureDefaultWarehouse();
      final Future<List<Warehouse>> warehousesFuture =
          whDs.listActiveWarehouses();
      final Future<AppConfig> configFuture =
          ref.read(configuracionLocalDataSourceProvider).loadConfig();

      final List<Warehouse> warehouses = (await warehousesFuture)
          .where(
            (Warehouse row) =>
                row.warehouseType.trim().toLowerCase() == 'central',
          )
          .toList()
        ..sort((Warehouse a, Warehouse b) => a.name.compareTo(b.name));
      final AppConfig config = await configFuture;

      String? warehouseId = _selectedWarehouseId;
      if (warehouseId == null ||
          warehouses.every((Warehouse row) => row.id != warehouseId)) {
        warehouseId = warehouses.isEmpty ? null : warehouses.first.id;
      }

      final List<InventoryView> inventoryRows = warehouseId == null
          ? <InventoryView>[]
          : await ref
              .read(inventarioLocalDataSourceProvider)
              .listStocked(warehouseId: warehouseId);
      final Map<String, double> stockByProductId = <String, double>{
        for (final InventoryView row in inventoryRows) row.productId: row.qty,
      };
      final Set<String> availableIds = stockByProductId.keys.toSet();
      final List<Product> products = await ref
          .read(productosLocalDataSourceProvider)
          .listActiveProductsByIds(availableIds);

      if (!mounted) {
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _selectedWarehouseId = warehouseId;
        _products = products;
        _visibleProducts = _filterProducts(products, _searchCtrl.text);
        _stockByProductId
          ..clear()
          ..addAll(stockByProductId);
        _warehouseProductIds
          ..clear()
          ..addAll(availableIds);
        _currencySymbol = config.currencySymbol;
        _allowNegativeStock = config.allowNegativeStock;
        _sanitizeCart();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar Ventas Directas: $e');
    }
  }

  Future<void> _changeWarehouse(String? warehouseId) async {
    if (warehouseId == null || warehouseId == _selectedWarehouseId) {
      return;
    }
    if (mounted) {
      setState(() {
        _selectedWarehouseId = warehouseId;
        _loading = true;
      });
    }
    await _bootstrap();
  }

  List<Product> _filterProducts(List<Product> products, String queryText) {
    final String query = queryText.trim().toLowerCase();
    if (query.isEmpty) {
      return products;
    }
    return products.where((Product product) {
      return product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<_DirectCartLine> get _cartLines {
    return _products
        .where((Product p) => (_qtyByProductId[p.id] ?? 0) > 0)
        .map(
          (Product p) => _DirectCartLine(
            product: p,
            qty: _qtyByProductId[p.id] ?? 0,
          ),
        )
        .toList();
  }

  int get _cartUnits {
    double total = 0;
    for (final _DirectCartLine line in _cartLines) {
      total += line.qty;
    }
    return total.round();
  }

  void _sanitizeCart() {
    final Set<String> ids = _products.map((Product row) => row.id).toSet();
    _qtyByProductId.removeWhere(
      (String productId, double _) => !ids.contains(productId),
    );
    if (_allowNegativeStock) {
      return;
    }
    final List<MapEntry<String, double>> entries =
        _qtyByProductId.entries.toList();
    for (final MapEntry<String, double> entry in entries) {
      final double stock = _stockByProductId[entry.key] ?? 0;
      if (entry.value <= stock) {
        continue;
      }
      if (stock <= 0) {
        _qtyByProductId.remove(entry.key);
      } else {
        _qtyByProductId[entry.key] = stock.floorToDouble();
      }
    }
  }

  bool _canIncreaseQty(String productId, {double delta = 1}) {
    if (_allowNegativeStock) {
      return true;
    }
    final double stock = _stockByProductId[productId] ?? 0;
    final double currentQty = _qtyByProductId[productId] ?? 0;
    return currentQty + delta <= stock + 0.000001;
  }

  void _changeQty(String productId, double delta) {
    if (delta > 0 && !_canIncreaseQty(productId, delta: delta)) {
      final Product? product = _findProduct(productId);
      final double stock = _stockByProductId[productId] ?? 0;
      if (product != null) {
        _show(
          'Stock insuficiente para ${product.name}. Disponible: ${_formatQty(stock)}',
        );
      }
      return;
    }
    final double next = (_qtyByProductId[productId] ?? 0) + delta;
    setState(() {
      if (next <= 0) {
        _qtyByProductId.remove(productId);
      } else {
        _qtyByProductId[productId] = next;
      }
    });
  }

  Product? _findProduct(String productId) {
    for (final Product product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  Future<void> _scanAndAddProduct() async {
    if (_loading || _posting) {
      return;
    }
    final String? raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CodeScannerPage(
          title: 'Escanear para venta directa',
          subtitle:
              'Escanea el QR del producto o su codigo de barras para agregarlo.',
        ),
        fullscreenDialog: true,
      ),
    );

    final String scanned = (raw ?? '').trim();
    if (scanned.isEmpty || !mounted) {
      return;
    }

    final ds = ref.read(productosLocalDataSourceProvider);
    Product? product;
    final ProductQrPayload? payload = ProductQrPayload.tryParse(scanned);
    if (payload != null) {
      product = await ds.findActiveProductById(payload.id);
      product ??= await ds.findActiveProductByCode(payload.code);
    } else {
      product = await ds.findActiveProductByBarcode(scanned);
      product ??= await ds.findActiveProductByCode(scanned);
    }
    if (!mounted) {
      return;
    }
    if (product == null) {
      _show('No se encontro un producto para el codigo escaneado.');
      return;
    }
    if (!_warehouseProductIds.contains(product.id)) {
      _show(
          'El producto ${product.name} no pertenece al almacen seleccionado.');
      return;
    }
    final double stock = _stockByProductId[product.id] ?? 0;
    if (!_allowNegativeStock && stock <= 0) {
      _show('El producto ${product.name} no tiene existencia.');
      return;
    }
    if (!_canIncreaseQty(product.id)) {
      _show(
        'Stock insuficiente para ${product.name}. Disponible: ${_formatQty(stock)}',
      );
      return;
    }
    _changeQty(product.id, 1);
  }

  int _subtotalFromLines(List<_DirectCartLine> lines) {
    int subtotal = 0;
    for (final _DirectCartLine line in lines) {
      subtotal += (line.qty * line.product.priceCents).round();
    }
    return subtotal;
  }

  int _taxFromLines(List<_DirectCartLine> lines) {
    int tax = 0;
    for (final _DirectCartLine line in lines) {
      final int lineSubtotal = (line.qty * line.product.priceCents).round();
      tax += (lineSubtotal * line.product.taxRateBps / 10000).round();
    }
    return tax;
  }

  int _totalFromLines(List<_DirectCartLine> lines, int discountCents) {
    final int gross = _subtotalFromLines(lines) + _taxFromLines(lines);
    if (discountCents >= gross) {
      return 0;
    }
    return gross - discountCents;
  }

  Future<void> _openCartSheet() async {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= 900) {
      await _openCartSidePanel();
      return;
    }
    await _openCartBottomSheet();
  }

  Future<void> _openCartBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: StatefulBuilder(
                builder: (
                  BuildContext modalContext,
                  StateSetter setModalState,
                ) {
                  return _buildCartBody(
                    modalContext: modalContext,
                    setModalState: setModalState,
                    withCloseButton: false,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCartSidePanel() async {
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Carrito',
      barrierDismissible: true,
      barrierColor: const Color(0x55000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return SafeArea(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
              child: Material(
                elevation: 10,
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 420,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: StatefulBuilder(
                      builder: (
                        BuildContext modalContext,
                        StateSetter setModalState,
                      ) {
                        return _buildCartBody(
                          modalContext: modalContext,
                          setModalState: setModalState,
                          withCloseButton: true,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Widget _buildCartBody({
    required BuildContext modalContext,
    required StateSetter setModalState,
    required bool withCloseButton,
  }) {
    final Color secondaryText = Theme.of(context).colorScheme.onSurfaceVariant;
    final List<_DirectCartLine> lines = _cartLines;
    final int subtotal = _subtotalFromLines(lines);
    final int tax = _taxFromLines(lines);
    final int total = subtotal + tax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Carrito',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${lines.length} item(s)',
              style: TextStyle(color: secondaryText),
            ),
            if (withCloseButton)
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(modalContext).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: lines.isEmpty
              ? const Center(child: Text('No hay productos en el carrito.'))
              : ListView.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, int index) {
                    final _DirectCartLine line = lines[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(line.product.name),
                      subtitle: Text(
                        '${line.product.sku} • ${_money(line.product.priceCents)}',
                      ),
                      trailing: SizedBox(
                        width: 138,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              onPressed: _posting
                                  ? null
                                  : () {
                                      _changeQty(line.product.id, -1);
                                      setModalState(() {});
                                    },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(_formatQty(line.qty)),
                            IconButton(
                              onPressed: _posting
                                  ? null
                                  : () {
                                      _changeQty(line.product.id, 1);
                                      setModalState(() {});
                                    },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (lines.isNotEmpty) ...<Widget>[
          const Divider(height: 1),
          const SizedBox(height: 10),
          _summaryRow('Subtotal', _money(subtotal)),
          _summaryRow('Impuesto', _money(tax)),
          _summaryRow('Total', _money(total), isBold: true),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _posting
                  ? null
                  : () async {
                      Navigator.of(modalContext).pop();
                      await _openPaymentSheet();
                    },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Procesar pago'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openPaymentSheet() async {
    final List<_DirectCartLine> lines = _cartLines;
    if (lines.isEmpty) {
      _show('El carrito esta vacio.');
      return;
    }
    final int subtotal = _subtotalFromLines(lines);
    final int tax = _taxFromLines(lines);
    final int gross = subtotal + tax;

    final String defaultMethod =
        _paymentMethods.contains('cash') ? 'cash' : _paymentMethods.first;
    final TextEditingController discountCtrl = TextEditingController();
    final List<_DirectPaymentLineDraft> drafts = <_DirectPaymentLineDraft>[
      _DirectPaymentLineDraft(method: defaultMethod)
        ..amountCtrl.text = (gross / 100).toStringAsFixed(2),
    ];

    int? submittedDiscountCents;
    Map<String, int>? submittedPayments;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  final int discountCents =
                      _moneyTextToCents(discountCtrl.text) ?? 0;
                  final int total =
                      discountCents >= gross ? 0 : gross - discountCents;

                  final Map<String, int> paymentByMethod = <String, int>{};
                  for (final _DirectPaymentLineDraft draft in drafts) {
                    final int cents =
                        _moneyTextToCents(draft.amountCtrl.text) ?? 0;
                    if (cents <= 0) {
                      continue;
                    }
                    paymentByMethod[draft.method] =
                        (paymentByMethod[draft.method] ?? 0) + cents;
                  }

                  final int paid = paymentByMethod.values.fold<int>(
                    0,
                    (int sum, int value) => sum + value,
                  );
                  final int pending = (total - paid) > 0 ? (total - paid) : 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Procesar pago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Lineas de pago',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              ...List<Widget>.generate(drafts.length, (
                                int index,
                              ) {
                                final _DirectPaymentLineDraft draft =
                                    drafts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: draft.method,
                                          items: _paymentMethods
                                              .map(
                                                (String method) =>
                                                    DropdownMenuItem<String>(
                                                  value: method,
                                                  child: Text(
                                                    _paymentMethodLabel(method),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (String? value) {
                                            if (value == null) {
                                              return;
                                            }
                                            setModalState(() {
                                              draft.method = value;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 110,
                                        child: TextField(
                                          controller: draft.amountCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: true,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: '0.00',
                                          ),
                                          onChanged: (_) =>
                                              setModalState(() {}),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: drafts.length <= 1
                                            ? null
                                            : () {
                                                setModalState(() {
                                                  final _DirectPaymentLineDraft
                                                      removed = drafts.removeAt(
                                                    index,
                                                  );
                                                  removed.dispose();
                                                  final int currentDiscount =
                                                      _moneyTextToCents(
                                                            discountCtrl.text,
                                                          ) ??
                                                          0;
                                                  final int currentTotal =
                                                      currentDiscount >= gross
                                                          ? 0
                                                          : gross -
                                                              currentDiscount;
                                                  _syncSinglePaymentLineToTotal(
                                                    drafts: drafts,
                                                    totalCents: currentTotal,
                                                  );
                                                });
                                              },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setModalState(() {
                                      drafts.add(
                                        _DirectPaymentLineDraft(
                                          method: defaultMethod,
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Agregar linea'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: discountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Descuento',
                                  hintText: '0.00',
                                ),
                                onChanged: (_) {
                                  setModalState(() {
                                    final int nextDiscount =
                                        _moneyTextToCents(discountCtrl.text) ??
                                            0;
                                    final int nextTotal = nextDiscount >= gross
                                        ? 0
                                        : gross - nextDiscount;
                                    _syncSinglePaymentLineToTotal(
                                      drafts: drafts,
                                      totalCents: nextTotal,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _summaryRow('Subtotal', _money(subtotal)),
                              _summaryRow('Impuesto', _money(tax)),
                              _summaryRow('Total', _money(total), isBold: true),
                              _summaryRow('Pagado', _money(paid)),
                              _summaryRow(
                                'Pendiente',
                                _money(pending),
                                valueColor: pending == 0
                                    ? const Color(0xFF148A65)
                                    : const Color(0xFFB13B5A),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _posting
                              ? null
                              : () {
                                  if (discountCents < 0) {
                                    _show(
                                      'El descuento no puede ser negativo.',
                                    );
                                    return;
                                  }
                                  if (discountCents > gross) {
                                    _show(
                                      'El descuento no puede superar el total bruto de la venta.',
                                    );
                                    return;
                                  }
                                  if (paymentByMethod.isEmpty) {
                                    _show('Debes ingresar al menos un pago.');
                                    return;
                                  }
                                  if (paid != total) {
                                    _show(
                                      'La suma de pagos debe ser igual al total de la venta.',
                                    );
                                    return;
                                  }
                                  submittedDiscountCents = discountCents;
                                  submittedPayments = paymentByMethod;
                                  Navigator.of(context).pop();
                                },
                          child: const Text('Validar pago'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    for (final _DirectPaymentLineDraft draft in drafts) {
      draft.dispose();
    }
    discountCtrl.dispose();

    if (submittedPayments == null || submittedDiscountCents == null) {
      return;
    }
    await _submitSale(
      discountCents: submittedDiscountCents!,
      paymentByMethod: submittedPayments!,
    );
  }

  Future<void> _submitSale({
    required int discountCents,
    required Map<String, int> paymentByMethod,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    if (_selectedWarehouseId == null) {
      _show('Selecciona un almacen para vender.');
      return;
    }

    final List<_DirectCartLine> lines = _cartLines;
    if (lines.isEmpty) {
      _show('Agrega al menos un producto con cantidad mayor a 0.');
      return;
    }
    final int subtotalCents = _subtotalFromLines(lines);
    final int taxCents = _taxFromLines(lines);
    final int gross = subtotalCents + taxCents;
    if (discountCents > gross) {
      _show('El descuento no puede superar el total bruto de la venta.');
      return;
    }
    final int totalCents = _totalFromLines(lines, discountCents);
    final int paymentsTotal = paymentByMethod.values.fold<int>(
      0,
      (int sum, int value) => sum + value,
    );
    if (paymentsTotal != totalCents) {
      _show('La suma de pagos no coincide con el total de la venta.');
      return;
    }

    final List<SaleItemInput> items = lines
        .map(
          (_DirectCartLine line) => SaleItemInput(
            productId: line.product.id,
            qty: line.qty,
            unitPriceCents: line.product.priceCents,
            taxRateBps: line.product.taxRateBps,
          ),
        )
        .toList();

    final CreateSaleInput input = CreateSaleInput(
      warehouseId: _selectedWarehouseId!,
      cashierId: session.userId,
      terminalId: null,
      terminalSessionId: null,
      items: items,
      payments: paymentByMethod.entries
          .map(
            (MapEntry<String, int> entry) =>
                PaymentInput(method: entry.key, amountCents: entry.value),
          )
          .toList(),
      discountCents: discountCents,
      allowNegativeStock: _allowNegativeStock,
      saleOrigin: 'direct',
    );

    setState(() => _posting = true);
    final AppResult<CreateSaleResult> result =
        await ref.read(ventasPosLocalDataSourceProvider).createSale(input);
    if (!mounted) {
      return;
    }
    setState(() => _posting = false);

    switch (result) {
      case AppSuccess<CreateSaleResult>(:final data):
        setState(() => _qtyByProductId.clear());
        await _bootstrap();
        if (!mounted) {
          return;
        }
        _show('Venta directa registrada. Folio: ${data.folio}');
      case AppFailure<CreateSaleResult>(:final message):
        _show(message);
    }
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

  void _syncSinglePaymentLineToTotal({
    required List<_DirectPaymentLineDraft> drafts,
    required int totalCents,
  }) {
    if (drafts.length != 1) {
      return;
    }
    final String next = (totalCents / 100).toStringAsFixed(2);
    if (drafts.first.amountCtrl.text == next) {
      return;
    }
    drafts.first.amountCtrl.text = next;
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'wallet':
        return 'Billetera';
      default:
        return method;
    }
  }

  String _money(int cents) {
    final bool negative = cents < 0;
    final int absCents = cents.abs();
    final String value =
        '$_currencySymbol${(absCents / 100).toStringAsFixed(2)}';
    return negative ? '-$value' : value;
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final TextStyle style = isBold
        ? const TextStyle(fontWeight: FontWeight.w800)
        : const TextStyle();
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

  int _gridColumnsForWidth(double width) {
    if (width >= 1180) {
      return 6;
    }
    if (width >= 980) {
      return 5;
    }
    if (width >= 760) {
      return 4;
    }
    if (width >= 350) {
      return 3;
    }
    return 2;
  }

  double _gridAspectRatioForWidth(double width) {
    if (width < 350) {
      return 0.88;
    }
    if (width < 430) {
      return 0.96;
    }
    if (width < 560) {
      return 1.02;
    }
    if (width < 760) {
      return 1.06;
    }
    return 1.1;
  }

  Widget _warehouseHeader() {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFE2DAF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ventas Directas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _selectedWarehouseId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Almacen',
              isDense: true,
            ),
            items: _warehouses
                .map(
                  (Warehouse warehouse) => DropdownMenuItem<String?>(
                    value: warehouse.id,
                    child: Text(warehouse.name),
                  ),
                )
                .toList(),
            onChanged: _posting ? null : _changeWarehouse,
          ),
        ],
      ),
    );
  }

  Widget _productFilterField() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: 'Filtrar productos',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchCtrl.text.isEmpty
            ? null
            : IconButton(
                onPressed: _searchCtrl.clear,
                icon: const Icon(Icons.clear_rounded),
              ),
        filled: true,
        fillColor: isDark ? const Color(0xFF211D2D) : const Color(0xFFF9F7FD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF342E46) : const Color(0xFFE1D8F2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF342E46) : const Color(0xFFE1D8F2),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String path = (product.imagePath ?? '').trim();
    if (path.isEmpty) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF28233A) : const Color(0xFFEDE7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.inventory_2_outlined, size: 16),
      );
    }

    final File file = File(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        file,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF28233A) : const Color(0xFFEDE7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image_outlined, size: 16),
          );
        },
      ),
    );
  }

  Widget _qtyButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isAdd,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool enabled = onTap != null;
    final Color bg = isAdd
        ? (isDark ? const Color(0xFF233246) : const Color(0xFFE4EEF9))
        : (isDark ? const Color(0xFF35263F) : const Color(0xFFF3EAF8));
    final Color fg = isAdd
        ? (isDark ? const Color(0xFF9AC1FF) : const Color(0xFF305A9A))
        : (isDark ? const Color(0xFFDAB4E7) : const Color(0xFF6C427A));

    return Material(
      color: enabled
          ? bg
          : (isDark ? const Color(0xFF2A2632) : const Color(0xFFECECEC)),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 31,
          height: 31,
          child: Icon(
            icon,
            size: 18,
            color:
                enabled ? fg : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _productCard(Product product) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final double qty = _qtyByProductId[product.id] ?? 0;
    final double stock = _stockByProductId[product.id] ?? 0;
    final bool outOfStock = stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFE3DAF8),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0E000000),
                  blurRadius: 6,
                  offset: Offset(0, 1.5),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildProductImage(product),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        product.sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: outOfStock
                        ? (isDark
                            ? const Color(0xFF472733)
                            : const Color(0xFFFBE9EE))
                        : (isDark
                            ? const Color(0xFF233246)
                            : const Color(0xFFE6ECFA)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatQty(stock),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: outOfStock
                          ? const Color(0xFFFF8EB4)
                          : (isDark
                              ? const Color(0xFF9AC1FF)
                              : const Color(0xFF3D4E89)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _money(product.priceCents),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.8,
                color: isDark ? scheme.primary : const Color(0xFF3A2D61),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                _qtyButton(
                  icon: Icons.remove_rounded,
                  isAdd: false,
                  onTap: _posting ? null : () => _changeQty(product.id, -1),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF28233A)
                            : const Color(0xFFF7F3FC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatQty(qty),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                _qtyButton(
                  icon: Icons.add_rounded,
                  isAdd: true,
                  onTap: _posting ? null : () => _changeQty(product.id, 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _productsGridSliver() {
    final List<Product> products = _visibleProducts;
    if (products.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No hay productos en el almacen seleccionado.'),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final double width = constraints.crossAxisExtent;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 98),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => _productCard(products[index]),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridColumnsForWidth(width),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: _gridAspectRatioForWidth(width),
            ),
          ),
        );
      },
    );
  }

  Widget _floatingButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FloatingActionButton.small(
          heroTag: 'directScanFab',
          onPressed: _scanAndAddProduct,
          child: const Icon(Icons.qr_code_scanner_rounded),
        ),
        const SizedBox(height: 10),
        Badge(
          isLabelVisible: _cartUnits > 0,
          label: Text('$_cartUnits'),
          child: FloatingActionButton.small(
            heroTag: 'directCartFab',
            onPressed: _openCartSheet,
            child: const Icon(Icons.shopping_cart_rounded),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ventas Directas',
      currentRoute: '/ventas-directas',
      onRefresh: _bootstrap,
      floatingActionButton: _floatingButtons(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: <Widget>[
                          _warehouseHeader(),
                          const SizedBox(height: 10),
                          _productFilterField(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  _productsGridSliver(),
                ],
              ),
            ),
    );
  }
}

class _DirectCartLine {
  const _DirectCartLine({required this.product, required this.qty});

  final Product product;
  final double qty;
}

class _DirectPaymentLineDraft {
  _DirectPaymentLineDraft({required this.method})
      : amountCtrl = TextEditingController();

  String method;
  final TextEditingController amountCtrl;

  void dispose() {
    amountCtrl.dispose();
  }
}
