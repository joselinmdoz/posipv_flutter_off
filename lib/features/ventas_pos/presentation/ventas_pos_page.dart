import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/security/app_permissions.dart';
import '../../../core/utils/app_result.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../clientes/data/clientes_local_datasource.dart';
import '../../clientes/presentation/clientes_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../inventario/data/inventario_local_datasource.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../productos/data/productos_local_datasource.dart';
import '../../productos/domain/product_scan_resolver.dart';
import '../../productos/presentation/productos_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../tpv/data/tpv_local_datasource.dart';
import '../../tpv/presentation/tpv_providers.dart';
import '../domain/sale_models.dart';
import 'ventas_pos_providers.dart';
import 'widgets/pos_bottom_footer.dart';
import 'widgets/pos_products_grid.dart';
import 'widgets/pos_search_bar.dart';
import 'widgets/pos_store_info_bar.dart';
import 'widgets/pos_inventory_movement_dialog.dart';
import 'widgets/pos_payment_dialog.dart';
import 'widgets/pos_payment_models.dart';
import 'widgets/pos_close_session_dialog.dart';
import 'widgets/pos_scanned_product_dialog.dart';
import 'widgets/pos_sale_receipt_page.dart';
import '../domain/sale_receipt.dart';
import '../../reportes/presentation/widgets/ipv_reporte_detail_page.dart';

class VentasPosPage extends ConsumerStatefulWidget {
  const VentasPosPage({super.key});

  @override
  ConsumerState<VentasPosPage> createState() => _VentasPosPageState();
}

class _VentasPosPageState extends ConsumerState<VentasPosPage> {
  List<Product> _products = <Product>[];
  List<Product> _visibleProducts = <Product>[];
  final Map<String, Product> _productsById = <String, Product>{};
  final Set<String> _warehouseProductIds = <String>{};
  final Map<String, double> _qtyByProductId = <String, double>{};
  final Map<String, double> _stockByProductId = <String, double>{};
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  List<String> _categories = <String>['Todos'];
  String _selectedCategory = 'Todos';

  String? _warehouseId;
  String? _warehouseName;
  String? _terminalId;
  String? _terminalName;
  String? _openSessionId;
  String? _sellerName;
  TpvTerminalConfig _terminalConfig = TpvTerminalConfig.defaults;
  String _terminalCurrencyCode = TpvTerminalConfig.defaults.currencyCode;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _allowNegativeStock = false;
  bool _loading = true;
  bool _posting = false;
  bool _closingSession = false;
  final bool _showingIpvSheet = false;
  bool _redirectingToTpv = false;
  PosSelectedCustomer? _selectedCustomer;

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

