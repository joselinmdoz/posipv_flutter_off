import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/auth_local_datasource.dart';
import 'auth_providers.dart';
import 'widgets/user_access_bottom_nav.dart';
import 'widgets/user_access_user_row.dart';
import 'widgets/user_form_dialog.dart';

class UserAccessManagementPage extends ConsumerStatefulWidget {
  const UserAccessManagementPage({super.key});

  @override
  ConsumerState<UserAccessManagementPage> createState() =>
      _UserAccessManagementPageState();
}

class _UserAccessManagementPageState
    extends ConsumerState<UserAccessManagementPage> {
  bool _loading = true;
  bool _saving = false;
  final TextEditingController _searchCtrl = TextEditingController();

  List<AuthRoleSummary> _roles = const <AuthRoleSummary>[];
  List<AuthUserSummary> _users = const <AuthUserSummary>[];

  AuthLocalDataSource get _authDs => ref.read(authLocalDataSourceProvider);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final List<AuthRoleSummary> roles =
          await _authDs.listRolesWithPermissions();
      final List<AuthUserSummary> users = await _authDs.listUsersWithRoles();
      if (!mounted) {
        return;
      }
      setState(() {
        _roles = roles;
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar usuarios: $error');
    }
  }

  Future<void> _createUser() async {
    final List<AuthRoleSummary> activeRoles =
        _roles.where((AuthRoleSummary role) => role.isActive).toList();
    if (activeRoles.isEmpty) {
      _show('No hay roles disponibles.');
      return;
    }
    final UserFormResult? result = await Navigator.of(context).push(
      MaterialPageRoute<UserFormResult>(
        builder: (_) => UserFormDialog(
          title: 'Nuevo usuario',
          roles: activeRoles,
          requirePassword: true,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await _runSaving(() async {
      await _authDs.createUserWithRoles(
        username: result.username,
        password: result.password ?? '',
        roleIds: result.roleIds,
        isActive: result.isActive,
      );
      await _load();
      _show('Usuario creado.');
    });
  }

  Future<void> _editUser(AuthUserSummary user) async {
    final UserFormResult? result = await Navigator.of(context).push(
      MaterialPageRoute<UserFormResult>(
        builder: (_) => UserFormDialog(
          title: 'Editar usuario',
          roles: _roles.where((AuthRoleSummary role) => role.isActive).toList(),
          initialUsername: user.username,
          initialRoleIds: user.roleIds.toSet(),
          initialIsActive: user.isActive,
          usernameLocked: user.isDefaultAdmin,
          activeLocked: user.isDefaultAdmin,
          rolesLocked: user.isDefaultAdmin,
          requirePassword: false,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    await _runSaving(() async {
      await _authDs.updateUser(
        userId: user.id,
        username: result.username,
        password: result.password,
        roleIds: result.roleIds,
        isActive: result.isActive,
      );
      await _load();
      _show('Usuario actualizado.');
    });
  }

  Future<void> _toggleUser(AuthUserSummary user) async {
    if (user.isDefaultAdmin) {
      _show('El usuario admin por defecto no se puede desactivar.');
      return;
    }
    await _runSaving(() async {
      await _authDs.toggleUserActive(
        userId: user.id,
        isActive: !user.isActive,
      );
      await _load();
      _show(user.isActive ? 'Usuario desactivado.' : 'Usuario activado.');
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

  List<AuthUserSummary> _filteredUsers() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _users;
    }
    return _users.where((AuthUserSummary user) {
      final String username = user.username.toLowerCase();
      final String roleNames = user.roleNames.join(' ').toLowerCase();
      final String employeeName = (user.employeeName ?? '').toLowerCase();
      return username.contains(query) ||
          roleNames.contains(query) ||
          employeeName.contains(query);
    }).toList(growable: false);
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
    final List<AuthUserSummary> filteredUsers = _filteredUsers();
    return AppScaffold(
      title: 'Gestión de Usuarios',
      currentRoute: '/configuracion-usuarios',
      showTopTabs: false,
      useDefaultActions: false,
      showBottomNavigationBar: false,
      onRefresh: _load,
      bottomNavigationBar: UserAccessBottomNav(
        activeTab: UserAccessBottomTab.users,
        onUsersTap: () {},
        onRolesTap: () => context.go('/configuracion-roles'),
      ),
      appBarActions: <Widget>[
        PopupMenuButton<String>(
          tooltip: 'Acciones',
          onSelected: (String value) {
            if (value == 'refresh') {
              _load();
              return;
            }
            if (value == 'roles') {
              context.go('/configuracion-roles');
              return;
            }
            if (value == 'new_user') {
              _createUser();
            }
          },
          itemBuilder: (_) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'new_user',
              child: Text('Nuevo usuario'),
            ),
            PopupMenuItem<String>(
              value: 'roles',
              child: Text('Ir a roles y permisos'),
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
        onPressed: (_loading || _saving) ? null : _createUser,
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
                  //   title: 'Usuarios',
                  //   subtitle:
                  //       'Gestiona las cuentas activas de tu equipo y controla\n'
                  //       'quién entra al sistema.',
                  //   lineHeight: 148,
                  // ),
                  // const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Usuarios',
                          style: TextStyle(
                            fontSize: 40 / 2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF11141A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1E5EA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: Color(0xFF3B4357),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar usuario...',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAEDEF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: filteredUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('No hay usuarios para mostrar.'),
                            ),
                          )
                        : Column(
                            children: filteredUsers.map((AuthUserSummary user) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: UserAccessUserRow(
                                  user: user,
                                  onTap: () => _editUser(user),
                                  onActionSelected: (String value) {
                                    if (value == 'edit') {
                                      _editUser(user);
                                      return;
                                    }
                                    if (value == 'toggle') {
                                      _toggleUser(user);
                                    }
                                  },
                                ),
                              );
                            }).toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
