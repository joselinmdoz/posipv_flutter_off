import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/user_session.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../reportes/presentation/widgets/ipv_reporte_detail_page.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_providers.dart';
import 'widgets/tpv_history_bottom_navigation.dart';
import 'widgets/tpv_session_history_card.dart';
import 'widgets/tpv_session_history_compact_card.dart';
import 'widgets/tpv_session_history_filter_tabs.dart';

class TpvSessionHistoryPage extends ConsumerStatefulWidget {
  const TpvSessionHistoryPage({
    super.key,
    required this.terminal,
  });

  final TpvTerminalView terminal;

  @override
  ConsumerState<TpvSessionHistoryPage> createState() =>
      _TpvSessionHistoryPageState();
}

class _TpvSessionHistoryPageState extends ConsumerState<TpvSessionHistoryPage> {
  bool _loading = true;
  bool _searchVisible = false;
  int _selectedTabIndex = 0;
  String _search = '';

  TpvTerminalConfig _config = TpvTerminalConfig.defaults;
  List<_SessionHistoryRecord> _records = <_SessionHistoryRecord>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      final List<TpvSessionWithUser> sessions = await ds.listSessionHistory(
        widget.terminal.terminal.id,
        limit: 60,
      );
      final Map<String, List<TpvSessionCashBreakdown>> breakdownBySession =
          await ds.listCashBreakdownForSessions(
        sessions.map((TpvSessionWithUser row) => row.session.id),
      );
      final TpvTerminalConfig config =
          ds.configFromTerminal(widget.terminal.terminal);

