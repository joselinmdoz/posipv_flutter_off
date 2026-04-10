import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../tpv/presentation/tpv_providers.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';
import 'widgets/analytics_period_tabs.dart';
import 'widgets/analytics_breakdown_card.dart';
import 'widgets/analytics_sales_channel_card.dart';
import 'widgets/analytics_sales_summary_cards.dart';
import 'widgets/analytics_top_customer_tile.dart';
import 'widgets/analytics_top_product_tile.dart';
import 'widgets/analytics_sales_list_page.dart';
import 'widgets/analytics_sale_detail_page.dart';
import 'widgets/ipv_reporte_detail_page.dart';

enum _ReportViewType {
  salesAnalytics,
  paymentsDetail,
  dailyReport,
}

class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage> {
  static const String _allPaymentMethodsToken = '__all__';
  static const String _allSalesSourceToken = '__all_sales_source__';
  static const String _directSalesSourceToken = '__direct_sales_source__';
  static const String _tpvSalesSourcePrefix = 'tpv:';
  static const List<int> _paymentPageSizes = <int>[25, 50, 100];
  static const List<int> _dailyPageSizes = <int>[10, 20, 40];

  SalesAnalyticsSnapshot? _analytics;
  DailyReportSnapshot? _dailyReport;
  List<SalesPaymentReportRow> _paymentReportRows = <SalesPaymentReportRow>[];
  List<String> _paymentMethodKeys = <String>[];
  String? _selectedPaymentMethodKey;
  int _paymentCurrentPage = 1;
  int _paymentPageSize = _paymentPageSizes.first;
  int _paymentTotalCount = 0;
  bool _loadingPaymentPage = false;
  bool _loadingDailyPage = false;
  DateTime _dailyReportDate = DateTime.now();
  int _dailySalesCurrentPage = 1;
  int _dailySalesPageSize = _dailyPageSizes.first;
  int _dailyMovementsCurrentPage = 1;
  int _dailyMovementsPageSize = _dailyPageSizes.first;
  int _dailyIpvLinesCurrentPage = 1;
  int _dailyIpvLinesPageSize = _dailyPageSizes.first;
  List<_AnalyticsSalesSourceOption> _salesSourceOptions =
      _defaultSalesSourceOptions();
  String _selectedSalesSourceKey = _allSalesSourceToken;
  Map<String, String> _paymentMethodLabelsByCode = <String, String>{};
  String _currencySymbol = AppConfig.defaultCurrencySymbol;
  bool _loading = true;
  bool _exportingAnalytics = false;
  bool _exportingDailyReport = false;
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
    switch (_selectedReport) {
      case _ReportViewType.salesAnalytics:
        return _loadAnalytics(showLoader: showLoader);
      case _ReportViewType.paymentsDetail:
        return _loadPaymentsReport(showLoader: showLoader);
      case _ReportViewType.dailyReport:
        return _loadDailyReport(showLoader: showLoader);
    }
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
    final Future<AppConfig> configFuture = configDs.loadConfig();
    final Future<List<AppPaymentMethodSetting>> paymentMethodsFuture =
        configDs.loadPaymentMethodSettings();

    String currencySymbol = _currencySymbol;
    Map<String, String> paymentMethodLabels = _paymentMethodLabelsByCode;
    SalesAnalyticsSnapshot? snapshot;
    List<_AnalyticsSalesSourceOption> sourceOptions = _salesSourceOptions;
    String selectedSourceKey = _selectedSalesSourceKey;
    String? warningMessage;

