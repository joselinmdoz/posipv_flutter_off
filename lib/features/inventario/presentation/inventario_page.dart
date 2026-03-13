import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/db/app_database.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  List<Warehouse> _warehouses = <Warehouse>[];
  List<InventoryView> _inventory = <InventoryView>[];
  String? _selectedWarehouseId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<void> _bootstrap() async {
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
          invDs.listStocked(warehouseId: warehouseId);

      final List<Warehouse> warehouses = await warehousesFuture;
      final List<InventoryView> inventory = await inventoryFuture;

      if (!mounted) {
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _selectedWarehouseId = warehouseId;
        _inventory = inventory;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar Inventario: $e');
    }
  }

  Future<void> _reloadInventory() async {
    final List<InventoryView> inventory = await ref
        .read(inventarioLocalDataSourceProvider)
        .listStocked(warehouseId: _selectedWarehouseId);
    if (!mounted) {
      return;
    }
    setState(() {
      _inventory = inventory;
    });
  }

  List<InventoryView> get _stockedFilteredInventory {
    final String query = _searchCtrl.text.trim().toLowerCase();
    return _inventory.where((InventoryView row) {
      if (query.isEmpty) {
        return true;
      }
      return row.productName.toLowerCase().contains(query) ||
          row.sku.toLowerCase().contains(query);
    }).toList();
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
    final List<InventoryView> rows = _stockedFilteredInventory;

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
                            await _reloadInventory();
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
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o SKU',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchCtrl.clear,
                              icon: const Icon(Icons.clear_rounded),
                            ),
                      filled: true,
                      fillColor: const Color(0xFFF9F6FD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE1D8F2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE1D8F2)),
                      ),
                    ),
                  ),
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
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, int index) {
                                final InventoryView row = rows[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE1D8F2),
                                    ),
                                    boxShadow: const <BoxShadow>[
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
                                                style: const TextStyle(
                                                  color: Color(0xFF625D78),
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
                                            color: const Color(0xFFE6ECFA),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _formatQty(row.qty),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2D4A86),
                                            ),
                                          ),
                                        ),
                                      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECFA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B426A),
        ),
      ),
    );
  }
}
