import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';
import 'widgets/analytics_period_tabs.dart';
import 'widgets/analytics_breakdown_card.dart';
import 'widgets/analytics_sales_channel_card.dart';
import 'widgets/analytics_sales_summary_cards.dart';
import 'widgets/analytics_top_customer_tile.dart';
import 'widgets/analytics_top_product_tile.dart';
import 'widgets/analytics_sales_list_page.dart';

enum _ReportViewType {
  salesAnalytics,
  paymentsDetail,
}

class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage> {
  static const String _allPaymentMethodsToken = '__all__';
  static const List<int> _paymentPageSizes = <int>[25, 50, 100];

  SalesAnalyticsSnapshot? _analytics;
  List<SalesPaymentReportRow> _paymentReportRows = <SalesPaymentReportRow>[];
  List<String> _paymentMethodKeys = <String>[];
  String? _selectedPaymentMethodKey;
  int _paymentCurrentPage = 1;
  int _paymentPageSize = _paymentPageSizes.first;
  int _paymentTotalCount = 0;
  bool _loadingPaymentPage = false;
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;
  bool _exportingAnalytics = false;
  late DateTimeRange _range;
  SalesAnalyticsGranularity _granularity = SalesAnalyticsGranularity.month;
  _ReportViewType _selectedReport = _ReportViewType.salesAnalytics;
  bool _showAllTopProducts = false;

