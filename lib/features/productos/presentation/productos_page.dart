import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../data/productos_local_datasource.dart';
import '../domain/product_qr_codec.dart';
import 'productos_providers.dart';

const List<String> _kCurrencies = <String>['USD', 'EUR', 'MXN', 'CUP'];

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  List<Product> _products = <Product>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final List<Product> data =
          await ref.read(productosLocalDataSourceProvider).listActiveProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar Productos: $e');
    }
  }

  Future<void> _openProductForm({Product? product}) async {
    final bool isEditing = product != null;
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => _ProductFormPage(product: product),
        fullscreenDialog: true,
      ),
    );

    if (result == null) {
      return;
    }

    await _loadProducts();

    if (result == 'saved') {
      _show(isEditing ? 'Producto actualizado.' : 'Producto creado.');
    } else if (result == 'deleted') {
      _show('Producto eliminado.');
    }
  }

  String _moneyByCurrency(int cents, String currencyCode) {
    return '$currencyCode ${(cents / 100).toStringAsFixed(2)}';
  }

  String _dateText(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildImageContent(String? path) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color placeholder =
        isDark ? const Color(0xFF2A243B) : const Color(0xFFDCD5F3);
    final Color placeholderIcon =
        isDark ? const Color(0xFFB9AEE2) : const Color(0xFF574A82);

    if (path == null || path.isEmpty) {
      return Container(
        color: placeholder,
        child: Icon(
          Icons.inventory_2_outlined,
          color: placeholderIcon,
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        cacheWidth: 480,
        errorBuilder: (_, __, ___) => Container(
          color: placeholder,
          child: Icon(Icons.broken_image_outlined, color: placeholderIcon),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: 480,
      errorBuilder: (_, __, ___) => Container(
        color: placeholder,
        child: Icon(Icons.broken_image_outlined, color: placeholderIcon),
      ),
    );
  }

  Future<void> _showProductQr(Product product) async {
    final String qrData = buildProductQrData(product);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'QR del producto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${product.name}\nID: ${product.id}\nPrecio: ${_moneyByCurrency(product.priceCents, product.currencyCode)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  'Este QR contiene: id, codigo, nombre, precio de venta y moneda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB9B1CD)
                        : const Color(0xFF59526E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final String barcode = (product.barcode ?? '').trim();
    final Widget imageThumb = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFD8D0EB),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 46,
          height: 46,
          child: _buildImageContent(product.imagePath),
        ),
      ),
    );
    final Widget infoBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.2,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Ver QR',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: 28,
                height: 28,
              ),
              padding: EdgeInsets.zero,
              splashRadius: 16,
              onPressed: () => _showProductQr(product),
              icon: const Icon(
                Icons.qr_code_2_rounded,
                size: 18,
              ),
            ),
          ],
        ),
        Text(
          barcode.isEmpty
              ? 'Cod: ${product.sku}'
              : 'Cod: ${product.sku} • Bar: $barcode',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${product.category} • ${product.productType} • ${product.unitMeasure} • ${_dateText(product.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    final Widget priceBlock = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          _moneyByCurrency(product.priceCents, product.currencyCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF57D0A6) : const Color(0xFF148A65),
            fontSize: 11.8,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'Costo ${_moneyByCurrency(product.costPriceCents, product.currencyCode)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 8.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFDDD5EF),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openProductForm(product: product),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 182;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        imageThumb,
                        const SizedBox(width: 8),
                        Expanded(child: infoBlock),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: priceBlock,
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  imageThumb,
                  const SizedBox(width: 8),
                  Expanded(child: infoBlock),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 108,
                    child: priceBlock,
                  ),
                ],
              );
            },
          ),
        ),
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
    final license = ref.watch(currentLicenseStatusProvider);
    return AppScaffold(
      title: 'Productos',
      currentRoute: '/productos',
      onRefresh: _loadProducts,
      floatingActionButton: license.canWrite
          ? FloatingActionButton.small(
              onPressed: () => _openProductForm(),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const <Widget>[
                        SizedBox(height: 32),
                        Center(
                            child: Text('No hay productos. Usa + para crear.')),
                      ],
                    )
                  : GridView.builder(
                      cacheExtent: 200,
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 90),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (_, int index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
            ),
    );
  }
}

