import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../productos/data/productos_local_datasource.dart';
import '../../productos/presentation/productos_providers.dart';
import 'widgets/catalog_search_field.dart';
import 'widgets/measurement_unit_card.dart';
import 'widgets/measurement_unit_type_tabs.dart';

class MeasurementUnitsSettingsPage extends ConsumerStatefulWidget {
  const MeasurementUnitsSettingsPage({super.key});

  @override
  ConsumerState<MeasurementUnitsSettingsPage> createState() =>
      _MeasurementUnitsSettingsPageState();
}

class _MeasurementUnitsSettingsPageState
    extends ConsumerState<MeasurementUnitsSettingsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  MeasurementUnitCatalog _catalog = const MeasurementUnitCatalog(
    types: <MeasurementUnitTypeModel>[],
    units: <MeasurementUnitModel>[],
  );
  String _selectedTypeId = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadCatalog();
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

  Future<void> _loadCatalog() async {
    setState(() => _loading = true);
    try {
      final MeasurementUnitCatalog catalog = await ref
          .read(productosLocalDataSourceProvider)
          .loadMeasurementUnitCatalog();
      if (!mounted) {
        return;
      }
      final Set<String> typeIds = catalog.types
          .where((MeasurementUnitTypeModel row) => row.isActive)
          .map((MeasurementUnitTypeModel row) => row.id)
          .toSet();
      setState(() {
        _catalog = catalog;
        if (_selectedTypeId != 'all' && !typeIds.contains(_selectedTypeId)) {
          _selectedTypeId = 'all';
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar unidades: $error');
    }
  }

  Future<void> _openTypeManager() async {
    await context.push('/configuracion-tipos-unidad');
    if (!mounted) {
      return;
    }
    await _loadCatalog();
  }

  Future<void> _openCreateDialog() async {
    final _MeasurementUnitDraft? draft = await _showUnitDialog();
    if (draft == null) {
      return;
    }
    try {
      await ref.read(productosLocalDataSourceProvider).upsertMeasurementUnit(
            typeId: draft.typeId,
            symbol: draft.symbol,
            name: draft.name,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadCatalog();
      _show('Unidad creada correctamente.');
    } catch (error) {
      _show('No se pudo crear la unidad: $error');
    }
  }

  Future<void> _openEditDialog(MeasurementUnitModel unit) async {
    final _MeasurementUnitDraft? draft = await _showUnitDialog(unit: unit);
    if (draft == null) {
      return;
    }
    try {
      await ref.read(productosLocalDataSourceProvider).upsertMeasurementUnit(
            unitId: unit.id,
            typeId: draft.typeId,
            symbol: draft.symbol,
            name: draft.name,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadCatalog();
      _show('Unidad actualizada.');
    } catch (error) {
      _show('No se pudo actualizar la unidad: $error');
    }
  }

  Future<void> _toggleActive(MeasurementUnitModel unit, bool isActive) async {
    try {
      await ref.read(productosLocalDataSourceProvider).setMeasurementUnitActive(
            unitId: unit.id,
            isActive: isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadCatalog();
    } catch (error) {
      _show('No se pudo actualizar estado: $error');
    }
  }

  List<MeasurementUnitTypeModel> _visibleTypes() {
    return _catalog.types
        .where((MeasurementUnitTypeModel row) => row.isActive)
        .toList(growable: false);
  }

  List<MeasurementUnitModel> _filteredUnits() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    final Set<String> activeTypeIds = _catalog.types
        .where((MeasurementUnitTypeModel row) => row.isActive)
        .map((MeasurementUnitTypeModel row) => row.id)
        .toSet();

    return _catalog.units.where((MeasurementUnitModel row) {
      if (!row.isActive) {
        return false;
      }
      if (!activeTypeIds.contains(row.typeId)) {
        return false;
      }
      if (_selectedTypeId != 'all' && row.typeId != _selectedTypeId) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return row.name.toLowerCase().contains(query) ||
          row.symbol.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<_MeasurementUnitDraft?> _showUnitDialog({
    MeasurementUnitModel? unit,
  }) async {
    final List<MeasurementUnitTypeModel> types =
        _catalog.types.where((MeasurementUnitTypeModel row) {
      if (row.isActive) {
        return true;
      }
      return unit != null && unit.typeId == row.id;
    }).toList(growable: false);
    if (types.isEmpty) {
      _show('Crea primero un tipo de unidad activo.');
      return null;
    }

    final TextEditingController symbolCtrl = TextEditingController(
      text: unit?.symbol ?? '',
    );
    final TextEditingController nameCtrl = TextEditingController(
      text: unit?.name ?? '',
    );
    String typeId = unit?.typeId ?? types.first.id;
    bool isActive = unit?.isActive ?? true;

    return showDialog<_MeasurementUnitDraft>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(unit == null ? 'Nueva unidad' : 'Editar unidad'),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: typeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de unidad',
                        border: OutlineInputBorder(),
                      ),
                      items: types
                          .map(
                            (MeasurementUnitTypeModel row) =>
                                DropdownMenuItem<String>(
                              value: row.id,
                              child: Text(row.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() => typeId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: symbolCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Símbolo',
                        hintText: 'Ej. kg, m, ud',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej. Kilogramo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Unidad activa'),
                      onChanged: (bool value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final String symbol = symbolCtrl.text.trim();
                    final String name = nameCtrl.text.trim();
                    if (symbol.isEmpty || name.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      _MeasurementUnitDraft(
                        typeId: typeId,
                        symbol: symbol,
                        name: name,
                        isActive: isActive,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _typeNameOf(String typeId) {
    for (final MeasurementUnitTypeModel row in _catalog.types) {
      if (row.id == typeId) {
        return row.name;
      }
    }
    return 'Sin tipo';
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
    final List<MeasurementUnitTypeModel> types = _visibleTypes();
    final List<MeasurementUnitModel> units = _filteredUnits();

    return AppScaffold(
      title: 'Unidades de medida',
      currentRoute: '/configuracion-unidades-medida',
      showTopTabs: false,
      showBottomNavigationBar: true,
      floatingActionButton: AppAddActionButton(
        heroTag: 'add-measurement-unit',
        onPressed: _openCreateDialog,
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Tipos de unidad',
          onPressed: _openTypeManager,
          icon: const Icon(Icons.category_outlined),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCatalog,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: <Widget>[
                  const Text(
                    'Define unidades por tipo para estandarizar inventario y productos.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CatalogSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar por símbolo o nombre...',
                  ),
                  const SizedBox(height: 12),
                  MeasurementUnitTypeTabs(
                    types: types,
                    selectedTypeId: _selectedTypeId,
                    onChanged: (String value) {
                      setState(() => _selectedTypeId = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${units.length} unidad(es) activas',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (units.isEmpty)
                    const _EmptyState(
                      text:
                          'No hay unidades activas para el filtro seleccionado.',
                    )
                  else
                    ...units.map((MeasurementUnitModel row) {
                      return MeasurementUnitCard(
                        key: ValueKey<String>(row.id),
                        unit: row,
                        typeName: _typeNameOf(row.typeId),
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

class _MeasurementUnitDraft {
  const _MeasurementUnitDraft({
    required this.typeId,
    required this.symbol,
    required this.name,
    required this.isActive,
  });

  final String typeId;
  final String symbol;
  final String name;
  final bool isActive;
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
