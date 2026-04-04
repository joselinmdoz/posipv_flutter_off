import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../productos/presentation/productos_page.dart';
import '../../productos/presentation/productos_providers.dart';
import '../data/inventario_local_datasource.dart';
import 'inventory_product_detail_page.dart';
import 'inventario_providers.dart';
import 'widgets/inventory_filter_chips.dart';
import 'widgets/inventory_product_card.dart';
import 'widgets/inventory_search_bar.dart';

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

  Future<void> _refreshWarehousesCatalog() async {
    final List<Warehouse> warehouses =
        await ref.read(almacenesLocalDataSourceProvider).listActiveWarehouses();
    if (!mounted) {
      return;
    }
    setState(() {
      _warehouses = warehouses;
      if (_selectedWarehouseId != null &&
          warehouses.every((Warehouse row) => row.id != _selectedWarehouseId)) {
        _selectedWarehouseId = warehouses.isEmpty ? null : warehouses.first.id;
      }
    });
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

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setStockFilter(InventoryListFilter filter) async {
    if (_stockFilter == filter) {
      return;
    }
    setState(() => _stockFilter = filter);
    await _reloadInventory(showLoader: true);
  }

  Future<void> _openWarehouseFilters() async {
    await _refreshWarehousesCatalog();
    if (!mounted) {
      return;
    }
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

  Future<void> _openCreateProductForm() async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ProductFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result != 'saved' || !mounted) {
      return;
    }
    await _reloadInventory(showLoader: true);
    _show('Producto creado.');
  }

  Future<void> _openProductDetail(InventoryView row) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => InventoryProductDetailPage(
          inventoryRow: row,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _reloadInventory();
  }

  Widget _buildInventoryCard(InventoryView row) {
    return InventoryProductCard(
      row: row,
      moneyFromCents: _moneyFromCents,
      onTap: () => _openProductDetail(row),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(inventoryRefreshSignalProvider, (int? previous, int next) {
      if (previous == null || previous == next || !mounted) {
        return;
      }
      unawaited(_bootstrap());
    });
    ref.listen<int>(productosCatalogRevisionProvider,
        (int? previous, int next) {
      if (previous == null || previous == next || !mounted) {
        return;
      }
      unawaited(_reloadInventory());
    });

    final List<InventoryView> rows = _inventory;
    final ThemeData theme = Theme.of(context);

    return AppScaffold(
      title: 'Inventario',
      currentRoute: '/inventario',
      onRefresh: _bootstrap,
      showTopTabs: false,
      showBottomNavigationBar: true,
      useDefaultActions: false,
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Movimientos',
          onPressed: () => context.go('/inventario-movimientos'),
          icon: const Icon(Icons.swap_horiz_rounded),
        ),
      ],
      floatingActionButton: AppAddActionButton(
        currentRoute: '/inventario',
        iconSize: 34,
        onPressed: _openCreateProductForm,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                children: <Widget>[
                  InventorySearchBar(
                    controller: _searchCtrl,
                    onFilterTap: _openWarehouseFilters,
                  ),
                  const SizedBox(height: 12),
                  InventoryFilterChips(
                    currentFilter: _stockFilter,
                    onFilterChanged: _setStockFilter,
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