    try {
      currencySymbol = (await configFuture).currencySymbol;
    } catch (e) {
      warningMessage = 'Configuracion: $e';
    }
    try {
      paymentMethodLabels = buildPaymentMethodLabelMap(
        await paymentMethodsFuture,
      );
    } catch (e) {
      final String message = 'Métodos de pago: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    try {
      sourceOptions = await _loadSalesSourceOptions();
      final bool hasSelection = sourceOptions.any(
        (_AnalyticsSalesSourceOption row) => row.key == selectedSourceKey,
      );
      if (!hasSelection) {
        selectedSourceKey = _allSalesSourceToken;
      }
    } catch (e) {
      final String message = 'Filtros de origen: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    final _ResolvedSalesSourceFilter sourceFilter =
        _resolveSalesSourceFilter(selectedSourceKey);

    try {
      snapshot = await reportesDs.loadSalesAnalytics(
        fromDate: _range.start,
        toDate: _range.end,
        granularity: _granularity,
        topLimit: 20,
        channel: sourceFilter.channel,
        terminalId: sourceFilter.terminalId,
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
      _paymentMethodLabelsByCode = paymentMethodLabels;
      _analytics = snapshot;
      _salesSourceOptions = sourceOptions;
      _selectedSalesSourceKey = selectedSourceKey;
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
    final Future<AppConfig> configFuture = configDs.loadConfig();
    final Future<List<AppPaymentMethodSetting>> paymentMethodsFuture =
        configDs.loadPaymentMethodSettings();

    String currencySymbol = _currencySymbol;
    Map<String, String> paymentMethodLabels = _paymentMethodLabelsByCode;
    List<SalesPaymentReportRow> rows = <SalesPaymentReportRow>[];
    List<String> methodKeys = _paymentMethodKeys;
    List<_AnalyticsSalesSourceOption> sourceOptions = _salesSourceOptions;
    String selectedSourceKey = _selectedSalesSourceKey;
    int totalCount = 0;
    int effectivePage = _paymentCurrentPage < 1 ? 1 : _paymentCurrentPage;
    String? effectiveMethod = _selectedPaymentMethodKey;
    String? warningMessage;

    try {
      currencySymbol = (await configFuture).currencySymbol;
    } catch (e) {
      warningMessage = 'Configuracion: $e';
    }
    try {
      paymentMethodLabels = buildPaymentMethodLabelMap(
        await paymentMethodsFuture,
      );
    } catch (e) {
      final String message = 'Métodos de pago: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    try {
      sourceOptions = await _loadSalesSourceOptions();
      final bool hasSelection = sourceOptions.any(
        (_AnalyticsSalesSourceOption row) => row.key == selectedSourceKey,
      );
      if (!hasSelection) {
        selectedSourceKey = _allSalesSourceToken;
      }
    } catch (e) {
      final String message = 'Filtros de origen: $e';
      warningMessage =
          warningMessage == null ? message : '$warningMessage\n$message';
    }

    final _ResolvedSalesSourceFilter sourceFilter =
        _resolveSalesSourceFilter(selectedSourceKey);

    try {
      if (refreshMethodKeys) {
        methodKeys = await reportesDs.listPaymentMethodKeysForRange(
          fromDate: _range.start,
          toDate: _range.end,
          channel: sourceFilter.channel,
          terminalId: sourceFilter.terminalId,
        );
      }

      final Set<String> methodSet = methodKeys.toSet();
      if (effectiveMethod != null && !methodSet.contains(effectiveMethod)) {
        effectiveMethod = null;
      }

      totalCount = await reportesDs.countSalesPaymentsReport(
        fromDate: _range.start,
        toDate: _range.end,
        channel: sourceFilter.channel,
        terminalId: sourceFilter.terminalId,
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
          channel: sourceFilter.channel,
          terminalId: sourceFilter.terminalId,
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
      _paymentMethodLabelsByCode = paymentMethodLabels;
      _salesSourceOptions = sourceOptions;
      _selectedSalesSourceKey = selectedSourceKey;
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

  Future<void> _loadDailyReport({bool showLoader = true}) async {
    final license = ref.read(currentLicenseStatusProvider);
    if (!license.canAccessGeneralReports) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadingDailyPage = false;
        _dailyReport = null;
      });
      return;
    }

    if (showLoader && mounted) {
      setState(() => _loading = true);
    } else if (mounted) {
      setState(() => _loadingDailyPage = true);
    }

    final ReportesLocalDataSource reportesDs =
        ref.read(reportesLocalDataSourceProvider);
    final ConfiguracionLocalDataSource configDs =
        ref.read(configuracionLocalDataSourceProvider);
    String currencySymbol = _currencySymbol;
    DailyReportSnapshot? snapshot;
    String? warningMessage;

    try {
      currencySymbol = (await configDs.loadConfig()).currencySymbol;
    } catch (e) {
      warningMessage = 'Configuracion: $e';
    }
    try {
      snapshot = await reportesDs.loadDailyReport(
        reportDate: _dailyReportDate,
        salesLimit: _dailySalesPageSize,
        salesOffset: (_dailySalesCurrentPage - 1) * _dailySalesPageSize,
        movementsLimit: _dailyMovementsPageSize,
        movementsOffset:
            (_dailyMovementsCurrentPage - 1) * _dailyMovementsPageSize,
        ipvLinesLimit: _dailyIpvLinesPageSize,
        ipvLinesOffset:
            (_dailyIpvLinesCurrentPage - 1) * _dailyIpvLinesPageSize,
      );
    } catch (e) {
      warningMessage = warningMessage == null
          ? 'Informe diario: $e'
          : '$warningMessage\nInforme diario: $e';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currencySymbol = currencySymbol;
      _dailyReport = snapshot;
      _loading = false;
      _loadingDailyPage = false;
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

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _pageCount(int total, int size) {
    if (total <= 0) {
      return 1;
    }
    return (total + size - 1) ~/ size;
  }

  Future<void> _pickDailyReportDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _startOfDay(_dailyReportDate);
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDate: initial,
      helpText: 'Seleccionar día',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dailyReportDate = _startOfDay(picked);
      _dailySalesCurrentPage = 1;
      _dailyMovementsCurrentPage = 1;
      _dailyIpvLinesCurrentPage = 1;
    });
    await _loadDailyReport(showLoader: true);
  }

  Future<void> _goToDailySalesPage(int page) async {
    if (_loadingDailyPage) {
      return;
    }
    final int maxPages = _pageCount(
      _dailyReport?.salesTotalCount ?? 0,
      _dailySalesPageSize,
    );
    final int safePage = page < 1 ? 1 : (page > maxPages ? maxPages : page);
    if (safePage == _dailySalesCurrentPage) {
      return;
    }
    setState(() => _dailySalesCurrentPage = safePage);
    await _loadDailyReport(showLoader: false);
  }

  Future<void> _changeDailySalesPageSize(int? value) async {
    if (value == null || value == _dailySalesPageSize) {
      return;
    }
    setState(() {
      _dailySalesPageSize = value;
      _dailySalesCurrentPage = 1;
    });
    await _loadDailyReport(showLoader: true);
  }

  Future<void> _goToDailyMovementsPage(int page) async {
    if (_loadingDailyPage) {
      return;
    }
    final int maxPages = _pageCount(
      _dailyReport?.movementsTotalCount ?? 0,
      _dailyMovementsPageSize,
    );
    final int safePage = page < 1 ? 1 : (page > maxPages ? maxPages : page);
    if (safePage == _dailyMovementsCurrentPage) {
      return;
    }
    setState(() => _dailyMovementsCurrentPage = safePage);
    await _loadDailyReport(showLoader: false);
  }

  Future<void> _changeDailyMovementsPageSize(int? value) async {
    if (value == null || value == _dailyMovementsPageSize) {
      return;
    }
    setState(() {
      _dailyMovementsPageSize = value;
      _dailyMovementsCurrentPage = 1;
    });
    await _loadDailyReport(showLoader: true);
  }

  Future<void> _goToDailyIpvLinesPage(int page) async {
    if (_loadingDailyPage) {
      return;
    }
    final int maxPages = _pageCount(
      _dailyReport?.ipvLinesTotalCount ?? 0,
      _dailyIpvLinesPageSize,
    );
    final int safePage = page < 1 ? 1 : (page > maxPages ? maxPages : page);
    if (safePage == _dailyIpvLinesCurrentPage) {
      return;
    }
    setState(() => _dailyIpvLinesCurrentPage = safePage);
    await _loadDailyReport(showLoader: false);
  }

  Future<void> _changeDailyIpvLinesPageSize(int? value) async {
    if (value == null || value == _dailyIpvLinesPageSize) {
      return;
    }
    setState(() {
      _dailyIpvLinesPageSize = value;
      _dailyIpvLinesCurrentPage = 1;
    });
    await _loadDailyReport(showLoader: true);
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
            channel: _currentSalesSourceFilter.channel,
            terminalId: _currentSalesSourceFilter.terminalId,
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

  Future<void> _handleDailyReportExportAction(
    _DailyReportExportAction action,
  ) async {
    if (_dailyReport == null || _exportingDailyReport) {
      return;
    }
    switch (action) {
      case _DailyReportExportAction.exportCsv:
        await _exportDailyReport(format: 'csv', shareFile: false);
      case _DailyReportExportAction.exportPdf:
        await _exportDailyReport(format: 'pdf', shareFile: false);
      case _DailyReportExportAction.shareCsv:
        await _exportDailyReport(format: 'csv', shareFile: true);
      case _DailyReportExportAction.sharePdf:
        await _exportDailyReport(format: 'pdf', shareFile: true);
    }
  }

  Future<void> _exportDailyReport({
    required String format,
    required bool shareFile,
  }) async {
    if (_dailyReport == null || _exportingDailyReport) {
      return;
    }
    setState(() => _exportingDailyReport = true);
    try {
      final ReportesLocalDataSource ds =
          ref.read(reportesLocalDataSourceProvider);
      final String path = format == 'pdf'
          ? await ds.exportDailyReportPdf(
              reportDate: _dailyReportDate,
              currencySymbol: _currencySymbol,
            )
          : await ds.exportDailyReportCsv(
              reportDate: _dailyReportDate,
              currencySymbol: _currencySymbol,
            );
      if (!mounted) {
        return;
      }
      if (shareFile) {
        await Share.shareXFiles(
          <XFile>[XFile(path)],
          text:
              'Informe diario ${_formatDate(_dailyReportDate)} (${format.toUpperCase()})',
          subject: 'Informe diario',
        );
        if (!mounted) {
          return;
        }
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              shareFile
                  ? 'Informe diario listo para compartir:\n$path'
                  : 'Informe diario exportado en:\n$path',
            ),
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
            content: Text('No se pudo exportar el informe diario: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _exportingDailyReport = false);
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

  String _formatQty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.000001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _movementTypeLabel(String type) {
    return type.trim().toLowerCase() == 'in' ? 'Entrada' : 'Salida';
  }

  String _movementSourceLabel(String source) {
    switch (source.trim().toLowerCase()) {
      case 'pos':
        return 'POS';
      case 'direct_sale':
        return 'Venta directa';
      case 'pos_consignment':
        return 'POS consignación';
      case 'direct_consignment':
        return 'Directa consignación';
      case 'transfer':
        return 'Transferencia';
      default:
        return 'Manual';
    }
  }

  String _ipvStatusLabel(String status) {
    return status.trim().toLowerCase() == 'closed' ? 'Cerrado' : 'Abierto';
  }

  Future<void> _openDailySaleDetail(String saleId) async {
    final bool? result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AnalyticsSaleDetailPage(
          saleId: saleId,
          currencySymbol: _currencySymbol,
        ),
      ),
    );
    if (result == true) {
      await _loadDailyReport(showLoader: true);
    }
  }

  Future<void> _openIpvDetail(IpvReportSummaryStat summary) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IpvReporteDetailPage(summary: summary),
      ),
    );
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
    final String code = method.trim().toLowerCase();
    if (code.isEmpty) {
      return 'Metodo';
    }
    return _paymentMethodLabelsByCode[code] ?? defaultPaymentMethodLabel(code);
  }

