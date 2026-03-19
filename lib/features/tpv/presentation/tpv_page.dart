import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
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
import 'widgets/tpv_open_session_dialog.dart';
import '../../reportes/presentation/widgets/ipv_reporte_detail_page.dart';

class TpvPage extends ConsumerStatefulWidget {
  const TpvPage({super.key});

  @override
  ConsumerState<TpvPage> createState() => _TpvPageState();
}

class _TpvPageState extends ConsumerState<TpvPage> {
  List<TpvTerminalView> _terminals = <TpvTerminalView>[];
  bool _loading = true;
  bool _showingIpvSheet = false;
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
      final List<TpvTerminalView> data =
          await ref.read(tpvLocalDataSourceProvider).listActiveTerminalViews();
      trace.mark('consulta completada');
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _terminals = data;
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
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TpvFormPage(terminal: terminal),
        fullscreenDialog: true,
      ),
    );
    if (saved == true) {
      await _load();
      _show(terminal == null
          ? 'TPV creado con su almacen asociado.'
          : 'TPV actualizado.');
    }
  }

  Future<void> _openEmployeesManager({bool create = false}) async {
    await context.push(create ? '/tpv-empleados?new=1' : '/tpv-empleados');
    if (mounted) {
      await _load();
    }
  }

  Future<void> _openSession(TpvTerminalView terminal) async {
    final UserSession? userSession = ref.read(currentSessionProvider);
    if (userSession == null) {
      _show('Debes iniciar sesion.');
      return;
    }

    final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
    List<TpvEmployee> employees = <TpvEmployee>[];
    bool allowMultipleResponsible = true;
    try {
      employees = await tpvDs.listActiveEmployees();
      final licenseStatus =
          await ref.read(offlineLicenseServiceProvider).current();
      allowMultipleResponsible = licenseStatus.isFull;
    } catch (e) {
      _show('No se pudieron cargar empleados: $e');
      return;
    }
    if (employees.isEmpty) {
      _show('Primero debes crear empleados responsables para abrir turno.');
      await _openEmployeesManager(create: true);
      return;
    }
    if (!mounted) {
      return;
    }
    final dynamic result = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return TpvOpenSessionDialog(
          terminal: terminal,
          employees: employees,
          allowMultipleSelection: allowMultipleResponsible,
          onManageEmployees: () => Navigator.pop(context, 'manage_employees'),
        );
      },
    );

    if (result == 'manage_employees') {
      await _openEmployeesManager(create: true);
      return;
    }
    if (result == null || result is! List<String>) {
      return;
    }
    final List<String> selectedEmployeeIds = result;

    try {
      await tpvDs.openSession(
        terminalId: terminal.terminal.id,
        userId: userSession.userId,
        responsibleEmployeeIds: selectedEmployeeIds,
        openingFloatCents: 0,
        note: null,
      );
      ref.read(currentSessionProvider.notifier).state =
          userSession.copyWith(activeTerminalId: terminal.terminal.id);
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

  Future<void> _closeSession(TpvTerminalView terminal) async {
    final TpvSessionWithUser? open = terminal.openSession;
    if (open == null) {
      _show('No hay una sesion abierta en este TPV.');
      return;
    }

    final UserSession? userSession = ref.read(currentSessionProvider);
    if (userSession == null) {
      _show('Debes iniciar sesion.');
      return;
    }

    final bool isAdmin = userSession.role == 'admin';
    if (!isAdmin && open.user.id != userSession.userId) {
      _show('Solo el usuario que abrio el turno puede cerrarlo.');
      return;
    }

    final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
    final TpvTerminalConfig config =
        tpvDs.configFromTerminal(terminal.terminal);
    Map<String, int> expectedByMethod = <String, int>{};
    try {
      expectedByMethod =
          await tpvDs.getSessionExpectedPaymentsByMethod(open.session.id);
    } catch (_) {
      expectedByMethod = <String, int>{};
    }
    if (!mounted) {
      return;
    }
    final Map<String, int> expectedConfigured = <String, int>{
      for (final String method in config.paymentMethods)
        method: expectedByMethod[method] ?? 0,
    };
    final int expectedCashFromSalesCents = expectedConfigured['cash'] ?? 0;
    final int expectedCashCents =
        open.session.openingFloatCents + expectedCashFromSalesCents;

    String closeNoteText = '';
    final Map<int, String> countTexts = <int, String>{
      for (final int cents in config.cashDenominationsCents) cents: '',
    };
    int totalCents = 0;
    int cashDifferenceCents = -expectedCashCents;
    bool cashMatchesExpected = expectedCashCents == 0;

    void recalculate() {
      int total = 0;
      for (final MapEntry<int, String> entry in countTexts.entries) {
        final int qty = int.tryParse(entry.value.trim()) ?? 0;
        if (qty > 0) {
          total += qty * entry.key;
        }
      }
      totalCents = total;
      cashDifferenceCents = totalCents - expectedCashCents;
      cashMatchesExpected = cashDifferenceCents == 0;
    }

    recalculate();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            void updateDialog(void Function() fn) {
              if (!context.mounted) {
                return;
              }
              setStateDialog(fn);
            }

            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text('Cerrar turno en ${terminal.terminal.name}'),
              content: SizedBox(
                width: 420,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Montos esperados por metodo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...config.paymentMethods.map((String method) {
                          final int cents = expectedConfigured[method] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    _paymentMethodLabel(method),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatCentsWithSymbol(
                                    cents,
                                    config.currencySymbol,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEF9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Fondo inicial efectivo: ${_formatCentsWithSymbol(open.session.openingFloatCents, config.currencySymbol)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Esperado en efectivo: ${_formatCentsWithSymbol(expectedCashCents, config.currencySymbol)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Desglose por denominacion',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...config.cashDenominationsCents.map((int cents) {
                          final String label =
                              '${config.currencySymbol}${(cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2)}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: countTexts[cents] ?? '',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                      hintText: '0',
                                    ),
                                    onChanged: (String value) {
                                      countTexts[cents] = value;
                                      updateDialog(recalculate);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Total contado: ${config.currencySymbol}${(totalCents / 100).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cashMatchesExpected
                                ? const Color(0xFFE3F5EE)
                                : const Color(0xFFFCE9EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                cashMatchesExpected
                                    ? 'Coincidencia efectivo: SI'
                                    : 'Coincidencia efectivo: NO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: cashMatchesExpected
                                      ? const Color(0xFF148A65)
                                      : const Color(0xFFB13B5A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Diferencia: ${cashDifferenceCents > 0 ? '+' : cashDifferenceCents < 0 ? '-' : ''}${_formatCentsWithSymbol(cashDifferenceCents.abs(), config.currencySymbol)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          initialValue: closeNoteText,
                          decoration: const InputDecoration(
                            labelText: 'Nota (opcional)',
                          ),
                          onChanged: (String value) => closeNoteText = value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirm != true) {
      return;
    }

    final Map<int, int> breakdown = <int, int>{};
    for (final MapEntry<int, String> entry in countTexts.entries) {
      final int qty = int.tryParse(entry.value.trim()) ?? 0;
      if (qty > 0) {
        breakdown[entry.key] = qty;
      }
    }
    final String closeNote = closeNoteText;

    if (breakdown.isEmpty) {
      _show('Debes ingresar al menos una denominacion para cerrar el turno.');
      return;
    }

    try {
      await ref.read(tpvLocalDataSourceProvider).closeSession(
            sessionId: open.session.id,
            closingCashCents: totalCents,
            note: closeNote,
            closedByUserId: userSession.userId,
            cashCountByDenomination: breakdown,
          );
      await _load();
      ref.invalidate(tpvTerminalsProvider);
      if (userSession.activeTerminalId == terminal.terminal.id) {
        ref.read(currentSessionProvider.notifier).state =
            userSession.copyWith(activeTerminalId: null);
      }
      _show('Turno cerrado.');
    } catch (e) {
      _show('No se pudo cerrar turno: $e');
    }
  }

  Future<void> _openHistory(TpvTerminalView terminal) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TpvSessionHistoryPage(terminal: terminal),
      ),
    );
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
      await ref
          .read(tpvLocalDataSourceProvider)
          .deactivateTerminal(terminal.terminal.id);
      await _load();
      _show('TPV desactivado.');
    } catch (e) {
      _show('No se pudo desactivar TPV: $e');
    }
  }

  void _goToPos(TpvTerminalView terminal) {
    final UserSession? current = ref.read(currentSessionProvider);
    if (current != null) {
      ref.read(currentSessionProvider.notifier).state =
          current.copyWith(activeTerminalId: terminal.terminal.id);
    }
    context.go('/ventas-pos');
  }

  String _formatCentsWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'wallet':
        return 'Billetera';
      default:
        return method;
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
      appBarActions: <Widget>[
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'Opciones',
        ),
      ],
      floatingActionButton: license.canWrite
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
                                    onEdit: () =>
                                        _openForm(terminal: terminal.terminal),
                                    onGoToPos: () => _goToPos(terminal),
                                    onOpenSession: () => _openSession(terminal),
                                    onCloseSession: () =>
                                        _closeSession(terminal),
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
