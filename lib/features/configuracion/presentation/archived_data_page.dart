import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../inventario/data/inventario_local_datasource.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../inventario/presentation/widgets/inventory_movement_type_tabs.dart';
import '../../productos/data/productos_local_datasource.dart';
import '../../productos/presentation/productos_providers.dart';
import '../../tpv/data/tpv_local_datasource.dart';
import '../../tpv/presentation/tpv_providers.dart';
import '../../ventas_pos/data/sale_service.dart';
import '../../ventas_pos/presentation/ventas_pos_providers.dart';
import 'widgets/archived_employee_card.dart';
import 'widgets/archived_movement_card.dart';
import 'widgets/archived_product_card.dart';
import 'widgets/archived_sale_card.dart';
import 'widgets/config_section_label.dart';

enum _ArchivedTab { products, movements, sales, employees }

class ArchivedDataPage extends ConsumerStatefulWidget {
  const ArchivedDataPage({super.key});

  @override
  ConsumerState<ArchivedDataPage> createState() => _ArchivedDataPageState();
}

class _ArchivedDataPageState extends ConsumerState<ArchivedDataPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  _ArchivedTab _activeTab = _ArchivedTab.products;
  String _search = '';
  String _movementType = 'all';
  bool _loading = true;

  List<ArchivedProductView> _archivedProducts = const <ArchivedProductView>[];
  List<InventoryArchivedMovementView> _archivedMovements =
      const <InventoryArchivedMovementView>[];
  List<ArchivedSaleView> _archivedSales = const <ArchivedSaleView>[];
  List<TpvEmployee> _archivedEmployees = const <TpvEmployee>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      if (mounted) {
        setState(() {
          _loading = false;
          _archivedProducts = const <ArchivedProductView>[];
          _archivedMovements = const <InventoryArchivedMovementView>[];
          _archivedSales = const <ArchivedSaleView>[];
          _archivedEmployees = const <TpvEmployee>[];
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final productosDs = ref.read(productosLocalDataSourceProvider);
      final inventarioDs = ref.read(inventarioLocalDataSourceProvider);
      final ventasDs = ref.read(ventasPosLocalDataSourceProvider);
      final tpvDs = ref.read(tpvLocalDataSourceProvider);
      final results = await Future.wait<Object>(<Future<Object>>[
        productosDs.listArchivedProducts(search: _search),
        inventarioDs.listArchivedMovements(
          movementType: _movementType,
          search: _search,
        ),
        ventasDs.listArchivedSales(search: _search),
        tpvDs.listArchivedEmployees(search: _search),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _archivedProducts = results[0] as List<ArchivedProductView>;
        _archivedMovements = results[1] as List<InventoryArchivedMovementView>;
        _archivedSales = results[2] as List<ArchivedSaleView>;
        _archivedEmployees = results[3] as List<TpvEmployee>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar archivados: $error');
    }
  }

  void _onSearchChanged(String value) {
    _search = value.trim();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restoreProduct(ArchivedProductView product) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede restaurar productos.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reactivar producto'),
          content: Text(
            'Se reactivará "${product.name}" para volver al catálogo activo.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reactivar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    try {
      await ref.read(productosLocalDataSourceProvider).reactivateProduct(
            product.id,
          );
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _load();
      _show('Producto reactivado.');
    } catch (error) {
      _show('No se pudo reactivar el producto: $error');
    }
  }

  Future<void> _deleteProductPermanently(ArchivedProductView product) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede eliminar definitivamente.');
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar producto definitivamente'),
          content: Text(
            'Se eliminará de forma permanente "${product.name}".\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
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

    try {
      await ref
          .read(productosLocalDataSourceProvider)
          .permanentlyDeleteArchivedProduct(
            productId: product.id,
            userId: session.userId,
          );
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _load();
      _show('Producto eliminado definitivamente.');
    } catch (error) {
      _show('No se pudo eliminar definitivamente el producto: $error');
    }
  }

  Future<void> _restoreMovement(InventoryArchivedMovementView movement) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede restaurar movimientos.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Revertir archivado'),
          content: Text(
            'Se restaurará el movimiento de "${movement.productName}" y se volverá a aplicar su impacto en stock.\n\nEsta acción puede alterar inventario y resultados de ventas.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    try {
      await ref.read(inventarioLocalDataSourceProvider).restoreArchivedMovement(
            movementId: movement.id,
            userId: session.userId,
            allowNegativeResult: true,
          );
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      await _load();
      _show('Movimiento restaurado.');
    } catch (error) {
      _show('No se pudo restaurar el movimiento: $error');
    }
  }

  Future<void> _deleteMovementPermanently(
    InventoryArchivedMovementView movement,
  ) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede eliminar definitivamente.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar movimiento definitivamente'),
          content: Text(
            'Se eliminará de forma permanente el movimiento de "${movement.productName}".\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
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

    try {
      await ref
          .read(inventarioLocalDataSourceProvider)
          .permanentlyDeleteArchivedMovement(
            movementId: movement.id,
            userId: session.userId,
          );
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      await _load();
      _show('Movimiento eliminado definitivamente.');
    } catch (error) {
      _show('No se pudo eliminar definitivamente el movimiento: $error');
    }
  }

  Future<void> _restoreSale(ArchivedSaleView sale) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede restaurar ventas.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar venta archivada'),
          content: Text(
            'Se restaurará la venta "${sale.folio}" y volverá a contar en reportes y caja.\n\n'
            'También se reaplicará la salida de inventario.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    try {
      await ref.read(ventasPosLocalDataSourceProvider).restoreArchivedSale(
            saleId: sale.id,
            userId: session.userId,
            allowNegativeResult: true,
          );
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      await _load();
      _show('Venta restaurada.');
    } catch (error) {
      _show('No se pudo restaurar la venta: $error');
    }
  }

  Future<void> _deleteSalePermanently(ArchivedSaleView sale) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede eliminar definitivamente ventas.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar venta definitivamente'),
          content: Text(
            'Se eliminará de forma permanente la venta "${sale.folio}".\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
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

    try {
      await ref
          .read(ventasPosLocalDataSourceProvider)
          .permanentlyDeleteArchivedSale(
            saleId: sale.id,
            userId: session.userId,
          );
      await _load();
      _show('Venta eliminada definitivamente.');
    } catch (error) {
      _show('No se pudo eliminar definitivamente la venta: $error');
    }
  }

  Future<void> _restoreEmployee(TpvEmployee employee) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede restaurar empleados.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar empleado'),
          content: Text(
            'Se reactivará el empleado "${employee.name}" para volver al listado activo.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    try {
      await ref
          .read(tpvLocalDataSourceProvider)
          .reactivateEmployee(employee.id);
      await _load();
      _show('Empleado restaurado.');
    } catch (error) {
      _show('No se pudo restaurar el empleado: $error');
    }
  }

  Future<void> _deleteEmployeePermanently(TpvEmployee employee) async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo el administrador puede eliminar definitivamente empleados.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar empleado definitivamente'),
          content: Text(
            'Se eliminará de forma permanente "${employee.name}".\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
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

    try {
      await ref.read(tpvLocalDataSourceProvider).permanentlyDeleteEmployee(
            employeeId: employee.id,
            userId: session.userId,
          );
      await _load();
      _show('Empleado eliminado definitivamente.');
    } catch (error) {
      _show('No se pudo eliminar definitivamente el empleado: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final bool isAdmin = session?.isAdmin ?? false;

    return AppScaffold(
      title: 'Archivados',
      currentRoute: '/configuracion-archivados',
      showTopTabs: false,
      showBottomNavigationBar: true,
      onRefresh: _load,
      body: isAdmin ? _buildAdminView() : _buildAdminOnlyView(),
    );
  }

  Widget _buildAdminOnlyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: Color(0xFF64748B),
            ),
            SizedBox(height: 10),
            Text(
              'Solo el administrador puede acceder a esta vista.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: <Widget>[
        _buildCounters(),
        const SizedBox(height: 10),
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: _activeTab == _ArchivedTab.products
                ? 'Buscar producto archivado...'
                : _activeTab == _ArchivedTab.movements
                    ? 'Buscar por nombre o SKU...'
                    : _activeTab == _ArchivedTab.sales
                        ? 'Buscar por folio, cliente o usuario...'
                        : 'Buscar por nombre, código o usuario...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            suffixIcon: IconButton(
              tooltip: 'Actualizar',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<_ArchivedTab>(
          segments: const <ButtonSegment<_ArchivedTab>>[
            ButtonSegment<_ArchivedTab>(
              value: _ArchivedTab.products,
              icon: Icon(Icons.inventory_2_outlined),
              label: Text('Productos'),
            ),
            ButtonSegment<_ArchivedTab>(
              value: _ArchivedTab.movements,
              icon: Icon(Icons.swap_horiz_rounded),
              label: Text('Movimientos'),
            ),
            ButtonSegment<_ArchivedTab>(
              value: _ArchivedTab.sales,
              icon: Icon(Icons.receipt_long_rounded),
              label: Text('Ventas'),
            ),
            ButtonSegment<_ArchivedTab>(
              value: _ArchivedTab.employees,
              icon: Icon(Icons.badge_outlined),
              label: Text('Empleados'),
            ),
          ],
          selected: <_ArchivedTab>{_activeTab},
          onSelectionChanged: (Set<_ArchivedTab> value) {
            if (value.isEmpty) {
              return;
            }
            setState(() => _activeTab = value.first);
          },
        ),
        if (_activeTab == _ArchivedTab.movements) ...<Widget>[
          const SizedBox(height: 12),
          InventoryMovementTypeTabs(
            selectedType: _movementType,
            onChanged: (String value) {
              setState(() => _movementType = value);
              _load();
            },
          ),
        ],
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_activeTab == _ArchivedTab.products)
          _buildArchivedProducts()
        else if (_activeTab == _ArchivedTab.movements)
          _buildArchivedMovements()
        else if (_activeTab == _ArchivedTab.sales)
          _buildArchivedSales()
        else
          _buildArchivedEmployees(),
      ],
    );
  }

  Widget _buildCounters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        SizedBox(
          width: 220,
          child: _CounterCard(
            label: 'Productos archivados',
            value: _archivedProducts.length.toString(),
            icon: Icons.inventory_2_outlined,
          ),
        ),
        SizedBox(
          width: 220,
          child: _CounterCard(
            label: 'Movimientos archivados',
            value: _archivedMovements.length.toString(),
            icon: Icons.swap_horiz_rounded,
          ),
        ),
        SizedBox(
          width: 220,
          child: _CounterCard(
            label: 'Ventas archivadas',
            value: _archivedSales.length.toString(),
            icon: Icons.receipt_long_rounded,
          ),
        ),
        SizedBox(
          width: 220,
          child: _CounterCard(
            label: 'Empleados archivados',
            value: _archivedEmployees.length.toString(),
            icon: Icons.badge_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildArchivedProducts() {
    if (_archivedProducts.isEmpty) {
      return const _EmptyArchiveState(
        icon: Icons.inventory_2_outlined,
        message: 'No hay productos archivados.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ConfigSectionLabel(text: 'Productos dados de baja'),
        ..._archivedProducts.map((ArchivedProductView product) {
          return ArchivedProductCard(
            product: product,
            dateLabel: _formatDateTime(product.archivedAt),
            onRestore: () => _restoreProduct(product),
            onDeletePermanently: () => _deleteProductPermanently(product),
          );
        }),
      ],
    );
  }

  Widget _buildArchivedMovements() {
    if (_archivedMovements.isEmpty) {
      return const _EmptyArchiveState(
        icon: Icons.swap_horiz_rounded,
        message: 'No hay movimientos archivados con este filtro.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ConfigSectionLabel(text: 'Movimientos archivados'),
        ..._archivedMovements.map((InventoryArchivedMovementView movement) {
          return ArchivedMovementCard(
            movement: movement,
            createdAtLabel: _formatDateTime(movement.createdAt),
            voidedAtLabel: _formatDateTime(movement.voidedAt),
            onRestore: () => _restoreMovement(movement),
            onDeletePermanently: () => _deleteMovementPermanently(movement),
          );
        }),
      ],
    );
  }

  Widget _buildArchivedSales() {
    if (_archivedSales.isEmpty) {
      return const _EmptyArchiveState(
        icon: Icons.receipt_long_rounded,
        message: 'No hay ventas archivadas.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ConfigSectionLabel(text: 'Ventas archivadas'),
        ..._archivedSales.map((ArchivedSaleView sale) {
          return ArchivedSaleCard(
            sale: sale,
            createdAtLabel: _formatDateTime(sale.createdAt),
            archivedAtLabel: _formatDateTime(sale.archivedAt),
            totalLabel: (sale.totalCents / 100).toStringAsFixed(2),
            onRestore: () => _restoreSale(sale),
            onDeletePermanently: () => _deleteSalePermanently(sale),
          );
        }),
      ],
    );
  }

  Widget _buildArchivedEmployees() {
    if (_archivedEmployees.isEmpty) {
      return const _EmptyArchiveState(
        icon: Icons.badge_outlined,
        message: 'No hay empleados archivados.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ConfigSectionLabel(text: 'Empleados archivados'),
        ..._archivedEmployees.map((TpvEmployee employee) {
          return ArchivedEmployeeCard(
            employee: employee,
            onRestore: () => _restoreEmployee(employee),
            onDeletePermanently: () => _deleteEmployeePermanently(employee),
          );
        }),
      ],
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }
    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = months[dateTime.month - 1];
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month ${dateTime.year}, $hour:$minute';
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyArchiveState extends StatelessWidget {
  const _EmptyArchiveState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 28, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