  String _reportTypeLabel(_ReportViewType type) {
    switch (type) {
      case _ReportViewType.salesAnalytics:
        return 'Analítica de ventas';
      case _ReportViewType.paymentsDetail:
        return 'Detalle de pagos';
      case _ReportViewType.dailyReport:
        return 'Informe diario';
    }
  }

  Future<void> _changeReportType(_ReportViewType next) async {
    if (_selectedReport == next) {
      return;
    }
    setState(() {
      _selectedReport = next;
      _paymentCurrentPage = 1;
      if (next == _ReportViewType.dailyReport) {
        _dailySalesCurrentPage = 1;
        _dailyMovementsCurrentPage = 1;
        _dailyIpvLinesCurrentPage = 1;
      }
    });
    await _loadCurrentReport(showLoader: true);
  }

  void _openLotsStatusPage() {
    context.push('/reportes-lotes');
  }

  static List<_AnalyticsSalesSourceOption> _defaultSalesSourceOptions() {
    return const <_AnalyticsSalesSourceOption>[
      _AnalyticsSalesSourceOption(
        key: _allSalesSourceToken,
        label: 'Todos los canales',
      ),
      _AnalyticsSalesSourceOption(
        key: _directSalesSourceToken,
        label: 'Ventas directas',
      ),
    ];
  }

