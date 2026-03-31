import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../reportes/data/reportes_local_datasource.dart';
import '../../reportes/presentation/reportes_providers.dart';
import 'widgets/home_recent_activity.dart';

class HomeRecentActivityPage extends ConsumerStatefulWidget {
  const HomeRecentActivityPage({super.key});

  @override
  ConsumerState<HomeRecentActivityPage> createState() =>
      _HomeRecentActivityPageState();
}

class _HomeRecentActivityPageState
    extends ConsumerState<HomeRecentActivityPage> {
  ReportesDashboard? _dashboard;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadRecentActivity();
    });
  }

  Future<void> _loadRecentActivity() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);

    ReportesDashboard? dashboard;
    String currencySymbol = _currencySymbol;
    String? warningMessage;

    try {
      currencySymbol = (await configDs.loadConfig()).currencySymbol;
    } catch (e) {
      warningMessage = 'Configuración: $e';
    }

    try {
      dashboard = await reportesDs.loadDashboard(
        recentLimit: 80,
        sessionClosureLimit: 60,
        ipvLimit: 60,
      );
    } catch (e) {
      final String message = 'Actividad reciente: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dashboard = dashboard;
      _currencySymbol = currencySymbol;
      _loading = false;
    });

    if (warningMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cargado con advertencias:\n$warningMessage')),
      );
    }
  }

  String _money(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  void _onBackPressed() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final ReportesDashboard? dashboard = _dashboard;

    return AppScaffold(
      title: 'Actividades recientes',
      currentRoute: '/home-actividad-reciente',
      onRefresh: _loadRecentActivity,
      useDefaultActions: false,
      showDrawer: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: _onBackPressed,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: const <Widget>[],
      body: _loading && dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecentActivity,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: <Widget>[
                  if (_loading) ...<Widget>[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 12),
                  ],
                  if (dashboard == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No se pudo cargar la actividad reciente.',
                        ),
                      ),
                    )
                  else
                    HomeRecentActivity(
                      recentSales: dashboard.recentSales,
                      recentSessionClosures: dashboard.recentSessionClosures,
                      recentIpvReports: dashboard.recentIpvReports,
                      currencySymbol: _currencySymbol,
                      moneyFormatter: _money,
                      maxItems: null,
                    ),
                ],
              ),
            ),
    );
  }
}
