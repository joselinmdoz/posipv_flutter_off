import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/utils/perf_trace.dart';
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
import '../../ventas_pos/domain/sale_receipt.dart';
import '../../ventas_pos/presentation/ventas_pos_providers.dart';
import '../../ventas_pos/presentation/widgets/pos_payment_models.dart';
import '../../ventas_pos/presentation/widgets/pos_bottom_footer.dart';
import '../../ventas_pos/presentation/widgets/pos_scanned_product_dialog.dart';
import '../../ventas_pos/presentation/widgets/pos_product_card.dart';
import '../../ventas_pos/presentation/widgets/pos_sale_receipt_page.dart';
import '../../ventas_pos/presentation/widgets/pos_search_bar.dart';
import 'widgets/direct_sales_payment_dialog.dart';

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
  final Map<String, Product> _productsById = <String, Product>{};
  String? _selectedWarehouseId;
  AppCurrencyConfig _currencyConfig = AppCurrencyConfig.defaults;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
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
    final PerfTrace trace = PerfTrace('ventas_directas.bootstrap');
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
        trace.end('sin sesion');
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

      final ({
        List<Product> products,
        Map<String, double> stockByProductId,
        Set<String> availableIds
      }) warehouseData = await _loadProductsForWarehouse(warehouseId);
      trace.mark('almacen + productos cargados');

      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _selectedWarehouseId = warehouseId;
        _applyProductsForWarehouse(
          products: warehouseData.products,
          stockByProductId: warehouseData.stockByProductId,
          availableIds: warehouseData.availableIds,
        );
        _currencyConfig = config.currencyConfig.normalized();
        _allowNegativeStock = config.allowNegativeStock;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudo cargar Ventas Directas: $e');
    }
  }

  Future<void> _changeWarehouse(String? warehouseId) async {
    if (warehouseId == null || warehouseId == _selectedWarehouseId) {
      return;
    }
    if (mounted) {
      setState(() => _selectedWarehouseId = warehouseId);
    }
    await _reloadWarehouseInventory(showLoader: true);
  }

  Future<
      ({
        List<Product> products,
        Map<String, double> stockByProductId,
        Set<String> availableIds
      })> _loadProductsForWarehouse(String? warehouseId) async {
    if (warehouseId == null || warehouseId.trim().isEmpty) {
      return (
        products: <Product>[],
        stockByProductId: <String, double>{},
        availableIds: <String>{},
      );
    }
    final List<InventoryView> inventoryRows = await ref
        .read(inventarioLocalDataSourceProvider)
        .listStocked(warehouseId: warehouseId);
    final Map<String, double> stockByProductId = <String, double>{
      for (final InventoryView row in inventoryRows) row.productId: row.qty,
    };
    final Set<String> availableIds = stockByProductId.keys.toSet();
    final List<Product> products = await ref
        .read(productosLocalDataSourceProvider)
        .listActiveProductsByIds(availableIds);
    return (
      products: products,
      stockByProductId: stockByProductId,
      availableIds: availableIds,
    );
  }

  void _applyProductsForWarehouse({
    required List<Product> products,
    required Map<String, double> stockByProductId,
    required Set<String> availableIds,
  }) {
    _products = products;
    _visibleProducts = _filterProducts(products, _searchCtrl.text);
    _productsById
      ..clear()
      ..addEntries(
        products.map(
          (Product product) => MapEntry<String, Product>(product.id, product),
        ),
      );
    _stockByProductId
      ..clear()
      ..addAll(stockByProductId);
    _warehouseProductIds
      ..clear()
      ..addAll(availableIds);
    _sanitizeCart();
  }

  Future<void> _reloadWarehouseInventory({bool showLoader = false}) async {
    final PerfTrace trace = PerfTrace('ventas_directas.reload_inventory');
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }
    try {
      final ({
        List<Product> products,
        Map<String, double> stockByProductId,
        Set<String> availableIds
      }) warehouseData = await _loadProductsForWarehouse(_selectedWarehouseId);
      trace.mark('productos recargados');
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _applyProductsForWarehouse(
          products: warehouseData.products,
          stockByProductId: warehouseData.stockByProductId,
          availableIds: warehouseData.availableIds,
        );
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudo recargar inventario del almacen: $e');
    }
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
    return _qtyByProductId.entries
        .where((MapEntry<String, double> entry) => entry.value > 0)
        .map((MapEntry<String, double> entry) {
          final Product? product = _productsById[entry.key];
          if (product == null) {
            return null;
          }
          return _DirectCartLine(
            product: product,
            qty: entry.value,
          );
        })
        .whereType<_DirectCartLine>()
        .toList();
  }

  int get _cartUnits {
    double total = 0;
    for (final double qty in _qtyByProductId.values) {
      if (qty > 0) {
        total += qty;
      }
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
    return _productsById[productId];
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
    final Product matched = product;
    if (!_warehouseProductIds.contains(matched.id)) {
      _show(
          'El producto ${matched.name} no pertenece al almacen seleccionado.');
      return;
    }
    final double stock = _stockByProductId[matched.id] ?? 0;
    if (!_allowNegativeStock && stock <= 0) {
      _show('El producto ${matched.name} no tiene existencia.');
      return;
    }
    if (!_canIncreaseQty(matched.id)) {
      _show(
        'Stock insuficiente para ${matched.name}. Disponible: ${_formatQty(stock)}',
      );
      return;
    }

    final double currentCartQty = _qtyByProductId[matched.id] ?? 0;
    final double availableToAdd = _allowNegativeStock
        ? 999999
        : (stock - currentCartQty).clamp(0, double.infinity);
    if (!_allowNegativeStock && availableToAdd < 1) {
      _show(
        'Stock insuficiente para ${matched.name}. Disponible: ${_formatQty(stock)}',
      );
      return;
    }

    final double? qtyToAdd = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return PosScannedProductDialog(
          product: matched,
          currencySymbol: _currencyConfig.symbolForCode(matched.currencyCode),
          availableToAdd: availableToAdd,
          allowNegativeStock: _allowNegativeStock,
        );
      },
    );
    if (qtyToAdd == null || qtyToAdd <= 0) {
      return;
    }
    if (!_allowNegativeStock && currentCartQty + qtyToAdd > stock + 0.000001) {
      _show('La cantidad excede el stock disponible para ${matched.name}.');
      return;
    }

    setState(() {
      _qtyByProductId[matched.id] = currentCartQty + qtyToAdd;
    });
  }

  int _subtotalFromLines(List<_DirectCartLine> lines) {
    int subtotal = 0;
    for (final _DirectCartLine line in lines) {
      subtotal += (line.qty * _unitPricePrimaryCents(line.product)).round();
    }
    return subtotal;
  }

  int _taxFromLines(List<_DirectCartLine> lines) {
    int tax = 0;
    for (final _DirectCartLine line in lines) {
      final int lineSubtotal =
          (line.qty * _unitPricePrimaryCents(line.product)).round();
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

  int _unitPricePrimaryCents(Product product) {
    return _toPrimaryCents(
      amountCents: product.priceCents,
      currencyCode: product.currencyCode,
    );
  }

  int _toPrimaryCents({
    required int amountCents,
    required String currencyCode,
  }) {
    final String code = currencyCode.trim().toUpperCase();
    if (code.isEmpty || code == _currencyConfig.primaryCurrencyCode) {
      return amountCents;
    }
    final AppCurrencySetting? currency = _currencyConfig.currencyByCode(code);
    final double rateToPrimary = currency?.rateToPrimary ?? 1;
    if (!rateToPrimary.isFinite || rateToPrimary <= 0) {
      return amountCents;
    }
    return (amountCents / rateToPrimary).round();
  }

  Future<void> _openPaymentSheet() async {
    final List<_DirectCartLine> lines = _cartLines;
    if (lines.isEmpty) {
      _show('El carrito esta vacio.');
      return;
    }
    final DirectSalesPaymentResult? result =
        await showDialog<DirectSalesPaymentResult>(
      context: context,
      builder: (BuildContext context) {
        return DirectSalesPaymentDialog(
          cartLines: lines
              .map(
                (_DirectCartLine line) =>
                    PosCartLine(product: line.product, qty: line.qty),
              )
              .toList(),
          stockByProductId: _stockByProductId,
          allowNegativeStock: _allowNegativeStock,
          currencyConfig: _currencyConfig,
          paymentMethods: _paymentMethods,
          paymentMethodLabel: _paymentMethodLabel,
        );
      },
    );

    if (result == null ||
        result.paymentByMethodPrimaryCents.isEmpty ||
        result.paymentLines.isEmpty ||
        result.cartLines.isEmpty) {
      return;
    }

    final List<_DirectCartLine> finalLines = result.cartLines
        .map(
          (PosCartLine line) => _DirectCartLine(
            product: line.product,
            qty: line.qty,
          ),
        )
        .toList();
    _applyCartLinesFromPayment(finalLines);

    await _submitSale(
      discountCents: result.discountCents,
      paymentByMethod: result.paymentByMethodPrimaryCents,
      paymentLines: result.paymentLines,
      linesOverride: finalLines,
    );
  }

  void _applyCartLinesFromPayment(List<_DirectCartLine> lines) {
    if (!mounted) {
      return;
    }
    setState(() {
      _qtyByProductId
        ..clear()
        ..addEntries(
          lines.map(
            (_DirectCartLine line) =>
                MapEntry<String, double>(line.product.id, line.qty),
          ),
        );
    });
  }

  Future<void> _submitSale({
    required int discountCents,
    required Map<String, int> paymentByMethod,
    List<DirectSalesPaymentLine> paymentLines =
        const <DirectSalesPaymentLine>[],
    List<_DirectCartLine>? linesOverride,
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

    final List<_DirectCartLine> lines = linesOverride ?? _cartLines;
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
    final int paymentsTotal = paymentLines.isEmpty
        ? paymentByMethod.values.fold<int>(
            0,
            (int sum, int value) => sum + value,
          )
        : paymentLines.fold<int>(
            0,
            (int sum, DirectSalesPaymentLine line) =>
                sum + line.primaryAmountCents,
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
            unitPriceCents: _unitPricePrimaryCents(line.product),
            taxRateBps: line.product.taxRateBps,
          ),
        )
        .toList();

    final List<PaymentInput> paymentInputs = paymentLines.isEmpty
        ? paymentByMethod.entries
            .map(
              (MapEntry<String, int> entry) =>
                  PaymentInput(method: entry.key, amountCents: entry.value),
            )
            .toList()
        : paymentLines
            .map(
              (DirectSalesPaymentLine line) => PaymentInput(
                method: line.method,
                amountCents: line.primaryAmountCents,
                sourceCurrencyCode: line.currencyCode,
                sourceAmountCents: line.enteredAmountCents,
              ),
            )
            .toList();

    final List<ReceiptPayment> receiptPayments = paymentLines.isEmpty
        ? paymentByMethod.entries
            .map(
              (MapEntry<String, int> entry) => ReceiptPayment(
                method: _paymentMethodLabel(entry.key),
                amountCents: entry.value,
              ),
            )
            .toList()
        : paymentLines
            .map(
              (DirectSalesPaymentLine line) => ReceiptPayment(
                method: _formatPaymentLineLabel(line),
                amountCents: line.primaryAmountCents,
              ),
            )
            .toList();

    final CreateSaleInput input = CreateSaleInput(
      warehouseId: _selectedWarehouseId!,
      cashierId: session.userId,
      terminalId: null,
      terminalSessionId: null,
      items: items,
      payments: paymentInputs,
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
        final licenseStatus = ref.read(currentLicenseStatusProvider);
        final SaleReceipt receipt = SaleReceipt(
          folio: data.folio,
          createdAt: DateTime.now(),
          cashierUsername: session.username,
          terminalName: 'Venta Directa',
          warehouseName: _selectedWarehouseName(),
          currencySymbol: _currencyConfig.primaryCurrency.symbol,
          lines: lines.map(
            (_DirectCartLine line) {
              final String code =
                  line.product.currencyCode.trim().toUpperCase();
              final String symbol = _currencyConfig.symbolForCode(code);
              final int lineTotalNativeCents =
                  (line.qty * line.product.priceCents).round();
              return SaleReceiptLine(
                name: line.product.name,
                sku: line.product.sku,
                qty: line.qty,
                unitPriceCents: _unitPricePrimaryCents(line.product),
                taxRateBps: line.product.taxRateBps,
                unitPriceDisplay:
                    '$symbol${(line.product.priceCents / 100).toStringAsFixed(2)} $code',
                lineTotalDisplay:
                    '$symbol${(lineTotalNativeCents / 100).toStringAsFixed(2)} $code',
              );
            },
          ).toList(),
          subtotalCents: subtotalCents,
          taxCents: taxCents,
          discountCents: discountCents,
          totalCents: totalCents,
          payments: receiptPayments,
          paidCents: paymentsTotal,
          isDemoMode: !licenseStatus.isFull,
        );

        setState(() => _qtyByProductId.clear());
        try {
          await _reloadWarehouseInventory();
        } catch (e) {
          _show(
              'Venta registrada, pero no se pudo refrescar el inventario: $e');
        }
        if (!mounted) {
          return;
        }
        _show('Venta directa registrada. Folio: ${data.folio}');
        await _showReceiptDialog(receipt);
      case AppFailure<CreateSaleResult>(:final message):
        _show(message);
    }
  }

  String _selectedWarehouseName() {
    final String? selectedId = _selectedWarehouseId;
    if (selectedId == null) {
      return '';
    }
    for (final Warehouse warehouse in _warehouses) {
      if (warehouse.id == selectedId) {
        return warehouse.name;
      }
    }
    return '';
  }

  Future<void> _showReceiptDialog(SaleReceipt receipt) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PosSaleReceiptPage(receipt: receipt);
      },
    );
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

  String _formatPaymentLineLabel(DirectSalesPaymentLine line) {
    final String method = _paymentMethodLabel(line.method);
    final String code = line.currencyCode.trim().toUpperCase();
    final String symbol = _currencyConfig.symbolForCode(code);
    final String source =
        '$symbol${(line.enteredAmountCents / 100).toStringAsFixed(2)} $code';
    return '$method ($source)';
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  double _computeFooterTotal() {
    double total = 0;
    for (final MapEntry<String, double> entry in _qtyByProductId.entries) {
      final Product? product = _productsById[entry.key];
      if (product == null) {
        continue;
      }
      total += (_unitPricePrimaryCents(product) / 100) * entry.value;
    }
    return total;
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  int _gridColumnsForWidth(double width) {
    if (width >= 1400) {
      return 5;
    }
    if (width >= 1100) {
      return 4;
    }
    if (width >= 860) {
      return 3;
    }
    return 2;
  }

  double _gridAspectRatioForWidth(double width) {
    return 0.82;
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
    return PosSearchBar(
      controller: _searchCtrl,
      onScanTap: _scanAndAddProduct,
      categories: const <String>['Todos'],
      selectedCategory: 'Todos',
      onCategoryChanged: (_) {},
    );
  }

  Widget _productCard(Product product) {
    return PosProductCard(
      product: product,
      qty: _qtyByProductId[product.id] ?? 0,
      stock: _stockByProductId[product.id] ?? 0,
      currencySymbol: _currencyConfig.symbolForCode(product.currencyCode),
      isPosting: _posting,
      onQtyChanged: (double delta) => _changeQty(product.id, delta),
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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, int index) {
                final Product product = products[index];
                return KeyedSubtree(
                  key: ValueKey<String>(product.id),
                  child: _productCard(product),
                );
              },
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

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(productosCatalogRevisionProvider,
        (int? previous, int next) {
      if (previous == null || previous == next || !mounted) {
        return;
      }
      unawaited(_reloadWarehouseInventory());
    });
    final license = ref.watch(currentLicenseStatusProvider);
    return AppScaffold(
      title: 'Ventas Directas',
      currentRoute: '/ventas-directas',
      onRefresh: _bootstrap,
      showBottomNavigationBar: false,
      floatingActionButton: null,
      body: license.canSell
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: SafeArea(
                        bottom: false,
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
                    ),
                    PosBottomFooter(
                      itemCount: _cartUnits,
                      total: _computeFooterTotal(),
                      currencySymbol: _currencyConfig.primaryCurrency.symbol,
                      onPayTap: _qtyByProductId.values.any((double q) => q > 0)
                          ? _openPaymentSheet
                          : null,
                    ),
                  ],
                ))
          : _buildLicenseBlockedBody(license.message),
    );
  }

  Widget _buildLicenseBlockedBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_outline_rounded, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Ventas bloqueadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
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
