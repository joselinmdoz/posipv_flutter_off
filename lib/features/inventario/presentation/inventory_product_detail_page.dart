import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../productos/presentation/productos_page.dart';
import '../../productos/presentation/productos_providers.dart';
import '../data/inventario_local_datasource.dart';
import 'inventario_providers.dart';
import 'widgets/inventory_detail_info_row.dart';
import 'widgets/inventory_stock_by_warehouse_section.dart';

class InventoryProductDetailPage extends ConsumerStatefulWidget {
  const InventoryProductDetailPage({
    super.key,
    required this.inventoryRow,
  });

  final InventoryView inventoryRow;

  @override
  ConsumerState<InventoryProductDetailPage> createState() =>
      _InventoryProductDetailPageState();
}

class _InventoryProductDetailPageState
    extends ConsumerState<InventoryProductDetailPage> {
  Product? _product;
  List<InventoryWarehouseStockView> _stockByWarehouse =
      <InventoryWarehouseStockView>[];
  bool _loading = true;
  bool _openingEditor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadProduct();
    });
  }

  Future<void> _loadProduct({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    try {
      final Future<Product?> productFuture = ref
          .read(productosLocalDataSourceProvider)
          .findActiveProductById(widget.inventoryRow.productId);
      final Future<List<InventoryWarehouseStockView>> stockFuture = ref
          .read(inventarioLocalDataSourceProvider)
          .listProductStockByWarehouses(widget.inventoryRow.productId);
      final Product? product = await productFuture;
      final List<InventoryWarehouseStockView> stockByWarehouse =
          await stockFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _product = product;
        _stockByWarehouse = stockByWarehouse;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar el detalle del producto: $e');
    }
  }

  Future<void> _openEditProduct() async {
    final Product? product = _product;
    if (product == null || _openingEditor) {
      return;
    }

    setState(() => _openingEditor = true);

    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ProductFormPage(product: product),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => _openingEditor = false);

    if (result == null) {
      return;
    }

    if (result == 'deleted') {
      _show('Producto dado de baja.');
      Navigator.of(context).pop();
      return;
    }

    await _loadProduct(showLoader: false);
    _show('Producto actualizado.');
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(int cents, String currencyCode) {
    final String symbol = switch (currencyCode.trim().toUpperCase()) {
      'USD' => r'$',
      'EUR' => '€',
      'CUP' => '₱',
      _ => r'$',
    };
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _formatPercentFromBps(int bps) {
    return '${(bps / 100).toStringAsFixed(2)} %';
  }

  Widget _buildImageCard(Product? product) {
    final ThemeData theme = Theme.of(context);
    final String? path = product?.imagePath ?? widget.inventoryRow.imagePath;
    final BorderRadius borderRadius = BorderRadius.circular(14);

    Widget frame({required Widget child}) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140, maxHeight: 240),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: child,
      );
    }

    Widget placeholderIcon() {
      return Icon(
        Icons.inventory_2_rounded,
        size: 52,
        color: theme.colorScheme.primary,
      );
    }

    Widget fallback() {
      return frame(child: placeholderIcon());
    }

    if (path == null || path.trim().isEmpty) {
      return fallback();
    }

    final String resolved = path.trim();
    final Widget imageWidget = resolved.startsWith('http')
        ? Image.network(
            resolved,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(child: placeholderIcon()),
          )
        : Image.file(
            File(resolved),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(child: placeholderIcon()),
          );

    return frame(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      ),
    );
  }

  Widget _buildDetailBody() {
    final Product? product = _product;
    final InventoryView row = widget.inventoryRow;

    if (product == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 26),
        children: <Widget>[
          const SizedBox(height: 24),
          const Icon(Icons.warning_amber_rounded, size: 48),
          const SizedBox(height: 12),
          Text(
            'Este producto ya no esta disponible.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver a inventario'),
          ),
        ],
      );
    }

    final String currencyCode = product.currencyCode.trim().toUpperCase();
    final int marginCents = product.priceCents - product.costPriceCents;

    return RefreshIndicator(
      onRefresh: _loadProduct,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        children: <Widget>[
          _buildImageCard(product),
          const SizedBox(height: 14),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'SKU: ${product.sku}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          InventoryDetailInfoRow(
            icon: Icons.warehouse_outlined,
            label: 'Stock disponible',
            value: _formatQty(row.qty),
          ),
          InventoryStockByWarehouseSection(
            rows: _stockByWarehouse,
            formatQty: _formatQty,
          ),
          InventoryDetailInfoRow(
            icon: Icons.sell_outlined,
            label: 'Precio de venta',
            value: _money(product.priceCents, currencyCode),
          ),
          InventoryDetailInfoRow(
            icon: Icons.shopping_cart_checkout_outlined,
            label: 'Costo',
            value: _money(product.costPriceCents, currencyCode),
          ),
          InventoryDetailInfoRow(
            icon: Icons.trending_up_rounded,
            label: 'Margen unitario',
            value: _money(marginCents, currencyCode),
          ),
          InventoryDetailInfoRow(
            icon: Icons.currency_exchange_rounded,
            label: 'Moneda',
            value: currencyCode,
          ),
          InventoryDetailInfoRow(
            icon: Icons.category_outlined,
            label: 'Categoria',
            value: product.category,
          ),
          InventoryDetailInfoRow(
            icon: Icons.layers_outlined,
            label: 'Tipo',
            value: product.productType,
          ),
          InventoryDetailInfoRow(
            icon: Icons.straighten_rounded,
            label: 'Unidad',
            value: product.unitMeasure,
          ),
          InventoryDetailInfoRow(
            icon: Icons.percent_rounded,
            label: 'Impuesto',
            value: _formatPercentFromBps(product.taxRateBps),
          ),
          InventoryDetailInfoRow(
            icon: Icons.qr_code_rounded,
            label: 'Codigo de barras',
            value: (product.barcode == null || product.barcode!.trim().isEmpty)
                ? 'No definido'
                : product.barcode!.trim(),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _openingEditor ? null : _openEditProduct,
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              _openingEditor ? 'Abriendo editor...' : 'Editar producto',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalle de producto',
      currentRoute: '/inventario',
      showTopTabs: false,
      showBottomNavigationBar: false,
      showDrawer: false,
      useDefaultActions: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Editar producto',
          onPressed:
              _product == null || _openingEditor ? null : _openEditProduct,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildDetailBody(),
    );
  }
}
