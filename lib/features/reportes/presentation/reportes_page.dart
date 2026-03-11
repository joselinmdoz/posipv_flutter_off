import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);

    ReportesDashboard dashboard = const ReportesDashboard(
      today: SalesSummary(salesCount: 0, totalCents: 0, taxCents: 0),
      lastDays: <DailySalesPoint>[],
      topProducts: <TopProductStat>[],
      recentSales: <RecentSaleStat>[],
    );
    String currencySymbol = AppConfig.defaultCurrencySymbol;
    String? warningMessage;

    try {
      dashboard = await reportesDs.loadDashboard();
    } catch (e) {
      warningMessage = 'Reportes: $e';
    }

    try {
      currencySymbol = (await configDs.loadConfig()).currencySymbol;
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
      _currencySymbol = currencySymbol;
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
    final ReportesDashboard? dashboard = _dashboard;

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
                  ],
                ],
              ),
            ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  String _formatDateTime(DateTime dt) {
    final String y = dt.year.toString().padLeft(4, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    final String d = dt.day.toString().padLeft(2, '0');
    final String hh = dt.hour.toString().padLeft(2, '0');
    final String mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
