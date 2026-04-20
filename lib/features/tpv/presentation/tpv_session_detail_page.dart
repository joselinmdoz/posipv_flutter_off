import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../reportes/presentation/widgets/ipv_reporte_detail_page.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_providers.dart';

class TpvSessionDetailPage extends ConsumerStatefulWidget {
  const TpvSessionDetailPage({
    super.key,
    required this.terminal,
    required this.sessionRow,
    this.initialBreakdown = const <TpvSessionCashBreakdown>[],
  });

  final TpvTerminalView terminal;
  final TpvSessionWithUser sessionRow;
  final List<TpvSessionCashBreakdown> initialBreakdown;

  @override
  ConsumerState<TpvSessionDetailPage> createState() =>
      _TpvSessionDetailPageState();
}

class _TpvSessionDetailPageState extends ConsumerState<TpvSessionDetailPage> {
  static const int _salesPageSize = 80;

  bool _loading = true;
  bool _loadingMoreSales = false;
  bool _hasMoreSales = true;
  TpvSessionSalesSummary _salesSummary = const TpvSessionSalesSummary(
    postedSalesCount: 0,
    postedSubtotalCents: 0,
    postedTaxCents: 0,
    postedTotalCents: 0,
    archivedSalesCount: 0,
  );
  Map<String, int> _paymentsByMethod = <String, int>{};
  List<TpvSessionCashBreakdown> _cashBreakdown = <TpvSessionCashBreakdown>[];
  List<TpvSessionSaleView> _sales = <TpvSessionSaleView>[];
  IpvReportSummaryStat? _ipvReport;
  Map<String, String> _paymentMethodLabelsByCode = <String, String>{};
  late PosSession _sessionSnapshot;

  PosSession get _session => _sessionSnapshot;

