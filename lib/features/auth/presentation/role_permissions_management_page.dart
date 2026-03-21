import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/auth_local_datasource.dart';
import 'auth_providers.dart';
import 'widgets/user_access_bottom_nav.dart';
import 'widgets/user_access_role_card.dart';
import 'widgets/user_role_form_dialog.dart';

class RolePermissionsManagementPage extends ConsumerStatefulWidget {
  const RolePermissionsManagementPage({super.key});

  @override
  ConsumerState<RolePermissionsManagementPage> createState() =>
      _RolePermissionsManagementPageState();
}

class _RolePermissionsManagementPageState
    extends ConsumerState<RolePermissionsManagementPage> {
  bool _loading = true;
  bool _saving = false;

  List<AuthPermissionSummary> _permissions = const <AuthPermissionSummary>[];
  List<AuthRoleSummary> _roles = const <AuthRoleSummary>[];

  AuthLocalDataSource get _authDs => ref.read(authLocalDataSourceProvider);

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

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final List<AuthPermissionSummary> permissions =
          await _authDs.listPermissions();
      final List<AuthRoleSummary> roles =
          await _authDs.listRolesWithPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissions = permissions;
        _roles = roles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar roles y permisos: $error');
    }
  }

  Future<void> _createRole() async {
    final UserRoleFormResult? result = await Navigator.of(context).push(
      MaterialPageRoute<UserRoleFormResult>(
        builder: (_) => UserRoleFormDialog(
          title: 'Nuevo rol',
          permissions: _permissions,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await _runSaving(() async {
      await _authDs.createRole(
        name: result.name,
        description: result.description,
        permissionKeys: result.permissionKeys,
      );
      await _load();
      _show('Rol creado correctamente.');
    });
  }

  Future<void> _editRole(AuthRoleSummary role) async {
    if (_isAdminRole(role.id)) {
      _show('El rol Administrador no se puede editar.');
      return;
    }
    final UserRoleFormResult? result = await Navigator.of(context).push(
      MaterialPageRoute<UserRoleFormResult>(
        builder: (_) => UserRoleFormDialog(
          title: 'Editar rol',
          initialName: role.name,
          initialDescription: role.description,
          initialPermissionKeys: role.permissionKeys,
          permissions: _permissions,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await _runSaving(() async {
      await _authDs.updateRole(
        roleId: role.id,
        name: result.name,
        description: result.description,
        permissionKeys: result.permissionKeys,
      );
      await _load();
      _show('Rol actualizado.');
    });
  }

  Future<void> _deleteRole(AuthRoleSummary role) async {
    if (_isAdminRole(role.id)) {
      _show('El rol Administrador no se puede eliminar.');
      return;
    }
    final bool confirm = await _confirm(
      title: 'Eliminar rol',
      message:
          'Se eliminará el rol "${role.name}". Esta acción no se puede deshacer.',
    );
    if (!confirm) {
      return;
    }
    await _runSaving(() async {
      await _authDs.deleteRole(role.id);
      await _load();
      _show('Rol eliminado.');
    });
  }

  Future<void> _runSaving(Future<void> Function() callback) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await callback();
    } catch (error) {
      _show('No se pudo guardar: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isAdminRole(String roleId) {
    return roleId.trim() == AppRoleIds.admin;
  }

  @override
  Widget build(BuildContext context) {
    final int activeRoles =
        _roles.where((AuthRoleSummary role) => role.isActive).length;
    return AppScaffold(
      title: 'Gestión de Roles',
      currentRoute: '/configuracion-roles',
      showTopTabs: false,
      useDefaultActions: false,
      showBottomNavigationBar: false,
      onRefresh: _load,
      bottomNavigationBar: UserAccessBottomNav(
        activeTab: UserAccessBottomTab.roles,
        onUsersTap: () => context.go('/configuracion-usuarios'),
        onRolesTap: () {},
      ),
      appBarActions: <Widget>[
        PopupMenuButton<String>(
          tooltip: 'Acciones',
          onSelected: (String value) {
            if (value == 'refresh') {
              _load();
              return;
            }
            if (value == 'users') {
              context.go('/configuracion-usuarios');
              return;
            }
            if (value == 'new_role') {
              _createRole();
            }
          },
          itemBuilder: (_) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'new_role',
              child: Text('Nuevo rol'),
            ),
            PopupMenuItem<String>(
              value: 'users',
              child: Text('Ir a usuarios'),
            ),
            PopupMenuItem<String>(
              value: 'refresh',
              child: Text('Actualizar'),
            ),
          ],
          icon: const Icon(
            Icons.account_circle_rounded,
            color: Color(0xFF1152D4),
            size: 30,
          ),
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: (_loading || _saving) ? null : _createRole,
        backgroundColor: const Color(0xFF1152D4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF2F4F7),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: <Widget>[
                  if (_saving) const LinearProgressIndicator(minHeight: 3),
                  // const SizedBox(height: 6),
                  // const UserAccessHero(
                  //   title: 'Roles y\nPermisos',
                  //   subtitle:
                  //       'Define jerarquías y acciones permitidas para cada\n'
                  //       'tipo de usuario de tu negocio.',
                  // ),
                  // const SizedBox(height: 28),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Roles',
                          style: TextStyle(
                            fontSize: 40 / 2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11141A),
                          ),
                        ),
                      ),
                      Text(
                        '$activeRoles ACTIVOS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6C7384),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._roles.map((AuthRoleSummary role) {
                    final bool isAdminRole = _isAdminRole(role.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: UserAccessRoleCard(
                        role: role,
                        isAdminRole: isAdminRole,
                        onTap: () => _editRole(role),
                        onActionSelected: (String value) {
                          if (value == 'edit') {
                            _editRole(role);
                            return;
                          }
                          if (value == 'delete') {
                            _deleteRole(role);
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