  Future<List<_AnalyticsSalesSourceOption>> _loadSalesSourceOptions() async {
    final List<_AnalyticsSalesSourceOption> defaults =
        _defaultSalesSourceOptions();
    final terminals =
        await ref.read(tpvLocalDataSourceProvider).listActiveTerminalOptions();
    if (terminals.isEmpty) {
      return defaults;
    }
    return <_AnalyticsSalesSourceOption>[
      ...defaults,
      ...terminals.map(
        (terminal) => _AnalyticsSalesSourceOption(
          key: '$_tpvSalesSourcePrefix${terminal.id}',
          label: 'TPV • ${terminal.name}',
        ),
      ),
    ];
  }

  _ResolvedSalesSourceFilter _resolveSalesSourceFilter(String selectedKey) {
    final String key = selectedKey.trim();
    if (key.isEmpty || key == _allSalesSourceToken) {
      return const _ResolvedSalesSourceFilter();
    }
    if (key == _directSalesSourceToken) {
      return const _ResolvedSalesSourceFilter(channel: 'directa');
    }
    if (key.startsWith(_tpvSalesSourcePrefix)) {
      final String terminalId = key.substring(_tpvSalesSourcePrefix.length);
      if (terminalId.trim().isNotEmpty) {
        return _ResolvedSalesSourceFilter(
          channel: 'pos',
          terminalId: terminalId.trim(),
        );
      }
    }
    return const _ResolvedSalesSourceFilter();
  }

