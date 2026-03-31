import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/clientes_local_datasource.dart';
import 'cliente_detail_page.dart';
import 'cliente_form_page.dart';
import 'clientes_providers.dart';
import 'widgets/client_list_card.dart';
import 'widgets/client_quick_create_card.dart';
import 'widgets/clients_bottom_nav.dart';
import 'widgets/clients_filter_tabs.dart';
import 'widgets/clients_search_field.dart';

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<ClienteListItem> _clients = <ClienteListItem>[];
  String _filter = 'todos';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), _load);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final List<ClienteListItem> rows =
          await ref.read(clientesLocalDataSourceProvider).listClients(
                searchQuery: _searchCtrl.text,
                typeFilter: _filter,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        _clients = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar los clientes: $error');
    }
  }

  Future<void> _openClientForm([String? clientId]) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClienteFormPage(clientId: clientId),
      ),
    );
    if (saved == true) {
      await _load();
      _show(clientId == null ? 'Cliente creado.' : 'Cliente actualizado.');
    }
  }

  Future<void> _openClientDetail(String clientId) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ClienteDetailPage(clientId: clientId),
      ),
    );
    if (changed == true) {
      await _load();
    }
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
    final UserSession? session = ref.watch(currentSessionProvider);
    final AppConfig config = ref.watch(currentAppConfigProvider);
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.customersManage) ?? false;

    return AppScaffold(
      title: 'Gestion de Clientes',
      currentRoute: '/clientes',
      showTopTabs: false,
      useDefaultActions: false,
      showBottomNavigationBar: false,
      onRefresh: _load,
      appBarLeading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF1152D4)),
          );
        },
      ),
      appBarActions: <Widget>[
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1152D4),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _initials(session?.username ?? 'AD'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
      bottomNavigationBar: const ClientsBottomNav(
        activeTab: ClientsBottomTab.clientes,
      ),
      floatingActionButton: canManage
          ? AppAddActionButton(
              heroTag: 'clients-add-fab',
              onPressed: () => _openClientForm(),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: <Widget>[
                  const Text(
                    'Clientes',
                    style: TextStyle(
                      fontSize: 48 / 2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11141A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Administra tu base de datos y fideliza a tus compradores.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClientsSearchField(
                    controller: _searchCtrl,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 12),
                  ClientsFilterTabs(
                    currentFilter: _filter,
                    onFilterChanged: (String value) {
                      if (_filter == value) {
                        return;
                      }
                      setState(() => _filter = value);
                      _load();
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_clients.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E9F0)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: const Text(
                        'No hay clientes para mostrar con los filtros actuales.',
                        style: TextStyle(
                          color: Color(0xFF6B7486),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    ..._clients.map((ClienteListItem row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClientListCard(
                          item: row,
                          currencySymbol: config.currencySymbol,
                          onTap: () => _openClientDetail(row.id),
                        ),
                      );
                    }),
                  if (canManage) ...<Widget>[
                    const SizedBox(height: 8),
                    ClientQuickCreateCard(
                      onPressed: () => _openClientForm(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _initials(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      return 'AD';
    }
    if (clean.length == 1) {
      return clean.toUpperCase();
    }
    return clean.substring(0, 2).toUpperCase();
  }
}
