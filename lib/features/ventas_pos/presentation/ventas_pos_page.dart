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
import '../../productos/domain/product_qr_codec.dart';
import '../../productos/presentation/productos_providers.dart';
import '../domain/sale_models.dart';
import 'ventas_pos_providers.dart';

class VentasPosPage extends ConsumerStatefulWidget {
  const VentasPosPage({super.key});

  @override
  ConsumerState<VentasPosPage> createState() => _VentasPosPageState();
}

class _VentasPosPageState extends ConsumerState<VentasPosPage> {
  List<Product> _products = <Product>[];
  List<Warehouse> _warehouses = <Warehouse>[];
  final Map<String, double> _qtyByProductId = <String, double>{};

  String? _warehouseId;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _allowNegativeStock = false;
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final whDs = ref.read(almacenesLocalDataSourceProvider);
      await whDs.ensureDefaultWarehouse();

      final List<Warehouse> warehouses = await whDs.listActiveWarehouses();
      final List<Product> products =
          await ref.read(productosLocalDataSourceProvider).listActiveProducts();
      final AppConfig config =
          await ref.read(configuracionLocalDataSourceProvider).loadConfig();

      if (!mounted) {
        return;
      }

      setState(() {
        _warehouses = warehouses;
        _products = products;
        _warehouseId = warehouses.isNotEmpty ? warehouses.first.id : null;
        _currencySymbol = config.currencySymbol;
        _allowNegativeStock = config.allowNegativeStock;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      _show('No se pudo cargar Ventas POS: $e');
    }
  }

  int get _subtotalCents {
    int subtotal = 0;
    for (final Product p in _products) {
      final double qty = _qtyByProductId[p.id] ?? 0;
      if (qty <= 0) {
        continue;
      }
      subtotal += (qty * p.priceCents).round();
    }
    return subtotal;
  }

  int get _taxCents {
    int tax = 0;
    for (final Product p in _products) {
      final double qty = _qtyByProductId[p.id] ?? 0;
      if (qty <= 0) {
        continue;
      }
      final int lineSubtotal = (qty * p.priceCents).round();
      tax += (lineSubtotal * p.taxRateBps / 10000).round();
    }
    return tax;
  }

  int get _totalCents => _subtotalCents + _taxCents;

  void _changeQty(String productId, double delta) {
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

    if (!_products.any((Product p) => p.id == matched.id)) {
      setState(() {
        _products = <Product>[..._products, matched]
          ..sort((Product a, Product b) => a.name.compareTo(b.name));
      });
    }

    _changeQty(matched.id, 1);
    _show('Producto agregado: ${matched.name}.');
  }

  Future<void> _postSale() async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    if (_warehouseId == null) {
      _show('Selecciona un almacen.');
      return;
    }

    final List<SaleItemInput> items = _products
        .where((Product p) => (_qtyByProductId[p.id] ?? 0) > 0)
        .map(
          (Product p) => SaleItemInput(
            productId: p.id,
            qty: _qtyByProductId[p.id] ?? 0,
            unitPriceCents: p.priceCents,
            taxRateBps: p.taxRateBps,
          ),
        )
        .toList();

    if (items.isEmpty) {
      _show('Agrega al menos un producto con cantidad mayor a 0.');
      return;
    }

    final CreateSaleInput input = CreateSaleInput(
      warehouseId: _warehouseId!,
      cashierId: session.userId,
      items: items,
      payments: <PaymentInput>[
        PaymentInput(method: 'cash', amountCents: _totalCents),
      ],
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
        setState(_qtyByProductId.clear);
        _show('Venta registrada. Folio: ${data.folio}');
      case AppFailure<CreateSaleResult>(:final message):
        _show(message);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ventas POS',
      currentRoute: '/ventas-pos',
      onRefresh: _bootstrap,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _scanAndAddProduct,
        child: const Icon(Icons.qr_code_scanner_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _warehouseId,
                    decoration: const InputDecoration(labelText: 'Almacen'),
                    items: _warehouses
                        .map(
                          (Warehouse w) => DropdownMenuItem<String>(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      setState(() => _warehouseId = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _allowNegativeStock
                          ? 'Politica de inventario: stock negativo permitido'
                          : 'Politica de inventario: stock negativo bloqueado',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _products.isEmpty
                        ? const Center(child: Text('No hay productos.'))
                        : ListView.separated(
                            itemCount: _products.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, int index) {
                              final Product p = _products[index];
                              final double qty = _qtyByProductId[p.id] ?? 0;
                              final double lineTotal =
                                  ((p.priceCents / 100) * qty) *
                                      (1 + p.taxRateBps / 10000);

                              return ListTile(
                                title: Text(p.name),
                                subtitle: Text(
                                  'Codigo: ${p.sku} | ${_money(p.priceCents)}',
                                ),
                                trailing: SizedBox(
                                  width: 190,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () => _changeQty(p.id, -1),
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                      ),
                                      Text(qty.toStringAsFixed(0)),
                                      IconButton(
                                        onPressed: () => _changeQty(p.id, 1),
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          lineTotal == 0
                                              ? ''
                                              : '$_currencySymbol${lineTotal.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: <Widget>[
                        _totalsRow('Subtotal', _subtotalCents),
                        _totalsRow('Impuesto', _taxCents),
                        _totalsRow('Total', _totalCents, isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _posting ? null : _postSale,
                      child:
                          Text(_posting ? 'Registrando...' : 'Registrar venta'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _totalsRow(String label, int cents, {bool isBold = false}) {
    final TextStyle style = isBold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : const TextStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(_money(cents), style: style),
        ],
      ),
    );
  }

  String _money(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }
}