  _ResolvedSalesSourceFilter get _currentSalesSourceFilter {
    return _resolveSalesSourceFilter(_selectedSalesSourceKey);
  }

  Future<void> _changeSalesSourceFilter(String? value) async {
    final String raw = (value ?? _allSalesSourceToken).trim();
    final String next = raw.isEmpty ? _allSalesSourceToken : raw;
    if (_selectedSalesSourceKey == next) {
      return;
    }
    setState(() {
      _selectedSalesSourceKey = next;
      _showAllTopProducts = false;
      _paymentCurrentPage = 1;
      _selectedPaymentMethodKey = null;
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
    String? terminalId,
    String? paymentMethodKey,
    String? dependentKey,
  }) async {
    final _ResolvedSalesSourceFilter activeFilter = _currentSalesSourceFilter;
    final String? effectiveChannel = channel ?? activeFilter.channel;
    String? effectiveTerminalId = terminalId ?? activeFilter.terminalId;
    if (effectiveChannel == 'directa') {
      effectiveTerminalId = null;
    }
    if ((effectiveTerminalId ?? '').trim().isNotEmpty) {
      // If a terminal is selected, the channel is always POS.
      effectiveTerminalId = effectiveTerminalId!.trim();
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsSalesListPage(
          fromDate: _range.start,
          toDate: _range.end,
          currencySymbol: _currencySymbol,
          title: title,
          channel: effectiveTerminalId == null ? effectiveChannel : 'pos',
          terminalId: effectiveTerminalId,
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
    final List<DropdownMenuItem<String>> sourceItems = _salesSourceOptions
        .map(
          (_AnalyticsSalesSourceOption row) => DropdownMenuItem<String>(
            value: row.key,
            child: Text(row.label),
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
              'ORIGEN DE VENTA',
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
                'payment-sales-source-$_selectedSalesSourceKey-${_salesSourceOptions.length}',
              ),
              initialValue: _selectedSalesSourceKey,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: sourceItems,
              onChanged: _changeSalesSourceFilter,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
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

  List<Widget> _buildDailyReportSections(BuildContext context) {
    final DailyReportSnapshot? report = _dailyReport;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (report == null) {
      return const <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay datos del informe diario para la fecha.'),
          ),
        ),
      ];
    }

    final List<DropdownMenuItem<int>> pageSizeItems = _dailyPageSizes
        .map(
          (int size) => DropdownMenuItem<int>(
            value: size,
            child: Text('$size filas'),
          ),
        )
        .toList(growable: false);
    final int salesTotalPages =
        _pageCount(report.salesTotalCount, _dailySalesPageSize);
    final int salesPage = _dailySalesCurrentPage < 1
        ? 1
        : (_dailySalesCurrentPage > salesTotalPages
            ? salesTotalPages
            : _dailySalesCurrentPage);
    final int salesStart = report.salesTotalCount == 0
        ? 0
        : ((salesPage - 1) * _dailySalesPageSize) + 1;
    final int salesEnd =
        report.salesTotalCount == 0 ? 0 : salesStart + report.sales.length - 1;

    final int movementsTotalPages =
        _pageCount(report.movementsTotalCount, _dailyMovementsPageSize);
    final int movementsPage = _dailyMovementsCurrentPage < 1
        ? 1
        : (_dailyMovementsCurrentPage > movementsTotalPages
            ? movementsTotalPages
            : _dailyMovementsCurrentPage);
    final int movementsStart = report.movementsTotalCount == 0
        ? 0
        : ((movementsPage - 1) * _dailyMovementsPageSize) + 1;
    final int movementsEnd = report.movementsTotalCount == 0
        ? 0
        : movementsStart + report.movements.length - 1;

    final int ipvLinesTotalPages =
        _pageCount(report.ipvLinesTotalCount, _dailyIpvLinesPageSize);
    final int ipvLinesPage = _dailyIpvLinesCurrentPage < 1
        ? 1
        : (_dailyIpvLinesCurrentPage > ipvLinesTotalPages
            ? ipvLinesTotalPages
            : _dailyIpvLinesCurrentPage);
    final int ipvLinesStart = report.ipvLinesTotalCount == 0
        ? 0
        : ((ipvLinesPage - 1) * _dailyIpvLinesPageSize) + 1;
    final int ipvLinesEnd = report.ipvLinesTotalCount == 0
        ? 0
        : ipvLinesStart + report.ipvLines.length - 1;

    Widget sectionCard({
      required String title,
      required String subtitle,
      required List<Widget> children,
    }) {
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
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFE2E8F0) : const Color(0xFf0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      );
    }

    Widget pager({
      required String rowsLabel,
      required int currentPage,
      required int totalPages,
      required int pageSize,
      required ValueChanged<int?> onPageSizeChanged,
      required VoidCallback? onPrev,
      required VoidCallback? onNext,
    }) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            rowsLabel,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          SizedBox(
            width: 132,
            child: DropdownButtonFormField<int>(
              key: ValueKey<int>(pageSize),
              initialValue: pageSize,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: pageSizeItems,
              onChanged: _loadingDailyPage ? null : onPageSizeChanged,
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _loadingDailyPage ? null : onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Anterior'),
          ),
          FilledButton.tonalIcon(
            onPressed: _loadingDailyPage ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Siguiente'),
          ),
          Text(
            'Página $currentPage de $totalPages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ],
      );
    }

    final Map<String, IpvReportSummaryStat> ipvById =
        <String, IpvReportSummaryStat>{
      for (final IpvReportSummaryStat summary in report.ipvReports)
        summary.reportId: summary,
    };

    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: _AnalyticsDateRangeCard(
              value: _formatDate(report.reportDate),
              onTap: _pickDailyReportDate,
              compact: false,
            ),
          ),
        ],
      ),
      if (_loadingDailyPage) ...<Widget>[
        const SizedBox(height: 8),
        const LinearProgressIndicator(minHeight: 2),
      ],
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          const double spacing = 10;
          final int columns = _kpiColumnsForWidth(c.maxWidth);
          final List<Widget> cards = <Widget>[
            _DailySummaryCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Total de ventas',
              value: report.salesSummary.salesCount.toString(),
              subtitle: 'Ventas completadas',
            ),
            _DailySummaryCard(
              icon: Icons.payments_outlined,
              title: 'Importe ventas',
              value: _money(report.salesSummary.totalCents),
              subtitle: 'Total facturado',
            ),
            _DailySummaryCard(
              icon: Icons.trending_up_rounded,
              title: 'Ganancia',
              value: _money(report.salesSummary.profitCents),
              subtitle: 'Utilidad real del día',
            ),
            _DailySummaryCard(
              icon: Icons.inventory_2_outlined,
              title: 'Productos vendidos',
              value: _formatQty(report.salesSummary.itemsSoldQty),
              subtitle: 'Unidades vendidas',
            ),
            _DailySummaryCard(
              icon: Icons.south_west_rounded,
              title: 'Entradas',
              value: _formatQty(report.movementsSummary.entriesQty),
              subtitle: '${report.movementsSummary.entriesCount} movimientos',
            ),
            _DailySummaryCard(
              icon: Icons.north_east_rounded,
              title: 'Salidas',
              value: _formatQty(report.movementsSummary.outputsQty),
              subtitle: '${report.movementsSummary.outputsCount} movimientos',
            ),
            _DailySummaryCard(
              icon: Icons.point_of_sale_rounded,
              title: 'Reportes IPV',
              value: report.ipvSummary.reportsCount.toString(),
              subtitle: '${report.ipvSummary.linesCount} líneas',
            ),
            _DailySummaryCard(
              icon: Icons.receipt_long_outlined,
              title: 'Importe IPV',
              value: _money(report.ipvSummary.totalAmountCents),
              subtitle:
                  '${_formatQty(report.ipvSummary.salesQty)} uds vendidas',
            ),
          ];
          return GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: c.maxWidth < 420 ? 1.15 : 1.35,
            ),
            itemBuilder: (_, int index) => cards[index],
          );
        },
      ),
      const SizedBox(height: 12),
      sectionCard(
        title: 'Ventas del día',
        subtitle: 'Detalle completo de ventas registradas',
        children: <Widget>[
          pager(
            rowsLabel:
                'Mostrando $salesStart-$salesEnd de ${report.salesTotalCount} ventas',
            currentPage: salesPage,
            totalPages: salesTotalPages,
            pageSize: _dailySalesPageSize,
            onPageSizeChanged: _changeDailySalesPageSize,
            onPrev:
                salesPage > 1 ? () => _goToDailySalesPage(salesPage - 1) : null,
            onNext: salesPage < salesTotalPages
                ? () => _goToDailySalesPage(salesPage + 1)
                : null,
          ),
          const SizedBox(height: 10),
          if (report.sales.isEmpty)
            const Text('No hay ventas en la fecha seleccionada.')
          else
            ...report.sales.map((SalesAnalyticsSaleStat sale) {
              final String channelLabel =
                  sale.channel.toLowerCase() == 'pos' ? 'POS' : 'DIRECTA';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${sale.folio} • $channelLabel',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            _money(sale.totalCents),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${_formatDateTime(sale.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Dependiente: ${sale.cashierUsername} • Almacén: ${sale.warehouseName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Ítems: ${sale.itemsCount} • Cliente: ${sale.customerName ?? 'Sin cliente'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if ((sale.terminalName ?? '').trim().isNotEmpty)
                        Text(
                          'TPV: ${sale.terminalName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _openDailySaleDetail(sale.saleId),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Ver detalle'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      const SizedBox(height: 12),
      sectionCard(
        title: 'Entradas y salidas',
        subtitle: 'Movimientos de inventario del día',
        children: <Widget>[
          pager(
            rowsLabel:
                'Mostrando $movementsStart-$movementsEnd de ${report.movementsTotalCount} movimientos',
            currentPage: movementsPage,
            totalPages: movementsTotalPages,
            pageSize: _dailyMovementsPageSize,
            onPageSizeChanged: _changeDailyMovementsPageSize,
            onPrev: movementsPage > 1
                ? () => _goToDailyMovementsPage(movementsPage - 1)
                : null,
            onNext: movementsPage < movementsTotalPages
                ? () => _goToDailyMovementsPage(movementsPage + 1)
                : null,
          ),
          const SizedBox(height: 10),
          if (report.movements.isEmpty)
            const Text('No hay movimientos en la fecha seleccionada.')
          else
            ...report.movements.map((DailyReportMovementStat movement) {
              final bool isIn = movement.movementType == 'in';
              final Color qtyColor =
                  isIn ? const Color(0xFF047857) : const Color(0xFFB91C1C);
              final String sign = isIn ? '+' : '-';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${movement.productName} • ${movement.sku}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            '$sign${_formatQty(movement.qty)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: qtyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_movementTypeLabel(movement.movementType)} • ${movement.reasonLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'Almacén: ${movement.warehouseName} • Origen: ${_movementSourceLabel(movement.movementSource)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Usuario: ${movement.username} • Fecha: ${_formatDateTime(movement.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if ((movement.refType ?? '').trim().isNotEmpty ||
                          (movement.refId ?? '').trim().isNotEmpty)
                        Text(
                          'Referencia: ${movement.refType ?? '-'} / ${movement.refId ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      if ((movement.note ?? '').trim().isNotEmpty)
                        Text(
                          'Nota: ${movement.note}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      const SizedBox(height: 12),
      sectionCard(
        title: 'IPV del día',
        subtitle: 'Reportes IPV vinculados a la fecha',
        children: <Widget>[
          if (report.ipvReports.isEmpty)
            const Text('No hay reportes IPV en la fecha seleccionada.')
          else
            ...report.ipvReports.map((IpvReportSummaryStat summary) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${summary.terminalName} • ${_ipvStatusLabel(summary.status)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            _money(summary.totalAmountCents),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apertura: ${_formatDateTime(summary.openedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (summary.closedAt != null)
                        Text(
                          'Cierre: ${_formatDateTime(summary.closedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      Text(
                        'Líneas: ${summary.lineCount} • Sesión: ${summary.sessionId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _openIpvDetail(summary),
                          icon:
                              const Icon(Icons.table_chart_outlined, size: 16),
                          label: const Text('Ver IPV'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
      const SizedBox(height: 12),
      sectionCard(
        title: 'Líneas IPV del día',
        subtitle: 'Desglose de productos en IPV',
        children: <Widget>[
          pager(
            rowsLabel:
                'Mostrando $ipvLinesStart-$ipvLinesEnd de ${report.ipvLinesTotalCount} líneas',
            currentPage: ipvLinesPage,
            totalPages: ipvLinesTotalPages,
            pageSize: _dailyIpvLinesPageSize,
            onPageSizeChanged: _changeDailyIpvLinesPageSize,
            onPrev: ipvLinesPage > 1
                ? () => _goToDailyIpvLinesPage(ipvLinesPage - 1)
                : null,
            onNext: ipvLinesPage < ipvLinesTotalPages
                ? () => _goToDailyIpvLinesPage(ipvLinesPage + 1)
                : null,
          ),
          const SizedBox(height: 10),
          if (report.ipvLines.isEmpty)
            const Text('No hay líneas IPV en la fecha seleccionada.')
          else
            ...report.ipvLines.map((DailyReportIpvLineStat line) {
              final IpvReportSummaryStat? parent = ipvById[line.reportId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${line.productName} • ${line.sku}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            _money(line.totalAmountCents),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TPV: ${line.terminalName} • Reporte: ${line.reportId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Inicio ${_formatQty(line.startQty)} • Entradas ${_formatQty(line.entriesQty)} • Salidas ${_formatQty(line.outputsQty)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Ventas ${_formatQty(line.salesQty)} • Final ${_formatQty(line.finalQty)} • Precio ${_money(line.salePriceCents)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (parent != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _openIpvDetail(parent),
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Abrir IPV'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    ];
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
          : (_selectedReport == _ReportViewType.dailyReport
              ? 'Informe diario'
              : 'Reportes'),
      currentRoute: '/reportes',
      onRefresh: _loadCurrentReport,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: _onBackPressed,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Estado de lotes',
          onPressed: _openLotsStatusPage,
          icon: const Icon(Icons.inventory_2_outlined),
        ),
        if (_selectedReport == _ReportViewType.salesAnalytics)
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
        if (_selectedReport == _ReportViewType.dailyReport)
          _exportingDailyReport
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : PopupMenuButton<_DailyReportExportAction>(
                  tooltip: 'Exportar / compartir',
                  onSelected: _handleDailyReportExportAction,
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<_DailyReportExportAction>>[
                    PopupMenuItem<_DailyReportExportAction>(
                      value: _DailyReportExportAction.exportCsv,
                      child: Text('Exportar CSV'),
                    ),
                    PopupMenuItem<_DailyReportExportAction>(
                      value: _DailyReportExportAction.exportPdf,
                      child: Text('Exportar PDF'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<_DailyReportExportAction>(
                      value: _DailyReportExportAction.shareCsv,
                      child: Text('Compartir CSV'),
                    ),
                    PopupMenuItem<_DailyReportExportAction>(
                      value: _DailyReportExportAction.sharePdf,
                      child: Text('Compartir PDF'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.ios_share_rounded),
                  ),
                ),
      ],
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _openLotsStatusPage,
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: const Text('Estado de lotes'),
                      ),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF263244)
                                : const Color(0xFFD8E0EC),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'ORIGEN DE VENTA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey<String>(
                                'sales-source-$_selectedSalesSourceKey-${_salesSourceOptions.length}',
                              ),
                              initialValue: _selectedSalesSourceKey,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: _salesSourceOptions
                                  .map(
                                    (_AnalyticsSalesSourceOption row) =>
                                        DropdownMenuItem<String>(
                                      value: row.key,
                                      child: Text(row.label),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: _changeSalesSourceFilter,
                            ),
                          ],
                        ),
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
                    ] else if (_selectedReport ==
                        _ReportViewType.paymentsDetail) ...<Widget>[
                      _AnalyticsDateRangeCard(
                        value: _formatDateRange(_range),
                        onTap: _pickDateRange,
                        compact: false,
                      ),
                      const SizedBox(height: 12),
                      ..._buildPaymentsReportSections(context),
                    ] else ...<Widget>[
                      ..._buildDailyReportSections(context),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

enum _DailyReportExportAction {
  exportCsv,
  exportPdf,
  shareCsv,
  sharePdf,
}

class _AnalyticsSalesSourceOption {
  const _AnalyticsSalesSourceOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

class _ResolvedSalesSourceFilter {
  const _ResolvedSalesSourceFilter({
    this.channel,
    this.terminalId,
  });

  final String? channel;
  final String? terminalId;
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
              DropdownMenuItem<_ReportViewType>(
                value: _ReportViewType.dailyReport,
                child: Text('Informe diario'),
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

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF263244) : const Color(0xFFD8E0EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 17,
              color: const Color(0xFF1152D4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
