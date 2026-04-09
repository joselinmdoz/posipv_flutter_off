import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/security/app_permissions.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../tpv/presentation/tpv_providers.dart';
import '../data/almacenes_local_datasource.dart';
import 'almacenes_providers.dart';

class AlmacenesPage extends ConsumerStatefulWidget {
  const AlmacenesPage({super.key});

  @override
  ConsumerState<AlmacenesPage> createState() => _AlmacenesPageState();
}

class _AlmacenesPageState extends ConsumerState<AlmacenesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<WarehouseWithStock> _warehouses = <WarehouseWithStock>[];
  List<WarehouseWithStock> _filteredWarehouses = <WarehouseWithStock>[];
  bool _loading = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadWarehouses();
    });
  }

  Future<void> _loadWarehouses() async {
    final PerfTrace trace = PerfTrace('almacenes.load');
    setState(() => _loading = true);

    try {
      final ds = ref.read(almacenesLocalDataSourceProvider);
      await ds.ensureDefaultWarehouse();
      final List<WarehouseWithStock> data = await ds.listWarehousesWithStock();
      trace.mark('consulta completada');

      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _warehouses = data;
        _filteredWarehouses = data;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar almacenes: $e')),
      );
    }
  }

  Future<void> _openWarehouseDetails(Warehouse warehouse) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _WarehouseDetailsPage(
          warehouse: warehouse,
          canManage: _canManageWarehouses(),
        ),
      ),
    );
    await _loadWarehouses();
  }

  Future<void> _confirmDelete(Warehouse warehouse) async {
    if (!_canManageWarehouses()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para gestionar almacenes.'),
        ),
      );
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar almacén'),
          content: Text('Se dará de baja el almacén "${warehouse.name}".'),
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

    try {
      await ref
          .read(almacenesLocalDataSourceProvider)
          .deactivateWarehouse(warehouse.id);
      await _loadWarehouses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Almacén eliminado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar el almacén: $e')),
        );
      }
    }
  }

  void _filterWarehouses(String query) {
    final String q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredWarehouses = _warehouses;
      } else {
        _filteredWarehouses = _warehouses.where((WarehouseWithStock wws) {
          final String name = wws.warehouse.name.toLowerCase();
          final String type = wws.warehouse.warehouseType.toLowerCase();
          return name.contains(q) || type.contains(q);
        }).toList();
      }
    });
  }

  Widget _buildWarehouseCard(WarehouseWithStock wws) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final String type = wws.warehouse.warehouseType;
    final bool isCentral = type == 'Central';

    IconData iconData = Icons.inventory_2_rounded;
    if (type == 'TPV') iconData = Icons.storefront_rounded;
    if (type == 'Central') iconData = Icons.warehouse_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openWarehouseDetails(wws.warehouse),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1152D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  color: const Color(0xFF1152D4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            wws.warehouse.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: scheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCentral
                                ? const Color(0xFF1152D4).withValues(alpha: 0.1)
                                : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isCentral
                                  ? const Color(0xFF1152D4)
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                        children: <TextSpan>[
                          TextSpan(text: '${wws.totalProducts} productos '),
                          TextSpan(
                            text:
                                '(${wws.totalQuantity.toStringAsFixed(0)} total)',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_canManageWarehouses())
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onSelected: (String value) {
                    if (value == 'edit') _openWarehouseDetails(wws.warehouse);
                    if (value == 'delete') _confirmDelete(wws.warehouse);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canManageWarehouses() {
    final session = ref.read(currentSessionProvider);
    return session?.hasPermission(AppPermissionKeys.warehousesManage) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    final bool canManageWarehouses =
        ref.watch(currentSessionProvider)?.hasPermission(
                  AppPermissionKeys.warehousesManage,
                ) ??
            false;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: 'Almacenes',
      currentRoute: '/almacenes',
      onRefresh: _loadWarehouses,
      useDefaultActions: false,
      appBarActions: const <Widget>[],
      floatingActionButton: license.canWrite && canManageWarehouses
          ? AppAddActionButton(
              currentRoute: '/almacenes',
              iconSize: 32,
              margin: const EdgeInsets.only(bottom: 20, right: 10),
              onPressed: () async {
                final NavigatorState navigator = Navigator.of(context);
                final ScaffoldMessengerState messenger =
                    ScaffoldMessenger.of(context);
                final bool? created = await navigator.push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const _WarehouseFormPage(),
                    fullscreenDialog: true,
                  ),
                );
                if (created == true) {
                  await _loadWarehouses();
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Registro creado correctamente.'),
                      ),
                    );
                  }
                }
              },
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWarehouses,
              displacement: 20,
              color: const Color(0xFF1152D4),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _filterWarehouses,
                          decoration: InputDecoration(
                            hintText: 'Buscar almacenes por nombre o tipo...',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_filteredWarehouses.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.warehouse_outlined,
                              size: 64,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchCtrl.text.isEmpty
                                  ? 'No hay almacenes configurados'
                                  : 'No se encontraron resultados',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final WarehouseWithStock warehouse =
                                _filteredWarehouses[index];
                            return KeyedSubtree(
                              key: ValueKey<String>(warehouse.warehouse.id),
                              child: _buildWarehouseCard(warehouse),
                            );
                          },
                          childCount: _filteredWarehouses.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _WarehouseFormPage extends ConsumerStatefulWidget {
  const _WarehouseFormPage();

  @override
  ConsumerState<_WarehouseFormPage> createState() => _WarehouseFormPageState();
}