      final Map<String, int> salesBySession = <String, int>{};
      final Iterable<TpvSessionWithUser> openSessions = sessions.where(
        (TpvSessionWithUser row) => row.session.status == 'open',
      );
      for (final TpvSessionWithUser row in openSessions) {
        final Map<String, int> totals =
            await ds.getSessionExpectedPaymentsByMethod(row.session.id);
        final int totalSales = totals.values.fold<int>(
          0,
          (int sum, int value) => sum + value,
        );
        salesBySession[row.session.id] = totalSales;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _config = config;
        _records = sessions
            .map(
              (TpvSessionWithUser row) => _SessionHistoryRecord(
                row: row,
                breakdown: breakdownBySession[row.session.id] ??
                    const <TpvSessionCashBreakdown>[],
                currentSalesCents: salesBySession[row.session.id] ?? 0,
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar historial de turnos: $e');
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

  List<_SessionHistoryRecord> _filteredRecords() {
    Iterable<_SessionHistoryRecord> source = _records;
    if (_selectedTabIndex == 1) {
      source = source.where((r) => r.row.session.status == 'open');
    } else if (_selectedTabIndex == 2) {
      source = source.where((r) => r.row.session.status != 'open');
    }

    final String query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      source = source.where((r) {
        final String sessionCode = _sessionCode(r.row.session.id).toLowerCase();
        final String username = r.row.user.username.toLowerCase();
        final String title = _titleFor(r).toLowerCase();
        final String responsible = _responsibleFor(r).toLowerCase();
        return sessionCode.contains(query) ||
            username.contains(query) ||
            title.contains(query) ||
            responsible.contains(query);
      });
    }

    return source.toList(growable: false);
  }

  String _sessionCode(String id) {
    final String digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      return '#${digits.substring(digits.length - 4)}';
    }
    int hash = 0;
    for (final int code in id.codeUnits) {
      hash = (hash * 31 + code) % 10000;
    }
    return '#${hash.toString().padLeft(4, '0')}';
  }

  String _titleFor(_SessionHistoryRecord record) {
    final String username = record.row.user.username.trim();
    if (username.toLowerCase() == 'admin') {
      return 'Turno Administrador';
    }
    final int hour = record.row.session.openedAt.hour;
    if (record.row.session.status == 'open') {
      if (hour < 12) {
        return 'Turno Matutino';
      }
      if (hour < 18) {
        return 'Turno Vespertino';
      }
      return 'Turno Nocturno';
    }
    return 'Turno ${_capitalize(username)}';
  }

  String _capitalize(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      return 'General';
    }
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _responsibleFor(_SessionHistoryRecord record) {
    if (record.row.responsibleEmployees.isNotEmpty) {
      return record.row.responsibleEmployees.first.name;
    }
    return record.row.user.username;
  }

  String _formatMoney(int cents) {
    return '${_config.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatSessionDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime local = date.toLocal();
    final String dd = local.day.toString().padLeft(2, '0');
    final String mon = months[local.month - 1];
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String hh = hour12.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    final String suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$dd $mon, $hh:$mm $suffix';
  }

  String _openingLabel(DateTime openedAt) {
    final DateTime now = DateTime.now();
    final DateTime local = openedAt.toLocal();
    final bool sameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    if (!sameDay) {
      return _formatSessionDate(local);
    }
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String hh = hour12.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    final String suffix = local.hour >= 12 ? 'PM' : 'AM';
    return 'Hoy, $hh:$mm $suffix';
  }

  Future<void> _openClosedDetails(_SessionHistoryRecord record) async {
    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final IpvReportSummaryStat? report =
          await reportesDs.findIpvReportBySessionId(record.row.session.id);
      if (report == null) {
        await _showFallbackSessionDetail(record);
        return;
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => IpvReporteDetailPage(summary: report),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo abrir el detalle del turno: $e');
    }
  }

  Future<void> _showFallbackSessionDetail(_SessionHistoryRecord record) async {
    final int breakdownTotal = record.breakdown.fold<int>(
      0,
      (int sum, TpvSessionCashBreakdown line) => sum + line.subtotalCents,
    );
    final int closingCashCents = breakdownTotal > 0
        ? breakdownTotal
        : (record.row.session.closingCashCents ?? 0);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_titleFor(record)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Turno: ${_sessionCode(record.row.session.id)}'),
                const SizedBox(height: 6),
                Text(
                    'Apertura: ${_formatSessionDate(record.row.session.openedAt)}'),
                const SizedBox(height: 6),
                Text(
                  'Cierre: ${record.row.session.closedAt == null ? 'En curso...' : _formatSessionDate(record.row.session.closedAt!)}',
                ),
                const SizedBox(height: 6),
                Text('Responsable: ${_responsibleFor(record)}'),
                const SizedBox(height: 10),
                Text(
                  'Efectivo cierre: ${_formatMoney(closingCashCents)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _monitorOpenShift() {
    final UserSession? current = ref.read(currentSessionProvider);
    if (current != null) {
      ref.read(currentSessionProvider.notifier).state =
          current.copyWith(activeTerminalId: widget.terminal.terminal.id);
    }
    context.go('/ventas-pos');
  }

  void _onBottomRouteTap(String route) {
    if (route == '/tpv-history') {
      return;
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<_SessionHistoryRecord> records = _filteredRecords();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Historial de Turnos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _search = '';
                }
              });
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      bottomNavigationBar: TpvHistoryBottomNavigation(
        onRouteTap: _onBottomRouteTap,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          TpvSessionHistoryFilterTabs(
            selectedIndex: _selectedTabIndex,
            onChanged: (int value) {
              setState(() => _selectedTabIndex = value);
            },
          ),
          if (_searchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                onChanged: (String value) {
                  setState(() => _search = value);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por turno, usuario o responsable...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFD8DEE9),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                    ? Center(
                        child: Text(
                          'No hay turnos para mostrar.',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                          itemCount: records.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (BuildContext context, int index) {
                            if (index == 0) {
                              return Text(
                                'TURNOS RECIENTES',
                                style: TextStyle(
                                  fontSize: 32 / 2,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  letterSpacing: 0.4,
                                ),
                              );
                            }

                            final _SessionHistoryRecord row =
                                records[index - 1];
                            final bool isOpen =
                                row.row.session.status == 'open';
                            final int breakdownTotal = row.breakdown.fold<int>(
                              0,
                              (int sum, TpvSessionCashBreakdown item) =>
                                  sum + item.subtotalCents,
                            );
                            final int closingCash = breakdownTotal > 0
                                ? breakdownTotal
                                : (row.row.session.closingCashCents ?? 0);

                            final bool renderCompact =
                                _selectedTabIndex == 0 && index > 2;

                            if (renderCompact) {
                              return TpvSessionHistoryCompactCard(
                                sessionCode: _sessionCode(row.row.session.id),
                                title:
                                    _formatSessionDate(row.row.session.openedAt)
                                        .split(',')
                                        .first,
                                amountText: _formatMoney(closingCash),
                                onTap: () => _openClosedDetails(row),
                              );
                            }

                            return TpvSessionHistoryCard(
                              isOpen: isOpen,
                              sessionCode: _sessionCode(row.row.session.id),
                              title: _titleFor(row),
                              openingText:
                                  _openingLabel(row.row.session.openedAt),
                              closingText: isOpen
                                  ? 'En curso...'
                                  : _formatSessionDate(
                                      row.row.session.closedAt ??
                                          row.row.session.openedAt,
                                    ),
                              responsible: _responsibleFor(row),
                              currencySymbol: _config.currencySymbol,
                              breakdown: row.breakdown,
                              closingCashCents: closingCash,
                              currentSalesCents: row.currentSalesCents,
                              onPrimaryAction: isOpen
                                  ? _monitorOpenShift
                                  : () => _openClosedDetails(row),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryRecord {
  const _SessionHistoryRecord({
    required this.row,
    required this.breakdown,
    required this.currentSalesCents,
  });

  final TpvSessionWithUser row;
  final List<TpvSessionCashBreakdown> breakdown;
  final int currentSalesCents;
}
