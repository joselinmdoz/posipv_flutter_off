import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../core/security/session_access.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/dashboard_widget_config.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../inventario/presentation/inventario_providers.dart';
import '../../productos/presentation/productos_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/widgets/analytics_sales_list_page.dart';
import '../../reportes/presentation/reportes_providers.dart';
import '../../tpv/data/tpv_local_datasource.dart';
import '../../tpv/presentation/tpv_providers.dart';
import 'widgets/home_dashboard_content.dart';
import 'widgets/home_dashboard_empty.dart';
import 'widgets/home_dashboard_loading.dart';
import 'widgets/home_header_section.dart';

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
  TpvEmployee? _currentEmployee;
  DashboardWidgetLayout _dashboardWidgetLayout = DashboardWidgetLayout.defaults;
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
    final UserSession? session = ref.read(currentSessionProvider);
    final Future<TpvEmployee?> employeeFuture = session == null
        ? Future<TpvEmployee?>.value(null)
        : ref
            .read(tpvLocalDataSourceProvider)
            .findActiveEmployeeByAssociatedUser(session.userId);
    final Future<DashboardWidgetLayout> dashboardWidgetsFuture = session == null
        ? Future<DashboardWidgetLayout>.value(
            DashboardWidgetLayout.defaults,
          )
        : configDs.loadDashboardWidgetLayout(userId: session.userId);

    ReportesDashboard dashboard = const ReportesDashboard(
      today: SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0),
      yesterday: SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0),
      lastDays: <DailySalesPoint>[],
      topProducts: <TopProductStat>[],
      recentSales: <RecentSaleStat>[],
      recentSessionClosures: <RecentSessionClosureStat>[],
      recentIpvReports: <IpvReportSummaryStat>[],
    );
    HomeOperationalInsight insight = const HomeOperationalInsight.empty();
    AppConfig config = AppConfig.defaults;
    TpvEmployee? employee;
    DashboardWidgetLayout dashboardWidgetLayout =
        DashboardWidgetLayout.defaults;
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

    try {
      employee = await employeeFuture;
    } catch (_) {
      employee = null;
    }

    try {
      dashboardWidgetLayout = await dashboardWidgetsFuture;
    } catch (_) {
      dashboardWidgetLayout = DashboardWidgetLayout.defaults;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboard = dashboard;
      _insight = insight;
      _businessName = config.businessName;
      _currencySymbol = config.currencySymbol;
      _currentEmployee = employee;
      _dashboardWidgetLayout = dashboardWidgetLayout;
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
    final HomeOperationalInsight insight = _insight;

    final SalesSummary today = dashboard?.today ??
        const SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0);

    final String employeeImagePath = (_currentEmployee?.imagePath ?? '').trim();
    final bool hasEmployeeImage =
        employeeImagePath.isNotEmpty && File(employeeImagePath).existsSync();
    final String displayName = (_currentEmployee?.name ?? '').trim().isNotEmpty
        ? _currentEmployee!.name
        : (session?.username ?? 'Usuario');
    final VoidCallback? openRecentActivityTap =
        _buildRecentActivityAction(session);
    final VoidCallback? openSalesMetricsTap = _buildSalesMetricsAction(session);
    final VoidCallback? openOrdersMetricsTap =
        _buildOrdersMetricsAction(session);
    final VoidCallback? openLowStockMetricsTap =
        _buildLowStockMetricsAction(session);

    return AppScaffold(
      title: _businessName,
      currentRoute: '/home',
      onRefresh: _loadDashboard,
      useDefaultActions: false,
      appBarActions: [
        IconButton(
          onPressed: openRecentActivityTap,
          icon: const Badge(
            backgroundColor: Colors.red,
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.push('/perfil-empleado'),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage:
                hasEmployeeImage ? FileImage(File(employeeImagePath)) : null,
            child: !hasEmployeeImage
                ? const Icon(Icons.person_outline_rounded, size: 20)
                : null,
          ),
        ),
        const SizedBox(width: 12),
      ],
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: <Widget>[
            HomeHeaderSection(session: session, displayName: displayName),
            const SizedBox(height: 24),
            if (_loading && dashboard == null)
              const HomeDashboardLoading()
            else if (dashboard == null)
              const HomeDashboardEmpty()
            else ...<Widget>[
              HomeDashboardContent(
                dashboard: dashboard,
                today: today,
                lowStockCount:
                    insight.lowStockProducts + insight.zeroStockProducts,
                layout: _dashboardWidgetLayout,
                moneyFormatter: _money,
                currencySymbol: _currencySymbol,
                onNewSaleTap: () => context.go('/tpv'),
                onAddStockTap: () => context.go('/inventario-movimientos'),
                onViewAllActivityTap: openRecentActivityTap,
                onSalesTap: openSalesMetricsTap,
                onOrdersTap: openOrdersMetricsTap,
                onLowStockTap: openLowStockMetricsTap,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _money(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  VoidCallback? _buildRecentActivityAction(UserSession? session) {
    if (SessionAccess.canAccessRoute(session, '/home-actividad-reciente')) {
      return () => context.push('/home-actividad-reciente');
    }
    return null;
  }

  VoidCallback? _buildSalesMetricsAction(UserSession? session) {
    if (_canOpenGeneralReports(session)) {
      return () => _openTodaySalesList(title: 'Ventas de hoy');
    }
    if (SessionAccess.canAccessRoute(session, '/ipv-reportes')) {
      return () => context.go('/ipv-reportes');
    }
    return null;
  }

  VoidCallback? _buildOrdersMetricsAction(UserSession? session) {
    if (_canOpenGeneralReports(session)) {
      return () => _openTodaySalesList(title: 'Órdenes de hoy');
    }
    if (SessionAccess.canAccessRoute(session, '/ipv-reportes')) {
      return () => context.go('/ipv-reportes');
    }
    return null;
  }

  VoidCallback? _buildLowStockMetricsAction(UserSession? session) {
    if (SessionAccess.canAccessRoute(session, '/inventario')) {
      return () => context.go('/inventario');
    }
    if (SessionAccess.canAccessRoute(session, '/productos')) {
      return () => context.go('/productos');
    }
    return null;
  }

  bool _canOpenGeneralReports(UserSession? session) {
    if (!SessionAccess.canAccessRoute(session, '/reportes')) {
      return false;
    }
    final license = ref.read(currentLicenseStatusProvider);
    return license.canAccessGeneralReports;
  }

  Future<void> _openTodaySalesList({required String title}) async {
    final DateTime now = DateTime.now();
    final DateTime day = DateTime(now.year, now.month, now.day);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsSalesListPage(
          fromDate: day,
          toDate: day,
          currencySymbol: _currencySymbol,
          title: title,
        ),
      ),
    );
  }
}