class _ProductFormPage extends ConsumerStatefulWidget {
  const _ProductFormPage({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<_ProductFormPage> {
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _saleCtrl;
  late final TextEditingController _profitCtrl;

  List<String> _typeOptions = <String>['Fisico', 'Servicio', 'Digital'];
  List<String> _categoryOptions = <String>['General'];
  List<String> _unitOptions = <String>[
    'Unidad',
    'Caja',
    'Kg',
    'Litro',
    'Metro',
    'Paquete',
  ];

  late String _selectedType;
  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedCurrency;

  String? _selectedImagePath;
  bool _saving = false;
  bool _loadingCatalogs = true;
  bool _syncingPriceFields = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final Product? product = widget.product;

    _nameCtrl = TextEditingController(text: product?.name ?? '');
    _codeCtrl = TextEditingController(text: product?.sku ?? '');
    _barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    _costCtrl = TextEditingController(
      text: product == null ? '' : _centsToText(product.costPriceCents),
    );
    _saleCtrl = TextEditingController(
      text: product == null ? '' : _centsToText(product.priceCents),
    );
    _profitCtrl = TextEditingController(
      text: _formatPercent(_initialProfitPercent(product)),
    );

    _selectedType = product?.productType ?? _typeOptions.first;
    _selectedCategory = product?.category ?? _categoryOptions.first;
    _selectedUnit = product?.unitMeasure ?? _unitOptions.first;
    _selectedCurrency = product?.currencyCode ?? _kCurrencies.first;
    _selectedImagePath = product?.imagePath;

    _loadCatalogs();

    if (product == null && _costCtrl.text.isNotEmpty) {
      _recalculateSaleFromMargin();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _barcodeCtrl.dispose();
    _costCtrl.dispose();
    _saleCtrl.dispose();
    _profitCtrl.dispose();
    super.dispose();
  }

  double _initialProfitPercent(Product? product) {
    if (product == null || product.costPriceCents <= 0) {
      return 30;
    }

    final double cost = product.costPriceCents / 100;
    final double sale = product.priceCents / 100;
    return ((sale - cost) / cost) * 100;
  }

  Future<void> _loadCatalogs() async {
    final ProductosLocalDataSource ds =
        ref.read(productosLocalDataSourceProvider);
    try {
      final List<String> types =
          await ds.listCatalogValues(ProductCatalogKind.type);
      final List<String> categories =
          await ds.listCatalogValues(ProductCatalogKind.category);
      final List<String> units =
          await ds.listCatalogValues(ProductCatalogKind.unit);

      if (!mounted) {
        return;
      }

      final List<String> mergedTypes =
          _mergeWithCurrent(types, _selectedType, fallback: 'Fisico');
      final List<String> mergedCategories =
          _mergeWithCurrent(categories, _selectedCategory, fallback: 'General');
      final List<String> mergedUnits =
          _mergeWithCurrent(units, _selectedUnit, fallback: 'Unidad');

      setState(() {
        _typeOptions = mergedTypes;
        _categoryOptions = mergedCategories;
        _unitOptions = mergedUnits;

        _selectedType = _resolveSelected(
          current: _selectedType,
          options: _typeOptions,
          fallback: 'Fisico',
        );
        _selectedCategory = _resolveSelected(
          current: _selectedCategory,
          options: _categoryOptions,
          fallback: 'General',
        );
        _selectedUnit = _resolveSelected(
          current: _selectedUnit,
          options: _unitOptions,
          fallback: 'Unidad',
        );
        _loadingCatalogs = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingCatalogs = false);
      _show('No se pudo cargar catalogos: $e');
    }
  }

  List<String> _mergeWithCurrent(
    List<String> values,
    String current, {
    required String fallback,
  }) {
    final List<String> merged = <String>[];

    for (final String value in values) {
      if (!merged.contains(value)) {
        merged.add(value);
      }
    }

    final String cleanedCurrent = current.trim();
    if (cleanedCurrent.isNotEmpty && !merged.contains(cleanedCurrent)) {
      merged.add(cleanedCurrent);
    }

    if (merged.isEmpty) {
      merged.add(fallback);
    }

    return merged;
  }

  String _resolveSelected({
    required String current,
    required List<String> options,
    required String fallback,
  }) {
    if (options.contains(current)) {
      return current;
    }
    if (options.contains(fallback)) {
      return fallback;
    }
    return options.first;
  }

  Future<void> _pickImage() async {
    final _ImagePickAction? action =
        await _showImageOptions(context, hasImage: _selectedImagePath != null);
    if (action == null) {
      return;
    }
    if (action == _ImagePickAction.remove) {
      setState(() => _selectedImagePath = null);
      return;
    }

    final XFile? file = await _imagePicker.pickImage(
      source: action == _ImagePickAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (file == null || !mounted) {
      return;
    }
    setState(() => _selectedImagePath = file.path);
  }

  Future<String?> _scanBarcode() {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const CodeScannerPage(
          title: 'Escanear codigo de barras',
          subtitle:
              'Escanea un codigo de barras o QR para rellenar el campo de codigo de barras.',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _scanAndSetBarcode() async {
    final String? raw = await _scanBarcode();
    if (raw == null || !mounted) {
      return;
    }

    final ProductQrPayload? payload = ProductQrPayload.tryParse(raw);
    final String resolved = (payload?.code ?? raw).trim();
    if (resolved.isEmpty) {
      return;
    }

    setState(() {
      _barcodeCtrl.text = resolved;
    });
  }

  Future<void> _addCatalogValue(ProductCatalogKind kind) async {
    final TextEditingController input = TextEditingController();
    final String title = switch (kind) {
      ProductCatalogKind.type => 'Nuevo tipo de producto',
      ProductCatalogKind.category => 'Nueva categoria',
      ProductCatalogKind.unit => 'Nueva unidad de medida',
    };

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: input,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Escribe un valor'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(input.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    final String cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) {
      return;
    }

    try {
      await ref.read(productosLocalDataSourceProvider).addCatalogValue(
            kind: kind,
            value: cleaned,
          );
      await _loadCatalogs();

      if (!mounted) {
        return;
      }

      setState(() {
        if (kind == ProductCatalogKind.type) {
          _selectedType =
              _firstExactOrCurrent(_typeOptions, cleaned, _selectedType);
        }
        if (kind == ProductCatalogKind.category) {
          _selectedCategory = _firstExactOrCurrent(
              _categoryOptions, cleaned, _selectedCategory);
        }
        if (kind == ProductCatalogKind.unit) {
          _selectedUnit =
              _firstExactOrCurrent(_unitOptions, cleaned, _selectedUnit);
        }
      });
    } catch (e) {
      _show('No se pudo guardar: $e');
    }
  }

  String _firstExactOrCurrent(
      List<String> options, String value, String current) {
    for (final String option in options) {
      if (option.toLowerCase() == value.toLowerCase()) {
        return option;
      }
    }
    return current;
  }

  Future<_ImagePickAction?> _showImageOptions(
    BuildContext context, {
    required bool hasImage,
  }) {
    return showModalBottomSheet<_ImagePickAction>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () =>
                    Navigator.of(context).pop(_ImagePickAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camara'),
                onTap: () => Navigator.of(context).pop(_ImagePickAction.camera),
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Quitar imagen'),
                  onTap: () =>
                      Navigator.of(context).pop(_ImagePickAction.remove),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final String code = _codeCtrl.text.trim();
    final String barcode = _barcodeCtrl.text.trim();
    final String name = _nameCtrl.text.trim();

    final int? costCents = _moneyTextToCents(_costCtrl.text);
    final int? saleCents = _moneyTextToCents(_saleCtrl.text);

    if (code.isEmpty || name.isEmpty) {
      _show('Codigo y nombre son obligatorios.');
      return;
    }
    if (costCents == null || saleCents == null) {
      _show('Precios invalidos.');
      return;
    }

    final ProductosLocalDataSource ds =
        ref.read(productosLocalDataSourceProvider);
    final String? excludeProductId = _isEditing ? widget.product!.id : null;

    final bool codeTaken = await ds.isCodeTaken(
      code,
      excludeProductId: excludeProductId,
    );
    if (codeTaken) {
      _show('El codigo personalizado ya existe. Usa otro codigo.');
      return;
    }

    if (barcode.isNotEmpty) {
      final bool barcodeTaken = await ds.isBarcodeTaken(
        barcode,
        excludeProductId: excludeProductId,
      );
      if (barcodeTaken) {
        _show('El codigo de barras ya existe.');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final ProductFormInput input = ProductFormInput(
        code: code,
        barcode: barcode.isEmpty ? null : barcode,
        name: name,
        imagePath: _selectedImagePath,
        costPriceCents: costCents,
        salePriceCents: saleCents,
        category: _selectedCategory,
        productType: _selectedType,
        unitMeasure: _selectedUnit,
        currencyCode: _selectedCurrency,
      );

      if (_isEditing) {
        await ds.updateProduct(
          productId: widget.product!.id,
          input: input,
        );
      } else {
        await ds.createProduct(input);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('saved');
    } catch (e) {
      final String raw = e.toString();
      if (raw.contains('UNIQUE constraint failed: products.sku')) {
        _show('El codigo personalizado ya existe. Usa otro codigo.');
      } else {
        _show('No se pudo guardar el producto: $e');
      }

      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteCurrentProduct() async {
    if (!_isEditing) {
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text(
            'Se dara de baja el producto "${widget.product!.name}".',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() => _saving = true);

    try {
      await ref
          .read(productosLocalDataSourceProvider)
          .deactivateProduct(widget.product!.id);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('deleted');
    } catch (e) {
      _show('No se pudo eliminar el producto: $e');
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _onCostChanged(String _) {
    _recalculateSaleFromMargin();
  }

  void _onProfitChanged(String _) {
    _recalculateSaleFromMargin();
  }

  void _onSaleChanged(String _) {
    _recalculateMarginFromSale();
  }

  void _recalculateSaleFromMargin() {
    if (_syncingPriceFields) {
      return;
    }

    final double? cost = _parseDecimal(_costCtrl.text);
    if (cost == null) {
      return;
    }

    final double margin = _parseDecimal(_profitCtrl.text) ?? 30;
    final double sale = cost * (1 + (margin / 100));

    _syncingPriceFields = true;
    _setControllerText(_saleCtrl, sale.toStringAsFixed(2));
    _syncingPriceFields = false;
  }

  void _recalculateMarginFromSale() {
    if (_syncingPriceFields) {
      return;
    }

    final double? cost = _parseDecimal(_costCtrl.text);
    final double? sale = _parseDecimal(_saleCtrl.text);
    if (cost == null || sale == null || cost <= 0) {
      return;
    }

    final double margin = ((sale - cost) / cost) * 100;
    _syncingPriceFields = true;
    _setControllerText(_profitCtrl, _formatPercent(margin));
    _syncingPriceFields = false;
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  int? _moneyTextToCents(String raw) {
    final double? value = _parseDecimal(raw);
    if (value == null || value < 0) {
      return null;
    }
    return (value * 100).round();
  }

  double? _parseDecimal(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  String _formatPercent(double value) {
    final String oneDecimal = value.toStringAsFixed(1);
    if (oneDecimal.endsWith('.0')) {
      return oneDecimal.substring(0, oneDecimal.length - 2);
    }
    return oneDecimal;
  }

  String _centsToText(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  String _dateText(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _timeText(DateTime date) {
    final DateTime local = date.toLocal();
    final String h = local.hour.toString().padLeft(2, '0');
    final String m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildImageContent(String? path) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (path == null || path.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF28233A) : const Color(0xFFE7E1F6),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 30,
          color: isDark ? const Color(0xFFB8A9F1) : const Color(0xFF5A4D88),
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        cacheWidth: 640,
        errorBuilder: (_, __, ___) => Container(
          color: isDark ? const Color(0xFF28233A) : const Color(0xFFDCD5F3),
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: 640,
      errorBuilder: (_, __, ___) => Container(
        color: isDark ? const Color(0xFF28233A) : const Color(0xFFDCD5F3),
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  Widget _buildImagePickerThumb() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: _saving ? null : _pickImage,
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF342E46) : const Color(0xFFD8D0EC),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageContent(_selectedImagePath),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF5B4B8A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF16131E)
                      : const Color(0xFFF2EEF9),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledBlock({
    required IconData icon,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241F33) : const Color(0xFFEDE8F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFDCD3EE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF312948)
                      : const Color(0xFFDCD3F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isDark
                      ? const Color(0xFFB8A9F1)
                      : const Color(0xFF564781),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5A4D89),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          dropdownColor:
              isDark ? const Color(0xFF241F33) : const Color(0xFFF4EFFB),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          iconEnabledColor: Colors.white,
          onChanged: (String? value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedCurrency = value);
          },
          items: _kCurrencies
              .map(
                (String currency) => DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF241F33) : const Color(0xFFEDE8F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF342E46) : const Color(0xFFDDD5EE),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      labelText: label,
                      filled: false,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildCurrencySelector(),
      ],
    );
  }

  Widget _buildProfitField() {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241F33) : const Color(0xFFEDE8F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFDDD5EE),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.trending_up_rounded, color: Color(0xFF51457D)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '% de ganancia',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: TextField(
              controller: _profitCtrl,
              onChanged: _onProfitChanged,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '30',
                filled: false,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4D4276),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalogDropdownField({
    required ProductCatalogKind kind,
    required IconData icon,
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final String selectedValue =
        options.contains(selected) ? selected : options.first;

    return _buildLabeledBlock(
      icon: icon,
      label: label,
      trailing: IconButton.filledTonal(
        tooltip: 'Anadir',
        onPressed: _saving ? null : () => _addCatalogValue(kind),
        icon: const Icon(Icons.add_rounded),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        dropdownColor:
            isDark ? const Color(0xFF241F33) : const Color(0xFFF4EFFB),
        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xFF211D2D) : const Color(0xFFF7F4FC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF342E46) : const Color(0xFFD8D0EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.2),
          ),
        ),
        items: options
            .map(
              (String option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
            )
            .toList(),
        onChanged: (String? value) {
          if (value == null) {
            return;
          }
          onChanged(value);
        },
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
    final DateTime now = DateTime.now();
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          _isEditing ? 'Editar' : 'Anadir',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nombre del producto',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                _buildImagePickerThumb(),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: <Widget>[
                Text(
                  _dateText(now),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _timeText(now),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildLabeledBlock(
              icon: Icons.tag_rounded,
              label: 'Codigo personalizado',
              child: TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Ej: A-001',
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildLabeledBlock(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Codigo de barras (opcional)',
              trailing: IconButton.filledTonal(
                tooltip: 'Escanear',
                onPressed: _saving ? null : _scanAndSetBarcode,
                icon: const Icon(Icons.center_focus_strong_rounded),
              ),
              child: TextField(
                controller: _barcodeCtrl,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Escanea o escribe el codigo de barras',
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildPriceField(
              label: 'Precio de costo',
              controller: _costCtrl,
              icon: Icons.savings_outlined,
              iconColor: const Color(0xFF4B6CF6),
              onChanged: _onCostChanged,
            ),
            const SizedBox(height: 10),
            _buildProfitField(),
            const SizedBox(height: 10),
            _buildPriceField(
              label: 'Precio de venta',
              controller: _saleCtrl,
              icon: Icons.sell_rounded,
              iconColor: const Color(0xFFE9487D),
              onChanged: _onSaleChanged,
            ),
            const SizedBox(height: 14),
            if (_loadingCatalogs)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            _catalogDropdownField(
              kind: ProductCatalogKind.category,
              icon: Icons.category_outlined,
              label: 'Categoria',
              options: _categoryOptions,
              selected: _selectedCategory,
              onChanged: (String value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 10),
            _catalogDropdownField(
              kind: ProductCatalogKind.type,
              icon: Icons.widgets_outlined,
              label: 'Tipo de producto',
              options: _typeOptions,
              selected: _selectedType,
              onChanged: (String value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 10),
            _catalogDropdownField(
              kind: ProductCatalogKind.unit,
              icon: Icons.straighten_rounded,
              label: 'Unidad de medida',
              options: _unitOptions,
              selected: _selectedUnit,
              onChanged: (String value) {
                setState(() => _selectedUnit = value);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1826) : const Color(0xFFEAE4F6),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            if (_isEditing) ...<Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _deleteCurrentProduct,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC73D6A),
                    side: const BorderSide(color: Color(0xFFC73D6A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: _isEditing ? 2 : 1,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Guardando...'
                      : _isEditing
                          ? 'Actualizar producto'
                          : 'Guardar producto',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ImagePickAction { gallery, camera, remove }
