import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../productos/presentation/productos_providers.dart';
import '../data/inventario_local_datasource.dart';
import 'inventario_providers.dart';

class InventarioPage extends ConsumerStatefulWidget {
  const InventarioPage({super.key});

  @override
  ConsumerState<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends ConsumerState<InventarioPage> {
  final TextEditingController _qtyCtrl = TextEditingController();

  List<Warehouse> _warehouses = <Warehouse>[];
  List<Product> _products = <Product>[];
  List<InventoryView> _inventory = <InventoryView>[];
  String? _selectedWarehouseId;
  String? _selectedProductId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);

    try {
      final whDs = ref.read(almacenesLocalDataSourceProvider);
      await whDs.ensureDefaultWarehouse();

      final List<Warehouse> warehouses = await whDs.listActiveWarehouses();
      final List<Product> products =
          await ref.read(productosLocalDataSourceProvider).listActiveProducts();

      String? warehouseId = _selectedWarehouseId;
      String? productId = _selectedProductId;

      if (warehouseId == null && warehouses.isNotEmpty) {
        warehouseId = warehouses.first.id;
      }
      if (productId == null && products.isNotEmpty) {
        productId = products.first.id;
      }

      List<InventoryView> inventory = <InventoryView>[];
      if (warehouseId != null) {
        inventory = await ref
            .read(inventarioLocalDataSourceProvider)
            .listByWarehouse(warehouseId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _warehouses = warehouses;
        _products = products;
        _selectedWarehouseId = warehouseId;
        _selectedProductId = productId;
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
    if (_selectedWarehouseId == null) {
      return;
    }
    final List<InventoryView> inventory = await ref
        .read(inventarioLocalDataSourceProvider)
        .listByWarehouse(_selectedWarehouseId!);
    if (!mounted) {
      return;
    }
    setState(() {
      _inventory = inventory;
    });
  }

  Future<void> _setStock() async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    if (_selectedWarehouseId == null || _selectedProductId == null) {
      _show('Selecciona almacen y producto.');
      return;
    }

    final double? qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty < 0) {
      _show('Cantidad invalida.');
      return;
    }

    try {
      await ref.read(inventarioLocalDataSourceProvider).setStock(
            productId: _selectedProductId!,
            warehouseId: _selectedWarehouseId!,
            qty: qty,
            userId: session.userId,
          );
      _qtyCtrl.clear();
      await _reloadInventory();
      _show('Stock actualizado.');
    } catch (e) {
      _show('No se pudo actualizar stock: $e');
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Inventario',
      currentRoute: '/inventario',
      onRefresh: _reloadInventory,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedWarehouseId,
                          decoration:
                              const InputDecoration(labelText: 'Almacen'),
                          items: _warehouses
                              .map(
                                (Warehouse w) => DropdownMenuItem<String>(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) async {
                            setState(() => _selectedWarehouseId = value);
                            await _reloadInventory();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProductId,
                          decoration:
                              const InputDecoration(labelText: 'Producto'),
                          items: _products
                              .map(
                                (Product p) => DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Text('${p.sku} - ${p.name}'),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            setState(() => _selectedProductId = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration:
                              const InputDecoration(labelText: 'Cantidad'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _setStock,
                        child: const Text('Ajustar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reloadInventory,
                      child: _inventory.isEmpty
                          ? ListView(
                              children: const <Widget>[
                                SizedBox(height: 40),
                                Center(
                                    child: Text('No hay datos de inventario.')),
                              ],
                            )
                          : ListView.separated(
                              itemCount: _inventory.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, int index) {
                                final InventoryView row = _inventory[index];
                                return ListTile(
                                  title: Text(row.productName),
                                  subtitle: Text('SKU: ${row.sku}'),
                                  trailing: Text(row.qty.toStringAsFixed(2)),
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
}