class _WarehouseFormPageState extends ConsumerState<_WarehouseFormPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  String _selectedType = 'Central';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bool canManage = ref.read(currentSessionProvider)?.hasPermission(
              AppPermissionKeys.warehousesManage,
            ) ??
        false;
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para gestionar almacenes.'),
        ),
      );
      return;
    }
    final String name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_selectedType == 'TPV') {
        await ref.read(tpvLocalDataSourceProvider).createTerminal(name: name);
      } else {
        final ds = ref.read(almacenesLocalDataSourceProvider);
        await ds.createWarehouse(
          name: name,
          warehouseType: _selectedType,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el almacén: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canManage = ref.watch(currentSessionProvider)?.hasPermission(
              AppPermissionKeys.warehousesManage,
            ) ??
        false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Nuevo Almacén',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: !canManage
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No tienes permisos para gestionar almacenes.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Información General',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nombre del almacén',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Ej: Tienda Central, Sucursal 1',
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Tipo de almacén',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona la función que cumplirá este almacén.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _TypeOption(
                          label: 'Central',
                          icon: Icons.warehouse_rounded,
                          isSelected: _selectedType == 'Central',
                          color: const Color(0xFF148A65),
                          onTap: () =>
                              setState(() => _selectedType = 'Central'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TypeOption(
                          label: 'TPV',
                          icon: Icons.store_rounded,
                          isSelected: _selectedType == 'TPV',
                          color: const Color(0xFF1152D4),
                          onTap: () => setState(() => _selectedType = 'TPV'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1152D4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Crear almacén',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color
                    : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF8FAFC)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? color
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseDetailsPage extends ConsumerStatefulWidget {
  const _WarehouseDetailsPage({
    required this.warehouse,
    required this.canManage,
  });

  final Warehouse warehouse;
  final bool canManage;

  @override
  ConsumerState<_WarehouseDetailsPage> createState() =>
      _WarehouseDetailsPageState();
}

class _WarehouseDetailsPageState extends ConsumerState<_WarehouseDetailsPage> {
  static const int _stockPageSize = 10;

  late TextEditingController _nameCtrl;
  late String _selectedType;
  bool _isEditing = false;
  bool _saving = false;
  List<StockBalanceWithProduct> _stock = <StockBalanceWithProduct>[];
  bool _loadingStock = true;
  int _stockPageIndex = 0;
  final ScrollController _stockScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.warehouse.name);
    _selectedType = widget.warehouse.warehouseType;
    _loadStock();
  }

  @override
  void dispose() {
    _stockScrollController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() => _loadingStock = true);
    try {
      final ds = ref.read(almacenesLocalDataSourceProvider);
      final stock = await ds.getWarehouseStock(widget.warehouse.id);
      if (mounted) {
        setState(() {
          _stock = stock;
          _stockPageIndex = 0;
          _loadingStock = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStock = false);
      }
    }
  }

  int get _stockPageCount {
    if (_stock.isEmpty) {
      return 1;
    }
    return (_stock.length / _stockPageSize).ceil();
  }

  List<StockBalanceWithProduct> get _currentStockPageItems {
    if (_stock.isEmpty) {
      return const <StockBalanceWithProduct>[];
    }
    final int start = _stockPageIndex * _stockPageSize;
    if (start >= _stock.length) {
      return const <StockBalanceWithProduct>[];
    }
    final int end = math.min(start + _stockPageSize, _stock.length);
    return _stock.sublist(start, end);
  }

  void _goToStockPage(int pageIndex) {
    final int safeIndex = pageIndex.clamp(0, _stockPageCount - 1);
    if (safeIndex == _stockPageIndex) {
      return;
    }
    setState(() => _stockPageIndex = safeIndex);
    if (_stockScrollController.hasClients) {
      _stockScrollController.jumpTo(0);
    }
  }

  Future<void> _saveChanges() async {
    if (!widget.canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para gestionar almacenes.'),
        ),
      );
      return;
    }
    final String name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final ds = ref.read(almacenesLocalDataSourceProvider);
      await ds.updateWarehouse(
        id: widget.warehouse.id,
        name: name,
        warehouseType: _selectedType,
      );

      if (!mounted) {
        return;
      }
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Almacén actualizado.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  String _formatCurrency(int cents) {
    return '\$${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  bool _isOutOfStock(double qty) => qty <= 0.000001;

  bool _isLowStock(double qty) => qty > 0 && qty <= 10;

  Color _stockLabelColor(double qty, bool isDark) {
    if (_isOutOfStock(qty)) {
      return isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    }
    if (_isLowStock(qty)) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    }
    return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
  }

  Color _stockBgColor(double qty, bool isDark) {
    if (_isOutOfStock(qty)) {
      return isDark
          ? const Color(0xFFE11D48).withValues(alpha: 0.12)
          : const Color(0xFFFFF1F2);
    }
    if (_isLowStock(qty)) {
      return isDark
          ? const Color(0xFFD97706).withValues(alpha: 0.12)
          : const Color(0xFFFEF3C7);
    }
    return isDark
        ? const Color(0xFF059669).withValues(alpha: 0.12)
        : const Color(0xFFECFDF5);
  }

  Widget _buildProductThumb(String? imagePath, bool isDark) {
    final Color fallbackBg =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    Widget fallback() {
      return Container(
        color: fallbackBg,
        child: Icon(
          Icons.inventory_2_rounded,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          size: 22,
        ),
      );
    }

    final String resolved = (imagePath ?? '').trim();
    if (resolved.isEmpty) {
      return fallback();
    }
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        cacheWidth: 200,
        errorBuilder: (_, __, ___) => fallback(),
      );
    }
    return Image.file(
      File(resolved),
      fit: BoxFit.cover,
      cacheWidth: 200,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isCentral = _selectedType == 'Central';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          _isEditing ? 'Configurar Almacén' : 'Detalles de Almacén',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: <Widget>[
          if (!_isEditing && widget.canManage)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: IconButton.filledTonal(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded, size: 20),
              ),
            )
          else if (widget.canManage)
            IconButton(
              onPressed: _saving ? null : _saveChanges,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, color: Color(0xFF148A65)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Información del almacén
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_isEditing) ...<Widget>[
                    Text(
                      'Nombre',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tipo de almacén',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _TypeChip(
                            label: 'Central',
                            isSelected: _selectedType == 'Central',
                            color: const Color(0xFF148A65),
                            onTap: () =>
                                setState(() => _selectedType = 'Central'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypeChip(
                            label: 'TPV',
                            isSelected: _selectedType == 'TPV',
                            color: const Color(0xFF1152D4),
                            onTap: () => setState(() => _selectedType = 'TPV'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...<Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isCentral
                                  ? <Color>[
                                      const Color(0xFF148A65),
                                      const Color(0xFF0D6B4E)
                                    ]
                                  : <Color>[
                                      const Color(0xFF1152D4),
                                      const Color(0xFF0A3C9F)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: (isCentral
                                        ? const Color(0xFF148A65)
                                        : const Color(0xFF1152D4))
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isCentral
                                ? Icons.warehouse_rounded
                                : Icons.store_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.warehouse.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isCentral
                                          ? const Color(0xFF148A65)
                                          : const Color(0xFF1152D4))
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.warehouse.warehouseType.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: isCentral
                                        ? const Color(0xFF148A65)
                                        : const Color(0xFF1152D4),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stock del almacén
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: scheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Stock del almacén',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_stock.length} ítems',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loadingStock)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_stock.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin productos en stock',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (BuildContext context) {
                        final List<StockBalanceWithProduct> pageItems =
                            _currentStockPageItems;
                        final int totalPages = _stockPageCount;
                        final int startItem = pageItems.isEmpty
                            ? 0
                            : (_stockPageIndex * _stockPageSize) + 1;
                        final int endItem = pageItems.isEmpty
                            ? 0
                            : startItem + pageItems.length - 1;
                        final double stockListHeight =
                            (MediaQuery.sizeOf(context).height * 0.34)
                                .clamp(220.0, 420.0);

                        return Column(
                          children: <Widget>[
                            SizedBox(
                              height: stockListHeight,
                              child: Scrollbar(
                                controller: _stockScrollController,
                                thumbVisibility: true,
                                child: ListView.separated(
                                  key: PageStorageKey<String>(
                                    'almacen-detail-stock-page-$_stockPageIndex',
                                  ),
                                  controller: _stockScrollController,
                                  itemCount: pageItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final item = pageItems[index];
                                    final double qty = item.stockBalance.qty;
                                    final Color cardColor = isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC);
                                    final Color borderColor = isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0);
                                    return KeyedSubtree(
                                      key: ValueKey<String>(item.product.id),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border:
                                              Border.all(color: borderColor),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: <Widget>[
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: SizedBox(
                                                  width: 62,
                                                  height: 62,
                                                  child: _buildProductThumb(
                                                    item.product.imagePath,
                                                    isDark,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: <Widget>[
                                                    Text(
                                                      item.product.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: theme.colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: <Widget>[
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                _stockBgColor(
                                                              qty,
                                                              isDark,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              20,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Stock: ${_formatQty(qty)}',
                                                            style: TextStyle(
                                                              color:
                                                                  _stockLabelColor(
                                                                qty,
                                                                isDark,
                                                              ),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            'SKU: ${item.product.sku}',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatCurrency(
                                                  item.product.priceCents,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF1152D4),
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
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    'Mostrando $startItem-$endItem de ${_stock.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (totalPages > 1) ...<Widget>[
                                  IconButton.filledTonal(
                                    onPressed: _stockPageIndex > 0
                                        ? () => _goToStockPage(
                                              _stockPageIndex - 1,
                                            )
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '${_stockPageIndex + 1}/$totalPages',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: _stockPageIndex + 1 < totalPages
                                        ? () => _goToStockPage(
                                              _stockPageIndex + 1,
                                            )
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? color
                  : (isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
