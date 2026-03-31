import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../reportes/presentation/widgets/ipv_reporte_detail_page.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_providers.dart';
import 'widgets/tpv_history_bottom_navigation.dart';

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
  String _search = '';
  int _selectedTabIndex = 0; // 0: Todos, 1: Abiertos, 2: Cerrados

  TpvTerminalConfig _config = TpvTerminalConfig.defaults;
  List<_SessionHistoryRecord> _records = <_SessionHistoryRecord>[];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final TpvLocalDataSource ds = ref.read(tpvLocalDataSourceProvider);
      final List<TpvSessionWithUser> sessions = await ds.listSessionHistory(
        widget.terminal.terminal.id,
        limit: 100,
      );
      final Map<String, List<TpvSessionCashBreakdown>> breakdownBySession =
          await ds.listCashBreakdownForSessions(
        sessions.map((row) => row.session.id),
      );
      final TpvTerminalConfig config =
          ds.configFromTerminal(widget.terminal.terminal);

      final Map<String, int> salesBySession = <String, int>{};
      final Iterable<TpvSessionWithUser> openSessions = sessions.where(
        (row) => row.session.status == 'open',
      );
      for (final row in openSessions) {
        final totals =
            await ds.getSessionExpectedPaymentsByMethod(row.session.id);
        final int totalSales = totals.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        salesBySession[row.session.id] = totalSales;
      }

      if (!mounted) return;

      setState(() {
        _config = config;
        _records = sessions
            .map(
              (row) => _SessionHistoryRecord(
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
      if (mounted) {
        setState(() => _loading = false);
        _show('Error: $e');
      }
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
        return sessionCode.contains(query) || username.contains(query);
      });
    }
    return source.toList();
  }

  String _sessionCode(String id) {
    final String digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      return '#${digits.substring(digits.length - 4)}';
    }
    return '#${id.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}';
  }

  String _money(int cents) {
    return '${_config.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String h = (local.hour % 12 == 0 ? 12 : local.hour % 12)
        .toString()
        .padLeft(2, '0');
    final String min = local.minute.toString().padLeft(2, '0');
    final String period = local.hour >= 12 ? 'PM' : 'AM';
    return '$d/$m, $h:$min $period';
  }

  Future<void> _openDetails(_SessionHistoryRecord record) async {
    if (record.row.session.status == 'open') {
      final current = ref.read(currentSessionProvider);
      if (current != null) {
        ref.read(currentSessionProvider.notifier).state =
            current.copyWith(activeTerminalId: widget.terminal.terminal.id);
      }
      context.push('/ventas-pos');
      return;
    }

    final reportesDs = ref.read(reportesLocalDataSourceProvider);
    try {
      final report =
          await reportesDs.findIpvReportBySessionId(record.row.session.id);
      if (!mounted) return;
      if (report == null) {
        _showFallbackDetail(record);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => IpvReporteDetailPage(summary: report)),
      );
    } catch (e) {
      _show('Error: $e');
    }
  }

  void _showFallbackDetail(_SessionHistoryRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Turno ${_sessionCode(record.row.session.id)}'),
        content: Text(
            'Apertura: ${_formatDate(record.row.session.openedAt)}\nResponsable: ${record.row.user.username}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? const Color(0xFF101622) : const Color(0xFFF1F5F9);
    final Color primaryColor = const Color(0xFF1152D4);
    final Color cardBg = isDark ? const Color(0xFF1A202E) : Colors.white;
    final Color mutedText = isDark ? Colors.white60 : Colors.black54;

    final List<_SessionHistoryRecord> filtered = _filteredRecords();

    // Stats calculations
    final int totalSalesCents = _records.fold(
        0,
        (sum, r) =>
            sum +
            (r.row.session.status == 'open'
                ? r.currentSalesCents
                : (r.row.session.closingCashCents ?? 0)));
    final int openShiftsCount =
        _records.where((r) => r.row.session.status == 'open').length;
    final int totalBaseCashCents =
        _records.fold(0, (sum, r) => sum + r.row.session.openingFloatCents);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: const Text('Historial de Turnos',
            style:
                TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Manrope')),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: TpvHistoryBottomNavigation(
        onRouteTap: (r) => r == '/tpv-history' ? null : context.go(r),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Grid
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildStatCard(
                          'Total Ventas',
                          _money(totalSalesCents),
                          Icons.payments_rounded,
                          const Color(0xFF1152D4),
                          isDark),
                      _buildStatCard(
                          'Turnos Activos',
                          openShiftsCount.toString(),
                          Icons.timer_rounded,
                          const Color(0xFF10B981),
                          isDark),
                      _buildStatCard(
                          'Fondo de Caja',
                          _money(totalBaseCashCents),
                          Icons.account_balance_wallet_rounded,
                          const Color(0xFFF59E0B),
                          isDark),
                    ],
                  ),
                ),

                // Filter Tabs & Search
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildTab('Todos', 0),
                            _buildTab('Abiertos', 1),
                            _buildTab('Cerrados', 2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar por turno o usuario...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: cardBg,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text('No se encontraron turnos.',
                              style: TextStyle(color: mutedText)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) {
                            final r = filtered[index];
                            return _buildShiftCard(
                                r, isDark, cardBg, mutedText, primaryColor);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A202E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Manrope')),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftCard(_SessionHistoryRecord record, bool isDark,
      Color cardBg, Color mutedText, Color primaryColor) {
    final bool isOpen = record.row.session.status == 'open';
    final String employeeName = record.row.responsibleEmployees.isNotEmpty
        ? record.row.responsibleEmployees.first.name
        : record.row.user.username;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(record),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar / Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFF64748B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOpen ? Icons.play_arrow_rounded : Icons.lock_rounded,
                    color: isOpen
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_sessionCode(record.row.session.id),
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: isOpen
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              isOpen ? 'ABIERTO' : 'CERRADO',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: isOpen
                                      ? const Color(0xFF10B981)
                                      : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(employeeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                        'Apertura: ${_formatDate(record.row.session.openedAt)}',
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(isOpen
                          ? record.currentSalesCents
                          : (record.row.session.closingCashCents ?? 0)),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          fontFamily: 'Manrope'),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: mutedText),
                  ],
                ),
              ],
            ),
          ),
        ),
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