  @override
  void initState() {
    super.initState();
    _range = _rangeForGranularity(_granularity, DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadCurrentReport();
    });
  }

  Future<void> _loadCurrentReport({bool showLoader = true}) {
    if (_selectedReport == _ReportViewType.salesAnalytics) {
      return _loadAnalytics(showLoader: showLoader);
    }
    return _loadPaymentsReport(showLoader: showLoader);
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

  Future<void> _loadPaymentsReport({
    bool showLoader = true,
    bool refreshMethodKeys = true,
  }) async {
    final license = ref.read(currentLicenseStatusProvider);
    if (!license.canAccessGeneralReports) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _paymentReportRows = <SalesPaymentReportRow>[];
        _paymentTotalCount = 0;
        _loadingPaymentPage = false;
      });
      return;
    }
    if (showLoader && mounted) {
      setState(() => _loading = true);
    } else if (mounted) {
      setState(() => _loadingPaymentPage = true);
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);

    String currencySymbol = _currencySymbol;
    List<SalesPaymentReportRow> rows = <SalesPaymentReportRow>[];
    List<String> methodKeys = _paymentMethodKeys;
    int totalCount = 0;
    int effectivePage = _paymentCurrentPage < 1 ? 1 : _paymentCurrentPage;
    String? effectiveMethod = _selectedPaymentMethodKey;
    String? warningMessage;

    try {
      currencySymbol = (await configDs.loadConfig()).currencySymbol;
    } catch (e) {
      warningMessage = 'Configuracion: $e';
    }

    try {
      if (refreshMethodKeys) {
        methodKeys = await reportesDs.listPaymentMethodKeysForRange(
          fromDate: _range.start,
          toDate: _range.end,
        );
      }

      final Set<String> methodSet = methodKeys.toSet();
      if (effectiveMethod != null && !methodSet.contains(effectiveMethod)) {
        effectiveMethod = null;
      }

      totalCount = await reportesDs.countSalesPaymentsReport(
        fromDate: _range.start,
        toDate: _range.end,
        paymentMethodKey: effectiveMethod,
      );

      final int totalPages = totalCount == 0
          ? 1
          : ((totalCount + _paymentPageSize - 1) ~/ _paymentPageSize);
      if (effectivePage > totalPages) {
        effectivePage = totalPages;
      }

      if (totalCount > 0) {
        rows = await reportesDs.listSalesPaymentsReport(
          fromDate: _range.start,
          toDate: _range.end,
          paymentMethodKey: effectiveMethod,
          limit: _paymentPageSize,
          offset: (effectivePage - 1) * _paymentPageSize,
        );
      }
    } catch (e) {
      final String message = 'Reporte de pagos: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currencySymbol = currencySymbol;
      _paymentMethodKeys = methodKeys;
      _paymentReportRows = rows;
      _paymentTotalCount = totalCount;
      _paymentCurrentPage = effectivePage;
      _selectedPaymentMethodKey = effectiveMethod;
      _loading = false;
      _loadingPaymentPage = false;
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
      _paymentCurrentPage = 1;
    });
    await _loadCurrentReport(showLoader: true);
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

  String _formatCompactRange(DateTimeRange range) {
    final DateTime start = range.start;
    final DateTime end = range.end;
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
    if (start.year == end.year && start.month == end.month) {
      return '${months[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) {
      return '${months[start.month - 1]}-${months[end.month - 1]} ${start.year}';
    }
    return '${months[start.month - 1]} ${start.year} - ${months[end.month - 1]} ${end.year}';
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

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _formatUnits(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.000001) {
      return '${qty.toStringAsFixed(0)} unidades vendidas';
    }
    return '${qty.toStringAsFixed(2)} unidades vendidas';
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

  String _paymentMethodLabel(String method) {
    switch (method.trim().toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'wallet':
        return 'Billetera';
      case 'consignment':
        return 'Consignación';
      default:
        final String clean = method.trim();
        return clean.isEmpty ? 'Método' : clean;
    }
  }

  String _reportTypeLabel(_ReportViewType type) {
    switch (type) {
      case _ReportViewType.salesAnalytics:
        return 'Analítica de ventas';
      case _ReportViewType.paymentsDetail:
        return 'Detalle de pagos';
    }
  }

  Future<void> _changeReportType(_ReportViewType next) async {
    if (_selectedReport == next) {
      return;
    }
    setState(() {
      _selectedReport = next;
      _paymentCurrentPage = 1;
    });
    await _loadCurrentReport(showLoader: true);
  }

  Future<void> _changePaymentMethodFilter(String? value) async {
    final String? next =
        value == null || value == _allPaymentMethodsToken ? null : value;
    if (_selectedPaymentMethodKey == next) {
      return;
    }
    setState(() {
      _selectedPaymentMethodKey = next;
      _paymentCurrentPage = 1;
    });
    await _loadPaymentsReport(
      showLoader: true,
      refreshMethodKeys: false,
    );
  }

  int _paymentTotalPages() {
    if (_paymentTotalCount <= 0) {
      return 1;
    }
    return (_paymentTotalCount + _paymentPageSize - 1) ~/ _paymentPageSize;
  }

  Future<void> _goToPaymentPage(int page) async {
    final int maxPages = _paymentTotalPages();
    final int nextPage = page < 1 ? 1 : (page > maxPages ? maxPages : page);
    if (_loadingPaymentPage || nextPage == _paymentCurrentPage) {
      return;
    }
    setState(() {
      _paymentCurrentPage = nextPage;
    });
    await _loadPaymentsReport(
      showLoader: false,
      refreshMethodKeys: false,
    );
  }

  Future<void> _changePaymentPageSize(int? value) async {
    if (value == null || value == _paymentPageSize) {
      return;
    }
    setState(() {
      _paymentPageSize = value;
      _paymentCurrentPage = 1;
    });
    await _loadPaymentsReport(
      showLoader: true,
      refreshMethodKeys: false,
    );
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

  int _kpiColumnsForWidth(double width) {
    if (width < 700) {
      return 2;
    }
    if (width < 1100) {
      return 3;
    }
    if (width < 1450) {
      return 4;
    }
    return 5;
  }

  Future<void> _openSalesList({
    String title = 'Ventas del período',
    String? channel,
    String? paymentMethodKey,
    String? dependentKey,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsSalesListPage(
          fromDate: _range.start,
          toDate: _range.end,
          currencySymbol: _currencySymbol,
          title: title,
          channel: channel,
          paymentMethodKey: paymentMethodKey,
          dependentKey: dependentKey,
        ),
      ),
    );
  }

  List<Widget> _buildPaymentsReportSections(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String selectorValue =
        _selectedPaymentMethodKey ?? _allPaymentMethodsToken;
    final int totalPages = _paymentTotalPages();
    final int safePage = _paymentCurrentPage < 1
        ? 1
        : (_paymentCurrentPage > totalPages ? totalPages : _paymentCurrentPage);
    final int startRow =
        _paymentTotalCount == 0 ? 0 : ((safePage - 1) * _paymentPageSize) + 1;
    final int endRow =
        _paymentTotalCount == 0 ? 0 : startRow + _paymentReportRows.length - 1;
    final bool canGoPrev = safePage > 1 && !_loadingPaymentPage;
    final bool canGoNext = safePage < totalPages && !_loadingPaymentPage;
    final List<DropdownMenuItem<String>> items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: _allPaymentMethodsToken,
        child: Text('Todos los métodos'),
      ),
      ..._paymentMethodKeys.map(
        (String key) => DropdownMenuItem<String>(
          value: key,
          child: Text(_paymentMethodLabel(key)),
        ),
      ),
    ];
    final List<DropdownMenuItem<int>> pageSizeItems = _paymentPageSizes
        .map(
          (int size) => DropdownMenuItem<int>(
            value: size,
            child: Text('$size filas'),
          ),
        )
        .toList(growable: false);

    Widget pager() {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'Mostrando $startRow-$endRow de $_paymentTotalCount pagos',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                SizedBox(
                  width: 135,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey<int>(_paymentPageSize),
                    initialValue: _paymentPageSize,
                    isDense: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: pageSizeItems,
                    onChanged:
                        _loadingPaymentPage ? null : _changePaymentPageSize,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      canGoPrev ? () => _goToPaymentPage(safePage - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Anterior'),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      canGoNext ? () => _goToPaymentPage(safePage + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Siguiente'),
                ),
                Text(
                  'Página $safePage de $totalPages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
            if (_loadingPaymentPage) ...<Widget>[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      );
    }

    final List<Widget> sections = <Widget>[
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'MÉTODO DE PAGO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(
                'payment-method-$selectorValue-${_paymentMethodKeys.join('|')}',
              ),
              initialValue: selectorValue,
              items: items,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (String? value) => _changePaymentMethodFilter(value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      pager(),
      const SizedBox(height: 12),
    ];

    if (_paymentReportRows.isEmpty) {
      sections.add(
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay pagos para el filtro seleccionado.'),
          ),
        ),
      );
      return sections;
    }

    sections.addAll(
      _paymentReportRows.map((SalesPaymentReportRow row) {
        final String methodLabel = _paymentMethodLabel(row.methodKey);
        final String amountLabel = _money(row.amountCents);
        final String saleTotalLabel = _money(row.saleTotalCents);
        final String channelLabel = row.channel == 'pos' ? 'POS' : 'DIRECTA';
        final String sourceAmount = (row.sourceCurrencyCode ?? '')
                .trim()
                .isEmpty
            ? ''
            : '${row.sourceCurrencyCode} ${((row.sourceAmountCents ?? 0) / 100).toStringAsFixed(2)}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '$methodLabel • ${row.folio}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      amountLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pago: ${_formatDateTime(row.paymentCreatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  'Venta: ${_formatDateTime(row.saleCreatedAt)} • Total venta: $saleTotalLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Dependiente: ${row.attendantName}'),
                Text('Almacén: ${row.warehouseName}'),
                Text('Canal: $channelLabel'),
                Text('Cliente: ${row.customerName ?? 'Sin cliente'}'),
                if ((row.terminalName ?? '').trim().isNotEmpty)
                  Text('TPV: ${row.terminalName}'),
                if ((row.transactionId ?? '').trim().isNotEmpty)
                  Text('Código: ${row.transactionId}'),
                if (sourceAmount.isNotEmpty)
                  Text('Monto origen: $sourceAmount'),
              ],
            ),
          ),
        );
      }),
    );

    sections
      ..add(const SizedBox(height: 2))
      ..add(pager());

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    final SalesAnalyticsSnapshot? analytics = _analytics;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!license.canAccessGeneralReports) {
      return AppScaffold(
        title: 'Reportes',
        currentRoute: '/reportes',
        onRefresh: _loadCurrentReport,
        useDefaultActions: false,
        showDrawer: false,
        appBarLeading: IconButton(
          tooltip: 'Volver',
          onPressed: _onBackPressed,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        appBarActions: const <Widget>[],
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
      title: _selectedReport == _ReportViewType.salesAnalytics
          ? 'Análisis'
          : 'Reportes',
      currentRoute: '/reportes',
      onRefresh: _loadCurrentReport,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: _onBackPressed,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: _selectedReport == _ReportViewType.salesAnalytics
          ? <Widget>[
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
            ]
          : const <Widget>[],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCurrentReport,
              child: ColoredBox(
                color:
                    isDark ? const Color(0xFF0B1220) : const Color(0xFFF7F9FB),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: <Widget>[
                    _ReportSelectorCard(
                      selected: _selectedReport,
                      valueLabel: _reportTypeLabel(_selectedReport),
                      onChanged: (_ReportViewType? value) {
                        if (value == null) {
                          return;
                        }
                        _changeReportType(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_selectedReport ==
                        _ReportViewType.salesAnalytics) ...<Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: AnalyticsPeriodTabs(
                                selected: _granularity,
                                onSelected: _setGranularity,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AnalyticsDateRangeCard(
                            value: _formatCompactRange(_range),
                            onTap: _pickDateRange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (analytics == null)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                                'No hay datos disponibles para el periodo.'),
                          ),
                        )
                      else ...<Widget>[
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints c) {
                            const double spacing = 10;
                            final int columns = _kpiColumnsForWidth(c.maxWidth);
                            final List<Widget> cards = <Widget>[
                              TotalSalesKpiWidget(
                                totalSales: analytics.ordersCount,
                                onTap: () => _openSalesList(
                                  title: 'Total de ventas',
                                ),
                              ),
                              SalesAmountKpiWidget(
                                totalAmountCents: analytics.totalRevenueCents,
                                moneyFormatter: _money,
                                deltaPercent:
                                    analytics.totalRevenueDeltaPercent,
                                deltaText: _formatDelta(
                                    analytics.totalRevenueDeltaPercent),
                                onTap: () => _openSalesList(
                                  title: 'Importe total de ventas',
                                ),
                              ),
                              ProfitKpiWidget(
                                totalProfitCents: analytics.totalProfitCents,
                                moneyFormatter: _money,
                              ),
                              SoldProductsKpiWidget(
                                totalProductsSold: analytics.itemsSoldQty,
                                onTap: () => _openSalesList(
                                  title: 'Productos vendidos',
                                ),
                              ),
                            ];
                            return GridView.builder(
                              itemCount: cards.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio:
                                    c.maxWidth < 420 ? 1.18 : 1.33,
                              ),
                              itemBuilder: (_, int index) => cards[index],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'CANALES DE VENTA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openSalesList(
                                title: 'Ventas del período',
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text('Detalles'),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AnalyticsSalesChannelCard(
                          currencySymbol: _currencySymbol,
                          posOrdersCount: analytics.posOrdersCount,
                          posRevenueCents: analytics.posRevenueCents,
                          directOrdersCount: analytics.directOrdersCount,
                          directRevenueCents: analytics.directRevenueCents,
                          onPosTap: () => _openSalesList(
                            title: 'Ventas canal POS',
                            channel: 'pos',
                          ),
                          onDirectTap: () => _openSalesList(
                            title: 'Ventas canal directa',
                            channel: 'directa',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnalyticsBreakdownCard(
                          title: 'Métodos de Pago',
                          currencySymbol: _currencySymbol,
                          totalBaseCents: analytics.totalRevenueCents,
                          items: analytics.paymentMethods,
                          emptyLabel: 'No hay pagos registrados en el rango.',
                          onItemTap: (SalesBreakdownStat row) {
                            _openSalesList(
                              title: 'Ventas por ${row.label}',
                              paymentMethodKey: row.key,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        AnalyticsBreakdownCard(
                          title: 'Ventas por Dependiente',
                          currencySymbol: _currencySymbol,
                          totalBaseCents: analytics.totalRevenueCents,
                          items: analytics.byCashier,
                          onItemTap: (SalesBreakdownStat row) {
                            _openSalesList(
                              title: 'Ventas de ${row.label}',
                              dependentKey: row.key,
                            );
                          },
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
                              child:
                                  Text('Sin clientes asociados en este rango.'),
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
                                child: Text(_showAllTopProducts
                                    ? 'Ver menos'
                                    : 'Ver todo'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (visibleTopProducts.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child:
                                  Text('Sin productos vendidos en el rango.'),
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
                    ] else ...<Widget>[
                      _AnalyticsDateRangeCard(
                        value: _formatDateRange(_range),
                        onTap: _pickDateRange,
                        compact: false,
                      ),
                      const SizedBox(height: 12),
                      ..._buildPaymentsReportSections(context),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _ReportSelectorCard extends StatelessWidget {
  const _ReportSelectorCard({
    required this.selected,
    required this.valueLabel,
    required this.onChanged,
  });

  final _ReportViewType selected;
  final String valueLabel;
  final ValueChanged<_ReportViewType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Tipo de reporte',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_ReportViewType>(
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const <DropdownMenuItem<_ReportViewType>>[
              DropdownMenuItem<_ReportViewType>(
                value: _ReportViewType.salesAnalytics,
                child: Text('Analítica de ventas'),
              ),
              DropdownMenuItem<_ReportViewType>(
                value: _ReportViewType.paymentsDetail,
                child: Text('Detalle de pagos'),
              ),
            ],
            onChanged: onChanged,
          ),
          const SizedBox(height: 4),
          Text(
            valueLabel,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsDateRangeCard extends StatelessWidget {
  const _AnalyticsDateRangeCard({
    required this.value,
    required this.onTap,
    this.compact = true,
  });

  final String value;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF263244) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? null
                : const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: <Widget>[
              const Icon(
                Icons.event_rounded,
                size: 16,
                color: Color(0xFF1152D4),
              ),
              const SizedBox(width: 6),
              if (compact)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                )
              else
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
