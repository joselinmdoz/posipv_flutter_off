import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../tpv/presentation/tpv_providers.dart';
import '../data/almacenes_local_datasource.dart';
import 'almacenes_providers.dart';

class AlmacenesPage extends ConsumerStatefulWidget {
  const AlmacenesPage({super.key});

  @override
  ConsumerState<AlmacenesPage> createState() => _AlmacenesPageState();
}

class _AlmacenesPageState extends ConsumerState<AlmacenesPage> {
  List<WarehouseWithStock> _warehouses = <WarehouseWithStock>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => _loading = true);

    try {
      final ds = ref.read(almacenesLocalDataSourceProvider);
      await ds.ensureDefaultWarehouse();
      final List<WarehouseWithStock> data = await ds.listWarehousesWithStock();

      if (!mounted) {
        return;
      }
      setState(() {
        _warehouses = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar almacenes: $e')),
      );
    }
  }

  Future<void> _openWarehouseDetails(Warehouse warehouse) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _WarehouseDetailsPage(warehouse: warehouse),
      ),
    );
    await _loadWarehouses();
  }

  Future<void> _confirmDelete(Warehouse warehouse) async {
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

  Widget _buildWarehouseCard(WarehouseWithStock wws) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isCentral = wws.warehouse.warehouseType == 'Central';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFDDD5EF),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openWarehouseDetails(wws.warehouse),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCentral
                      ? (isDark
                          ? const Color(0xFF1F3A34)
                          : const Color(0xFFE7F6F1))
                      : (isDark
                          ? const Color(0xFF312948)
                          : const Color(0xFFE8E2F4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCentral
                      ? Icons.storefront_rounded
                      : Icons.point_of_sale_rounded,
                  color: isCentral
                      ? const Color(0xFF148A65)
                      : const Color(0xFF5B4B8A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      wws.warehouse.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCentral
                                ? const Color(0xFF148A65)
                                : const Color(0xFF5B4B8A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            wws.warehouse.warehouseType,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${wws.totalProducts} productos',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${wws.totalQuantity.toStringAsFixed(0)})',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFE1487D),
                onPressed: () => _confirmDelete(wws.warehouse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Almacenes',
      currentRoute: '/almacenes',
      onRefresh: _loadWarehouses,
      floatingActionButton: FloatingActionButton.small(
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
                const SnackBar(content: Text('Registro creado correctamente.')),
              );
            }
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWarehouses,
              child: _warehouses.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const <Widget>[
                        SizedBox(height: 32),
                        Center(
                            child: Text('No hay almacenes. Usa + para crear.')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 90),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _warehouses.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _buildWarehouseCard(_warehouses[index]);
                      },
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Nuevo Almacén',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Nombre',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF272238),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Ej: Tienda Central, Sucursal 1',
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tipo de almacén',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF272238),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TypeOption(
                    label: 'Central',
                    icon: Icons.storefront_rounded,
                    isSelected: _selectedType == 'Central',
                    color: const Color(0xFF148A65),
                    onTap: () => setState(() => _selectedType = 'Central'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeOption(
                    label: 'TPV',
                    icon: Icons.point_of_sale_rounded,
                    isSelected: _selectedType == 'TPV',
                    color: const Color(0xFF5B4B8A),
                    onTap: () => setState(() => _selectedType = 'TPV'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4B8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crear almacén',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF342E46) : const Color(0xFFDDD5EF)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: isSelected ? color : const Color(0xFF8B83A8)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : const Color(0xFF655D83),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseDetailsPage extends ConsumerStatefulWidget {
  const _WarehouseDetailsPage({required this.warehouse});

  final Warehouse warehouse;

  @override
  ConsumerState<_WarehouseDetailsPage> createState() =>
      _WarehouseDetailsPageState();
}

class _WarehouseDetailsPageState extends ConsumerState<_WarehouseDetailsPage> {
  late TextEditingController _nameCtrl;
  late String _selectedType;
  bool _isEditing = false;
  bool _saving = false;
  List<StockBalanceWithProduct> _stock = <StockBalanceWithProduct>[];
  bool _loadingStock = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.warehouse.name);
    _selectedType = widget.warehouse.warehouseType;
    _loadStock();
  }

  @override
  void dispose() {
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
          _loadingStock = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStock = false);
      }
    }
  }

  Future<void> _saveChanges() async {
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
        title: Text(_isEditing ? 'Editar Almacén' : 'Detalles'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: <Widget>[
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined),
            )
          else
            IconButton(
              onPressed: _saving ? null : _saveChanges,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Información del almacén
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_isEditing) ...<Widget>[
                    Text(
                      'Nombre',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF211D2D)
                            : const Color(0xFFF5F3FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tipo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            label: 'TPV',
                            isSelected: _selectedType == 'TPV',
                            color: const Color(0xFF5B4B8A),
                            onTap: () => setState(() => _selectedType = 'TPV'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...<Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isCentral
                                ? (isDark
                                    ? const Color(0xFF1F3A34)
                                    : const Color(0xFFE7F6F1))
                                : (isDark
                                    ? const Color(0xFF312948)
                                    : const Color(0xFFE8E2F4)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isCentral
                                ? Icons.storefront_rounded
                                : Icons.point_of_sale_rounded,
                            color: isCentral
                                ? const Color(0xFF148A65)
                                : const Color(0xFF5B4B8A),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.warehouse.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isCentral
                                      ? const Color(0xFF148A65)
                                      : const Color(0xFF5B4B8A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.warehouse.warehouseType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.inventory_2_outlined,
                        color: scheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stock en este almacén',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_stock.length} productos',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingStock)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_stock.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No hay productos en stock',
                          style: TextStyle(color: Color(0xFF8B83A8)),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stock.length > 10 ? 10 : _stock.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final item = _stock[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF272238),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SKU: ${item.product.sku}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B83A8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    item.stockBalance.qty.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: item.stockBalance.qty > 0
                                          ? const Color(0xFF148A65)
                                          : const Color(0xFFE1487D),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(item.product.priceCents),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8B83A8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (_stock.length > 10) ...<Widget>[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'y ${_stock.length - 10} más...',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B83A8),
                        ),
                      ),
                    ),
                  ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : const Color(0xFFF5F3FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : const Color(0xFF655D83),
            ),
          ),
        ),
      ),
    );
  }
}
