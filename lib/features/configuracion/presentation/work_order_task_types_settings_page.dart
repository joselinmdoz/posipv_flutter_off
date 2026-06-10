import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../pedidos/data/pedidos_local_datasource.dart';
import '../../pedidos/presentation/pedidos_providers.dart';
import 'widgets/catalog_search_field.dart';
import 'widgets/work_order_task_type_card.dart';

class WorkOrderTaskTypesSettingsPage extends ConsumerStatefulWidget {
  const WorkOrderTaskTypesSettingsPage({super.key});

  @override
  ConsumerState<WorkOrderTaskTypesSettingsPage> createState() =>
      _WorkOrderTaskTypesSettingsPageState();
}

class _WorkOrderTaskTypesSettingsPageState
    extends ConsumerState<WorkOrderTaskTypesSettingsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<WorkOrderTaskTypeModel> _types = const <WorkOrderTaskTypeModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadTypes();
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

  Future<void> _loadTypes() async {
    setState(() => _loading = true);
    try {
      final List<WorkOrderTaskTypeModel> types =
          await ref.read(pedidosLocalDataSourceProvider).loadTaskTypesCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _types = types;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar los tipos: $error');
    }
  }

  Future<void> _openCreateDialog() async {
    final _TaskTypeDraft? draft = await _showTypeDialog();
    if (draft == null) {
      return;
    }
    try {
      await ref.read(pedidosLocalDataSourceProvider).upsertTaskType(
            name: draft.name,
            description: draft.description,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      await _loadTypes();
      _show('Tipo de trabajo creado.');
    } catch (error) {
      _show('No se pudo crear el tipo: $error');
    }
  }

  Future<void> _openEditDialog(WorkOrderTaskTypeModel type) async {
    final _TaskTypeDraft? draft = await _showTypeDialog(type: type);
    if (draft == null) {
      return;
    }
    try {
      await ref.read(pedidosLocalDataSourceProvider).upsertTaskType(
            typeId: type.id,
            name: draft.name,
            description: draft.description,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      await _loadTypes();
      _show('Tipo de trabajo actualizado.');
    } catch (error) {
      _show('No se pudo actualizar el tipo: $error');
    }
  }

  Future<void> _toggleActive(
    WorkOrderTaskTypeModel type,
    bool isActive,
  ) async {
    try {
      await ref.read(pedidosLocalDataSourceProvider).setTaskTypeActive(
            typeId: type.id,
            isActive: isActive,
          );
      if (!mounted) {
        return;
      }
      await _loadTypes();
    } catch (error) {
      _show('No se pudo cambiar estado: $error');
    }
  }

  List<WorkOrderTaskTypeModel> _filteredTypes() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _types;
    }
    return _types.where((WorkOrderTaskTypeModel row) {
      return row.name.toLowerCase().contains(query) ||
          row.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<_TaskTypeDraft?> _showTypeDialog({
    WorkOrderTaskTypeModel? type,
  }) {
    final TextEditingController nameCtrl = TextEditingController(
      text: type?.name ?? '',
    );
    final TextEditingController descCtrl = TextEditingController(
      text: type?.description ?? '',
    );
    bool isActive = type?.isActive ?? true;

    return showDialog<_TaskTypeDraft>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                type == null
                    ? 'Nuevo tipo de trabajo'
                    : 'Editar tipo de trabajo',
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
                        hintText: 'Ej. Impresión',
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
                        hintText: 'Describe cuándo se usa este tipo.',
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
                      _TaskTypeDraft(
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
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<WorkOrderTaskTypeModel> types = _filteredTypes();

    return AppScaffold(
      title: 'Tipos de trabajo',
      currentRoute: '/configuracion-tipos-trabajo-pedidos',
      showTopTabs: false,
      showDrawer: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      floatingActionButton: AppAddActionButton(
        heroTag: 'add-work-order-task-type',
        currentRoute: '/configuracion-tipos-trabajo-pedidos',
        onPressed: _openCreateDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: <Widget>[
                const Text(
                  'Tipos de trabajo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Define las etapas o procesos del taller para usarlas al registrar trabajos realizados.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                CatalogSearchField(
                  controller: _searchCtrl,
                  hintText: 'Buscar tipo de trabajo...',
                ),
                const SizedBox(height: 18),
                if (types.isEmpty)
                  const _EmptyPanel(
                    text: 'No hay tipos de trabajo para mostrar.',
                  )
                else
                  ...types.map((WorkOrderTaskTypeModel row) {
                    return WorkOrderTaskTypeCard(
                      type: row,
                      onEdit: () => _openEditDialog(row),
                      onToggleActive: (bool value) => _toggleActive(row, value),
                    );
                  }),
              ],
            ),
    );
  }
}

class _TaskTypeDraft {
  const _TaskTypeDraft({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String description;
  final bool isActive;
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
