import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ReportesDashboard? _dashboard;
  String _businessName = 'POSIPV';
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
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

    ReportesDashboard dashboard = const ReportesDashboard(
      today: SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0),
      lastDays: <DailySalesPoint>[],
      topProducts: <TopProductStat>[],
      recentSales: <RecentSaleStat>[],
      recentSessionClosures: <RecentSessionClosureStat>[],
      recentIpvReports: <IpvReportSummaryStat>[],
    );
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
      final String message = 'Configuracion: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboard = dashboard;
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
    final ReportesDashboard? dashboard = _dashboard;

    return AppScaffold(
      title: _businessName,
      currentRoute: '/home',
      onRefresh: _loadDashboard,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => context.go('/tpv'),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: <Widget>[
            _heroCard(session),
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _kpiCard(
                    title: 'Ventas hoy',
                    value: dashboard.today.salesCount.toString(),
                    icon: Icons.receipt_long_rounded,
                    tint: const Color(0xFFD8D0F3),
                  ),
                  _kpiCard(
                    title: 'Total hoy',
                    value: _money(dashboard.today.totalCents),
                    icon: Icons.trending_up_rounded,
                    tint: const Color(0xFFCFEEDF),
                  ),
                  _kpiCard(
                    title: 'Impuesto',
                    value: _money(dashboard.today.taxCents),
                    icon: Icons.account_balance_wallet_outlined,
                    tint: const Color(0xFFF6D6E6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Resumen 7 dias',
                trailing: const Icon(Icons.show_chart_rounded),
                child: _weeklyBars(dashboard.lastDays),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Accesos rapidos',
                trailing: const Icon(Icons.dashboard_customize_outlined),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickActions
                      .map(
                        (_QuickAction action) => ActionChip(
                          avatar: Icon(action.icon, size: 18),
                          label: Text(action.label),
                          onPressed: () => context.go(action.route),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Ultimas ventas',
                trailing: TextButton(
                  onPressed: () => context.go('/reportes'),
                  child: const Text('Ver todo'),
                ),
                child: dashboard.recentSales.isEmpty
                    ? const Text('Aun no hay ventas registradas.')
                    : Column(
                        children: dashboard.recentSales
                            .take(5)
                            .map(
                              (RecentSaleStat sale) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE2DCF5),
                                  child: Icon(
                                    Icons.receipt,
                                    size: 18,
                                    color: Color(0xFF4D4272),
                                  ),
                                ),
                                title: Text(
                                  sale.folio,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${sale.warehouseName} | ${sale.cashierUsername}',
                                ),
                                trailing: Text(
                                  _money(sale.totalCents),
                                  style: const TextStyle(
                                    color: Color(0xFF1E9A74),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroCard(UserSession? session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
              child: const Icon(Icons.storefront_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    session == null
                        ? 'Sesion no iniciada'
                        : 'Hola, ${session.username}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controla ventas, stock y almacenes desde un solo panel.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF35304D),
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

  Widget _weeklyBars(List<DailySalesPoint> points) {
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
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4E4768),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF47B88E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.day.length >= 10 ? p.day.substring(8, 10) : p.day,
                    style: TextStyle(
                      color: Colors.grey.shade700,
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

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color tint,
  }) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: tint,
                child: Icon(icon, size: 18, color: const Color(0xFF50467A)),
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
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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

  String _moneyCompact(int cents) {
    final double value = cents / 100;
    if (value >= 1000) {
      return '$_currencySymbol${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$_currencySymbol${value.toStringAsFixed(0)}';
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}

const List<_QuickAction> _quickActions = <_QuickAction>[
  _QuickAction('TPV', '/tpv', Icons.storefront_rounded),
  _QuickAction('Empleados', '/tpv-empleados', Icons.badge_outlined),
  _QuickAction('Ventas', '/ventas-directas', Icons.point_of_sale_rounded),
  _QuickAction('Inventario', '/inventario', Icons.inventory_2_outlined),
  _QuickAction(
    'Movimientos',
    '/inventario-movimientos',
    Icons.swap_horiz_rounded,
  ),
  _QuickAction('Productos', '/productos', Icons.shopping_bag_outlined),
  _QuickAction('Reportes', '/reportes', Icons.stacked_bar_chart_rounded),
  _QuickAction('IPV', '/ipv-reportes', Icons.table_chart_outlined),
  _QuickAction('Ajustes', '/configuracion', Icons.settings_outlined),
];
