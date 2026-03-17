import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';

class IpvReportesPage extends ConsumerStatefulWidget {
  const IpvReportesPage({super.key});

  @override
  ConsumerState<IpvReportesPage> createState() => _IpvReportesPageState();
}

class _IpvReportesPageState extends ConsumerState<IpvReportesPage> {
  bool _loading = true;
  bool _loadingIpv = false;
  bool _showingIpvSheet = false;
  List<PosTerminal> _terminalOptions = <PosTerminal>[];
  String? _terminalId;
  DateTime? _fromDate;
  DateTime? _toDate;
  List<IpvReportSummaryStat> _reports = <IpvReportSummaryStat>[];

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
    final PerfTrace trace = PerfTrace('ipv_reportes.load');
    if (mounted) {
      setState(() => _loading = true);
    }
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final Future<List<PosTerminal>> terminalsFuture =
          ds.listIpvTerminalOptions();
      List<IpvReportSummaryStat> reports = await ds.listIpvReports(
        terminalId: _terminalId,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 200,
      );
      trace.mark('reportes cargados');
      final List<PosTerminal> terminals = await terminalsFuture;
      trace.mark('terminales cargados');
      if (_terminalId != null &&
          terminals.every((PosTerminal row) => row.id != _terminalId)) {
        _terminalId = null;
        reports = await ds.listIpvReports(
          terminalId: null,
          fromDate: _fromDate,
          toDate: _toDate,
          limit: 200,
        );
      }
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _terminalOptions = terminals;
        _reports = reports;
        _loading = false;
      });
      trace.end('ok');
    } catch (e, st) {
      debugPrint('IPV export failed (reportes/ipv_reportes_page). $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar IPV: $e')),
      );
    }
  }

  Future<void> _reloadIpvReports() async {
    if (mounted) {
      setState(() => _loadingIpv = true);
    }
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final List<IpvReportSummaryStat> reports = await ds.listIpvReports(
        terminalId: _terminalId,
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _reports = reports;
        _loadingIpv = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loadingIpv = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar IPV: $e')),
      );
    }
  }

  Widget _reportCard(IpvReportSummaryStat report) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? const Color(0xFF1C2430) : const Color(0xFFEFF3FB),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(report),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      report.terminalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDateTime(report.openedAt)} → ${report.closedAt == null ? '-' : _formatDateTime(report.closedAt!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_ipvSourceLabel(report.openingSource)} • ${report.lineCount} producto(s)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 88, maxWidth: 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      _moneyWithSymbol(
                        report.totalAmountCents,
                        report.currencySymbol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.status == 'open' ? 'IPV abierto' : 'IPV cerrado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFFB8A9F1)
                            : const Color(0xFF5B4B8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _fromDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _toDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _toDate = picked);
  }

  void _clearFilters() {
    setState(() {
      _terminalId = null;
      _fromDate = null;
      _toDate = null;
    });
    _reloadIpvReports();
  }

  Future<void> _exportIpv(IpvReportSummaryStat report, String format) async {
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final String path = format == 'pdf'
          ? await ds.exportIpvReportPdf(report.reportId)
          : await ds.exportIpvReportCsv(report.reportId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado $format en: $path')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar IPV: $e')),
      );
    }
  }

  Future<void> _closeSheetAndExportIpv(
    BuildContext sheetContext,
    IpvReportSummaryStat report,
    String format,
  ) async {
    Navigator.of(sheetContext).pop();
    await _exportIpv(report, format);
  }

  Future<void> _openDetail(IpvReportSummaryStat report) async {
    if (_showingIpvSheet) {
      return;
    }
    if (!mounted) {
      return;
    }

    _showingIpvSheet = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          final Color secondaryText =
              Theme.of(context).colorScheme.onSurfaceVariant;
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'IPV ${report.terminalName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDateTime(report.openedAt)} → ${report.closedAt == null ? '-' : _formatDateTime(report.closedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () =>
                              _closeSheetAndExportIpv(context, report, 'csv'),
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('Exportar CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _closeSheetAndExportIpv(context, report, 'pdf'),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Exportar PDF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 4),
                    Text(
                      'El detalle IPV se consulta por archivo exportado.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _showingIpvSheet = false;
    }
  }

  String _moneyWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatDate(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _ipvSourceLabel(String source) {
    switch (source.trim().toLowerCase()) {
      case 'previous_final':
        return 'Inicio desde cierre IPV anterior';
      case 'initial_stock':
      default:
        return 'Inicio desde stock del TPV';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      title: 'Reportes IPV',
      currentRoute: '/ipv-reportes',
      onRefresh: _load,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: <Widget>[
                  if (_loadingIpv)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  Card(
                    elevation: 0,
                    color: isDark
                        ? const Color(0xFF241F33)
                        : const Color(0xFFF4F1FB),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 230,
                            child: DropdownButtonFormField<String?>(
                              initialValue: _terminalId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'TPV',
                                isDense: true,
                              ),
                              items: <DropdownMenuItem<String?>>[
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Todos los TPV'),
                                ),
                                ..._terminalOptions.map(
                                  (PosTerminal terminal) =>
                                      DropdownMenuItem<String?>(
                                    value: terminal.id,
                                    child: Text(terminal.name),
                                  ),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() => _terminalId = value);
                              },
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickFromDate,
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              _fromDate == null
                                  ? 'Desde'
                                  : _formatDate(_fromDate!),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickToDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Text(_toDate == null
                                ? 'Hasta'
                                : _formatDate(_toDate!)),
                          ),
                          IconButton(
                            tooltip: 'Limpiar filtros',
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.restart_alt_rounded),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _loadingIpv ? null : _reloadIpvReports,
                            icon: const Icon(Icons.filter_alt_rounded),
                            label: const Text('Aplicar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_reports.isEmpty)
                    const Card(
                      elevation: 0,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Text('No hay reportes IPV para el filtro actual.'),
                      ),
                    )
                  else
                    ListView.builder(
                      key: const PageStorageKey<String>('ipv-reportes-list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reports.length,
                      itemBuilder: (BuildContext context, int index) {
                        final IpvReportSummaryStat report = _reports[index];
                        return KeyedSubtree(
                          key: ValueKey<String>(report.reportId),
                          child: _reportCard(report),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
