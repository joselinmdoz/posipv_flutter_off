import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';
import 'widgets/analytics_kpi_card.dart';
import 'widgets/analytics_period_tabs.dart';
import 'widgets/analytics_breakdown_card.dart';
import 'widgets/analytics_sales_channel_card.dart';
import 'widgets/analytics_top_customer_tile.dart';
import 'widgets/analytics_top_product_tile.dart';
import 'widgets/sales_trend_card.dart';

class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage> {
  SalesAnalyticsSnapshot? _analytics;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;
  bool _exportingAnalytics = false;
  late DateTimeRange _range;
  SalesAnalyticsGranularity _granularity = SalesAnalyticsGranularity.month;
  bool _showAllTopProducts = false;

  @override
  void initState() {
    super.initState();
    _range = _rangeForGranularity(_granularity, DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics({bool showLoader = true}) async {
    final license = ref.read(currentLicenseStatusProvider);
    if (!license.canAccessGeneralReports) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _analytics = null;
      });
      return;
    }

    if (showLoader && mounted) {
      setState(() => _loading = true);
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);

    String currencySymbol = _currencySymbol;
    SalesAnalyticsSnapshot? snapshot;
    String? warningMessage;

    try {
      currencySymbol = (await configDs.loadConfig()).currencySymbol;
    } catch (e) {
      warningMessage = 'Configuracion: $e';
    }

