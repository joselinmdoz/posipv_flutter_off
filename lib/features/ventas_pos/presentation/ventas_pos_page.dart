import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/app_result.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../inventario/data/inventario_local_datasource.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../productos/domain/product_qr_codec.dart';
import '../../productos/presentation/productos_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../tpv/data/tpv_local_datasource.dart';
import '../../tpv/presentation/tpv_providers.dart';
import '../domain/sale_models.dart';
import 'ventas_pos_providers.dart';

class VentasPosPage extends ConsumerStatefulWidget {
  const VentasPosPage({super.key});

  @override
  ConsumerState<VentasPosPage> createState() => _VentasPosPageState();
}

class _VentasPosPageState extends ConsumerState<VentasPosPage> {
  List<Product> _products = <Product>[];
  List<Product> _visibleProducts = <Product>[];
  List<Product> _quickAdjustProducts = <Product>[];
  final Set<String> _warehouseProductIds = <String>{};
  final Map<String, double> _qtyByProductId = <String, double>{};
  final Map<String, double> _stockByProductId = <String, double>{};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  String? _warehouseId;
  String? _warehouseName;
  String? _terminalId;
  String? _terminalName;
  String? _openSessionId;
  TpvTerminalConfig _terminalConfig = TpvTerminalConfig.defaults;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _allowNegativeStock = false;
  bool _loading = true;
  bool _posting = false;
  bool _closingSession = false;
  bool _showingIpvSheet = false;
  bool _redirectingToTpv = false;

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
      final UserSession? session = ref.read(currentSessionProvider);
      final Future<AppConfig> configFuture =
          ref.read(configuracionLocalDataSourceProvider).loadConfig();

      if (session == null || session.activeTerminalId == null) {
        AppConfig config = AppConfig.defaults;
        try {
          config = await configFuture;
        } catch (_) {}
        if (!mounted) {
          return;
        }
        setState(() {
          _resetPosState(
            currencySymbol: config.currencySymbol,
            allowNegativeStock: config.allowNegativeStock,
          );
          _loading = false;
        });
        _redirectToTpv('Abre un turno en un TPV para usar el POS.');
        return;
      }

      final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
      final Future<TpvTerminalView?> terminalFuture =
          tpvDs.getTerminalView(session.activeTerminalId!);
      AppConfig config = AppConfig.defaults;
      try {
        config = await configFuture;
      } catch (_) {}
      final TpvTerminalView? terminalView = await terminalFuture;
      if (terminalView == null ||
          !terminalView.terminal.isActive ||
          !terminalView.warehouse.isActive) {
        if (!mounted) {
          return;
        }
        setState(() {
          _resetPosState(
            currencySymbol: config.currencySymbol,
            allowNegativeStock: config.allowNegativeStock,
          );
          _loading = false;
        });
        _redirectToTpv('El TPV activo no es valido. Abre un turno nuevamente.');
        return;
      }

      final TpvTerminalConfig terminalConfig =
          tpvDs.configFromTerminal(terminalView.terminal);
      final Future<PosSession?> openSessionFuture =
          tpvDs.getOpenSessionForTerminalAndUser(
        terminalId: terminalView.terminal.id,
        userId: session.userId,
      );
      final Future<List<InventoryView>> stockedFuture = ref
          .read(inventarioLocalDataSourceProvider)
          .listStocked(warehouseId: terminalView.warehouse.id);
      final Future<List<InventoryView>> warehouseRowsFuture = ref
          .read(inventarioLocalDataSourceProvider)
          .listByWarehouse(terminalView.warehouse.id);

      final PosSession? openSession = await openSessionFuture;
      final List<InventoryView> stockedRows = await stockedFuture;
      final List<InventoryView> warehouseRows = await warehouseRowsFuture;

