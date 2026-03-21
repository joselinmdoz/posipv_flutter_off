import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/dashboard_widget_config.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/data/auth_local_datasource.dart';
import '../../auth/presentation/auth_providers.dart';
import 'configuracion_providers.dart';
import 'widgets/dashboard_widget_reorder_list.dart';
import 'widgets/dashboard_widget_toggle_tile.dart';

class DashboardWidgetsSettingsPage extends ConsumerStatefulWidget {
  const DashboardWidgetsSettingsPage({super.key});

  @override
  ConsumerState<DashboardWidgetsSettingsPage> createState() =>
      _DashboardWidgetsSettingsPageState();
}

class _DashboardWidgetsSettingsPageState
    extends ConsumerState<DashboardWidgetsSettingsPage> {
  bool _loading = true;
  bool _saving = false;
  List<AuthUserSummary> _users = const <AuthUserSummary>[];
  String? _selectedUserId;
  DashboardWidgetLayout _layout = DashboardWidgetLayout.defaults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadUsersAndConfig();
    });
  }

  Future<void> _loadUsersAndConfig() async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      List<AuthUserSummary> users = <AuthUserSummary>[];
      if (session.isAdmin) {
        users =
            await ref.read(authLocalDataSourceProvider).listUsersWithRoles();
        users = users
            .where((AuthUserSummary user) => user.isActive)
            .toList(growable: false);
      } else {
        users = <AuthUserSummary>[
          AuthUserSummary(
            id: session.userId,
            username: session.username,
            isActive: true,
            isDefaultAdmin: session.isAdmin,
            roleIds: session.roleIds,
            roleNames: session.roleNames,
          ),
        ];
      }

      String selectedUserId = _selectedUserId ?? session.userId;
      final bool existsInList = users.any(
        (AuthUserSummary user) => user.id == selectedUserId,
      );
      if (!existsInList && users.isNotEmpty) {
        selectedUserId = users.first.id;
      }
      final DashboardWidgetLayout layout = users.isEmpty
          ? DashboardWidgetLayout.defaults
          : await ref
              .read(configuracionLocalDataSourceProvider)
              .loadDashboardWidgetLayout(userId: selectedUserId);
      if (!mounted) {
        return;
      }
      setState(() {
        _users = users;
        _selectedUserId = users.isEmpty ? null : selectedUserId;
        _layout = layout;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar la configuración: $error');
    }
  }

  Future<void> _changeSelectedUser(String userId) async {
    if (_selectedUserId == userId) {
      return;
    }
    setState(() {
      _selectedUserId = userId;
      _loading = true;
    });
    try {
      final DashboardWidgetLayout layout = await ref
          .read(configuracionLocalDataSourceProvider)
          .loadDashboardWidgetLayout(userId: userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _layout = layout;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar widgets del usuario: $error');
    }
  }

  Future<void> _save() async {
    final String? userId = _selectedUserId;
    if (userId == null || userId.trim().isEmpty) {
      _show('Selecciona un usuario.');
      return;
    }
    if (_saving) {
      return;
    }
    if (_layout.visibleKeys.isEmpty) {
      _show('Debes dejar al menos un widget visible.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(configuracionLocalDataSourceProvider)
          .saveDashboardWidgetLayout(
            userId: userId,
            layout: _layout,
          );
      if (!mounted) {
        return;
      }
      final AuthUserSummary? user = _findUserById(userId);
      _show(
        user == null
            ? 'Configuración guardada.'
            : 'Widgets guardados para @${user.username}.',
      );
    } catch (error) {
      _show('No se pudo guardar la configuración: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _restoreDefaults() {
    setState(() {
      _layout = DashboardWidgetLayout.defaults;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final List<String> ordered = List<String>.from(_layout.orderedKeys);
    if (oldIndex < 0 ||
        oldIndex >= ordered.length ||
        newIndex < 0 ||
        newIndex > ordered.length) {
      return;
    }
    final String moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    setState(() {
      _layout = _layout.copyWith(orderedKeys: ordered);
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final bool isAdmin = session?.isAdmin ?? false;
    final String? selectedUserId = _selectedUserId;
    final AuthUserSummary? selectedUser =
        selectedUserId == null ? null : _findUserById(selectedUserId);

    return AppScaffold(
      title: 'Widgets Dashboard',
      currentRoute: '/configuracion-dashboard-widgets',
      showTopTabs: false,
      showBottomNavigationBar: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 3),
                if (isAdmin) ...<Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      border: OutlineInputBorder(),
                    ),
                    items: _users
                        .map(
                          (AuthUserSummary user) => DropdownMenuItem<String>(
                            value: user.id,
                            child: Text('@${user.username}'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _saving
                        ? null
                        : (String? value) {
                            if (value == null) {
                              return;
                            }
                            _changeSelectedUser(value);
                          },
                  ),
                  const SizedBox(height: 12),
                ],
                if (selectedUser != null)
                  Text(
                    'Configurando widgets para @${selectedUser.username}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 10),
                Text(
                  'Activa o desactiva qué widgets se mostrarán en el dashboard.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 14),
                ...DashboardWidgetCatalog.definitions
                    .map((DashboardWidgetDefinition definition) {
                  return DashboardWidgetToggleTile(
                    definition: definition,
                    value: _layout.visibleKeys.contains(definition.key),
                    enabled: !_saving,
                    onChanged: (bool value) {
                      final Set<String> nextVisible =
                          Set<String>.from(_layout.visibleKeys);
                      setState(() {
                        if (value) {
                          nextVisible.add(definition.key);
                        } else if (nextVisible.length > 1) {
                          nextVisible.remove(definition.key);
                        }
                        _layout = _layout.copyWith(visibleKeys: nextVisible);
                      });
                    },
                  );
                }),
                const SizedBox(height: 8),
                Text(
                  'Orden de visualización (arrastra para reordenar)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                DashboardWidgetReorderList(
                  orderedKeys: _layout.orderedKeys,
                  visibleKeys: _layout.visibleKeys,
                  enabled: !_saving,
                  onReorder: _onReorder,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _restoreDefaults,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Restaurar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  AuthUserSummary? _findUserById(String userId) {
    for (final AuthUserSummary user in _users) {
      if (user.id == userId) {
        return user;
      }
    }
    return null;
  }
}