    try {
      snapshot = await reportesDs.loadSalesAnalytics(
        fromDate: _range.start,
        toDate: _range.end,
        granularity: _granularity,
        topLimit: 20,
      );
    } catch (e) {
      final String message = 'Analiticas: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currencySymbol = currencySymbol;
      _analytics = snapshot;
      _loading = false;
    });

    if (warningMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cargado con advertencias:\n$warningMessage')),
      );
    }
  }

  DateTimeRange _rangeForGranularity(
    SalesAnalyticsGranularity granularity,
    DateTime now,
  ) {
    final DateTime dayStart = DateTime(now.year, now.month, now.day);
    switch (granularity) {
      case SalesAnalyticsGranularity.day:
        return DateTimeRange(start: dayStart, end: dayStart);
      case SalesAnalyticsGranularity.week:
        final int diff = dayStart.weekday - DateTime.monday;
        final DateTime start = dayStart.subtract(Duration(days: diff));
        final DateTime end = start.add(const Duration(days: 6));
        return DateTimeRange(start: start, end: end);
      case SalesAnalyticsGranularity.month:
        final DateTime start = DateTime(now.year, now.month, 1);
        final DateTime end = DateTime(now.year, now.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case SalesAnalyticsGranularity.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
    }
  }

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: _range,
      saveText: 'Aplicar',
      helpText: 'Seleccionar período',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _range = DateTimeRange(
        start:
            DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
      _showAllTopProducts = false;
    });
    await _loadAnalytics(showLoader: true);
  }

  Future<void> _setGranularity(SalesAnalyticsGranularity value) async {
    if (_granularity == value) {
      return;
    }
    final DateTimeRange nextRange = _rangeForGranularity(value, DateTime.now());
    setState(() {
      _granularity = value;
      _range = nextRange;
      _showAllTopProducts = false;
    });
    await _loadAnalytics(showLoader: true);
  }

  void _onBackPressed() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Future<void> _exportAnalytics() async {
    if (_exportingAnalytics) {
      return;
    }
    setState(() => _exportingAnalytics = true);
    try {
      final String filePath = await ref
          .read(reportesLocalDataSourceProvider)
          .exportSalesAnalyticsCsv(
            fromDate: _range.start,
            toDate: _range.end,
            granularity: _granularity,
            currencySymbol: _currencySymbol,
            topLimit: 20,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Analítica exportada en:\n$filePath'),
            duration: const Duration(seconds: 5),
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('No se pudo exportar la analítica: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _exportingAnalytics = false);
      }
    }
  }

  String _money(int cents, {String? symbol}) {
    final String useSymbol = symbol ?? _currencySymbol;
    return '$useSymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatDelta(double value) {
    final String sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }

  String _formatDateRange(DateTimeRange range) {
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final String day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]}, ${date.year}';
  }

  String _formatUnits(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.000001) {
      return '${qty.toStringAsFixed(0)} unidades vendidas';
    }
    return '${qty.toStringAsFixed(2)} unidades vendidas';
  }

  String _number(num value) {
    if (value is int) {
      return value.toString();
    }
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _customerTypeLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'frecuente':
        return 'Frecuente';
      case 'mayorista':
        return 'Mayorista';
      case 'vip':
        return 'VIP';
      default:
        return 'General';
    }
  }

  String _formatShortDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final DateTime d = value.toLocal();
    final String day = d.day.toString().padLeft(2, '0');
    final String month = d.month.toString().padLeft(2, '0');
    final String year = d.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    final SalesAnalyticsSnapshot? analytics = _analytics;

    if (!license.canAccessGeneralReports) {
      return AppScaffold(
        title: 'Analítica de Ventas',
        currentRoute: '/reportes',
        onRefresh: _loadAnalytics,
        useDefaultActions: false,
        showDrawer: false,
        appBarLeading: IconButton(
          tooltip: 'Volver',
          onPressed: _onBackPressed,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        appBarActions: <Widget>[
          IconButton(
            tooltip: 'Descargar',
            onPressed: _exportingAnalytics ? null : _exportAnalytics,
            icon: _exportingAnalytics
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
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

    final List<AnalyticsTopProductStat> topProducts =
        analytics?.topProducts ?? <AnalyticsTopProductStat>[];
    final bool canExpandTopProducts = topProducts.length > 3;
    final List<AnalyticsTopProductStat> visibleTopProducts =
        _showAllTopProducts || !canExpandTopProducts
            ? topProducts
            : topProducts.take(3).toList(growable: false);

    return AppScaffold(
      title: 'Analítica de Ventas',
      currentRoute: '/reportes',
      onRefresh: _loadAnalytics,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: _onBackPressed,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Descargar',
          onPressed: _exportingAnalytics ? null : _exportAnalytics,
          icon: _exportingAnalytics
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
        ),
      ],
      body: _loading && analytics == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                children: <Widget>[
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  _AnalyticsDateRangeCard(
                    value: _formatDateRange(_range),
                    onTap: _pickDateRange,
                  ),
                  const SizedBox(height: 12),
                  AnalyticsPeriodTabs(
                    selected: _granularity,
                    onSelected: _setGranularity,
                  ),
                  const SizedBox(height: 14),
                  if (analytics == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child:
                            Text('No hay datos disponibles para el periodo.'),
                      ),
                    )
                  else ...<Widget>[
                    LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints c) {
                        final bool compact = c.maxWidth < 560;
                        final double cardWidth =
                            compact ? c.maxWidth : (c.maxWidth - 12) / 2;
                        final List<Widget> cards = <Widget>[
                          AnalyticsKpiCard(
                            title: 'INGRESOS TOTALES',
                            value: _money(analytics.totalRevenueCents),
                            deltaPercent: analytics.totalRevenueDeltaPercent,
                            deltaText: _formatDelta(
                                analytics.totalRevenueDeltaPercent),
                          ),
                          AnalyticsKpiCard(
                            title: 'PEDIDO PROMEDIO',
                            value: _money(analytics.avgOrderCents),
                            deltaPercent: analytics.avgOrderDeltaPercent,
                            deltaText:
                                _formatDelta(analytics.avgOrderDeltaPercent),
                          ),
                          AnalyticsKpiCard(
                            title: 'VENTAS',
                            value: _number(analytics.ordersCount),
                          ),
                          AnalyticsKpiCard(
                            title: 'UNIDADES VENDIDAS',
                            value: _number(analytics.itemsSoldQty),
                          ),
                          AnalyticsKpiCard(
                            title: 'CLIENTES ÚNICOS',
                            value: _number(analytics.uniqueCustomersCount),
                          ),
                          AnalyticsKpiCard(
                            title: 'VENTAS SIN CLIENTE',
                            value: _number(analytics.salesWithoutCustomerCount),
                          ),
                        ];
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: cards
                              .map(
                                (Widget card) => SizedBox(
                                  width: cardWidth,
                                  child: card,
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    AnalyticsSalesChannelCard(
                      currencySymbol: _currencySymbol,
                      posOrdersCount: analytics.posOrdersCount,
                      posRevenueCents: analytics.posRevenueCents,
                      directOrdersCount: analytics.directOrdersCount,
                      directRevenueCents: analytics.directRevenueCents,
                    ),
                    const SizedBox(height: 12),
                    SalesTrendCard(
                      points: analytics.trend,
                      currencySymbol: _currencySymbol,
                    ),
                    const SizedBox(height: 12),
                    AnalyticsBreakdownCard(
                      title: 'Métodos de Pago',
                      currencySymbol: _currencySymbol,
                      totalBaseCents: analytics.totalRevenueCents,
                      items: analytics.paymentMethods,
                      emptyLabel: 'No hay pagos registrados en el rango.',
                    ),
                    const SizedBox(height: 12),
                    AnalyticsBreakdownCard(
                      title: 'Ventas por Cajero',
                      currencySymbol: _currencySymbol,
                      totalBaseCents: analytics.totalRevenueCents,
                      items: analytics.byCashier,
                    ),
                    const SizedBox(height: 12),
                    AnalyticsBreakdownCard(
                      title: 'Ventas por Almacén',
                      currencySymbol: _currencySymbol,
                      totalBaseCents: analytics.totalRevenueCents,
                      items: analytics.byWarehouse,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Clientes Destacados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (analytics.topCustomers.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('Sin clientes asociados en este rango.'),
                        ),
                      )
                    else
                      ...analytics.topCustomers.map(
                        (AnalyticsTopCustomerStat customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnalyticsTopCustomerTile(
                            customer: customer,
                            currencySymbol: _currencySymbol,
                            typeLabel:
                                _customerTypeLabel(customer.customerType),
                            lastSaleLabel:
                                _formatShortDate(customer.lastSaleAt),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Productos Destacados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (canExpandTopProducts)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAllTopProducts = !_showAllTopProducts;
                              });
                            },
                            child: Text(
                                _showAllTopProducts ? 'Ver menos' : 'Ver todo'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (visibleTopProducts.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(14),
                          child: Text('Sin productos vendidos en el rango.'),
                        ),
                      )
                    else
                      ...visibleTopProducts.map(
                        (AnalyticsTopProductStat product) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnalyticsTopProductTile(
                            name: product.productName,
                            subtitle: _formatUnits(product.qty),
                            amount: _money(product.totalCents),
                            deltaPercent: product.deltaPercent,
                            deltaText: _formatDelta(product.deltaPercent),
                            imagePath: product.imagePath,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AnalyticsDateRangeCard extends StatelessWidget {
  const _AnalyticsDateRangeCard({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SELECCIONAR PERÍODO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 31 / 2,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF1152D4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