      final Set<String> warehouseProductIds =
          stockedRows.map((InventoryView row) => row.productId).toSet();
      final Set<String> quickAdjustIds =
          warehouseRows.map((InventoryView row) => row.productId).toSet();
      final Map<String, double> stockByProductId = <String, double>{
        for (final InventoryView row in stockedRows) row.productId: row.qty,
      };
      final List<Product> products = await ref
          .read(productosLocalDataSourceProvider)
          .listActiveProductsByIds(warehouseProductIds);
      final List<Product> quickAdjustProducts = quickAdjustIds
              .difference(
                warehouseProductIds,
              )
              .isEmpty
          ? products
          : await ref
              .read(productosLocalDataSourceProvider)
              .listActiveProductsByIds(quickAdjustIds);

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
        _visibleProducts = _filterProducts(products, _searchCtrl.text);
        _quickAdjustProducts = quickAdjustProducts;
        _warehouseProductIds
          ..clear()
          ..addAll(warehouseProductIds);
        _stockByProductId
          ..clear()
          ..addAll(stockByProductId);
        _warehouseId = terminalView.warehouse.id;
        _warehouseName = terminalView.warehouse.name;
        _terminalId = terminalView.terminal.id;
        _terminalName = terminalView.terminal.name;
        _openSessionId = openSession?.id;
        _terminalConfig = terminalConfig;
        _currencySymbol = terminalConfig.currencySymbol;
        _allowNegativeStock = config.allowNegativeStock;
        _sanitizeCartForWarehouseStock();
        _loading = false;
      });

      if (openSession == null) {
        _redirectToTpv('No hay un turno abierto para este usuario en el TPV.');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar Ventas POS: $e');
    }
  }

  void _resetPosState({
    required String currencySymbol,
    required bool allowNegativeStock,
  }) {
    _products = <Product>[];
    _visibleProducts = <Product>[];
    _quickAdjustProducts = <Product>[];
    _warehouseProductIds.clear();
    _qtyByProductId.clear();
    _stockByProductId.clear();
    _warehouseId = null;
    _warehouseName = null;
    _terminalId = null;
    _terminalName = null;
    _openSessionId = null;
    _terminalConfig = TpvTerminalConfig.defaults;
    _currencySymbol = currencySymbol;
    _allowNegativeStock = allowNegativeStock;
  }

  void _redirectToTpv(String message) {
    if (_redirectingToTpv || !mounted) {
      return;
    }
    _redirectingToTpv = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _redirectingToTpv = false;
        return;
      }
      _show(message);
      context.go('/tpv');
      _redirectingToTpv = false;
    });
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

  List<_CartLine> get _cartLines {
    return _products
        .where((Product p) => (_qtyByProductId[p.id] ?? 0) > 0)
        .map(
          (Product p) => _CartLine(
            product: p,
            qty: _qtyByProductId[p.id] ?? 0,
          ),
        )
        .toList();
  }

  int get _cartUnits {
    double total = 0;
    for (final _CartLine line in _cartLines) {
      total += line.qty;
    }
    return total.round();
  }

  int _subtotalFromLines(List<_CartLine> lines) {
    int subtotal = 0;
    for (final _CartLine line in lines) {
      subtotal += (line.qty * line.product.priceCents).round();
    }
    return subtotal;
  }

  int _taxFromLines(List<_CartLine> lines) {
    int tax = 0;
    for (final _CartLine line in lines) {
      final int lineSubtotal = (line.qty * line.product.priceCents).round();
      tax += (lineSubtotal * line.product.taxRateBps / 10000).round();
    }
    return tax;
  }

  int _totalFromLines(List<_CartLine> lines, int discountCents) {
    final int gross = _subtotalFromLines(lines) + _taxFromLines(lines);
    if (discountCents >= gross) {
      return 0;
    }
    return gross - discountCents;
  }

  void _sanitizeCartForWarehouseStock() {
    final Set<String> visibleProductIds =
        _products.map((Product product) => product.id).toSet();
    _qtyByProductId.removeWhere(
      (String productId, double _) => !visibleProductIds.contains(productId),
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
        continue;
      }
      _qtyByProductId[entry.key] = stock.floorToDouble();
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
      final Product? product = _findProductById(productId);
      if (product != null) {
        final double stock = _stockByProductId[product.id] ?? 0;
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

  Future<void> _scanAndAddProduct() async {
    if (_loading || _posting) {
      return;
    }

    final String? raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CodeScannerPage(
          title: 'Escanear para venta',
          subtitle:
              'Escanea el QR del producto o su codigo de barras para agregarlo a la venta.',
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

    final Product matched = product;
    if (!_warehouseProductIds.contains(matched.id)) {
      _show(
        'El producto ${matched.name} no pertenece al almacen de este TPV.',
      );
      return;
    }

    final double stock = _stockByProductId[matched.id] ?? 0;
    if (!_allowNegativeStock && stock <= 0) {
      _show(
        'El producto ${matched.name} no tiene existencia en el almacen del TPV.',
      );
      return;
    }

    if (!_canIncreaseQty(matched.id)) {
      _show(
        'Stock insuficiente para ${matched.name}. Disponible: ${_formatQty(stock)}',
      );
      return;
    }

    _changeQty(matched.id, 1);
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
                builder:
                    (BuildContext modalContext, StateSetter setModalState) {
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
                      builder: (BuildContext modalContext,
                          StateSetter setModalState) {
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
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  Widget _buildCartBody({
    required BuildContext modalContext,
    required StateSetter setModalState,
    required bool withCloseButton,
  }) {
    final Color secondaryText = Theme.of(context).colorScheme.onSurfaceVariant;
    final List<_CartLine> lines = _cartLines;
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
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
              ? const Center(
                  child: Text('No hay productos en el carrito.'),
                )
              : ListView.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, int index) {
                    final _CartLine line = lines[index];
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
    final List<_CartLine> lines = _cartLines;
    if (lines.isEmpty) {
      _show('El carrito esta vacio.');
      return;
    }

    final List<String> methods = _terminalConfig.paymentMethods.isEmpty
        ? <String>['cash']
        : _terminalConfig.paymentMethods;

    final int subtotal = _subtotalFromLines(lines);
    final int tax = _taxFromLines(lines);
    final int gross = subtotal + tax;
    final String defaultMethod =
        methods.contains('cash') ? 'cash' : methods.first;
    final TextEditingController discountCtrl = TextEditingController();
    final List<_PaymentLineDraft> drafts = <_PaymentLineDraft>[
      _PaymentLineDraft(method: defaultMethod)
        ..amountCtrl.text = (gross / 100).toStringAsFixed(2),
    ];
    final List<_PaymentLineDraft> removedDrafts = <_PaymentLineDraft>[];

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
                  for (final _PaymentLineDraft draft in drafts) {
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
                                final _PaymentLineDraft draft = drafts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: draft.method,
                                          items: methods
                                              .map(
                                                (String method) =>
                                                    DropdownMenuItem<String>(
                                                  value: method,
                                                  child: Text(
                                                    _paymentMethodLabel(
                                                      method,
                                                    ),
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
                                                _PaymentLineDraft? removed;
                                                setModalState(() {
                                                  removed =
                                                      drafts.removeAt(index);
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
                                                if (removed != null) {
                                                  removedDrafts.add(removed!);
                                                }
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
                                        _PaymentLineDraft(
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
                              _summaryRow(
                                'Total',
                                _money(total),
                                isBold: true,
                              ),
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
                                        'El descuento no puede ser negativo.');
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final _PaymentLineDraft draft in <_PaymentLineDraft>[
        ...drafts,
        ...removedDrafts,
      ]) {
        draft.dispose();
      }
      discountCtrl.dispose();
    });

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
    if (_terminalId == null || _warehouseId == null) {
      _show('No hay un TPV activo para esta sesion.');
      return;
    }
    if (_openSessionId == null) {
      _show('Debes abrir un turno en este TPV antes de vender.');
      return;
    }

    final List<_CartLine> lines = _cartLines;
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
          (_CartLine line) => SaleItemInput(
            productId: line.product.id,
            qty: line.qty,
            unitPriceCents: line.product.priceCents,
            taxRateBps: line.product.taxRateBps,
          ),
        )
        .toList();

    final CreateSaleInput input = CreateSaleInput(
      warehouseId: _warehouseId!,
      cashierId: session.userId,
      terminalId: _terminalId!,
      terminalSessionId: _openSessionId!,
      items: items,
      payments: paymentByMethod.entries
          .map(
            (MapEntry<String, int> entry) =>
                PaymentInput(method: entry.key, amountCents: entry.value),
          )
          .toList(),
      discountCents: discountCents,
      allowNegativeStock: _allowNegativeStock,
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
        final _SaleReceipt receipt = _SaleReceipt(
          folio: data.folio,
          createdAt: DateTime.now(),
          cashierUsername: session.username,
          terminalName: _terminalName ?? '',
          warehouseName: _warehouseName ?? '',
          lines: lines
              .map(
                (_CartLine line) => _SaleReceiptLine(
                  name: line.product.name,
                  sku: line.product.sku,
                  qty: line.qty,
                  unitPriceCents: line.product.priceCents,
                  taxRateBps: line.product.taxRateBps,
                ),
              )
              .toList(),
          subtotalCents: subtotalCents,
          taxCents: taxCents,
          discountCents: discountCents,
          totalCents: totalCents,
          payments: paymentByMethod.entries
              .map(
                (MapEntry<String, int> entry) => _ReceiptPayment(
                  method: _paymentMethodLabel(entry.key),
                  amountCents: entry.value,
                ),
              )
              .toList(),
          paidCents: paymentsTotal,
        );

        setState(() {
          _qtyByProductId.clear();
        });
        await _bootstrap();
        if (!mounted) {
          return;
        }
        _show('Venta registrada. Folio: ${data.folio}');
        await _showReceiptDialog(receipt);
      case AppFailure<CreateSaleResult>(:final message):
        _show(message);
    }
  }

  Future<void> _showReceiptDialog(_SaleReceipt receipt) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Comprobante de venta'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Folio: ${receipt.folio}'),
                  Text('Fecha: ${_formatDateTime(receipt.createdAt)}'),
                  Text('Cajero: ${receipt.cashierUsername}'),
                  Text('TPV: ${receipt.terminalName}'),
                  Text('Almacen: ${receipt.warehouseName}'),
                  const Divider(height: 20),
                  ...receipt.lines.map((_SaleReceiptLine line) {
                    final int lineTotalCents = line.lineTotalCents;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${line.name}\n${line.sku} • ${_formatQty(line.qty)} x ${_money(line.unitPriceCents)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_money(lineTotalCents)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  _summaryRow('Subtotal', _money(receipt.subtotalCents)),
                  _summaryRow('Impuesto', _money(receipt.taxCents)),
                  _summaryRow('Descuento', _money(receipt.discountCents)),
                  _summaryRow('Total', _money(receipt.totalCents),
                      isBold: true),
                  const SizedBox(height: 10),
                  const Text('Pagos',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ...receipt.payments.map(
                    (_ReceiptPayment payment) => _summaryRow(
                        payment.method, _money(payment.amountCents)),
                  ),
                  _summaryRow('Pagado', _money(receipt.paidCents)),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openQuickStockDialog() async {
    if (_warehouseId == null || _terminalId == null) {
      _show('No hay TPV activo para ajustar stock.');
      return;
    }
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    final List<Product> adjustProducts = _quickAdjustProducts;
    if (adjustProducts.isEmpty) {
      _show('No hay productos para ajustar.');
      return;
    }
    final InventarioLocalDataSource inventarioDs =
        ref.read(inventarioLocalDataSourceProvider);
    final List<InventoryMovementReason> entryReasons =
        await inventarioDs.listManualMovementReasons(movementType: 'in');
    final List<InventoryMovementReason> outputReasons =
        await inventarioDs.listManualMovementReasons(movementType: 'out');
    if (entryReasons.isEmpty && outputReasons.isEmpty) {
      _show('No hay motivos disponibles para registrar movimientos.');
      return;
    }
    if (!mounted) {
      return;
    }

    final Map<String, Product> productById = <String, Product>{
      for (final Product product in adjustProducts) product.id: product,
    };
    final List<Product> stockedAdjustProducts = adjustProducts
        .where((Product product) => (_stockByProductId[product.id] ?? 0) > 0)
        .toList();

    String? selectedProductId = adjustProducts.first.id;
    bool isEntry = entryReasons.isNotEmpty || outputReasons.isEmpty;
    String? selectedReasonCode = isEntry
        ? (entryReasons.isNotEmpty ? entryReasons.first.code : null)
        : (outputReasons.isNotEmpty ? outputReasons.first.code : null);
    String qtyText = '';
    String noteText = '';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color secondaryText =
                Theme.of(context).colorScheme.onSurfaceVariant;
            final List<Product> selectableProducts =
                isEntry ? adjustProducts : stockedAdjustProducts;
            final List<InventoryMovementReason> selectableReasons =
                isEntry ? entryReasons : outputReasons;
            final Product? selectedProduct = selectedProductId == null
                ? null
                : productById[selectedProductId];
            final double selectedStock = selectedProduct == null
                ? 0
                : (_stockByProductId[selectedProduct.id] ?? 0);
            return AlertDialog(
              title: const Text('Entrada / Salida'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<String?>(
                        initialValue: selectedProductId,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Producto'),
                        items: selectableProducts
                            .map(
                              (Product p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text('${p.sku} - ${p.name}'),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setStateDialog(() => selectedProductId = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF241F33)
                              : const Color(0xFFF6F2FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF342E46)
                                : const Color(0xFFD8D0EB),
                          ),
                        ),
                        child: selectedProduct == null
                            ? Text(
                                'No hay productos con stock para realizar una salida.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    selectedProduct.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Precio venta: ${_money(selectedProduct.priceCents)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Stock TPV: ${_formatQty(selectedStock)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Entrada'),
                            icon: Icon(Icons.add_box_outlined),
                          ),
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Salida'),
                            icon: Icon(Icons.indeterminate_check_box_outlined),
                          ),
                        ],
                        selected: <bool>{isEntry},
                        onSelectionChanged: (Set<bool> value) {
                          setStateDialog(() {
                            final bool nextIsEntry = value.first;
                            final List<InventoryMovementReason> nextReasons =
                                nextIsEntry ? entryReasons : outputReasons;
                            isEntry = nextIsEntry;
                            if (!nextIsEntry) {
                              if (stockedAdjustProducts.isEmpty) {
                                selectedProductId = null;
                              } else if (selectedProductId == null ||
                                  !_stockByProductId.containsKey(
                                    selectedProductId,
                                  ) ||
                                  (_stockByProductId[selectedProductId] ?? 0) <=
                                      0) {
                                selectedProductId =
                                    stockedAdjustProducts.first.id;
                              }
                            } else if (selectedProductId == null &&
                                adjustProducts.isNotEmpty) {
                              selectedProductId = adjustProducts.first.id;
                            }
                            if (nextReasons.isEmpty) {
                              selectedReasonCode = null;
                            } else if (selectedReasonCode == null ||
                                !nextReasons.any(
                                  (InventoryMovementReason reason) =>
                                      reason.code == selectedReasonCode,
                                )) {
                              selectedReasonCode = nextReasons.first.code;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        key: ValueKey<String>(
                          '${isEntry ? 'in' : 'out'}-${selectedReasonCode ?? 'none'}',
                        ),
                        initialValue: selectedReasonCode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Motivo del movimiento',
                        ),
                        items: selectableReasons
                            .map(
                              (InventoryMovementReason reason) =>
                                  DropdownMenuItem<String?>(
                                value: reason.code,
                                child: Text(reason.label),
                              ),
                            )
                            .toList(),
                        onChanged: selectableReasons.isEmpty
                            ? null
                            : (String? value) {
                                setStateDialog(
                                    () => selectedReasonCode = value);
                              },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          hintText: '0.00',
                        ),
                        onChanged: (String value) => qtyText = value,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Nota (opcional)',
                        ),
                        onChanged: (String value) => noteText = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed:
                      selectedProductId == null || selectedReasonCode == null
                          ? null
                          : () => Navigator.of(context).pop(true),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (selectedProductId == null) {
      _show('Selecciona un producto valido para ajustar.');
      return;
    }
    final String safeProductId = selectedProductId!;
    if (selectedReasonCode == null || selectedReasonCode!.trim().isEmpty) {
      _show('Selecciona un motivo para registrar el movimiento.');
      return;
    }
    final String safeReasonCode = selectedReasonCode!;

    final double? qty = double.tryParse(qtyText.trim().replaceAll(',', '.'));
    final String note = noteText.trim();

    if (qty == null || qty <= 0) {
      _show('Cantidad invalida.');
      return;
    }

    final double currentQty = _stockByProductId[safeProductId] ?? 0;
    final double nextQty = isEntry ? currentQty + qty : currentQty - qty;
    if (!isEntry && currentQty <= 0) {
      _show('Solo puedes hacer salidas de productos con stock en el TPV.');
      return;
    }
    if (!isEntry && qty > currentQty) {
      _show('La salida supera el stock disponible en el TPV.');
      return;
    }
    if (isEntry == false && nextQty < 0) {
      _show('La salida supera el stock disponible.');
      return;
    }
    if (isEntry && !_allowNegativeStock && nextQty < 0) {
      _show('No se pudo calcular el stock final.');
      return;
    }

    try {
      await inventarioDs.createManualMovement(
        productId: safeProductId,
        warehouseId: _warehouseId!,
        type: isEntry ? 'in' : 'out',
        qty: qty,
        reasonCode: safeReasonCode,
        userId: session.userId,
        note: note.isEmpty
            ? (isEntry ? 'Entrada rapida TPV' : 'Salida rapida TPV')
            : note,
      );
      await _bootstrap();
      _show('Inventario actualizado desde TPV.');
    } catch (e) {
      _show('No se pudo ajustar inventario: $e');
    }
  }

  Future<void> _openCurrentIpvFromPos() async {
    if (_showingIpvSheet) {
      return;
    }
    final String? sessionId = _openSessionId;
    if (sessionId == null || sessionId.trim().isEmpty) {
      _show('No hay turno abierto para consultar IPV.');
      _redirectToTpv('Abre un turno para consultar el IPV.');
      return;
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    IpvReportSummaryStat? report;
    List<IpvReportLineStat> lines = <IpvReportLineStat>[];
    try {
      report = await reportesDs.findIpvReportBySessionId(
        sessionId,
        includeOpen: true,
      );
      if (report == null) {
        _show('No se encontro IPV para la sesion actual.');
        return;
      }
      lines = await reportesDs.listIpvReportLines(report.reportId);
    } catch (e) {
      _show('No se pudo cargar IPV: $e');
      return;
    }

    if (!mounted) {
      return;
    }

    final IpvReportSummaryStat activeReport = report;
    _showingIpvSheet = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'IPV ${_terminalName ?? "TPV"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDateTime(activeReport.openedAt)} → ${activeReport.closedAt == null ? '-' : _formatDateTime(activeReport.closedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF655D83),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _exportIpvReport(activeReport, 'csv');
                          },
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _exportIpvReport(activeReport, 'pdf');
                          },
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: lines.isEmpty
                          ? const Center(
                              child: Text(
                                'Este IPV aun no tiene lineas con movimiento.',
                              ),
                            )
                          : ListView.separated(
                              itemCount: lines.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, int index) {
                                final IpvReportLineStat row = lines[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        row.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'SKU ${row.sku}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF655D83),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 4,
                                        children: <Widget>[
                                          Text(
                                            'Inicio: ${row.startQty.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            'Entradas: ${row.entriesQty.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            'Salidas: ${row.outputsQty.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            'Ventas: ${row.salesQty.toStringAsFixed(2)}',
                                          ),
                                          Text(
                                            'Final: ${row.finalQty.toStringAsFixed(2)}',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              'P. venta: ${_formatCentsWithSymbol(row.salePriceCents, activeReport.currencySymbol)}',
                                            ),
                                          ),
                                          Text(
                                            'Importe: ${_formatCentsWithSymbol(row.totalAmountCents, activeReport.currencySymbol)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _showingIpvSheet = false;
    }
  }

  Future<void> _exportIpvReport(
    IpvReportSummaryStat report,
    String format,
  ) async {
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final String path = format == 'pdf'
          ? await ds.exportIpvReportPdf(report.reportId)
          : await ds.exportIpvReportCsv(report.reportId);
      _show('IPV exportado $format en: $path');
    } catch (e, st) {
      debugPrint('IPV export failed (ventas_pos_page). $e');
      debugPrintStack(stackTrace: st);
      _show('No se pudo exportar IPV: $e');
    }
  }

  Future<void> _closeSessionFromPos() async {
    if (_closingSession) {
      return;
    }
    final UserSession? userSession = ref.read(currentSessionProvider);
    if (userSession == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    final String? terminalId = _terminalId;
    final String? sessionId = _openSessionId;
    if (terminalId == null || sessionId == null) {
      _show('No hay turno abierto para cerrar.');
      _redirectToTpv('Abre un turno para operar el POS.');
      return;
    }

    final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
    final PosSession? openSession =
        await tpvDs.getOpenSessionForTerminalAndUser(
      terminalId: terminalId,
      userId: userSession.userId,
    );
    if (openSession == null) {
      _show('No hay turno abierto para este usuario.');
      _redirectToTpv('Abre un turno para operar el POS.');
      return;
    }

    Map<String, int> expectedByMethod = <String, int>{};
    try {
      expectedByMethod =
          await tpvDs.getSessionExpectedPaymentsByMethod(openSession.id);
    } catch (_) {
      expectedByMethod = <String, int>{};
    }

    final Map<String, int> expectedConfigured = <String, int>{
      for (final String method in _terminalConfig.paymentMethods)
        method: expectedByMethod[method] ?? 0,
    };
    final int expectedCashFromSalesCents = expectedConfigured['cash'] ?? 0;
    final int expectedCashCents =
        openSession.openingFloatCents + expectedCashFromSalesCents;

    String closeNoteText = '';
    final Map<int, String> countTexts = <int, String>{
      for (final int cents in _terminalConfig.cashDenominationsCents) cents: '',
    };
    int totalCents = 0;
    int cashDifferenceCents = -expectedCashCents;
    bool cashMatchesExpected = expectedCashCents == 0;

    void recalculate() {
      int total = 0;
      for (final MapEntry<int, String> entry in countTexts.entries) {
        final int qty = int.tryParse(entry.value.trim()) ?? 0;
        if (qty > 0) {
          total += qty * entry.key;
        }
      }
      totalCents = total;
      cashDifferenceCents = totalCents - expectedCashCents;
      cashMatchesExpected = cashDifferenceCents == 0;
    }

    recalculate();
    if (!mounted) {
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            void refreshDialog() {
              if (!context.mounted) {
                return;
              }
              setStateDialog(recalculate);
            }

            return AlertDialog(
              title: Text('Cerrar turno en ${_terminalName ?? "TPV"}'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Montos esperados por metodo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ..._terminalConfig.paymentMethods.map((String method) {
                        final int cents = expectedConfigured[method] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  _paymentMethodLabel(method),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _formatCentsWithSymbol(
                                  cents,
                                  _terminalConfig.currencySymbol,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF233246)
                              : const Color(0xFFE8EEF9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Fondo inicial efectivo: ${_formatCentsWithSymbol(openSession.openingFloatCents, _terminalConfig.currencySymbol)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Esperado en efectivo: ${_formatCentsWithSymbol(expectedCashCents, _terminalConfig.currencySymbol)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Desglose por denominacion',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ..._terminalConfig.cashDenominationsCents
                          .map((int cents) {
                        final String label =
                            '${_terminalConfig.currencySymbol}${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: <Widget>[
                              SizedBox(
                                width: 120,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: countTexts[cents] ?? '',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad',
                                    hintText: '0',
                                  ),
                                  onChanged: (String value) {
                                    countTexts[cents] = value;
                                    refreshDialog();
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF28233A)
                              : const Color(0xFFEDE7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Total contado: ${_terminalConfig.currencySymbol}${(totalCents / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cashMatchesExpected
                              ? (isDark
                                  ? const Color(0xFF1F3A34)
                                  : const Color(0xFFE3F5EE))
                              : (isDark
                                  ? const Color(0xFF472733)
                                  : const Color(0xFFFCE9EE)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              cashMatchesExpected
                                  ? 'Coincidencia efectivo: SI'
                                  : 'Coincidencia efectivo: NO',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: cashMatchesExpected
                                    ? const Color(0xFF57D0A6)
                                    : const Color(0xFFFF8EB4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Diferencia: ${cashDifferenceCents > 0 ? '+' : cashDifferenceCents < 0 ? '-' : ''}${_formatCentsWithSymbol(cashDifferenceCents.abs(), _terminalConfig.currencySymbol)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: closeNoteText,
                        decoration: const InputDecoration(
                          labelText: 'Nota (opcional)',
                        ),
                        onChanged: (String value) => closeNoteText = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirm != true) {
      return;
    }

    final Map<int, int> breakdown = <int, int>{};
    for (final MapEntry<int, String> entry in countTexts.entries) {
      final int qty = int.tryParse(entry.value.trim()) ?? 0;
      if (qty > 0) {
        breakdown[entry.key] = qty;
      }
    }
    if (breakdown.isEmpty) {
      _show('Debes ingresar al menos una denominacion para cerrar el turno.');
      return;
    }

    if (mounted) {
      setState(() => _closingSession = true);
    } else {
      _closingSession = true;
    }
    try {
      await tpvDs.closeSession(
        sessionId: openSession.id,
        closingCashCents: totalCents,
        note: closeNoteText,
        closedByUserId: userSession.userId,
        cashCountByDenomination: breakdown,
      );
      ref.read(currentSessionProvider.notifier).state =
          userSession.copyWith(clearActiveTerminal: true);
      if (!mounted) {
        return;
      }
      _show('Turno cerrado.');
      context.go('/tpv');
    } catch (e) {
      _show('No se pudo cerrar turno: $e');
    } finally {
      if (mounted) {
        setState(() => _closingSession = false);
      } else {
        _closingSession = false;
      }
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
    required List<_PaymentLineDraft> drafts,
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

  Product? _findProductById(String productId) {
    for (final Product product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
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

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _money(int cents) {
    final bool negative = cents < 0;
    final int absCents = cents.abs();
    final String value =
        '$_currencySymbol${(absCents / 100).toStringAsFixed(2)}';
    return negative ? '-$value' : value;
  }

  String _formatCentsWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
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
    if (width >= 1200) {
      return 7;
    }
    if (width >= 980) {
      return 6;
    }
    if (width >= 760) {
      return 5;
    }
    if (width >= 560) {
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

  Widget _terminalHeader() {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool hasTerminal = _terminalId != null;
    final String title =
        hasTerminal ? (_terminalName ?? 'TPV') : 'Sin TPV activo';
    final bool open = _openSessionId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFE2DAF3),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: !hasTerminal
                        ? (isDark
                            ? const Color(0xFF2D2740)
                            : const Color(0xFFECE9F5))
                        : open
                            ? (isDark
                                ? const Color(0xFF1F3A34)
                                : const Color(0xFFE3F5EE))
                            : (isDark
                                ? const Color(0xFF472733)
                                : const Color(0xFFF8E9EF)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    !hasTerminal
                        ? 'Sin seleccionar'
                        : open
                            ? 'Turno abierto'
                            : 'Sin turno',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: !hasTerminal
                          ? scheme.onSurfaceVariant
                          : open
                              ? const Color(0xFF57D0A6)
                              : const Color(0xFFFF8EB4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!hasTerminal)
            TextButton(
              onPressed: () => context.go('/tpv'),
              child: const Text('Ir a TPV'),
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
                          horizontal: 10, vertical: 4),
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
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            _terminalId == null
                ? 'Selecciona un TPV para vender.'
                : 'No hay productos en el almacen de este TPV.',
          ),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (BuildContext context, constraints) {
        final double width = constraints.crossAxisExtent;
        final int columns = _gridColumnsForWidth(width);
        final double aspect = _gridAspectRatioForWidth(width);
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 98),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, int index) => _productCard(products[index]),
              childCount: products.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: aspect,
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
          heroTag: 'scanFab',
          onPressed: _scanAndAddProduct,
          child: const Icon(Icons.qr_code_scanner_rounded),
        ),
        const SizedBox(height: 10),
        Badge(
          isLabelVisible: _cartUnits > 0,
          label: Text('$_cartUnits'),
          child: FloatingActionButton.small(
            heroTag: 'cartFab',
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
      title: 'Ventas POS',
      currentRoute: '/ventas-pos',
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: _terminalHeader()),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: 'Entrada / salida',
                                onPressed: _posting || _closingSession
                                    ? null
                                    : _openQuickStockDialog,
                                icon: const Icon(Icons.inventory_2_outlined),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                tooltip: 'Ver IPV',
                                onPressed: _posting ||
                                        _closingSession ||
                                        _openSessionId == null
                                    ? null
                                    : _openCurrentIpvFromPos,
                                icon: const Icon(Icons.table_chart_outlined),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                tooltip: 'Cerrar turno',
                                onPressed: _posting ||
                                        _closingSession ||
                                        _openSessionId == null
                                    ? null
                                    : _closeSessionFromPos,
                                icon: const Icon(Icons.lock_clock_outlined),
                              ),
                            ],
                          ),
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

class _CartLine {
  const _CartLine({required this.product, required this.qty});

  final Product product;
  final double qty;
}

class _PaymentLineDraft {
  _PaymentLineDraft({required this.method})
      : amountCtrl = TextEditingController();

  String method;
  final TextEditingController amountCtrl;

  void dispose() {
    amountCtrl.dispose();
  }
}

class _SaleReceipt {
  const _SaleReceipt({
    required this.folio,
    required this.createdAt,
    required this.cashierUsername,
    required this.terminalName,
    required this.warehouseName,
    required this.lines,
    required this.subtotalCents,
    required this.taxCents,
    required this.discountCents,
    required this.totalCents,
    required this.payments,
    required this.paidCents,
  });

  final String folio;
  final DateTime createdAt;
  final String cashierUsername;
  final String terminalName;
  final String warehouseName;
  final List<_SaleReceiptLine> lines;
  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final List<_ReceiptPayment> payments;
  final int paidCents;
}

class _ReceiptPayment {
  const _ReceiptPayment({
    required this.method,
    required this.amountCents,
  });

  final String method;
  final int amountCents;
}

class _SaleReceiptLine {
  const _SaleReceiptLine({
    required this.name,
    required this.sku,
    required this.qty,
    required this.unitPriceCents,
    required this.taxRateBps,
  });

  final String name;
  final String sku;
  final double qty;
  final int unitPriceCents;
  final int taxRateBps;

  int get lineSubtotalCents => (qty * unitPriceCents).round();

  int get lineTaxCents => (lineSubtotalCents * taxRateBps / 10000).round();

  int get lineTotalCents => lineSubtotalCents + lineTaxCents;
}
