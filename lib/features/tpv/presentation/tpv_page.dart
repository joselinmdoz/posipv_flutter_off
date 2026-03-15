import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_providers.dart';

Widget _employeeAvatar({
  required String? imagePath,
  required double radius,
  required Color backgroundColor,
  required Color iconColor,
}) {
  final String trimmedPath = (imagePath ?? '').trim();
  if (trimmedPath.isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(Icons.badge_outlined, color: iconColor),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: backgroundColor,
    child: ClipOval(
      child: Image.file(
        File(trimmedPath),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        cacheWidth: (radius * 4).round(),
        errorBuilder: (_, __, ___) => Icon(
          Icons.badge_outlined,
          color: iconColor,
        ),
      ),
    ),
  );
}

class TpvPage extends ConsumerStatefulWidget {
  const TpvPage({super.key});

  @override
  ConsumerState<TpvPage> createState() => _TpvPageState();
}

class _TpvPageState extends ConsumerState<TpvPage> {
  List<TpvTerminalView> _terminals = <TpvTerminalView>[];
  bool _loading = true;
  bool _showingIpvSheet = false;

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
        builder: (_) => _TpvFormPage(terminal: terminal),
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
    try {
      employees = await tpvDs.listActiveEmployees();
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
    final Set<String> selectedEmployeeIds = <String>{employees.first.id};

    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text('Abrir turno en ${terminal.terminal.name}'),
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
                        const Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Empleados responsables',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            final double maxWidth =
                                constraints.maxWidth.isFinite &&
                                        constraints.maxWidth > 0
                                    ? constraints.maxWidth
                                    : 360;
                            final double cardWidth =
                                maxWidth >= 380 ? (maxWidth - 8) / 2 : maxWidth;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: employees.map((TpvEmployee employee) {
                                final bool selected =
                                    selectedEmployeeIds.contains(employee.id);
                                return InkWell(
                                  onTap: () {
                                    setStateDialog(() {
                                      if (selected) {
                                        selectedEmployeeIds.remove(employee.id);
                                      } else {
                                        selectedEmployeeIds.add(employee.id);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    width: cardWidth,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFE8E1FA)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF7060A8)
                                            : const Color(0xFFDCCFF4),
                                        width: selected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        _employeeAvatar(
                                          imagePath: employee.imagePath,
                                          radius: 19,
                                          backgroundColor:
                                              const Color(0xFFE7E1F7),
                                          iconColor: const Color(0xFF5A4D88),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            employee.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked,
                                          size: 20,
                                          color: selected
                                              ? const Color(0xFF5C4A9D)
                                              : const Color(0xFF8A7FB0),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        if (selectedEmployeeIds.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Debes seleccionar al menos un empleado.',
                              style: TextStyle(
                                color: Color(0xFFB13B5A),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pop('manage_employees'),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Agregar empleado'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selectedEmployeeIds.isEmpty
                      ? null
                      : () => Navigator.of(context).pop('open'),
                  child: const Text('Abrir'),
                ),
              ],
            );
          },
        );
      },
    );
    if (action == 'manage_employees') {
      await _openEmployeesManager(create: true);
      return;
    }
    if (action != 'open') {
      return;
    }

    try {
      await tpvDs.openSession(
        terminalId: terminal.terminal.id,
        userId: userSession.userId,
        responsibleEmployeeIds: selectedEmployeeIds.toList(),
        openingFloatCents: 0,
        note: null,
      );
      ref.read(currentSessionProvider.notifier).state =
          userSession.copyWith(activeTerminalId: terminal.terminal.id);
      if (!mounted) {
        return;
      }
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
      _show('Turno cerrado.');
    } catch (e) {
      _show('No se pudo cerrar turno: $e');
    }
  }

  Future<void> _openHistory(TpvTerminalView terminal) async {
    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      final List<TpvSessionWithUser> sessions =
          await ds.listSessionHistory(terminal.terminal.id, limit: 40);
      final Map<String, List<TpvSessionCashBreakdown>> breakdownBySession =
          await ds.listCashBreakdownForSessions(
        sessions.map((TpvSessionWithUser row) => row.session.id),
      );
      final TpvTerminalConfig config = ds.configFromTerminal(terminal.terminal);
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Historial de turnos - ${terminal.terminal.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Sin sesiones registradas.'),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ListView.separated(
                        key: const PageStorageKey<String>(
                          'tpv-history-sessions',
                        ),
                        shrinkWrap: true,
                        cacheExtent: 320,
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, int index) {
                          final TpvSessionWithUser row = sessions[index];
                          final List<TpvSessionCashBreakdown> breakdown =
                              breakdownBySession[row.session.id] ??
                                  <TpvSessionCashBreakdown>[];
                          final int breakdownTotal = breakdown.fold<int>(
                            0,
                            (int sum, TpvSessionCashBreakdown item) =>
                                sum + item.subtotalCents,
                          );
                          return KeyedSubtree(
                            key: ValueKey<String>(row.session.id),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            row.user.username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          row.session.status == 'open'
                                              ? 'Abierta'
                                              : 'Cerrada',
                                          style: TextStyle(
                                            color: row.session.status == 'open'
                                                ? const Color(0xFF148A65)
                                                : const Color(0xFF655D83),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Apertura: ${_formatDateTime(row.session.openedAt)}',
                                    ),
                                    if (row.responsibleEmployees.isNotEmpty)
                                      Text(
                                        'Responsables: ${row.responsibleEmployees.map((TpvEmployee employee) => employee.name).join(', ')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF655D83),
                                        ),
                                      ),
                                    if (row.session.closedAt != null)
                                      Text(
                                        'Cierre: ${_formatDateTime(row.session.closedAt!)}',
                                      ),
                                    if (row.session.closedAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'Efectivo cierre: ${_formatCentsWithSymbol(row.session.closingCashCents ?? 0, config.currencySymbol)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    if (breakdown.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Desglose por denominacion',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...breakdown
                                          .map((TpvSessionCashBreakdown line) {
                                        return Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                '${_formatCentsWithSymbol(line.denominationCents, config.currencySymbol)} x ${line.unitCount}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ),
                                            Text(
                                              _formatCentsWithSymbol(
                                                line.subtotalCents,
                                                config.currencySymbol,
                                              ),
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        );
                                      }),
                                      const SizedBox(height: 2),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Total desglose: ${_formatCentsWithSymbol(breakdownTotal, config.currencySymbol)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _show('No se pudo cargar historial: $e');
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
    _showingIpvSheet = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'IPV turno actual - ${terminal.terminal.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDateTime(activeReport.openedAt)} → ${activeReport.closedAt == null ? '-' : _formatDateTime(activeReport.closedAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF655D83),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'El IPV se visualiza por exportacion.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF655D83),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _exportIpv(activeReport, 'csv');
                        },
                        icon: const Icon(Icons.table_view_outlined),
                        label: const Text('Exportar CSV'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _exportIpv(activeReport, 'pdf');
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exportar PDF'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _showingIpvSheet = false;
    }
  }

  Future<void> _exportIpv(IpvReportSummaryStat report, String format) async {
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final String path = format == 'pdf'
          ? await ds.exportIpvReportPdf(report.reportId)
          : await ds.exportIpvReportCsv(report.reportId);
      _show('IPV exportado $format en: $path');
    } catch (e, st) {
      debugPrint('IPV export failed (tpv_page). $e');
      debugPrintStack(stackTrace: st);
      _show('No se pudo exportar IPV: $e');
    }
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

  String _formatDateTime(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
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

  Widget _terminalCard(TpvTerminalView terminal) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final TpvSessionWithUser? open = terminal.openSession;
    final bool isOpen = open != null;
    final TpvTerminalConfig config = ref
        .read(tpvLocalDataSourceProvider)
        .configFromTerminal(terminal.terminal);
    final String methods = config.paymentMethods.map((String method) {
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
    }).join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFDDD5EF),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF312948)
                        : const Color(0xFFE8E2F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.point_of_sale_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        terminal.terminal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${terminal.terminal.code} • Almacen: ${terminal.warehouse.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? (isDark
                            ? const Color(0xFF1F3A34)
                            : const Color(0xFFE3F5EE))
                        : (isDark
                            ? const Color(0xFF312948)
                            : const Color(0xFFE9E5F5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOpen ? 'Turno abierto' : 'Sin turno',
                    style: TextStyle(
                      color: isOpen ? const Color(0xFF57D0A6) : scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Moneda: ${config.currencyCode} (${config.currencySymbol}) • Pagos: $methods',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            if (open != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Usuario: ${open.user.username} • Apertura: ${_formatDateTime(open.session.openedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (open.responsibleEmployees.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Responsables: ${open.responsibleEmployees.map((TpvEmployee row) => row.name).join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              )
            else
              Text(
                'No hay sesion activa para este TPV.',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (isOpen)
                  FilledButton.icon(
                    onPressed: () => _goToPos(terminal),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: const Text('Ir al POS'),
                  ),
                OutlinedButton.icon(
                  onPressed: isOpen
                      ? () => _closeSession(terminal)
                      : () => _openSession(terminal),
                  icon: Icon(isOpen
                      ? Icons.lock_clock_outlined
                      : Icons.lock_open_rounded),
                  label: Text(isOpen ? 'Cerrar turno' : 'Abrir turno'),
                ),
                if (isOpen)
                  OutlinedButton.icon(
                    onPressed: () => _openCurrentSessionIpv(terminal),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Ver IPV'),
                  ),
                IconButton.filledTonal(
                  tooltip: 'Historial',
                  onPressed: () => _openHistory(terminal),
                  icon: const Icon(Icons.history_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: 'Editar',
                  onPressed: () => _openForm(terminal: terminal.terminal),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton.filledTonal(
                  tooltip: 'Desactivar',
                  onPressed: () => _deactivate(terminal),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    return AppScaffold(
      title: 'Terminales TPV',
      currentRoute: '/tpv',
      onRefresh: _load,
      floatingActionButton: license.canWrite
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FloatingActionButton.small(
                  heroTag: 'tpv-employees-fab',
                  tooltip: 'Gestionar empleados',
                  onPressed: _openEmployeesManager,
                  child: const Icon(Icons.badge_outlined),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'tpv-create-fab',
                  tooltip: 'Nuevo TPV',
                  onPressed: () => _openForm(),
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _terminals.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const <Widget>[
                        SizedBox(height: 40),
                        Center(
                          child: Text('No hay TPVs creados. Usa + para crear.'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      key: const PageStorageKey<String>('tpv-terminals-list'),
                      cacheExtent: 420,
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 90),
                      itemCount: _terminals.length,
                      itemBuilder: (_, int index) {
                        final TpvTerminalView terminal = _terminals[index];
                        return KeyedSubtree(
                          key: ValueKey<String>(terminal.terminal.id),
                          child: _terminalCard(terminal),
                        );
                      },
                    ),
            ),
    );
  }
}

class TpvEmployeesPage extends ConsumerStatefulWidget {
  const TpvEmployeesPage({
    super.key,
    this.openCreateOnLoad = false,
  });

  final bool openCreateOnLoad;

  @override
  ConsumerState<TpvEmployeesPage> createState() => _TpvEmployeesPageState();
}

class _TpvEmployeesPageState extends ConsumerState<TpvEmployeesPage> {
  List<TpvEmployee> _employees = <TpvEmployee>[];
  bool _loading = true;

  String _sexLabel(String sex) {
    switch (sex.trim().toUpperCase()) {
      case 'F':
        return 'Femenino';
      case 'M':
        return 'Masculino';
      case 'X':
        return 'Otro';
      default:
        return sex;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openForm();
      });
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final List<TpvEmployee> rows = await ref
          .read(tpvLocalDataSourceProvider)
          .listEmployees(includeInactive: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _employees = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar empleados: $e');
    }
  }

  Future<void> _openForm({TpvEmployee? employee}) async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => _TpvEmployeeFormPage(employee: employee),
        fullscreenDialog: true,
      ),
    );
    if (result != 'saved') {
      return;
    }
    await _load();
  }

  Future<void> _toggleEmployee(TpvEmployee employee) async {
    try {
      await ref.read(tpvLocalDataSourceProvider).updateEmployee(
            employeeId: employee.id,
            name: employee.name,
            code: employee.code,
            sex: employee.sex,
            identityNumber: employee.identityNumber,
            address: employee.address,
            imagePath: employee.imagePath,
            associatedUserId: employee.associatedUserId,
            isActive: !employee.isActive,
          );
      await _load();
    } catch (e) {
      _show('No se pudo actualizar empleado: $e');
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
    final license = ref.watch(currentLicenseStatusProvider);
    return AppScaffold(
      title: 'Empleados TPV',
      currentRoute: '/tpv-empleados',
      onRefresh: _load,
      floatingActionButton: license.canWrite
          ? FloatingActionButton.small(
              tooltip: 'Nuevo empleado',
              onPressed: () => _openForm(),
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _employees.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: <Widget>[
                              const Text('No hay empleados registrados.'),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: () => _openForm(),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Crear empleado'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      key: const PageStorageKey<String>('tpv-employees-list'),
                      cacheExtent: 360,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: _employees.length,
                      itemBuilder: (_, int index) {
                        final TpvEmployee employee = _employees[index];
                        final List<String> info = <String>[
                          if ((employee.sex ?? '').isNotEmpty)
                            'Sexo: ${_sexLabel(employee.sex!)}',
                          if ((employee.identityNumber ?? '').isNotEmpty)
                            'CI: ${employee.identityNumber}',
                          if ((employee.associatedUsername ?? '').isNotEmpty)
                            'Usuario: ${employee.associatedUsername}',
                          employee.isActive ? 'Activo' : 'Inactivo',
                        ];
                        return KeyedSubtree(
                          key: ValueKey<String>(employee.id),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: _employeeAvatar(
                                imagePath: employee.imagePath,
                                radius: 20,
                                backgroundColor: employee.isActive
                                    ? const Color(0xFFE3F5EE)
                                    : const Color(0xFFE9E5F5),
                                iconColor: employee.isActive
                                    ? const Color(0xFF148A65)
                                    : const Color(0xFF5A4D88),
                              ),
                              title: Text(
                                employee.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                info.join(' • '),
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: <Widget>[
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () =>
                                        _openForm(employee: employee),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: employee.isActive
                                        ? 'Desactivar'
                                        : 'Activar',
                                    onPressed: () => _toggleEmployee(employee),
                                    icon: Icon(
                                      employee.isActive
                                          ? Icons.person_off_outlined
                                          : Icons.person_add_alt,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _TpvEmployeeFormPage extends ConsumerStatefulWidget {
  const _TpvEmployeeFormPage({this.employee});

  final TpvEmployee? employee;

  @override
  ConsumerState<_TpvEmployeeFormPage> createState() =>
      _TpvEmployeeFormPageState();
}

class _TpvEmployeeFormPageState extends ConsumerState<_TpvEmployeeFormPage> {
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _identityCtrl;
  late final TextEditingController _addressCtrl;
  List<TpvUserOption> _userOptions = <TpvUserOption>[];
  String? _selectedSex;
  String? _selectedUserId;
  String? _imagePath;
  bool _loadingUsers = true;
  bool _saving = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final TpvEmployee? employee = widget.employee;
    _nameCtrl = TextEditingController(text: employee?.name ?? '');
    _identityCtrl = TextEditingController(text: employee?.identityNumber ?? '');
    _addressCtrl = TextEditingController(text: employee?.address ?? '');
    _selectedSex = employee?.sex;
    _selectedUserId = employee?.associatedUserId;
    _imagePath = employee?.imagePath;
    _loadUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final List<TpvUserOption> options =
          await ref.read(tpvLocalDataSourceProvider).listActiveUserOptions();
      if (!mounted) {
        return;
      }
      setState(() {
        _userOptions = options;
        if (_selectedUserId != null &&
            options.every((TpvUserOption row) => row.id != _selectedUserId)) {
          _selectedUserId = null;
        }
        _loadingUsers = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _userOptions = <TpvUserOption>[];
        _selectedUserId = null;
        _loadingUsers = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final _EmployeeImageAction? action =
        await showModalBottomSheet<_EmployeeImageAction>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () =>
                    Navigator.of(context).pop(_EmployeeImageAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camara'),
                onTap: () =>
                    Navigator.of(context).pop(_EmployeeImageAction.camera),
              ),
              if ((_imagePath ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Quitar imagen'),
                  onTap: () =>
                      Navigator.of(context).pop(_EmployeeImageAction.remove),
                ),
            ],
          ),
        );
      },
    );
    if (action == null) {
      return;
    }
    if (action == _EmployeeImageAction.remove) {
      setState(() => _imagePath = null);
      return;
    }
    final XFile? file = await _imagePicker.pickImage(
      source: action == _EmployeeImageAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (file == null || !mounted) {
      return;
    }
    setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _show('El nombre es obligatorio.');
      return;
    }

    setState(() => _saving = true);
    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      if (_isEditing) {
        await ds.updateEmployee(
          employeeId: widget.employee!.id,
          name: name,
          code: widget.employee!.code,
          sex: _selectedSex,
          identityNumber: _identityCtrl.text,
          address: _addressCtrl.text,
          imagePath: _imagePath,
          associatedUserId: _selectedUserId,
          isActive: widget.employee!.isActive,
        );
      } else {
        await ds.createEmployee(
          name: name,
          sex: _selectedSex,
          identityNumber: _identityCtrl.text,
          address: _addressCtrl.text,
          imagePath: _imagePath,
          associatedUserId: _selectedUserId,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('saved');
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
      }
      _show('No se pudo guardar empleado: $e');
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
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(_isEditing ? 'Editar empleado' : 'Nuevo empleado'),
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickImage,
                child: _employeeAvatar(
                  imagePath: _imagePath,
                  radius: 42,
                  backgroundColor: isDark
                      ? const Color(0xFF312948)
                      : const Color(0xFFE7E1F7),
                  iconColor: isDark
                      ? const Color(0xFFB8A9F1)
                      : const Color(0xFF5A4D88),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Imagen del empleado'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Ana Perez',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedSex,
              decoration: const InputDecoration(labelText: 'Sexo'),
              items: const <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin especificar'),
                ),
                DropdownMenuItem<String?>(
                  value: 'F',
                  child: Text('Femenino'),
                ),
                DropdownMenuItem<String?>(
                  value: 'M',
                  child: Text('Masculino'),
                ),
                DropdownMenuItem<String?>(
                  value: 'X',
                  child: Text('Otro'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (String? value) {
                      setState(() => _selectedSex = value);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _identityCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Numero de identidad (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Direccion',
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingUsers)
              const LinearProgressIndicator(minHeight: 3)
            else
              DropdownButtonFormField<String?>(
                initialValue: _selectedUserId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Usuario asociado',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin usuario asociado'),
                  ),
                  ..._userOptions.map(
                    (TpvUserOption user) => DropdownMenuItem<String?>(
                      value: user.id,
                      child: Text(user.username),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (String? value) {
                        setState(() => _selectedUserId = value);
                      },
              ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar empleado'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _EmployeeImageAction {
  gallery,
  camera,
  remove,
}

class _TpvFormPage extends ConsumerStatefulWidget {
  const _TpvFormPage({this.terminal});

  final PosTerminal? terminal;

  @override
  ConsumerState<_TpvFormPage> createState() => _TpvFormPageState();
}

class _TpvFormPageState extends ConsumerState<_TpvFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _currencyCodeCtrl;
  late final TextEditingController _currencySymbolCtrl;
  late final TextEditingController _denominationsCtrl;

  bool _payCash = true;
  bool _payCard = false;
  bool _payTransfer = false;
  bool _payWallet = false;
  bool _saving = false;

  bool get _isEditing => widget.terminal != null;

  @override
  void initState() {
    super.initState();
    final TpvTerminalConfig config = widget.terminal == null
        ? TpvTerminalConfig.defaults
        : ref
            .read(tpvLocalDataSourceProvider)
            .configFromTerminal(widget.terminal!);

    _nameCtrl = TextEditingController(text: widget.terminal?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.terminal?.code ?? '');
    _currencyCodeCtrl = TextEditingController(text: config.currencyCode);
    _currencySymbolCtrl = TextEditingController(text: config.currencySymbol);
    _denominationsCtrl = TextEditingController(
      text: config.cashDenominationsCents
          .map((int cents) =>
              (cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2))
          .join(', '),
    );
    _payCash = config.paymentMethods.contains('cash');
    _payCard = config.paymentMethods.contains('card');
    _payTransfer = config.paymentMethods.contains('transfer');
    _payWallet = config.paymentMethods.contains('wallet');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _currencyCodeCtrl.dispose();
    _currencySymbolCtrl.dispose();
    _denominationsCtrl.dispose();
    super.dispose();
  }

  Future<void> _suggestCode() async {
    final String name = _nameCtrl.text.trim();
    final String suggested =
        await ref.read(tpvLocalDataSourceProvider).suggestTerminalCode(name);
    if (!mounted) {
      return;
    }
    setState(() {
      _codeCtrl.text = suggested;
    });
  }

  Future<void> _save() async {
    final String name = _nameCtrl.text.trim();
    final String code = _codeCtrl.text.trim();
    final String currencyCode = _currencyCodeCtrl.text.trim().toUpperCase();
    final String currencySymbol = _currencySymbolCtrl.text.trim();
    final List<String> methods = _selectedPaymentMethods();
    final List<int> denominations =
        _parseDenominationsInput(_denominationsCtrl.text);

    if (name.isEmpty) {
      _show('El nombre es obligatorio.');
      return;
    }
    if (currencyCode.isEmpty) {
      _show('La moneda del TPV es obligatoria.');
      return;
    }
    if (currencySymbol.isEmpty) {
      _show('El simbolo de moneda del TPV es obligatorio.');
      return;
    }
    if (methods.isEmpty) {
      _show('Selecciona al menos un metodo de pago.');
      return;
    }
    if (denominations.isEmpty) {
      _show('Configura al menos una denominacion de efectivo.');
      return;
    }

    final TpvTerminalConfig config = TpvTerminalConfig(
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      paymentMethods: methods,
      cashDenominationsCents: denominations,
    );

    setState(() => _saving = true);
    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      if (_isEditing) {
        await ds.updateTerminal(
          terminalId: widget.terminal!.id,
          name: name,
          code: code,
          config: config,
        );
      } else {
        await ds.createTerminal(name: name, code: code, config: config);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
      }
      _show('No se pudo guardar TPV: $e');
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _selectedPaymentMethods() {
    final List<String> methods = <String>[];
    if (_payCash) {
      methods.add('cash');
    }
    if (_payCard) {
      methods.add('card');
    }
    if (_payTransfer) {
      methods.add('transfer');
    }
    if (_payWallet) {
      methods.add('wallet');
    }
    return methods;
  }

  List<int> _parseDenominationsInput(String raw) {
    final List<int> cents = <int>[];
    final List<String> chunks = raw.split(RegExp(r'[,\n;]+'));
    for (final String chunk in chunks) {
      final String clean = chunk.trim();
      if (clean.isEmpty) {
        continue;
      }
      final double? value = double.tryParse(clean.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        continue;
      }
      cents.add((value * 100).round());
    }
    final List<int> unique = cents.toSet().toList()
      ..sort((int a, int b) => b.compareTo(a));
    return unique;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(_isEditing ? 'Editar TPV' : 'Nuevo TPV'),
        leading: IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Nombre del TPV',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Ej: Caja Principal',
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Codigo del TPV',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Se genera automaticamente si lo dejas vacio',
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Sugerir codigo',
                  onPressed: _saving ? null : _suggestCode,
                  icon: const Icon(Icons.auto_fix_high_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Moneda del TPV',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _currencyCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Codigo',
                      hintText: 'USD, EUR, CUP',
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _currencySymbolCtrl,
                    decoration: InputDecoration(
                      labelText: 'Simbolo',
                      hintText: r'$',
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Metodos de pago habilitados',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilterChip(
                  label: const Text('Efectivo'),
                  selected: _payCash,
                  onSelected: (bool v) => setState(() => _payCash = v),
                ),
                FilterChip(
                  label: const Text('Tarjeta'),
                  selected: _payCard,
                  onSelected: (bool v) => setState(() => _payCard = v),
                ),
                FilterChip(
                  label: const Text('Transferencia'),
                  selected: _payTransfer,
                  onSelected: (bool v) => setState(() => _payTransfer = v),
                ),
                FilterChip(
                  label: const Text('Billetera'),
                  selected: _payWallet,
                  onSelected: (bool v) => setState(() => _payWallet = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Denominaciones de efectivo',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _denominationsCtrl,
              decoration: InputDecoration(
                hintText: 'Ej: 100, 50, 20, 10, 5, 1, 0.25',
                helperText: 'Separadas por coma. Se usan en cierre de turno.',
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Al guardar el TPV se crea automaticamente su almacen asociado.',
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving
                    ? 'Guardando...'
                    : _isEditing
                        ? 'Actualizar TPV'
                        : 'Crear TPV'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
