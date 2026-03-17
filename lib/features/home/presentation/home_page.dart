import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../productos/presentation/productos_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../tpv/presentation/tpv_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ReportesDashboard? _dashboard;
  HomeOperationalInsight _insight = const HomeOperationalInsight.empty();
  String _businessName = 'POSIPV';
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;
  bool _prewarmStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startPrewarm();
      _loadDashboard();
    });
  }

  void _startPrewarm() {
    if (_prewarmStarted) {
      return;
    }
    _prewarmStarted = true;
    unawaited(_prewarmNavigationData());
    unawaited(_prewarmLicenseData());
  }

  Future<void> _safeWarmup(
    PerfTrace trace,
    String label,
    Future<Object?> Function() run,
  ) async {
    if (!mounted) {
      return;
    }
    try {
      await run();
      trace.mark(label);
    } catch (error) {
      debugPrint('[PERF][app.prewarm] $label failed: $error');
    }
  }

  Future<void> _prewarmNavigationData() async {
    final PerfTrace trace = PerfTrace('app.prewarm');
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) {
      trace.end('disposed');
      return;
    }

    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);
    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);

    await _safeWarmup(trace, 'config', () => configDs.loadConfig());
    await _safeWarmup(
      trace,
      'almacenes',
      () async {
        final ds = ref.read(almacenesLocalDataSourceProvider);
        await ds.ensureDefaultWarehouse();
        return ds.listActiveWarehouses();
      },
    );

    await Future.wait<void>(<Future<void>>[
      _safeWarmup(
        trace,
        'productos',
        () => ref
            .read(productosLocalDataSourceProvider)
            .listActiveProductsPage(limit: 40),
      ),
      _safeWarmup(
        trace,
        'inventario',
        () => ref
            .read(inventarioLocalDataSourceProvider)
            .listStockedPage(limit: 60),
      ),
      _safeWarmup(
        trace,
        'movimientos',
        () => ref
            .read(inventarioLocalDataSourceProvider)
            .listMovements(limit: 80),
      ),
      _safeWarmup(
        trace,
        'tpv',
        () => ref.read(tpvLocalDataSourceProvider).listActiveTerminalViews(),
      ),
      _safeWarmup(
        trace,
        'ipv_terminales',
        () => reportesDs.listIpvTerminalOptions(),
      ),
    ]);
    trace.end('ok');
  }

  Future<void> _prewarmLicenseData() async {
    final PerfTrace trace = PerfTrace('app.prewarm_license');
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) {
      trace.end('disposed');
      return;
    }
    await _safeWarmup(
      trace,
      'licencia',
      () => ref.read(licenseControllerProvider.future),
    );
    await _safeWarmup(
      trace,
      'seguridad_runtime',
      () => ref.read(runtimeSecurityControllerProvider.future),
    );
    trace.end('ok');
  }

  Future<void> _loadDashboard() async {
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
    final Future<HomeOperationalInsight> insightFuture =
        reportesDs.loadHomeOperationalInsight();

    ReportesDashboard dashboard = const ReportesDashboard(
      today: SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0),
      lastDays: <DailySalesPoint>[],
      topProducts: <TopProductStat>[],
      recentSales: <RecentSaleStat>[],
      recentSessionClosures: <RecentSessionClosureStat>[],
      recentIpvReports: <IpvReportSummaryStat>[],
    );
    HomeOperationalInsight insight = const HomeOperationalInsight.empty();
    AppConfig config = AppConfig.defaults;
    String? warningMessage;

    try {
      dashboard = await dashboardFuture;
    } catch (e) {
      warningMessage = 'Dashboard: $e';
    }

    try {
      config = await configFuture;
    } catch (e) {
      final String message = 'Configuración: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    try {
      insight = await insightFuture;
    } catch (e) {
      final String message = 'Insight operativo: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboard = dashboard;
      _insight = insight;
      _businessName = config.businessName;
      _currencySymbol = config.currencySymbol;
      _loading = false;
    });

    if (warningMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cargado con advertencias:\n$warningMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? session = ref.watch(currentSessionProvider);
    final license = ref.watch(currentLicenseStatusProvider);
    final ReportesDashboard? dashboard = _dashboard;
    final HomeOperationalInsight insight = _insight;

    final SalesSummary today = dashboard?.today ??
        const SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0);
    final int avgTicketCents = today.salesCount == 0
        ? 0
        : (today.totalCents / today.salesCount).round();

    return AppScaffold(
      title: _businessName,
      currentRoute: '/home',
      onRefresh: _loadDashboard,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => context.go('/tpv'),
        child: const Icon(Icons.point_of_sale_rounded, size: 30),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: <Widget>[
            _heroCard(
              session: session,
              license: license,
            ),
            const SizedBox(height: 12),
            if (_loading && dashboard == null)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dashboard == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No hay datos para mostrar.'),
                ),
              )
            else ...<Widget>[
              _sectionCard(
                title: 'Resumen Hoy',
                trailing: IconButton(
                  onPressed: () => context.go('/ventas-pos'),
                  icon: const Icon(Icons.open_in_new_rounded),
                  tooltip: 'Ir a ventas',
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.25,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _metricTile(
                      title: 'Ventas',
                      value: today.salesCount.toString(),
                      icon: Icons.receipt_long_rounded,
                    ),
                    _metricTile(
                      title: 'Total',
                      value: _money(today.totalCents),
                      icon: Icons.trending_up_rounded,
                    ),
                    _metricTile(
                      title: 'Ticket promedio',
                      value: _money(avgTicketCents),
                      icon: Icons.local_atm_rounded,
                    ),
                    _metricTile(
                      title: 'Movimientos',
                      value: insight.movementsToday.toString(),
                      icon: Icons.swap_horiz_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Alertas Operativas',
                trailing: IconButton(
                  onPressed: () => context.go('/inventario'),
                  icon: const Icon(Icons.inventory_2_outlined),
                  tooltip: 'Ir a inventario',
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _alertCounter(
                            label: 'Sin stock',
                            count: insight.zeroStockProducts,
                            icon: Icons.warning_amber_rounded,
                            critical: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _alertCounter(
                            label: 'Bajo stock',
                            count: insight.lowStockProducts,
                            icon: Icons.inventory_outlined,
                            critical: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (insight.lowStockPreview.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No hay productos en bajo stock.'),
                      )
                    else
                      Column(
                        children: insight.lowStockPreview
                            .map(
                              (StockAlertStat item) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.circle,
                                  size: 10,
                                ),
                                title: Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('SKU ${item.sku}'),
                                trailing: Text(
                                  _qty(item.qty),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Estado Operativo',
                child: Column(
                  children: <Widget>[
                    _statusLine(
                      icon: Icons.storefront_rounded,
                      label: 'TPV activos',
                      value:
                          '${insight.openSessions}/${insight.activeTerminals} con turno abierto',
                    ),
                    _statusLine(
                      icon: Icons.table_chart_outlined,
                      label: 'IPV abiertos',
                      value: insight.openIpvReports.toString(),
                    ),
                    _statusLine(
                      icon: Icons.schedule_rounded,
                      label: 'Último movimiento',
                      value: insight.lastMovementAt == null
                          ? 'Sin registros'
                          : _formatDateTime(insight.lastMovementAt!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Tendencia (7 Días)',
                trailing: const Icon(Icons.show_chart_rounded),
                child: _weeklyBars(dashboard.lastDays),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Actividad Reciente',
                child: Column(
                  children: <Widget>[
                    _latestSaleLine(dashboard.recentSales),
                    _latestSessionLine(dashboard.recentSessionClosures),
                    _latestIpvLine(dashboard.recentIpvReports),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroCard({
    required UserSession? session,
    required dynamic license,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color secondaryText = theme.colorScheme.onSurfaceVariant;
    final int? days = license.daysRemaining as int?;
    final String licenseText = license.isLoading
        ? 'Validando licencia...'
        : days == null
            ? license.statusLabel.toString()
            : 'Licencia: $days día(s) restantes';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF5A4D89), Color(0xFF7B6AB3)],
                    ),
                  ),
                  child:
                      const Icon(Icons.storefront_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        session == null
                            ? 'Sesión no iniciada'
                            : 'Hola, ${session.username}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Panel operativo: ventas, turnos, inventario y alertas.',
                        style: TextStyle(color: secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(licenseText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final Color titleColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241F33) : const Color(0xFFF0EBFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCounter({
    required String label,
    required int count,
    required IconData icon,
    required bool critical,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color bg = critical
        ? (isDark ? const Color(0xFF4A2633) : const Color(0xFFF9DDE6))
        : (isDark ? const Color(0xFF312948) : const Color(0xFFE7DEF8));
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 19),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _latestSaleLine(List<RecentSaleStat> sales) {
    if (sales.isEmpty) {
      return const ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.receipt_long_outlined),
        title: Text('Ventas'),
        trailing: Text('Sin registros'),
      );
    }
    final RecentSaleStat s = sales.first;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text('Última venta: ${s.folio}'),
      subtitle: Text('${s.warehouseName} • ${s.cashierUsername}'),
      trailing: Text(_money(s.totalCents)),
    );
  }

  Widget _latestSessionLine(List<RecentSessionClosureStat> closures) {
    if (closures.isEmpty) {
      return const ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.lock_clock_outlined),
        title: Text('Cierres TPV'),
        trailing: Text('Sin registros'),
      );
    }
    final RecentSessionClosureStat c = closures.first;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.lock_clock_outlined),
      title: Text('Último cierre: ${c.terminalName}'),
      subtitle: Text(_formatDateTime(c.closedAt)),
      trailing: Text(_moneyWithSymbol(c.closingCashCents, c.currencySymbol)),
    );
  }

  Widget _latestIpvLine(List<IpvReportSummaryStat> reports) {
    if (reports.isEmpty) {
      return const ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.table_chart_outlined),
        title: Text('IPV'),
        trailing: Text('Sin registros'),
      );
    }
    final IpvReportSummaryStat r = reports.first;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.table_chart_outlined),
      title: Text('Último IPV: ${r.terminalName}'),
      subtitle: Text(
        r.closedAt == null ? 'Abierto' : _formatDateTime(r.closedAt!),
      ),
      trailing: Text(_moneyWithSymbol(r.totalAmountCents, r.currencySymbol)),
    );
  }

  Widget _weeklyBars(List<DailySalesPoint> points) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    if (points.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text('Sin movimiento de ventas en el rango.'),
      );
    }

    final List<DailySalesPoint> sorted = <DailySalesPoint>[...points]
      ..sort((DailySalesPoint a, DailySalesPoint b) => a.day.compareTo(b.day));

    final int maxCents = sorted.fold<int>(
      1,
      (int prev, DailySalesPoint element) => math.max(prev, element.totalCents),
    );

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sorted.map((DailySalesPoint p) {
          final double ratio = p.totalCents / maxCents;
          final double barHeight = 26 + (ratio * 90);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _moneyCompact(p.totalCents),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: scheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.day.length >= 10 ? p.day.substring(8, 10) : p.day,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _money(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _moneyWithSymbol(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _moneyCompact(int cents) {
    final double value = cents / 100;
    if (value >= 1000) {
      return '$_currencySymbol${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$_currencySymbol${value.toStringAsFixed(0)}';
  }

  String _qty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.000001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
