import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/security/app_permissions.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_session_history_page.dart';
import 'tpv_providers.dart';
import 'widgets/tpv_terminal_card.dart';
import 'widgets/tpv_form.dart';
import '../../reportes/presentation/widgets/ipv_reporte_detail_page.dart';

class TpvPage extends ConsumerStatefulWidget {
  const TpvPage({super.key});

  @override
  ConsumerState<TpvPage> createState() => _TpvPageState();
}

class _TpvPageState extends ConsumerState<TpvPage> {
  List<TpvTerminalView> _terminals = <TpvTerminalView>[];
  bool _loading = true;
  final bool _showingIpvSheet = false;
  String _selectedFilter = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

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
    final PerfTrace trace = PerfTrace('tpv.load');
    setState(() => _loading = true);
    try {
      final UserSession? session = ref.read(currentSessionProvider);
      final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
      final List<TpvTerminalView> data = await tpvDs.listActiveTerminalViews();
      trace.mark('consulta completada');
      List<TpvTerminalView> visible = data;
      if (session != null && !session.isAdmin) {
        final TpvEmployee? employee =
            await tpvDs.findActiveEmployeeByAssociatedUser(session.userId);
        if (employee == null) {
          visible = <TpvTerminalView>[];
        } else {
          visible = await tpvDs.filterTerminalViewsForEmployee(
            terminals: data,
            employeeId: employee.id,
          );
        }
      }
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _terminals = visible;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudo cargar TPV: $e');
    }
  }

  Future<void> _openForm({PosTerminal? terminal}) async {
    if (!_canManageTerminals()) {
      _show('No tienes permisos para gestionar terminales.');
      return;
    }
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TpvFormPage(terminal: terminal),
        fullscreenDialog: true,
      ),
    );
    if (saved == true) {
      await _load();
      _show(terminal == null ? 'TPV creado.' : 'TPV actualizado.');
    }
  }

  Future<void> _openSession(TpvTerminalView terminal) async {
    final UserSession? userSession = ref.read(currentSessionProvider);
    if (userSession == null) {
      _show('Debes iniciar sesion.');
      return;
    }

    final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
    final bool allowedForTerminal = await tpvDs.userCanAccessTerminal(
      terminalId: terminal.terminal.id,
      userId: userSession.userId,
    );
    if (!allowedForTerminal) {
      _show('No tienes acceso autorizado a este TPV.');
      return;
    }
    TpvEmployee? associatedEmployee;
    try {
      associatedEmployee =
          await tpvDs.findActiveEmployeeByAssociatedUser(userSession.userId);
    } catch (e) {
      _show('No se pudo validar el empleado asociado: $e');
      return;
    }
    if (associatedEmployee == null) {
      _show(
        'No tienes un empleado activo asociado a este usuario. '
        'Asocialo desde Empleados TPV para poder abrir turno.',
      );
      return;
    }

    try {
      await tpvDs.openSession(
        terminalId: terminal.terminal.id,
        userId: userSession.userId,
        responsibleEmployeeIds: <String>[associatedEmployee.id],
        openingFloatCents: 0,
        note: null,
      );
      final UserSession nextSession =
          userSession.copyWith(activeTerminalId: terminal.terminal.id);
      ref.read(currentSessionProvider.notifier).state = nextSession;
      unawaited(
        ref.read(localAuthServiceProvider).persistSession(
              session: nextSession,
              rememberOnDevice: true,
            ),
      );
      if (!mounted) {
        return;
      }
      ref.invalidate(tpvTerminalsProvider);
      _show('Turno abierto.');
      context.go('/ventas-pos');
    } catch (e) {
      _show('No se pudo abrir turno: $e');
    }
  }

  Future<void> _openHistory(TpvTerminalView terminal) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TpvSessionHistoryPage(terminal: terminal),
      ),
    );
  }

  Future<void> _openManualSync() async {
    final UserSession? session = ref.read(currentSessionProvider);
    if (session == null ||
        !session.hasPermission(AppPermissionKeys.tpvManageSessions)) {
      _show('No tienes permisos para usar la sincronización manual.');
      return;
    }
    await context.push('/sync-manual');
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openCurrentSessionIpv(TpvTerminalView terminal) async {
    if (_showingIpvSheet) {
      return;
    }
    final TpvSessionWithUser? open = terminal.openSession;
    if (open == null) {
      _show('No hay turno abierto en este TPV.');
      return;
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    IpvReportSummaryStat? report;
    try {
      report = await reportesDs.findIpvReportBySessionId(
        open.session.id,
        includeOpen: true,
      );
      if (report == null) {
        _show('No hay IPV asociado a la sesion actual.');
        return;
      }
    } catch (e) {
      _show('No se pudo cargar IPV de la sesion: $e');
      return;
    }
    if (!mounted) {
      return;
    }

    final IpvReportSummaryStat activeReport = report;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IpvReporteDetailPage(summary: activeReport),
      ),
    );
  }

  Future<void> _deactivate(TpvTerminalView terminal) async {
    if (!_canManageTerminals()) {
      _show('No tienes permisos para gestionar terminales.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desactivar TPV'),
          content: Text(
            'Se desactivara el TPV "${terminal.terminal.name}" y su almacen asociado.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    try {
      final String? actorUserId = ref.read(currentSessionProvider)?.userId;
      await ref.read(tpvLocalDataSourceProvider).deactivateTerminal(
            terminal.terminal.id,
            actorUserId: actorUserId,
          );
      await _load();
      _show('TPV desactivado.');
    } catch (e) {
      _show('No se pudo desactivar TPV: $e');
    }
  }

  void _goToPos(TpvTerminalView terminal) {
    final UserSession? current = ref.read(currentSessionProvider);
    if (current != null) {
      final UserSession nextSession =
          current.copyWith(activeTerminalId: terminal.terminal.id);
      ref.read(currentSessionProvider.notifier).state = nextSession;
      unawaited(
        ref.read(localAuthServiceProvider).persistSession(
              session: nextSession,
              rememberOnDevice: true,
            ),
      );
    }
    context.go('/ventas-pos');
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canManageTerminals() {
    final UserSession? session = ref.read(currentSessionProvider);
    return session?.hasPermission(AppPermissionKeys.tpvManageTerminals) ??
        false;
  }

  List<TpvTerminalView> _getFilteredTerminals() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    return _terminals.where((TpvTerminalView terminal) {
      // Filter by tab
      if (_selectedFilter == 'open' && terminal.openSession == null) {
        return false;
      }
      if (_selectedFilter == 'closed' && terminal.openSession != null) {
        return false;
      }
      // Filter by search
      if (query.isEmpty) return true;
      return terminal.terminal.name.toLowerCase().contains(query) ||
          terminal.terminal.code.toLowerCase().contains(query) ||
          terminal.warehouse.name.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildFilterTab({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final bool selected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF1152D4) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF1152D4)
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the TPV list provider to trigger a refresh
    ref.listen(tpvTerminalsProvider, (_, __) => _load());

    final license = ref.watch(currentLicenseStatusProvider);
    final bool canManageTerminals =
        ref.watch(currentSessionProvider)?.hasPermission(
                  AppPermissionKeys.tpvManageTerminals,
                ) ??
            false;
    final bool canManualSync = ref.watch(currentSessionProvider)?.hasPermission(
              AppPermissionKeys.tpvManageSessions,
            ) ??
        false;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<TpvTerminalView> filteredTerminals = _getFilteredTerminals();

    // Count terminals by status
    final int totalCount = _terminals.length;

    return AppScaffold(
      title: 'Terminales de Venta',
      currentRoute: '/tpv',
      onRefresh: _load,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: canManualSync
          ? <Widget>[
              IconButton(
                onPressed: _openManualSync,
                icon: const Icon(Icons.sync_alt_rounded),
                tooltip: 'Sincronización manual',
              ),
            ]
          : const <Widget>[],
      floatingActionButton: license.canWrite && canManageTerminals
          ? AppAddActionButton(
              currentRoute: '/tpv',
              iconSize: 28,
              onPressed: () => _openForm(),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                // Tabs
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: <Widget>[
                        _buildFilterTab(
                          label: 'Todos ($totalCount)',
                          value: 'all',
                          theme: theme,
                        ),
                        const SizedBox(width: 24),
                        _buildFilterTab(
                          label: 'Abiertos',
                          value: 'open',
                          theme: theme,
                        ),
                        const SizedBox(width: 24),
                        _buildFilterTab(
                          label: 'Cerrados',
                          value: 'closed',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    displacement: 20,
                    color: const Color(0xFF1152D4),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        // Search bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText:
                                      'Buscar terminal por nombre o código...',
                                  hintStyle: TextStyle(
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.4),
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (filteredTerminals.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.terminal_rounded,
                                    size: 64,
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchCtrl.text.isEmpty
                                        ? 'No hay terminales'
                                        : 'Sin resultados',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final terminal = filteredTerminals[index];
                                  return TpvTerminalCard(
                                    key: ValueKey<String>(terminal.terminal.id),
                                    terminal: terminal,
                                    isDark: theme.brightness == Brightness.dark,
                                    onEdit: canManageTerminals
                                        ? () => _openForm(
                                            terminal: terminal.terminal)
                                        : null,
                                    onDelete: canManageTerminals
                                        ? () => _deactivate(terminal)
                                        : null,
                                    onGoToPos: () => _goToPos(terminal),
                                    onOpenSession: () => _openSession(terminal),
                                    onHistory: () => _openHistory(terminal),
                                    onIpv: () =>
                                        _openCurrentSessionIpv(terminal),
                                  );
                                },
                                childCount: filteredTerminals.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
