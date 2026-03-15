import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

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
      final Future<List<InventoryView>> inventoryFuture = invDs.listStockedPage(
        warehouseId: warehouseId,
        search: _searchCtrl.text,
        limit: _pageSize,
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
          await ref.read(inventarioLocalDataSourceProvider).listStockedPage(
                warehouseId: _selectedWarehouseId,
                search: _searchCtrl.text,
                limit: _pageSize,
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
          await ref.read(inventarioLocalDataSourceProvider).listStockedPage(
                warehouseId: _selectedWarehouseId,
                search: _searchCtrl.text,
                limit: _pageSize,
                offset: _inventory.length,
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

  String _moneyFromCents(int cents) {
    return (cents / 100).toStringAsFixed(2);
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

  @override
  Widget build(BuildContext context) {
    final List<InventoryView> rows = _inventory;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: 'Inventario',
      currentRoute: '/inventario',
      onRefresh: _bootstrap,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedWarehouseId,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Almacen'),
                          items: <DropdownMenuItem<String?>>[
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._warehouses.map(
                              (Warehouse w) => DropdownMenuItem<String?>(
                                value: w.id,
                                child: Text(
                                  w.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (String? value) async {
                            setState(() => _selectedWarehouseId = value);
                            await _reloadInventory(showLoader: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Movimientos',
                        onPressed: () => context.go('/inventario-movimientos'),
                        icon: const Icon(Icons.swap_horiz_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchCtrl,
                    builder: (
                      BuildContext context,
                      TextEditingValue value,
                      Widget? child,
                    ) {
                      return TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o SKU',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _searchCtrl.clear,
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF211D2D)
                              : const Color(0xFFF9F6FD),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF342E46)
                                  : const Color(0xFFE1D8F2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF342E46)
                                  : const Color(0xFFE1D8F2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_searching) ...<Widget>[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 10),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reloadInventory,
                      child: rows.isEmpty
                          ? ListView(
                              children: const <Widget>[
                                SizedBox(height: 44),
                                Center(
                                  child: Text(
                                    'No hay productos con stock para mostrar.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              key: const PageStorageKey<String>(
                                'inventario-list',
                              ),
                              controller: _scrollController,
                              cacheExtent: 420,
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
                                final InventoryView row = rows[index];
                                return Padding(
                                  key: ValueKey<String>(row.productId),
                                  padding: EdgeInsets.only(
                                    bottom: index == rows.length - 1 ? 0 : 8,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF342E46)
                                            : const Color(0xFFE1D8F2),
                                      ),
                                      boxShadow: isDark
                                          ? const <BoxShadow>[]
                                          : const <BoxShadow>[
                                              BoxShadow(
                                                color: Color(0x10000000),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  row.productName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'SKU: ${row.sku}',
                                                  style: TextStyle(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: <Widget>[
                                                    _infoChip(
                                                      'Precio',
                                                      _moneyFromCents(
                                                        row.priceCents,
                                                      ),
                                                    ),
                                                    _infoChip(
                                                      'Impuesto',
                                                      '${(row.taxRateBps / 100).toStringAsFixed(2)}%',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF233246)
                                                  : const Color(0xFFE6ECFA),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _formatQty(row.qty),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: isDark
                                                    ? const Color(0xFF9AC1FF)
                                                    : const Color(0xFF2D4A86),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoChip(String label, String value) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF28233A) : const Color(0xFFF2ECFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