  @override
  void initState() {
    super.initState();
    _sessionSnapshot = widget.sessionRow.session;
    _cashBreakdown = widget.initialBreakdown;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadDetails());
    });
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);
    try {
      final TpvLocalDataSource tpvDs = ref.read(tpvLocalDataSourceProvider);
      final ReportesLocalDataSource reportesDs =
          ref.read(reportesLocalDataSourceProvider);

      final Future<TpvSessionSalesSummary> summaryFuture =
          tpvDs.getSessionSalesSummary(_session.id);
      final Future<Map<String, int>> paymentsFuture =
          tpvDs.getSessionExpectedPaymentsByMethod(_session.id);
      final Future<List<AppPaymentMethodSetting>> paymentMethodsFuture = ref
          .read(configuracionLocalDataSourceProvider)
          .loadPaymentMethodSettings();
      final Future<List<TpvSessionSaleView>> salesFuture =
          tpvDs.listSessionSales(_session.id, limit: _salesPageSize);
      final Future<IpvReportSummaryStat?> ipvFuture =
          reportesDs.findIpvReportBySessionId(_session.id);
      final Future<List<TpvSessionCashBreakdown>> breakdownFuture =
          _cashBreakdown.isNotEmpty
              ? Future<List<TpvSessionCashBreakdown>>.value(_cashBreakdown)
              : tpvDs.listSessionCashBreakdown(_session.id);

      final TpvSessionSalesSummary summary = await summaryFuture;
      final Map<String, int> payments = await paymentsFuture;
      List<AppPaymentMethodSetting> paymentSettings =
          const <AppPaymentMethodSetting>[];
      try {
        paymentSettings = await paymentMethodsFuture;
      } catch (_) {}
      final List<TpvSessionSaleView> sales = await salesFuture;
      final IpvReportSummaryStat? ipv = await ipvFuture;
      final List<TpvSessionCashBreakdown> breakdown = await breakdownFuture;

      if (!mounted) {
        return;
      }
      setState(() {
        _salesSummary = summary;
        _paymentsByMethod = payments;
        _paymentMethodLabelsByCode =
            buildPaymentMethodLabelMap(paymentSettings);
        _sales = sales;
        _hasMoreSales = sales.length == _salesPageSize;
        _loadingMoreSales = false;
        _ipvReport = ipv;
        _cashBreakdown = breakdown;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar los detalles del turno: $e');
    }
  }

  Future<void> _loadMoreSales() async {
    if (_loading || _loadingMoreSales || !_hasMoreSales) {
      return;
    }
    setState(() => _loadingMoreSales = true);
    try {
      final List<TpvSessionSaleView> nextPage =
          await ref.read(tpvLocalDataSourceProvider).listSessionSales(
                _session.id,
                limit: _salesPageSize,
                offset: _sales.length,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        _sales = <TpvSessionSaleView>[..._sales, ...nextPage];
        _hasMoreSales = nextPage.length == _salesPageSize;
        _loadingMoreSales = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingMoreSales = false);
      _show('No se pudieron cargar mas ventas del turno: $e');
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _sessionCode(String id) {
    final String digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      return '#${digits.substring(digits.length - 4)}';
    }
    return '#${id.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}';
  }

  String _money(int cents) {
    final String symbol = widget.terminal.terminal.currencySymbol;
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _date(DateTime value) {
    final DateTime local = value.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  String _paymentMethodLabel(String method) {
    final String code = method.trim().toLowerCase();
    if (code.isEmpty) {
      return 'Metodo';
    }
    return _paymentMethodLabelsByCode[code] ?? defaultPaymentMethodLabel(code);
  }

  Future<void> _openIpv() async {
    final IpvReportSummaryStat? report = _ipvReport;
    if (report == null) {
      _show('Este turno no tiene reporte IPV asociado.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IpvReporteDetailPage(summary: report),
      ),
    );
  }

  void _openPos() {
    context.push('/ventas-pos');
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null) {
      return null;
    }
    if (!mounted) {
      return null;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _adjustSessionTimeline() async {
    final session = ref.read(currentSessionProvider);
    if (session == null || !session.isAdmin) {
      _show('Solo administrador puede ajustar fecha/hora de turnos.');
      return;
    }

    DateTime draftOpenedAt = _session.openedAt.toLocal();
    DateTime? draftClosedAt = _session.closedAt?.toLocal();
    final bool isOpen = _session.status.trim().toLowerCase() == 'open';
    final TextEditingController noteCtrl = TextEditingController();
    try {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder:
                (BuildContext context, void Function(void Function()) setD) {
              Future<void> pickOpenedAt() async {
                final DateTime now = DateTime.now();
                final DateTime firstDate = DateTime(now.year - 5, 1, 1);
                final DateTime? picked = await _pickDateTime(
                  initial: draftOpenedAt,
                  firstDate: firstDate,
                  lastDate: now,
                );
                if (picked == null) {
                  return;
                }
                setD(() {
                  draftOpenedAt = picked;
                  if (draftClosedAt != null &&
                      draftClosedAt!.isBefore(draftOpenedAt)) {
                    draftClosedAt = draftOpenedAt;
                  }
                });
              }

              Future<void> pickClosedAt() async {
                final DateTime now = DateTime.now();
                final DateTime firstDate = DateTime(now.year - 5, 1, 1);
                final DateTime? picked = await _pickDateTime(
                  initial: draftClosedAt ?? draftOpenedAt,
                  firstDate: firstDate,
                  lastDate: now,
                );
                if (picked == null) {
                  return;
                }
                setD(() {
                  draftClosedAt = picked;
                });
              }

              return AlertDialog(
                title: const Text('Ajustar fecha/hora del turno'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.login_rounded),
                        title: const Text('Apertura'),
                        subtitle: Text(_date(draftOpenedAt)),
                        trailing: TextButton(
                          onPressed: pickOpenedAt,
                          child: const Text('Cambiar'),
                        ),
                      ),
                      if (!isOpen)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout_rounded),
                          title: const Text('Cierre'),
                          subtitle: Text(
                            draftClosedAt == null ? '-' : _date(draftClosedAt!),
                          ),
                          trailing: TextButton(
                            onPressed: pickClosedAt,
                            child: const Text('Cambiar'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteCtrl,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Nota (opcional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Se validará que no haya solapamiento con otros turnos y que las ventas queden dentro del rango.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!isOpen &&
                          draftClosedAt != null &&
                          draftClosedAt!.isBefore(draftOpenedAt)) {
                        _show('El cierre no puede ser anterior a la apertura.');
                        return;
                      }
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: const Text('Guardar'),
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

      final PosSession updated = await ref
          .read(tpvLocalDataSourceProvider)
          .updateSessionTimeline(
            sessionId: _session.id,
            actorUserId: session.userId,
            openedAt: draftOpenedAt,
            closedAt: isOpen ? null : draftClosedAt,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
      if (!mounted) {
        return;
      }
      setState(() => _sessionSnapshot = updated);
      await _loadDetails();
      if (!mounted) {
        return;
      }
      _show('Fecha/hora del turno actualizada correctamente.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo ajustar el turno: $e');
    } finally {
      noteCtrl.dispose();
    }
  }

  Widget _buildGeneralCard(bool isDark) {
    final bool isOpen = _session.status == 'open';
    final String employeeNames = widget.sessionRow.responsibleEmployees.isEmpty
        ? widget.sessionRow.user.username
        : widget.sessionRow.responsibleEmployees
            .map((TpvEmployee row) => row.name.trim())
            .where((String row) => row.isNotEmpty)
            .toSet()
            .join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Turno ${_sessionCode(_session.id)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFF64748B).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'ABIERTO' : 'CERRADO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isOpen
                        ? const Color(0xFF047857)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kv('TPV', widget.terminal.terminal.name),
          _kv('Almacén', widget.terminal.warehouse.name),
          _kv('Usuario apertura', widget.sessionRow.user.username),
          _kv('Empleado(s)', employeeNames),
          _kv('Apertura', _date(_session.openedAt)),
          _kv(
            'Cierre',
            _session.closedAt == null ? '-' : _date(_session.closedAt!),
          ),
          _kv('Fondo inicial', _money(_session.openingFloatCents)),
          _kv(
            'Efectivo cierre',
            _money(_session.closingCashCents ?? 0),
          ),
          _kv('Nota',
              (_session.note ?? '').trim().isEmpty ? '-' : _session.note!),
        ],
      ),
    );
  }

  Widget _buildSalesSummaryCard(bool isDark) {
    final int discountsCents = (_salesSummary.postedSubtotalCents +
            _salesSummary.postedTaxCents -
            _salesSummary.postedTotalCents)
        .clamp(0, 1 << 30);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Resumen de Ventas',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _kv('Ventas publicadas', _salesSummary.postedSalesCount.toString()),
          _kv('Ventas archivadas', _salesSummary.archivedSalesCount.toString()),
          _kv('Subtotal', _money(_salesSummary.postedSubtotalCents)),
          _kv('Impuestos', _money(_salesSummary.postedTaxCents)),
          _kv('Descuentos', _money(discountsCents)),
          _kv('Total neto', _money(_salesSummary.postedTotalCents)),
        ],
      ),
    );
  }

  Widget _buildPaymentsCard(bool isDark) {
    final List<MapEntry<String, int>> entries = _paymentsByMethod.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final int total = entries.fold<int>(0, (sum, row) => sum + row.value);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Pagos del Turno',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            const Text(
              'Sin pagos registrados.',
              style: TextStyle(fontSize: 13),
            ),
          for (final MapEntry<String, int> row in entries)
            _kv(_paymentMethodLabel(row.key), _money(row.value)),
          if (entries.isNotEmpty) ...<Widget>[
            const Divider(height: 20),
            _kv('Total', _money(total), valueBold: true),
          ],
        ],
      ),
    );
  }

  Widget _buildCashBreakdownCard(bool isDark) {
    if (_cashBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    final int total = _cashBreakdown.fold<int>(
      0,
      (int sum, TpvSessionCashBreakdown row) => sum + row.subtotalCents,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Desglose de Cierre',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          for (final TpvSessionCashBreakdown row in _cashBreakdown)
            _kv(
              '${_money(row.denominationCents)} x ${row.unitCount}',
              _money(row.subtotalCents),
            ),
          const Divider(height: 20),
          _kv('Total cierre', _money(total), valueBold: true),
        ],
      ),
    );
  }

  Widget _buildSalesListCard(bool isDark) {
    final int totalSessionSales =
        _salesSummary.postedSalesCount + _salesSummary.archivedSalesCount;
    final String loadedLabel = _hasMoreSales
        ? '${_sales.length} de $totalSessionSales'
        : _sales.length.toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ventas del Turno ($loadedLabel)',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 10),
          if (_sales.isEmpty)
            const Text(
              'Sin ventas registradas en este turno.',
              style: TextStyle(fontSize: 13),
            ),
          for (final TpvSessionSaleView sale in _sales)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          sale.folio,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _date(sale.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          sale.customerName ?? 'Cliente general',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (sale.paymentMethods.isNotEmpty)
                          Text(
                            sale.paymentMethods
                                .map(_paymentMethodLabel)
                                .join(' • '),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        _money(sale.totalCents),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sale.status == 'posted'
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFB91C1C).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sale.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: sale.status == 'posted'
                                ? const Color(0xFF047857)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_sales.isNotEmpty && (_hasMoreSales || _loadingMoreSales))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadingMoreSales ? null : _loadMoreSales,
                icon: _loadingMoreSales
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(
                  _loadingMoreSales ? 'Cargando...' : 'Ver mas ventas',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueBold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isOpen = _session.status == 'open';
    final bool isAdmin = ref.watch(currentSessionProvider)?.isAdmin ?? false;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Detalle ${_sessionCode(_session.id)}'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _loadDetails,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (isAdmin)
            IconButton(
              onPressed: _loading ? null : _adjustSessionTimeline,
              icon: const Icon(Icons.edit_calendar_rounded),
              tooltip: 'Ajustar fecha/hora',
            ),
          if (_ipvReport != null)
            IconButton(
              onPressed: _openIpv,
              icon: const Icon(Icons.analytics_rounded),
              tooltip: 'Abrir IPV',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: <Widget>[
                _buildGeneralCard(isDark),
                const SizedBox(height: 12),
                _buildSalesSummaryCard(isDark),
                const SizedBox(height: 12),
                _buildPaymentsCard(isDark),
                if (_cashBreakdown.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _buildCashBreakdownCard(isDark),
                ],
                const SizedBox(height: 12),
                _buildSalesListCard(isDark),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _ipvReport == null ? null : _openIpv,
                icon: const Icon(Icons.analytics_rounded),
                label: const Text('Ver IPV'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: isOpen ? _openPos : null,
                icon: const Icon(Icons.point_of_sale_rounded),
                label: const Text('Ir al POS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
