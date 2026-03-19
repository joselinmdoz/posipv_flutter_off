import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';

class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage> {
  ReportesDashboard? _dashboard;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;
  bool _loadingIpv = false;
  bool _showingIpvSheet = false;
  List<PosTerminal> _ipvTerminalOptions = <PosTerminal>[];
  String? _ipvTerminalId;
  DateTime? _ipvFromDate;
  DateTime? _ipvToDate;
  List<IpvReportSummaryStat> _ipvReports = <IpvReportSummaryStat>[];

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
    final license = ref.read(currentLicenseStatusProvider);
    if (!license.canAccessGeneralReports) {
      if (mounted) {
        setState(() {
          _loading = false;
          _dashboard = null;
        });
      }
      return;
    }

    final PerfTrace trace = PerfTrace('reportes.load');
    if (mounted) {
      setState(() => _loading = true);
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);
    final Future<ReportesDashboard> dashboardFuture =
        reportesDs.loadDashboard();
    final Future<AppConfig> configFuture = configDs.loadConfig();

    ReportesDashboard dashboard = const ReportesDashboard(
      today: SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0),
      lastDays: <DailySalesPoint>[],
      topProducts: <TopProductStat>[],
      recentSales: <RecentSaleStat>[],
      recentSessionClosures: <RecentSessionClosureStat>[],
      recentIpvReports: <IpvReportSummaryStat>[],
    );
    String currencySymbol = AppConfig.defaultCurrencySymbol;
    String? warningMessage;

    try {
      dashboard = await dashboardFuture;
      trace.mark('dashboard cargado');
    } catch (e) {
      warningMessage = 'Reportes: $e';
    }

    try {
      currencySymbol = (await configFuture).currencySymbol;
      trace.mark('config cargada');
    } catch (e) {
      final String message = 'Configuracion: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    if (!mounted) {
      trace.end('unmounted');
      return;
    }

    setState(() {
      _dashboard = dashboard;
      _currencySymbol = currencySymbol;
      _loading = false;
    });
    trace.end('ok');

    if (warningMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cargado con advertencias:\n$warningMessage')),
      );
    }

    unawaited(
        _reloadIpvReports(loadTerminalOptions: _ipvTerminalOptions.isEmpty));
  }

  Future<void> _reloadIpvReports({bool loadTerminalOptions = false}) async {
    if (mounted) {
      setState(() => _loadingIpv = true);
    }
    final ReportesLocalDataSource ds =
        ref.read(reportesLocalDataSourceProvider);
    try {
      final Future<List<PosTerminal>> terminalFuture = loadTerminalOptions
          ? ds.listIpvTerminalOptions()
          : Future<List<PosTerminal>>.value(_ipvTerminalOptions);
      final Future<List<IpvReportSummaryStat>> rowsFuture = ds.listIpvReports(
        terminalId: _ipvTerminalId,
        fromDate: _ipvFromDate,
        toDate: _ipvToDate,
        limit: 120,
      );
      List<PosTerminal> terminals = await terminalFuture;
      List<IpvReportSummaryStat> rows = await rowsFuture;
      if (_ipvTerminalId != null &&
          terminals.every((PosTerminal row) => row.id != _ipvTerminalId)) {
        _ipvTerminalId = null;
        rows = await ds.listIpvReports(
          terminalId: null,
          fromDate: _ipvFromDate,
          toDate: _ipvToDate,
          limit: 120,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _ipvTerminalOptions = terminals;
        _ipvReports = rows;
        _loadingIpv = false;
      });
    } catch (e, st) {
      debugPrint('IPV export failed (reportes/reportes_page). $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) {
        return;
      }
      setState(() => _loadingIpv = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar IPV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    final ReportesDashboard? dashboard = _dashboard;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!license.canAccessGeneralReports) {
      return AppScaffold(
        title: 'Reportes',
        currentRoute: '/reportes',
        onRefresh: _load,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                const Text(
                  'El módulo de Reportes está disponible solo con licencia activa.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Puedes seguir usando IPV en modo demo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => context.go('/ipv-reportes'),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Ir a IPV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/licencia'),
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Activar licencia'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Reportes',
      currentRoute: '/reportes',
      onRefresh: _load,
      body: _loading && dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (dashboard == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No hay datos disponibles.'),
                      ),
                    )
                  else ...<Widget>[
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        _kpiCard(
                          title: 'Ventas hoy',
                          value: dashboard.today.salesCount.toString(),
                          icon: Icons.point_of_sale_outlined,
                        ),
                        _kpiCard(
                          title: 'Total hoy',
                          value: _money(dashboard.today.totalCents),
                          icon: Icons.attach_money_outlined,
                        ),
                        _kpiCard(
                          title: 'Impuestos hoy',
                          value: _money(dashboard.today.taxCents),
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _section(
                      title: 'Ultimos 7 dias',
                      child: dashboard.lastDays.isEmpty
                          ? const Text('Sin ventas en el rango.')
                          : Column(
                              children: dashboard.lastDays
                                  .map(
                                    (DailySalesPoint point) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(point.day),
                                      subtitle:
                                          Text('${point.salesCount} venta(s)'),
                                      trailing: Text(_money(point.totalCents)),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Top productos (30 dias)',
                      child: dashboard.topProducts.isEmpty
                          ? const Text('Sin datos suficientes.')
                          : Column(
                              children: dashboard.topProducts
                                  .map(
                                    (TopProductStat product) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(product.productName),
                                      subtitle: Text(
                                        'SKU ${product.sku} | ${product.qty.toStringAsFixed(2)} u',
                                      ),
                                      trailing:
                                          Text(_money(product.totalCents)),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Ultimas ventas',
                      child: dashboard.recentSales.isEmpty
                          ? const Text('No hay ventas registradas.')
                          : Column(
                              children: dashboard.recentSales
                                  .map(
                                    (RecentSaleStat sale) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(sale.folio),
                                      subtitle: Text(
                                        '${_formatDateTime(sale.createdAt)} | ${sale.warehouseName} | ${sale.cashierUsername}',
                                      ),
                                      trailing: Text(_money(sale.totalCents)),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Ultimos cierres de turno TPV',
                      child: dashboard.recentSessionClosures.isEmpty
                          ? const Text('No hay cierres de turno registrados.')
                          : Column(
                              children: dashboard.recentSessionClosures
                                  .map(
                                    (RecentSessionClosureStat closure) => Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      elevation: 0,
                                      color: isDark
                                          ? const Color(0xFF241F33)
                                          : const Color(0xFFF4F1FB),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    closure.terminalName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _moneyWithSymbol(
                                                    closure.closingCashCents,
                                                    closure.currencySymbol,
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_formatDateTime(closure.closedAt)} | ${closure.cashierUsername}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            if (closure.breakdown.isNotEmpty)
                                              const SizedBox(height: 6),
                                            if (closure.breakdown.isNotEmpty)
                                              ...closure.breakdown.map(
                                                (SessionClosureBreakdownStat
                                                    row) {
                                                  return Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: Text(
                                                          '${_moneyWithSymbol(row.denominationCents, closure.currencySymbol)} x ${row.unitCount}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        _moneyWithSymbol(
                                                          row.subtotalCents,
                                                          closure
                                                              .currencySymbol,
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      title: 'Reportes IPV recientes',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (_loadingIpv)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 230,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _ipvTerminalId,
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
                                    ..._ipvTerminalOptions.map(
                                      (PosTerminal terminal) =>
                                          DropdownMenuItem<String?>(
                                        value: terminal.id,
                                        child: Text(terminal.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: (String? value) {
                                    setState(() => _ipvTerminalId = value);
                                  },
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickIpvFromDate(),
                                icon: const Icon(Icons.date_range_outlined),
                                label: Text(
                                  _ipvFromDate == null
                                      ? 'Desde'
                                      : _formatDate(_ipvFromDate!),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _pickIpvToDate(),
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  _ipvToDate == null
                                      ? 'Hasta'
                                      : _formatDate(_ipvToDate!),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Limpiar filtros',
                                onPressed: _clearIpvFilters,
                                icon: const Icon(Icons.restart_alt_rounded),
                              ),
                              FilledButton.tonalIcon(
                                onPressed:
                                    _loadingIpv ? null : _reloadIpvReports,
                                icon: const Icon(Icons.filter_alt_rounded),
                                label: const Text('Aplicar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _ipvReports.isEmpty
                              ? const Text('No hay reportes IPV en el filtro.')
                              : ListView.builder(
                                  key: const PageStorageKey<String>(
                                    'reportes-ipv-summary-list',
                                  ),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _ipvReports.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final IpvReportSummaryStat report =
                                        _ipvReports[index];
                                    return KeyedSubtree(
                                      key: ValueKey<String>(report.reportId),
                                      child: _ipvReportCard(report),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    final Color titleColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _ipvReportCard(IpvReportSummaryStat report) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isDark ? const Color(0xFF1C2430) : const Color(0xFFEFF3FB),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openIpvDetail(report),
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

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    isDark ? const Color(0xFF312948) : const Color(0xFFE9E3F7),
                child: Icon(icon, size: 18, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
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

  String _money(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _moneyWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
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

  String _formatDate(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickIpvFromDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _ipvFromDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _ipvFromDate = picked);
  }

  Future<void> _pickIpvToDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _ipvToDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() => _ipvToDate = picked);
  }

  void _clearIpvFilters() {
    setState(() {
      _ipvTerminalId = null;
      _ipvFromDate = null;
      _ipvToDate = null;
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

  Future<void> _openIpvDetail(IpvReportSummaryStat report) async {
    if (_showingIpvSheet) {
      return;
    }
    if (!mounted) {
      return;
    }

    final bool canExportIpv = ref.read(currentLicenseStatusProvider).isFull;
    _showingIpvSheet = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: canExportIpv
                              ? () => _closeSheetAndExportIpv(
                                    context,
                                    report,
                                    'csv',
                                  )
                              : null,
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('Exportar CSV'),
                        ),
                        OutlinedButton.icon(
                          onPressed: canExportIpv
                              ? () => _closeSheetAndExportIpv(
                                    context,
                                    report,
                                    'pdf',
                                  )
                              : null,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Exportar PDF'),
                        ),
                      ],
                    ),
                    if (!canExportIpv) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Modo demo: exportar IPV requiere licencia activa.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const SizedBox(height: 4),
                    Text(
                      'El detalle IPV se consulta por archivo exportado.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}
