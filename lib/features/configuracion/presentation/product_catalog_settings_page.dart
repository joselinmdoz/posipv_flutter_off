import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../productos/data/productos_local_datasource.dart';
import '../../productos/presentation/productos_providers.dart';
import 'widgets/catalog_search_field.dart';
import 'widgets/product_catalog_entry_card.dart';
import 'widgets/product_catalog_kind_tabs.dart';

class ProductCatalogSettingsPage extends ConsumerStatefulWidget {
  const ProductCatalogSettingsPage({super.key});

  @override
  ConsumerState<ProductCatalogSettingsPage> createState() =>
      _ProductCatalogSettingsPageState();
}

class _ProductCatalogSettingsPageState
    extends ConsumerState<ProductCatalogSettingsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  ProductCatalogKind _selectedKind = ProductCatalogKind.type;
  List<ProductCatalogEntry> _entries = const <ProductCatalogEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadEntries();
    });
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    try {
      final List<ProductCatalogEntry> rows = await ref
          .read(productosLocalDataSourceProvider)
          .listCatalogEntries(_selectedKind);
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar el catálogo: $error');
    }
  }

  Future<void> _changeKind(ProductCatalogKind nextKind) async {
    if (nextKind == _selectedKind) {
      return;
    }
    setState(() {
      _selectedKind = nextKind;
      _entries = const <ProductCatalogEntry>[];
    });
    await _loadEntries();
  }

  Future<void> _openCreateDialog() async {
    final String title = _selectedKind == ProductCatalogKind.type
        ? 'Nuevo tipo de producto'
        : 'Nueva categoría';
    final String label = _selectedKind == ProductCatalogKind.type
        ? 'Nombre del tipo'
        : 'Nombre de la categoría';
    final String? value = await _showValueDialog(title: title, label: label);
    if (value == null) {
      return;
    }
    try {
      await ref.read(productosLocalDataSourceProvider).addCatalogValue(
            kind: _selectedKind,
            value: value,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadEntries();
      _show('Elemento creado correctamente.');
    } catch (error) {
      _show('No se pudo crear el elemento: $error');
    }
  }

  Future<void> _openEditDialog(ProductCatalogEntry entry) async {
    final String title = _selectedKind == ProductCatalogKind.type
        ? 'Editar tipo de producto'
        : 'Editar categoría';
    final String label = _selectedKind == ProductCatalogKind.type
        ? 'Nombre del tipo'
        : 'Nombre de la categoría';
    final String? value = await _showValueDialog(
      title: title,
      label: label,
      initialValue: entry.value,
    );
    if (value == null) {
      return;
    }
    try {
      await ref.read(productosLocalDataSourceProvider).renameCatalogValue(
            kind: _selectedKind,
            itemId: entry.id,
            nextValue: value,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadEntries();
      _show('Elemento actualizado.');
    } catch (error) {
      _show('No se pudo actualizar: $error');
    }
  }

  Future<void> _toggleActive(ProductCatalogEntry entry, bool isActive) async {
    try {
      await ref.read(productosLocalDataSourceProvider).setCatalogValueActive(
            kind: _selectedKind,
            itemId: entry.id,
            isActive: isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadEntries();
    } catch (error) {
      _show('No se pudo actualizar el estado: $error');
    }
  }

  List<ProductCatalogEntry> _filteredEntries() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _entries;
    }
    return _entries.where((ProductCatalogEntry row) {
      return row.value.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<String?> _showValueDialog({
    required String title,
    required String label,
    String? initialValue,
  }) {
    final TextEditingController ctrl = TextEditingController(
      text: initialValue ?? '',
    );
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final String value = ctrl.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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
    final List<ProductCatalogEntry> visible = _filteredEntries();
    final String subtitle = _selectedKind == ProductCatalogKind.type
        ? 'Administra tipos de producto para clasificar tu catálogo.'
        : 'Administra categorías para agrupar productos.';

    return AppScaffold(
      title: 'Catálogo de productos',
      currentRoute: '/configuracion-catalogos-producto',
      showTopTabs: false,
      showBottomNavigationBar: true,
      floatingActionButton: AppAddActionButton(
        heroTag: 'add-product-catalog-entry',
        onPressed: _openCreateDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: <Widget>[
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CatalogSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar por nombre...',
                  ),
                  const SizedBox(height: 12),
                  ProductCatalogKindTabs(
                    selected: _selectedKind,
                    onChanged: _changeKind,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${visible.length} elemento(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (visible.isEmpty)
                    _EmptyState(
                      text: 'No hay elementos para mostrar con ese filtro.',
                    )
                  else
                    ...visible.map((ProductCatalogEntry row) {
                      return ProductCatalogEntryCard(
                        key: ValueKey<String>(row.id),
                        entry: row,
                        onEdit: () => _openEditDialog(row),
                        onToggleActive: (bool value) =>
                            _toggleActive(row, value),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
