import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../pedidos/data/pedidos_local_datasource.dart';
import '../../pedidos/presentation/pedidos_providers.dart';
import 'widgets/catalog_search_field.dart';
import 'widgets/work_order_task_worker_role_card.dart';

class WorkOrderTaskWorkerRolesSettingsPage extends ConsumerStatefulWidget {
  const WorkOrderTaskWorkerRolesSettingsPage({super.key});

  @override
  ConsumerState<WorkOrderTaskWorkerRolesSettingsPage> createState() =>
      _WorkOrderTaskWorkerRolesSettingsPageState();
}

class _WorkOrderTaskWorkerRolesSettingsPageState
    extends ConsumerState<WorkOrderTaskWorkerRolesSettingsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<WorkOrderTaskWorkerRoleModel> _roles =
      const <WorkOrderTaskWorkerRoleModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadRoles();
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

  Future<void> _loadRoles() async {
    setState(() => _loading = true);
    try {
      final List<WorkOrderTaskWorkerRoleModel> roles = await ref
          .read(pedidosLocalDataSourceProvider)
          .loadTaskWorkerRolesCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _roles = roles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar los roles: $error');
    }
  }

  Future<void> _openCreateDialog() async {
    final _TaskWorkerRoleDraft? draft = await _showRoleDialog();
    if (draft == null) {
      return;
    }
    try {
      await ref.read(pedidosLocalDataSourceProvider).upsertTaskWorkerRole(
            name: draft.name,
            description: draft.description,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      await _loadRoles();
      _show('Rol de trabajo creado.');
    } catch (error) {
      _show('No se pudo crear el rol: $error');
    }
  }

  Future<void> _openEditDialog(WorkOrderTaskWorkerRoleModel role) async {
    final _TaskWorkerRoleDraft? draft = await _showRoleDialog(role: role);
    if (draft == null) {
      return;
    }
    try {
      await ref.read(pedidosLocalDataSourceProvider).upsertTaskWorkerRole(
            roleId: role.id,
            name: draft.name,
            description: draft.description,
            isActive: draft.isActive,
          );
      if (!mounted) {
        return;
      }
      await _loadRoles();
      _show('Rol de trabajo actualizado.');
    } catch (error) {
      _show('No se pudo actualizar el rol: $error');
    }
  }

  Future<void> _toggleActive(
    WorkOrderTaskWorkerRoleModel role,
    bool isActive,
  ) async {
    try {
      await ref.read(pedidosLocalDataSourceProvider).setTaskWorkerRoleActive(
            roleId: role.id,
            isActive: isActive,
          );
      if (!mounted) {
        return;
      }
      await _loadRoles();
    } catch (error) {
      _show('No se pudo cambiar estado: $error');
    }
  }

  List<WorkOrderTaskWorkerRoleModel> _filteredRoles() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _roles;
    }
    return _roles.where((WorkOrderTaskWorkerRoleModel row) {
      return row.name.toLowerCase().contains(query) ||
          row.description.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<_TaskWorkerRoleDraft?> _showRoleDialog({
    WorkOrderTaskWorkerRoleModel? role,
  }) {
    final TextEditingController nameCtrl = TextEditingController(
      text: role?.name ?? '',
    );
    final TextEditingController descCtrl = TextEditingController(
      text: role?.description ?? '',
    );
    bool isActive = role?.isActive ?? true;

    return showDialog<_TaskWorkerRoleDraft>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                role == null ? 'Nuevo rol de trabajo' : 'Editar rol de trabajo',
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
                        hintText: 'Ej. Impresor',
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
                        hintText: 'Describe cuándo aplica este rol.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rol activo'),
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
                      _TaskWorkerRoleDraft(
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
    final List<WorkOrderTaskWorkerRoleModel> roles = _filteredRoles();

    return AppScaffold(
      title: 'Roles de trabajo',
      currentRoute: '/configuracion-roles-trabajo-pedidos',
      showTopTabs: false,
      showDrawer: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      floatingActionButton: AppAddActionButton(
        heroTag: 'add-work-order-task-worker-role',
        currentRoute: '/configuracion-roles-trabajo-pedidos',
        onPressed: _openCreateDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: <Widget>[
                const Text(
                  'Roles de trabajo',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Define los roles que pueden desempenar los trabajadores en cada trabajo realizado.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                CatalogSearchField(
                  controller: _searchCtrl,
                  hintText: 'Buscar rol de trabajo...',
                ),
                const SizedBox(height: 18),
                if (roles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      'No hay roles de trabajo que coincidan con la búsqueda.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...roles.map(
                    (WorkOrderTaskWorkerRoleModel role) =>
                        WorkOrderTaskWorkerRoleCard(
                      role: role,
                      onEdit: () => _openEditDialog(role),
                      onToggleActive: (bool value) =>
                          _toggleActive(role, value),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TaskWorkerRoleDraft {
  const _TaskWorkerRoleDraft({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String description;
  final bool isActive;
}
