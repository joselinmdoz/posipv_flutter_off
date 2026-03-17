import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../data/inventario_local_datasource.dart';
import 'inventario_providers.dart';

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  static const int _pageSize = 60;
  static const double _lowStockThreshold = 10;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<Warehouse> _warehouses = <Warehouse>[];
  List<InventoryView> _inventory = <InventoryView>[];
  String? _selectedWarehouseId;
  bool _loading = true;
  bool _loadingMore = false;
  bool _searching = false;
  bool _hasMore = true;
  InventoryListFilter _stockFilter = InventoryListFilter.all;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) {
        return;
      }
      _applySearch();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        _searching ||
        !_hasMore) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMoreInventory();
    }
  }

  Future<void> _bootstrap() async {
    final PerfTrace trace = PerfTrace('inventario.bootstrap');
    setState(() => _loading = true);

    try {
      final whDs = ref.read(almacenesLocalDataSourceProvider);
      await whDs.ensureDefaultWarehouse();
      final InventarioLocalDataSource invDs =
          ref.read(inventarioLocalDataSourceProvider);
      final String? warehouseId = _selectedWarehouseId;

      final Future<List<Warehouse>> warehousesFuture =
          whDs.listActiveWarehouses();
      final Future<List<InventoryView>> inventoryFuture =
          invDs.listInventoryPage(
        warehouseId: warehouseId,
        search: _searchCtrl.text,
        limit: _pageSize,
        filter: _stockFilter,
        lowStockThreshold: _lowStockThreshold,
      );

      final List<Warehouse> warehouses = await warehousesFuture;
      final List<InventoryView> inventory = await inventoryFuture;
      trace.mark('datos cargados');

      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _selectedWarehouseId = warehouseId;
        _inventory = inventory;
        _hasMore = inventory.length == _pageSize;
        _loadingMore = false;
        _searching = false;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudo cargar Inventario: $e');
    }
  }

  Future<void> _reloadInventory({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    try {
      final List<InventoryView> inventory =
          await ref.read(inventarioLocalDataSourceProvider).listInventoryPage(
                warehouseId: _selectedWarehouseId,
                search: _searchCtrl.text,
                limit: _pageSize,
                filter: _stockFilter,
                lowStockThreshold: _lowStockThreshold,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        _inventory = inventory;
        _hasMore = inventory.length == _pageSize;
        _loadingMore = false;
        _searching = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMore = false;
        _searching = false;
        _loading = false;
      });
      _show('No se pudo cargar Inventario: $e');
    }
  }

  Future<void> _applySearch() async {
    if (_loading) {
      return;
    }
    setState(() => _searching = true);
    await _reloadInventory();
  }

  Future<void> _loadMoreInventory() async {
    if (_loading || _loadingMore || _searching || !_hasMore) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final List<InventoryView> nextRows =
          await ref.read(inventarioLocalDataSourceProvider).listInventoryPage(
                warehouseId: _selectedWarehouseId,
                search: _searchCtrl.text,
                limit: _pageSize,
                offset: _inventory.length,
                filter: _stockFilter,
                lowStockThreshold: _lowStockThreshold,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        _inventory = <InventoryView>[..._inventory, ...nextRows];
        _hasMore = nextRows.length == _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingMore = false);
      _show('No se pudo cargar mas inventario: $e');
    }
  }

  String _moneyFromCents(int cents, String currencyCode) {
    final String symbol = switch (currencyCode.toUpperCase()) {
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

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isOutOfStock(double qty) => qty <= 0.000001;

  bool _isLowStock(double qty) => qty > 0 && qty <= _lowStockThreshold;

  String _stockLabel(double qty) {
    if (_isOutOfStock(qty)) {
      return 'Agotado';
    }
    if (_isLowStock(qty)) {
      return '${_formatQty(qty)} en stock';
    }
    return 'en stock';
  }

  Color _stockLabelColor(ThemeData theme, double qty) {
    if (_isOutOfStock(qty)) {
      return theme.colorScheme.error;
    }
    if (_isLowStock(qty)) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFF059669);
  }

  Color _stockBgColor(ThemeData theme, double qty) {
    if (_isOutOfStock(qty)) {
      return theme.colorScheme.errorContainer.withValues(alpha: 0.55);
    }
    if (_isLowStock(qty)) {
      return const Color(0xFFFEF3C7);
    }
    return const Color(0xFFD1FAE5);
  }

  Future<void> _setStockFilter(InventoryListFilter filter) async {
    if (_stockFilter == filter) {
      return;
    }
    setState(() => _stockFilter = filter);
    await _reloadInventory(showLoader: true);
  }

  Future<void> _openWarehouseFilters() async {
    String? draftWarehouse = _selectedWarehouseId;
    final bool? apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return SafeArea(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Filtros de inventario',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: draftWarehouse,
                      decoration: const InputDecoration(
                        labelText: 'Almacen',
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ..._warehouses.map(
                          (Warehouse warehouse) => DropdownMenuItem<String?>(
                            value: warehouse.id,
                            child: Text(
                              warehouse.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setModalState(() => draftWarehouse = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Aplicar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          context.go('/inventario-movimientos');
                        },
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('Ir a movimientos'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (apply != true || !mounted) {
      return;
    }

    setState(() => _selectedWarehouseId = draftWarehouse);
    await _reloadInventory(showLoader: true);
  }

  Widget _buildSearchField(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _searchCtrl,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        return TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar producto o SKU...',
            prefixIcon: const Icon(Icons.search_rounded, size: 30),
            suffixIcon: SizedBox(
              width: value.text.isEmpty ? 52 : 96,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (value.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpiar',
                      onPressed: _searchCtrl.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  IconButton(
                    tooltip: 'Filtros',
                    onPressed: _openWarehouseFilters,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required InventoryListFilter filter,
    required ThemeData theme,
  }) {
    final bool isSelected = _stockFilter == filter;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color fillColor = isSelected
        ? theme.colorScheme.primary
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final Color textColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    final Color borderColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => _setStockFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumb(String? path, ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color fallbackBg =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    Widget fallback() {
      return Container(
        color: fallbackBg,
        child: Icon(
          Icons.inventory_2_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (path == null || path.trim().isEmpty) {
      return fallback();
    }

    final String resolved = path.trim();
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        cacheWidth: 280,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    return Image.file(
      File(resolved),
      fit: BoxFit.cover,
      cacheWidth: 280,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  Widget _buildInventoryCard(InventoryView row) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardBorder = theme.colorScheme.outline.withValues(alpha: 0.7);
    final Color priceColor = theme.colorScheme.primary;

    return Container(
      key: ValueKey<String>(row.productId),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('/inventario-movimientos'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: _buildProductThumb(row.imagePath, theme),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      row.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _stockBgColor(theme, row.qty),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _stockLabel(row.qty),
                            style: TextStyle(
                              color: _stockLabelColor(theme, row.qty),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SKU: ${row.sku}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _moneyFromCents(row.priceCents, row.currencyCode),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: priceColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<InventoryView> rows = _inventory;
    final ThemeData theme = Theme.of(context);

    return AppScaffold(
      title: 'Inventario',
      currentRoute: '/inventario',
      onRefresh: _bootstrap,
      showTopTabs: false,
      useDefaultActions: false,
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () => _show('Notificaciones próximamente.'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.go('/configuracion'),
            child: CircleAvatar(
              radius: 17,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.14),
              child: Icon(
                Icons.account_circle_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/inventario-movimientos'),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                children: <Widget>[
                  _buildSearchField(theme),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _buildFilterChip(
                          label: 'Todos',
                          filter: InventoryListFilter.all,
                          theme: theme,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: 'En stock',
                          filter: InventoryListFilter.inStock,
                          theme: theme,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: 'Stock bajo',
                          filter: InventoryListFilter.lowStock,
                          theme: theme,
                        ),
                        const SizedBox(width: 10),
                        _buildFilterChip(
                          label: 'Agotado',
                          filter: InventoryListFilter.outOfStock,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                  if (_searching) ...<Widget>[
                    const SizedBox(height: 6),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reloadInventory,
                      child: rows.isEmpty
                          ? ListView(
                              children: <Widget>[
                                const SizedBox(height: 68),
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 44,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No se encontraron productos con este filtro.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              key: const PageStorageKey<String>(
                                  'inventario-list'),
                              controller: _scrollController,
                              cacheExtent: 520,
                              padding:
                                  const EdgeInsets.only(top: 2, bottom: 110),
                              itemCount: rows.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (_, int index) {
                                if (index >= rows.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildInventoryCard(rows[index]);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
