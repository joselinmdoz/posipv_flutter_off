import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/code_scanner_page.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/productos_local_datasource.dart';
import '../domain/product_qr_codec.dart';
import 'productos_providers.dart';
import 'widgets/product_card.dart';

const List<String> _kFallbackCurrencies = <String>['USD', 'EUR', 'MXN', 'CUP'];

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  static const int _pageSize = 40;

  final ScrollController _scrollController = ScrollController();
  List<Product> _products = <Product>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts() async {
    final PerfTrace trace = PerfTrace('productos.load');
    setState(() => _loading = true);
    try {
      final List<Product> data = await ref
          .read(productosLocalDataSourceProvider)
          .listActiveProductsPage(limit: _pageSize);
      trace.mark('consulta completada');

      if (!mounted) {
        trace.end('unmounted');
        return;
      }

      setState(() {
        _products = data;
        _hasMore = data.length == _pageSize;
        _loadingMore = false;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudo cargar Productos: $e');
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loading || _loadingMore || !_hasMore) {
      return;
    }

    setState(() => _loadingMore = true);
    try {
      final List<Product> data = await ref
          .read(productosLocalDataSourceProvider)
          .listActiveProductsPage(
            limit: _pageSize,
            offset: _products.length,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _products = <Product>[..._products, ...data];
        _hasMore = data.length == _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingMore = false);
      _show('No se pudo cargar mas productos: $e');
    }
  }

  Future<void> _openProductForm({Product? product}) async {
    final bool isEditing = product != null;
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ProductFormPage(product: product),
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
          ? AppAddActionButton(
              currentRoute: '/productos',
              onPressed: () => _openProductForm(),
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
                      key: const PageStorageKey<String>('productos-grid'),
                      controller: _scrollController,
                      cacheExtent: 200,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 178,
                      ),
                      itemBuilder: (_, int index) {
                        final Product product = _products[index];
                        return KeyedSubtree(
                          key: ValueKey<String>(product.id),
                          child: ProductCard(
                            product: product,
                            onTap: () => _openProductForm(product: product),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
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
  List<String> _currencyOptions = <String>[..._kFallbackCurrencies];
  Map<String, String> _currencySymbolsByCode = <String, String>{
    'USD': r'$',
    'EUR': '€',
    'MXN': r'$',
    'CUP': '₱',
  };

  late String _selectedType;
  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedCurrency;

  String? _selectedImagePath;
  bool _saving = false;
  bool _loadingCatalogs = true;
  bool _syncingPriceFields = false;

  bool get _isEditing => widget.product != null;

  Color _accentColor(ThemeData theme) => theme.colorScheme.primary;

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
    _selectedCurrency = product?.currencyCode ?? _kFallbackCurrencies.first;
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
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);
    try {
      final Future<List<List<String>>> catalogsFuture =
          Future.wait<List<String>>(
        <Future<List<String>>>[
          ds.listCatalogValues(ProductCatalogKind.type),
          ds.listCatalogValues(ProductCatalogKind.category),
          ds.listCatalogValues(ProductCatalogKind.unit),
        ],
      );
      final Future<AppConfig> configFuture = configDs.loadConfig();

      final List<List<String>> catalogs = await catalogsFuture;
      final AppConfig config = await configFuture;
      final List<String> types = catalogs[0];
      final List<String> categories = catalogs[1];
      final List<String> units = catalogs[2];
      final AppCurrencyConfig currencyConfig =
          config.currencyConfig.normalized();
      final List<String> activeCurrencyCodes = currencyConfig.currencies
          .map((AppCurrencySetting currency) => currency.code)
          .toList();
      final List<String> mergedCurrencies = _mergeWithCurrent(
        activeCurrencyCodes,
        _selectedCurrency,
        fallback: currencyConfig.primaryCurrencyCode,
      );
      final Map<String, String> symbolsByCode = <String, String>{
        for (final AppCurrencySetting currency in currencyConfig.currencies)
          currency.code: currency.symbol,
      };

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
        _currencyOptions = mergedCurrencies;
        _currencySymbolsByCode = symbolsByCode;
        _selectedCurrency = _resolveSelected(
          current: _selectedCurrency,
          options: _currencyOptions,
          fallback: currencyConfig.primaryCurrencyCode,
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
      ref.read(productosCatalogRevisionProvider.notifier).state++;

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
      ref.read(productosCatalogRevisionProvider.notifier).state++;

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

  Widget _buildImageContent(String? path) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (path == null || path.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF1A2334) : const Color(0xFFEAF0F7),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 30,
          color: isDark ? const Color(0xFF9FB0C8) : const Color(0xFF798CA7),
        ),
      );
    }

    if (path.startsWith('http')) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Image.network(
          path,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          cacheWidth: 640,
          errorBuilder: (_, __, ___) => Container(
            color: isDark ? const Color(0xFF1A2334) : const Color(0xFFEAF0F7),
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        cacheWidth: 640,
        errorBuilder: (_, __, ___) => Container(
          color: isDark ? const Color(0xFF1A2334) : const Color(0xFFEAF0F7),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget _buildImagePickerThumb() {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = _accentColor(theme);
    final Color dashColor =
        isDark ? const Color(0xFF3A475E) : const Color(0xFFC4CFDF);
    final Color boxColor =
        isDark ? const Color(0xFF1A2334) : const Color(0xFFEFF3F8);

    return InkWell(
      onTap: _saving ? null : _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: 230,
            padding: const EdgeInsets.all(3),
            child: CustomPaint(
              painter: _DashedRoundedRectPainter(
                color: dashColor,
                radius: 14,
                strokeWidth: 1.2,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: _selectedImagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.image,
                            size: 44,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pulsa para añadir imagen',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PNG, JPG hasta 10MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : _buildImageContent(_selectedImagePath),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(22),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final ThemeData theme = Theme.of(context);
    final Color accent = _accentColor(theme);
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    String? prefixText,
    String? suffixText,
    Widget? suffixIcon,
    bool emphasize = false,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = _accentColor(theme);
    final Color borderColor = emphasize
        ? accent.withValues(alpha: 0.65)
        : (isDark ? const Color(0xFF3C4A60) : const Color(0xFFCAD4E2));
    final Color fillColor = isDark ? const Color(0xFF1A2333) : Colors.white;
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      prefixStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: emphasize ? accent : theme.colorScheme.onSurfaceVariant,
      ),
      suffixStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      hintStyle: TextStyle(
        fontSize: 15,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );
  }

  String _currencySymbolFor(String code) {
    final String normalized = code.toUpperCase();
    final String? configured = _currencySymbolsByCode[normalized];
    if (configured != null && configured.trim().isNotEmpty) {
      return configured;
    }
    switch (normalized) {
      case 'USD':
        return r'$';
      case 'CUP':
        return '₱';
      case 'EUR':
        return '€';
      default:
        return r'$';
    }
  }

  IconData _typeIcon(String option) {
    final String normalized = option.trim().toLowerCase();
    if (normalized.contains('digital')) {
      return Icons.computer_rounded;
    }
    if (normalized.contains('serv')) {
      return Icons.handyman_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  Widget _catalogDropdownField({
    required String label,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String selectedValue =
        options.contains(selected) ? selected : options.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildFieldLabel(label),
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          isExpanded: true,
          dropdownColor:
              isDark ? const Color(0xFF1E2739) : const Color(0xFFF8FAFD),
          decoration: _fieldDecoration(hintText: 'Seleccionar'),
          icon: Icon(
            Icons.expand_more_rounded,
            color: isDark ? const Color(0xFF9BA9BE) : const Color(0xFF7F8FA7),
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
      ],
    );
  }

  Widget _buildTypeSelector() {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = _accentColor(theme);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = (constraints.maxWidth - 12) / 2;
        final String physical = _typeOptions.firstWhere(
          (String item) => item.toLowerCase().contains('fis'),
          orElse: () => _typeOptions.isNotEmpty ? _typeOptions.first : 'Fisico',
        );
        final String digital = _typeOptions.firstWhere(
          (String item) => item.toLowerCase().contains('dig'),
          orElse: () => 'Digital',
        );
        final List<String> options = <String>[
          physical,
          if (digital != physical) digital,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildFieldLabel('Tipo de Producto'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options.map((String option) {
                final bool selected = _selectedType == option;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _saving
                      ? null
                      : () => setState(() => _selectedType = option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: width,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(
                              alpha: isDark ? 0.25 : 0.12,
                            )
                          : (isDark ? const Color(0xFF1A2333) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? accent
                            : (isDark
                                ? const Color(0xFF3C4A60)
                                : const Color(0xFFCAD4E2)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _typeIcon(option),
                          size: 20,
                          color: selected
                              ? accent
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? accent
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPricingFields() {
    final String symbol = _currencySymbolFor(_selectedCurrency);
    return Column(
      children: <Widget>[
        _catalogDropdownField(
          label: 'Moneda de precios',
          options: _currencyOptions,
          selected: _selectedCurrency,
          onChanged: (String value) {
            setState(() => _selectedCurrency = value);
          },
        ),
        const SizedBox(height: 12),
        _buildFieldLabel('Precio Coste'),
        TextField(
          controller: _costCtrl,
          onChanged: _onCostChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            hintText: '0.00',
            prefixText: '$symbol ',
          ),
        ),
        const SizedBox(height: 12),
        _buildFieldLabel('Margen (%)'),
        TextField(
          controller: _profitCtrl,
          onChanged: _onProfitChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            hintText: '30',
            suffixText: '%',
          ),
        ),
        const SizedBox(height: 12),
        _buildFieldLabel('Precio Venta'),
        TextField(
          controller: _saleCtrl,
          onChanged: _onSaleChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            hintText: '0.00',
            prefixText: '$symbol ',
            emphasize: true,
          ),
        ),
      ],
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
    final Color accent = _accentColor(theme);
    final Color pageColor = isDark ? const Color(0xFF0F1624) : Colors.white;

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: pageColor,
        title: Text(
          _isEditing ? 'Editar Producto' : 'Añadir Producto',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Opciones',
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF2A364A) : const Color(0xFFD8E0EB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildImagePickerThumb(),
            const SizedBox(height: 18),
            _buildSectionTitle('INFORMACIÓN BÁSICA'),
            const SizedBox(height: 12),
            _buildFieldLabel('Nombre del Producto'),
            TextField(
              controller: _nameCtrl,
              decoration: _fieldDecoration(
                hintText: 'Ej. Camiseta de Algodón Premium',
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingCatalogs)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            _catalogDropdownField(
              label: 'Categoría',
              options: _categoryOptions,
              selected: _selectedCategory,
              onChanged: (String value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 12),
            _catalogDropdownField(
              label: 'Unidad de Medida',
              options: _unitOptions,
              selected: _selectedUnit,
              onChanged: (String value) {
                setState(() => _selectedUnit = value);
              },
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildSectionTitle('PRECIOS Y MÁRGENES'),
            const SizedBox(height: 12),
            _buildPricingFields(),
            const SizedBox(height: 20),
            _buildSectionTitle('IDENTIFICACIÓN'),
            const SizedBox(height: 12),
            _buildFieldLabel('Código Personalizado'),
            TextField(
              controller: _codeCtrl,
              decoration: _fieldDecoration(
                hintText: 'Ej: A-001',
              ),
            ),
            const SizedBox(height: 12),
            _buildFieldLabel('Código de Barras'),
            TextField(
              controller: _barcodeCtrl,
              decoration: _fieldDecoration(
                hintText: 'Escanea o escribe',
                suffixIcon: IconButton(
                  tooltip: 'Escanear',
                  onPressed: _saving ? null : _scanAndSetBarcode,
                  icon: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141B29) : pageColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2D3850) : const Color(0xFFD8E0EB),
            ),
          ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: _isEditing ? 2 : 1,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(
                  _saving
                      ? 'Guardando...'
                      : _isEditing
                          ? 'Actualizar producto'
                          : 'Guardar producto',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  static const double _dashWidth = 7;
  static const double _dashGap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + _dashWidth).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

enum _ImagePickAction { gallery, camera, remove }
