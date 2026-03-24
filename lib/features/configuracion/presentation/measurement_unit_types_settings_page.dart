import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../productos/data/productos_local_datasource.dart';
import '../../productos/presentation/productos_providers.dart';
import 'widgets/catalog_search_field.dart';
import 'widgets/measurement_unit_type_card.dart';

class MeasurementUnitTypesSettingsPage extends ConsumerStatefulWidget {
  const MeasurementUnitTypesSettingsPage({super.key});

  @override
  ConsumerState<MeasurementUnitTypesSettingsPage> createState() =>
      _MeasurementUnitTypesSettingsPageState();
}

class _MeasurementUnitTypesSettingsPageState
    extends ConsumerState<MeasurementUnitTypesSettingsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  MeasurementUnitCatalog _catalog = const MeasurementUnitCatalog(
    types: <MeasurementUnitTypeModel>[],
    units: <MeasurementUnitModel>[],
  );
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
      setState(() {
        _catalog = catalog;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar tipos: $error');
    }
  }

  Future<void> _openCreateDialog() async {
    final _MeasurementUnitTypeDraft? draft = await _showTypeDialog();
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(productosLocalDataSourceProvider)
          .upsertMeasurementUnitType(
            name: draft.name,
            description: draft.description,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadCatalog();
      _show('Tipo de unidad creado.');
    } catch (error) {
      _show('No se pudo crear el tipo: $error');
    }
  }

  Future<void> _openEditDialog(MeasurementUnitTypeModel type) async {
    final _MeasurementUnitTypeDraft? draft = await _showTypeDialog(type: type);
    if (draft == null) {
      return;
    }
    try {
      await ref
          .read(productosLocalDataSourceProvider)
          .upsertMeasurementUnitType(
            typeId: type.id,
            name: draft.name,
            description: draft.description,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadCatalog();
      _show('Tipo de unidad actualizado.');
    } catch (error) {
      _show('No se pudo actualizar el tipo: $error');
    }
  }

  Future<void> _toggleActive(
    MeasurementUnitTypeModel type,
    bool isActive,
  ) async {
    try {
      await ref
          .read(productosLocalDataSourceProvider)
          .setMeasurementUnitTypeActive(
            typeId: type.id,
            isActive: isActive,
          );
      if (!mounted) {
        return;
      }
      ref.read(productosCatalogRevisionProvider.notifier).state += 1;
      await _loadCatalog();
    } catch (error) {
      _show('No se pudo cambiar estado: $error');
    }
  }

  List<MeasurementUnitTypeModel> _filteredTypes() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _catalog.types;
    }
    return _catalog.types.where((MeasurementUnitTypeModel row) {
      return row.name.toLowerCase().contains(query) ||
          row.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  int _unitsCountForType(String typeId, {required bool onlyActive}) {
    int total = 0;
    for (final MeasurementUnitModel row in _catalog.units) {
      if (row.typeId != typeId) {
        continue;
      }
      if (onlyActive && !row.isActive) {
        continue;
      }
      total++;
    }
    return total;
  }

  Future<_MeasurementUnitTypeDraft?> _showTypeDialog({
    MeasurementUnitTypeModel? type,
  }) {
    final TextEditingController nameCtrl = TextEditingController(
      text: type?.name ?? '',
    );
    final TextEditingController descCtrl = TextEditingController(
      text: type?.description ?? '',
    );
    bool isActive = type?.isActive ?? true;

    return showDialog<_MeasurementUnitTypeDraft>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                type == null ? 'Nuevo tipo de unidad' : 'Editar tipo de unidad',
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej. Longitud',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Describe para qué se utilizará este tipo.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tipo activo'),
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
                    final String name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      _MeasurementUnitTypeDraft(
                        name: name,
                        description: descCtrl.text.trim(),
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
    final List<MeasurementUnitTypeModel> types = _filteredTypes();

    return AppScaffold(
      title: 'Tipos de unidad',
      currentRoute: '/configuracion-tipos-unidad',
      showTopTabs: false,
      showBottomNavigationBar: true,
      floatingActionButton: AppAddActionButton(
        heroTag: 'add-measurement-unit-type',
        onPressed: _openCreateDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCatalog,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: <Widget>[
                  const Text(
                    'Organiza tus unidades por tipo para mantener control y consistencia.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CatalogSearchField(
                    controller: _searchCtrl,
                    hintText: 'Buscar tipos...',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${types.length} tipo(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (types.isEmpty)
                    const _EmptyState(
                      text: 'No hay tipos de unidad para mostrar.',
                    )
                  else
                    ...types.map((MeasurementUnitTypeModel row) {
                      return MeasurementUnitTypeCard(
                        key: ValueKey<String>(row.id),
                        type: row,
                        unitsCount: _unitsCountForType(
                          row.id,
                          onlyActive: false,
                        ),
                        activeUnitsCount: _unitsCountForType(
                          row.id,
                          onlyActive: true,
                        ),
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

class _MeasurementUnitTypeDraft {
  const _MeasurementUnitTypeDraft({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String description;
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