  void _onCategoryChanged(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _visibleProducts = _filterProducts(_products, _searchCtrl.text);
    });
  }

  Future<void> _bootstrap() async {
    final PerfTrace trace = PerfTrace('ventas_pos.bootstrap');
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final UserSession? session = ref.read(currentSessionProvider);
      final Future<AppConfig> configFuture =
          ref.read(configuracionLocalDataSourceProvider).loadConfig();
      trace.mark('session + config future');

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
        trace.end('sin sesion activa');
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
      trace.mark('terminal + config listos');
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
        trace.end('tpv invalido');
        _redirectToTpv('El TPV activo no es valido. Abre un turno nuevamente.');
        return;
      }

      final TpvTerminalConfig terminalConfig =
          tpvDs.configFromTerminal(terminalView.terminal);
      final bool canAccessTerminal = await tpvDs.userCanAccessTerminal(
        terminalId: terminalView.terminal.id,
        userId: session.userId,
      );
      if (!canAccessTerminal) {
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
        trace.end('sin acceso tpv');
        _redirectToTpv('No tienes permiso para operar este TPV.');
        return;
      }
      final Future<PosSession?> openSessionFuture =
          tpvDs.getOpenSessionForTerminalAndUser(
        terminalId: terminalView.terminal.id,
        userId: session.userId,
      );
      final Future<List<InventoryView>> stockedFuture = ref
          .read(inventarioLocalDataSourceProvider)
          .listStocked(warehouseId: terminalView.warehouse.id);

      final PosSession? openSession = await openSessionFuture;
      String sellerName = session.username;
      final TpvSessionWithUser? sessionInfo = terminalView.openSession;
      if (sessionInfo != null &&
          sessionInfo.session.userId == session.userId &&
          sessionInfo.responsibleEmployees.isNotEmpty) {
        sellerName = sessionInfo.responsibleEmployees.first.name;
      } else if (openSession != null) {
        final List<TpvEmployee> responsible =
            await tpvDs.listSessionResponsibleEmployees(openSession.id);
        if (responsible.isNotEmpty) {
          sellerName = responsible.first.name;
        }
      }
      final List<InventoryView> stockedRows = await stockedFuture;
      trace.mark('session + stock cargados');

      final Set<String> warehouseProductIds =
          stockedRows.map((InventoryView row) => row.productId).toSet();
      final Map<String, double> stockByProductId = <String, double>{
        for (final InventoryView row in stockedRows) row.productId: row.qty,
      };
      final List<Product> products = await ref
          .read(productosLocalDataSourceProvider)
          .listActiveProductsByIds(warehouseProductIds);

      final List<String> realCats = await ref
          .read(productosLocalDataSourceProvider)
          .listCatalogValues(ProductCatalogKind.category);

      trace.mark('productos + categorias cargados');

      if (!mounted) {
        return;
      }

      setState(() {
        _terminalCurrencyCode = terminalConfig.currencyCode;
        _applyStockedProducts(
          products: products,
          warehouseProductIds: warehouseProductIds,
          stockByProductId: stockByProductId,
        );
        _categories = <String>['Todos', ...realCats];
        _warehouseId = terminalView.warehouse.id;
        _warehouseName = terminalView.warehouse.name;
        _terminalId = terminalView.terminal.id;
        _terminalName = terminalView.terminal.name;
        _openSessionId = openSession?.id;
        _sellerName = sellerName;
        _terminalConfig = terminalConfig;
        _currencySymbol = terminalConfig.currencySymbol;
        _allowNegativeStock = config.allowNegativeStock;
        _loading = false;
      });
      trace.end('ok');

      if (openSession == null) {
        _redirectToTpv('No hay un turno abierto para este usuario en el TPV.');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudo cargar Ventas POS: $e');
    }
  }

  void _resetPosState({
    required String currencySymbol,
    required bool allowNegativeStock,
  }) {
    _products = <Product>[];
    _visibleProducts = <Product>[];
    _productsById.clear();
    _warehouseProductIds.clear();
    _qtyByProductId.clear();
    _stockByProductId.clear();
    _warehouseId = null;
    _warehouseName = null;
    _terminalId = null;
    _terminalName = null;
    _openSessionId = null;
    _sellerName = null;
    _terminalConfig = TpvTerminalConfig.defaults;
    _terminalCurrencyCode = TpvTerminalConfig.defaults.currencyCode;
    _currencySymbol = currencySymbol;
    _allowNegativeStock = allowNegativeStock;
    _selectedCustomer = null;
  }

  void _applyStockedProducts({
    required List<Product> products,
    required Set<String> warehouseProductIds,
    required Map<String, double> stockByProductId,
  }) {
    final List<Product> filteredByCurrency = products
        .where((Product product) => _matchesTerminalCurrency(product))
        .toList();

    _products = filteredByCurrency;
    _visibleProducts = _filterProducts(filteredByCurrency, _searchCtrl.text);
    _productsById
      ..clear()
      ..addEntries(
        filteredByCurrency.map(
          (Product product) => MapEntry<String, Product>(product.id, product),
        ),
      );
    _warehouseProductIds
      ..clear()
      ..addAll(warehouseProductIds);
    _stockByProductId
      ..clear()
      ..addAll(stockByProductId);
    _sanitizeCartForWarehouseStock();
  }

  bool _matchesTerminalCurrency(Product product) {
    return _matchesTerminalCurrencyCode(product.currencyCode);
  }

  bool _matchesTerminalCurrencyCode(String currencyCode) {
    final String terminalCurrency = _terminalCurrencyCode.trim().toUpperCase();
    if (terminalCurrency.isEmpty) {
      return true;
    }
    final String productCurrency = currencyCode.trim().toUpperCase();
    return productCurrency == terminalCurrency;
  }

  Future<void> _reloadPosInventory() async {
    final PerfTrace trace = PerfTrace('ventas_pos.reload_inventory');
    final String? warehouseId = _warehouseId;
    if (warehouseId == null || warehouseId.trim().isEmpty) {
      trace.end('sin almacen');
      return;
    }

    final List<InventoryView> stockedRows = await ref
        .read(inventarioLocalDataSourceProvider)
        .listStocked(warehouseId: warehouseId);
    trace.mark('stock cargado');
    final Set<String> warehouseProductIds =
        stockedRows.map((InventoryView row) => row.productId).toSet();
    final Map<String, double> stockByProductId = <String, double>{
      for (final InventoryView row in stockedRows) row.productId: row.qty,
    };
    final List<Product> products = await ref
        .read(productosLocalDataSourceProvider)
        .listActiveProductsByIds(warehouseProductIds);
    trace.mark('productos cargados');

    if (!mounted) {
      trace.end('unmounted');
      return;
    }
    setState(() {
      _applyStockedProducts(
        products: products,
        warehouseProductIds: warehouseProductIds,
        stockByProductId: stockByProductId,
      );
    });
    trace.end('ok');
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

    return products.where((Product product) {
      // Filter by category
      bool categoryMatch = true;
      if (_selectedCategory != 'Todos') {
        categoryMatch = product.category == _selectedCategory;
      }

      final bool searchMatch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);

      return categoryMatch && searchMatch;
    }).toList();
  }

  String _emptyProductsMessage() {
    final bool hasActiveFilter =
        _searchCtrl.text.trim().isNotEmpty || _selectedCategory != 'Todos';
    if (hasActiveFilter) {
      return 'No hay productos que coincidan.';
    }
    final String terminalCurrency = _terminalCurrencyCode.trim().toUpperCase();
    if (terminalCurrency.isEmpty) {
      return 'No hay productos disponibles.';
    }
    return 'No hay productos en $terminalCurrency para este TPV.';
  }

  List<_CartLine> get _cartLines {
    return _qtyByProductId.entries
        .where((MapEntry<String, double> entry) => entry.value > 0)
        .map((MapEntry<String, double> entry) {
          final Product? product = _productsById[entry.key];
          if (product == null) {
            return null;
          }
          return _CartLine(
            product: product,
            qty: entry.value,
          );
        })
        .whereType<_CartLine>()
        .toList();
  }

  bool get _hasCartItems => _qtyByProductId.values.any((double qty) => qty > 0);

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

  void _setQty(String productId, double nextQtyRaw) {
    if (!nextQtyRaw.isFinite) {
      return;
    }
    final double nextQty = nextQtyRaw < 0 ? 0 : nextQtyRaw;
    if (!_allowNegativeStock) {
      final double stock = _stockByProductId[productId] ?? 0;
      if (nextQty > stock + 0.000001) {
        final Product? product = _findProductById(productId);
        if (product != null) {
          _show(
            'Stock insuficiente para ${product.name}. Disponible: ${_formatQty(stock)}',
          );
        }
        return;
      }
    }
    setState(() {
      if (nextQty <= 0) {
        _qtyByProductId.remove(productId);
      } else {
        _qtyByProductId[productId] = nextQty;
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
    final Product? product = await ProductScanResolver.resolve(
      dataSource: ds,
      scannedValue: scanned,
    );

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
    if (!_matchesTerminalCurrency(matched)) {
      final String productCurrency = matched.currencyCode.trim().toUpperCase();
      final String terminalCurrency =
          _terminalCurrencyCode.trim().toUpperCase();
      _show(
        'El producto ${matched.name} esta en $productCurrency y este TPV opera en $terminalCurrency.',
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
          currencySymbol: _currencySymbol,
          availableToAdd: availableToAdd,
          allowNegativeStock: _allowNegativeStock,
        );
      },
    );

    if (qtyToAdd == null || qtyToAdd <= 0) {
      return;
    }

    if (!_allowNegativeStock && currentCartQty + qtyToAdd > stock + 0.000001) {
      _show(
        'La cantidad excede el stock disponible para ${matched.name}.',
      );
      return;
    }

    setState(() {
      _qtyByProductId[matched.id] = currentCartQty + qtyToAdd;
    });
  }

  Future<void> _openPaymentSheet() async {
    final List<_CartLine> lines = _cartLines;
    if (lines.isEmpty) {
      _show('El carrito esta vacio.');
      return;
    }
    final UserSession? session = ref.read(currentSessionProvider);

    final List<String> methods = _terminalConfig.paymentMethods.isEmpty
        ? <String>['cash', 'card']
        : List<String>.from(_terminalConfig.paymentMethods);
    if (!methods.contains('consignment')) {
      methods.add('consignment');
    }
    List<ClienteListItem> customers = const <ClienteListItem>[];
    Set<String> onlinePaymentMethodCodes = <String>{
      'transfer',
      'wallet',
    };
    try {
      customers = await _loadCustomersForPayment();
    } catch (e) {
      _show('No se pudo cargar la lista de clientes: $e');
    }
    try {
      onlinePaymentMethodCodes = await ref
          .read(configuracionLocalDataSourceProvider)
          .loadOnlinePaymentMethodCodes();
    } catch (_) {}
    if (!mounted) {
      return;
    }

    final PosPaymentResult? result =
        await Navigator.of(context).push<PosPaymentResult>(
      MaterialPageRoute<PosPaymentResult>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return PosPaymentDialog(
            cartLines: lines
                .map((_CartLine line) =>
                    PosCartLine(product: line.product, qty: line.qty))
                .toList(),
            currencySymbol: _currencySymbol,
            paymentMethods: methods,
            paymentMethodLabel: _paymentMethodLabel,
            stockByProductId: _stockByProductId,
            allowNegativeStock: _allowNegativeStock,
            customers: customers,
            onlinePaymentMethodCodes: onlinePaymentMethodCodes,
            selectedCustomer: _selectedCustomer,
            canCreateCustomer:
                session?.hasPermission(AppPermissionKeys.customersManage) ??
                    false,
            reloadCustomers: _loadCustomersForPayment,
          );
        },
      ),
    );

    if (result == null) {
      return;
    }
    if (result.cancelOrderRequested) {
      if (mounted) {
        setState(() => _qtyByProductId.clear());
      }
      _show('Orden cancelada.');
      return;
    }
    if (result.cartLines.isEmpty) {
      return;
    }
    if (!result.isConsignmentSale && result.paymentLines.isEmpty) {
      return;
    }

    final List<_CartLine> finalLines = result.cartLines
        .map((PosCartLine line) =>
            _CartLine(product: line.product, qty: line.qty))
        .toList();
    if (mounted) {
      setState(() => _selectedCustomer = result.selectedCustomer);
    }
    _applyCartLinesFromPayment(finalLines);

    await _submitSale(
      discountCents: 0,
      paymentLines: result.paymentLines,
      linesOverride: finalLines,
      isConsignmentSale: result.isConsignmentSale,
    );
  }

  void _applyCartLinesFromPayment(List<_CartLine> lines) {
    if (!mounted) {
      return;
    }
    setState(() {
      _qtyByProductId
        ..clear()
        ..addEntries(
          lines.map(
            (_CartLine line) =>
                MapEntry<String, double>(line.product.id, line.qty),
          ),
        );
    });
  }

  Future<void> _submitSale({
    required int discountCents,
    required List<PosPaymentLine> paymentLines,
    List<_CartLine>? linesOverride,
    bool isConsignmentSale = false,
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

    final List<_CartLine> lines = linesOverride ?? _cartLines;
    if (lines.isEmpty) {
      _show('Agrega al menos un producto con cantidad mayor a 0.');
      return;
    }
    if (isConsignmentSale && _selectedCustomer == null) {
      _show('La venta en consignación requiere seleccionar un cliente.');
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

    final int paymentsTotal = paymentLines.fold<int>(
      0,
      (int sum, PosPaymentLine value) => sum + value.amountCents,
    );
    if (!isConsignmentSale && paymentsTotal != totalCents) {
      _show('La suma de pagos no coincide con el total de la venta.');
      return;
    }
    if (isConsignmentSale && paymentsTotal != 0) {
      _show('La venta en consignación se registra sin pagos iniciales.');
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
      customerId: _selectedCustomer?.id,
      terminalId: _terminalId!,
      terminalSessionId: _openSessionId!,
      items: items,
      payments: paymentLines
          .map(
            (PosPaymentLine line) => PaymentInput(
              method: line.method,
              amountCents: line.amountCents,
              transactionId: line.transactionId,
            ),
          )
          .toList(),
      discountCents: discountCents,
      allowNegativeStock: _allowNegativeStock,
      isConsignmentSale: isConsignmentSale,
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
          cashierUsername: _sellerName ?? session.username,
          terminalName: _terminalName ?? '',
          warehouseName: _warehouseName ?? '',
          currencySymbol: _currencySymbol,
          customerName: _selectedCustomer?.fullName,
          customerCode: _selectedCustomer?.code,
          lines: lines
              .map(
                (_CartLine line) => SaleReceiptLine(
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
          payments: (isConsignmentSale && paymentLines.isEmpty)
              ? const <ReceiptPayment>[
                  ReceiptPayment(
                    method: 'Consignación (pendiente)',
                    amountCents: 0,
                  ),
                ]
              : paymentLines
                  .map(
                    (PosPaymentLine line) => ReceiptPayment(
                      method: (line.transactionId ?? '').trim().isEmpty
                          ? _paymentMethodLabel(line.method)
                          : '${_paymentMethodLabel(line.method)} • TX: ${line.transactionId!.trim()}',
                      amountCents: line.amountCents,
                    ),
                  )
                  .toList(),
          paidCents: paymentsTotal,
          isDemoMode: !licenseStatus.isFull,
        );

        setState(() {
          _qtyByProductId.clear();
        });
        try {
          await _reloadPosInventory();
        } catch (e) {
          _show(
              'Venta registrada, pero no se pudo refrescar el inventario: $e');
        }
        if (!mounted) {
          return;
        }
        _show('Venta registrada. Folio: ${data.folio}');
        await _showReceiptDialog(receipt);
      case AppFailure<CreateSaleResult>(:final message):
        _show(message);
    }
  }

  Future<List<ClienteListItem>> _loadCustomersForPayment() {
    return ref.read(clientesLocalDataSourceProvider).listClients(limit: 300);
  }

  Future<void> _showReceiptDialog(SaleReceipt receipt) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PosSaleReceiptPage(receipt: receipt);
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
    final InventarioLocalDataSource inventarioDs =
        ref.read(inventarioLocalDataSourceProvider);
    final List<InventoryView> baseRows =
        await inventarioDs.listByWarehouse(_warehouseId!);
    final List<InventoryView> adjustRows = baseRows
        .where((InventoryView row) =>
            _matchesTerminalCurrencyCode(row.currencyCode))
        .toList(growable: false);
    if (adjustRows.isEmpty) {
      _show(
          'No hay productos en ${_terminalCurrencyCode.trim().toUpperCase()} para ajustar.');
      return;
    }
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

    final Map<String, InventoryView> rowByProductId = <String, InventoryView>{
      for (final InventoryView row in adjustRows) row.productId: row,
    };

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return PosInventoryMovementDialog(
          adjustRows: adjustRows,
          entryReasons: entryReasons,
          outputReasons: outputReasons,
          currencySymbol: _currencySymbol,
          loadAdjustRowsForWarehouse: (String warehouseId) async {
            final List<InventoryView> rows =
                await inventarioDs.listByWarehouse(warehouseId);
            return rows
                .where((InventoryView row) =>
                    _matchesTerminalCurrencyCode(row.currencyCode))
                .toList(growable: false);
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    final String safeProductId = result['productId'] as String;
    final bool isEntry = result['isEntry'] as bool;
    final double qty = result['qty'] as double;
    final String safeReasonCode = result['reasonCode'] as String;
    final String note = (result['note'] as String).trim();

    final InventoryView? selectedProduct = rowByProductId[safeProductId];
    final double currentQty = selectedProduct?.qty ?? 0;
    final double nextQty = isEntry ? currentQty + qty : currentQty - qty;

    if (!isEntry && currentQty <= 0) {
      _show('El producto no tiene stock en el TPV.');
      return;
    }
    if (!isEntry && qty > currentQty) {
      _show('La salida supera el stock disponible en el TPV.');
      return;
    }
    if (!isEntry && nextQty < 0) {
      _show('La cantidad resultante no puede ser negativa.');
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
      await _reloadPosInventory();
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
    try {
      report = await reportesDs.findIpvReportBySessionId(
        sessionId,
        includeOpen: true,
      );
      if (report == null) {
        _show('No se encontro IPV para la sesion actual.');
        return;
      }
    } catch (e) {
      _show('No se pudo cargar IPV: $e');
      return;
    }

    if (!mounted) {
      return;
    }

    final IpvReportSummaryStat activeReport = report;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IpvReporteDetailPage(summary: activeReport),
      ),
    );
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
    if (!mounted) {
      return;
    }
    final CloseSessionResult? confirm = await showDialog<CloseSessionResult>(
      context: context,
      builder: (BuildContext context) {
        return PosCloseSessionDialog(
          terminalName: _terminalName ?? 'TPV',
          expectedPayments: expectedConfigured,
          openingFloatCents: openSession.openingFloatCents,
          denominations: _terminalConfig.cashDenominationsCents,
          currencySymbol: _terminalConfig.currencySymbol,
          paymentMethodLabel: _paymentMethodLabel,
          formatCents: _formatCentsWithSymbol,
        );
      },
    );

    if (confirm == null) {
      return;
    }

    final int totalCents = confirm.totalCents;
    final Map<int, int> breakdown = confirm.breakdown;
    final String closeNoteText = confirm.note;

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
      final UserSession nextSession =
          userSession.copyWith(clearActiveTerminal: true);
      ref.read(currentSessionProvider.notifier).state = nextSession;
      unawaited(
        ref.read(localAuthServiceProvider).persistSession(
              session: nextSession,
              rememberOnDevice: true,
            ),
      );

      // Invalidate TPV terminals to force refresh when returning to TPV selection
      ref.invalidate(tpvTerminalsProvider);

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

  Product? _findProductById(String productId) {
    return _productsById[productId];
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
      case 'consignment':
        return 'Consignación';
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

  String _formatCentsWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── Action Buttons ──────────────────────────────────────────────────────

  Widget _appBarActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isDark,
    bool isRed = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isRed
            ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
            : (isDark ? Colors.white : const Color(0xFF1E293B)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(productosCatalogRevisionProvider,
        (int? previous, int next) {
      if (previous == null || previous == next || !mounted) {
        return;
      }
      unawaited(_reloadPosInventory());
    });
    ref.listen<UserSession?>(currentSessionProvider,
        (UserSession? previous, UserSession? next) {
      final String? prevUserId = previous?.userId;
      final String? nextUserId = next?.userId;
      final String? prevTerminalId = previous?.activeTerminalId;
      final String? nextTerminalId = next?.activeTerminalId;

      final bool sameUser = prevUserId == nextUserId;
      final bool sameTerminal = prevTerminalId == nextTerminalId;
      if (sameUser && sameTerminal) {
        return;
      }
      if (!mounted) {
        return;
      }
      unawaited(_bootstrap());
    });

    final license = ref.watch(currentLicenseStatusProvider);
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: 'Ventas POS',
      currentRoute: '/ventas-pos',
      onRefresh: _bootstrap,
      useDefaultActions: false,
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        tooltip: 'Atrás',
        onPressed: () => context.go('/tpv'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        _appBarActionButton(
          icon: Icons.swap_horiz_rounded,
          tooltip: 'Movimientos',
          onPressed: _openQuickStockDialog,
          isDark: isDark,
        ),
        _appBarActionButton(
          icon: Icons.ios_share_rounded,
          tooltip: 'Exportar IPV',
          onPressed: _openSessionId != null ? _openCurrentIpvFromPos : () {},
          isDark: isDark,
        ),
        _appBarActionButton(
          icon: Icons.logout_rounded,
          tooltip: 'Cerrar Turno',
          onPressed: _openSessionId != null ? _closeSessionFromPos : () {},
          isDark: isDark,
          isRed: true,
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: null,
      body: license.canSell
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: <Widget>[
                        PosStoreInfoBar(
                          terminalName: _terminalName,
                          open: _openSessionId != null,
                          sellerName: _sellerName,
                        ),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: PosSearchBar(
                                  controller: _searchCtrl,
                                  onScanTap: _scanAndAddProduct,
                                  categories: _categories,
                                  selectedCategory: _selectedCategory,
                                  onCategoryChanged: _onCategoryChanged,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: PosProductsGrid(
                                  products: _visibleProducts,
                                  qtyByProductId: _qtyByProductId,
                                  stockByProductId: _stockByProductId,
                                  currencySymbol: _currencySymbol,
                                  emptyMessage: _emptyProductsMessage(),
                                  isPosting: _posting,
                                  onQtyChanged: _changeQty,
                                  onQtySet: _setQty,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PosBottomFooter(
                          itemCount: _qtyByProductId.values
                              .fold<double>(
                                  0, (double sum, double qty) => sum + qty)
                              .toInt(),
                          total: _computeTotal(),
                          currencySymbol: _currencySymbol,
                          onPayTap: _hasCartItems ? _openPaymentSheet : null,
                        ),
                      ],
                    ),
            )
          : _buildLicenseBlockedBody(license.message),
    );
  }

  double _computeTotal() {
    double total = 0;
    for (final MapEntry<String, double> entry in _qtyByProductId.entries) {
      final Product? product = _productsById[entry.key];
      if (product != null) {
        total += (product.priceCents / 100) * entry.value;
      }
    }
    return total;
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

class _CartLine {
  const _CartLine({required this.product, required this.qty});

  final Product product;
  final double qty;
}

// Sale receipt models are now defined in domain/sale_receipt.dart
