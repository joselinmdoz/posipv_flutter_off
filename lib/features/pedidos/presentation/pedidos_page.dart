import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/pedidos_local_datasource.dart';
import 'pedido_detail_page.dart';
import 'pedido_form_page.dart';
import 'pedidos_providers.dart';
import 'widgets/work_order_list_card.dart';
import 'widgets/work_orders_breakdown_card.dart';
import 'widgets/work_orders_dashboard_panel.dart';
import 'widgets/work_orders_status_tabs.dart';

class PedidosPage extends ConsumerStatefulWidget {
  const PedidosPage({super.key});

  @override
  ConsumerState<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends ConsumerState<PedidosPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  WorkOrderDashboardSummary? _summary;
  List<WorkOrderListItem> _orders = <WorkOrderListItem>[];
  WorkOrderPaymentDisplayConfig _paymentDisplayConfig =
      WorkOrderPaymentDisplayConfig.defaults;
  bool _loading = true;
  bool _exportingReport = false;
  String _statusFilter = 'all';
  final Set<_OrdersInsightFilter> _insightFilters = <_OrdersInsightFilter>{};
  DateTime? _summaryDateFrom;
  DateTime? _summaryDateTo;
  String _dateCriterion = WorkOrderDateFilterCriterion.createdAt;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 240), _load);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      final ConfiguracionLocalDataSource configDs =
          ref.read(configuracionLocalDataSourceProvider);
      final DateTime? createdFrom =
          _summaryDateFrom == null ? null : _startOfDay(_summaryDateFrom!);
      final DateTime? createdTo = _summaryDateTo == null
          ? null
          : _startOfDay(_summaryDateTo!).add(const Duration(days: 1));
      final results = await Future.wait<Object>(<Future<Object>>[
        ds.loadDashboardSummary(
          createdFrom: createdFrom,
          createdTo: createdTo,
          dateCriterion: _dateCriterion,
        ),
        ds.listOrders(
          searchQuery: _searchCtrl.text,
          statusFilter: _statusFilter,
          createdFrom: createdFrom,
          createdTo: createdTo,
          dateCriterion: _dateCriterion,
        ),
        configDs.loadWorkOrderPaymentDisplayConfig(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = results[0] as WorkOrderDashboardSummary;
        _orders = results[1] as List<WorkOrderListItem>;
        _paymentDisplayConfig = results[2] as WorkOrderPaymentDisplayConfig;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar los pedidos: $error');
    }
  }

  DateTime _startOfDay(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Future<void> _pickSummaryDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _summaryDateFrom != null && _summaryDateTo != null
          ? DateTimeRange(
              start: _summaryDateFrom!,
              end: _summaryDateTo!,
            )
          : null,
      helpText: 'Seleccionar rango del panel',
      saveText: 'Aplicar',
    );
    if (range == null || !mounted) {
      return;
    }
    setState(() {
      _summaryDateFrom = _startOfDay(range.start);
      _summaryDateTo = _startOfDay(range.end);
    });
    await _load();
  }

  Future<void> _clearSummaryDateRange() async {
    if (_summaryDateFrom == null && _summaryDateTo == null) {
      return;
    }
    setState(() {
      _summaryDateFrom = null;
      _summaryDateTo = null;
    });
    await _load();
  }

  Future<void> _pickDateCriterion() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: WorkOrderDateFilterCriterion.all
              .map(
                (String value) => ListTile(
                  title: Text(WorkOrderDateFilterCriterion.label(value)),
                  trailing: value == _dateCriterion
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF1152D4),
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(value),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    if (selected == null || !mounted || selected == _dateCriterion) {
      return;
    }
    setState(() => _dateCriterion = selected);
    await _load();
  }

  Future<void> _openForm([String? orderId]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PedidoFormPage(orderId: orderId),
      ),
    );
    if (changed == true) {
      await _load();
      _show(orderId == null ? 'Pedido creado.' : 'Pedido actualizado.');
    }
  }

  Future<void> _openDetail(String orderId) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PedidoDetailPage(orderId: orderId),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _handlePanelMenuAction(
    WorkOrdersDashboardMenuAction action,
  ) async {
    switch (action) {
      case WorkOrdersDashboardMenuAction.exportPdf:
        await _exportOrdersReport(shareFile: false);
      case WorkOrdersDashboardMenuAction.sharePdf:
        await _exportOrdersReport(shareFile: true);
      case WorkOrdersDashboardMenuAction.cloudSync:
        if (!mounted) {
          return;
        }
        context.push('/sync-cloud');
    }
  }

  Future<void> _exportOrdersReport({required bool shareFile}) async {
    if (_exportingReport) {
      return;
    }
    final List<WorkOrderListItem> visibleOrders = _visibleOrders();
    final WorkOrderDashboardSummary? summary = _summary;
    if (summary == null || visibleOrders.isEmpty) {
      _show('No hay pedidos para exportar con los filtros actuales.');
      return;
    }
    setState(() => _exportingReport = true);
    try {
      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      final List<WorkOrderDetail> details =
          (await Future.wait<WorkOrderDetail?>(
        visibleOrders.map((WorkOrderListItem item) => ds.getOrderById(item.id)),
      ))
              .whereType<WorkOrderDetail>()
              .toList(growable: false);
      if (details.isEmpty) {
        if (!mounted) {
          return;
        }
        _show('No se encontraron detalles para exportar.');
        return;
      }
      final String path =
          await ref.read(workOrdersReportServiceProvider).exportOrdersReportPdf(
                orders: details,
                summary: summary,
                rangeLabel: _summaryRangeLabel(),
                criterionLabel: _dateCriterionLabel(),
                statusFilterLabel: _statusFilterLabel(),
                insightFilterLabel: _insightFilters.isEmpty
                    ? null
                    : _insightFilterLabels().join(' + '),
                searchQuery: _searchCtrl.text.trim(),
              );
      if (!mounted) {
        return;
      }
      if (shareFile) {
        await Share.shareXFiles(
          <XFile>[XFile(path)],
          text: 'Informe de pedidos',
          subject: 'Informe de pedidos',
        );
        if (!mounted) {
          return;
        }
      }
      _show(
        shareFile
            ? 'Informe de pedidos listo para compartir.'
            : 'Informe de pedidos exportado en:\n$path',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo exportar el informe de pedidos: $error');
    } finally {
      if (mounted) {
        setState(() => _exportingReport = false);
      }
    }
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleInsightFilter(_OrdersInsightFilter value) {
    setState(() {
      if (_insightFilters.contains(value)) {
        _insightFilters.remove(value);
      } else {
        _insightFilters.add(value);
      }
    });
  }

  List<WorkOrderListItem> _visibleOrders() {
    if (_insightFilters.isEmpty) {
      return _orders;
    }
    return _orders
        .where(
          (WorkOrderListItem item) => _insightFilters.every(
            (_OrdersInsightFilter filter) =>
                _matchesInsightFilter(item, filter),
          ),
        )
        .toList(growable: false);
  }

  bool _matchesInsightFilter(
    WorkOrderListItem item,
    _OrdersInsightFilter filter,
  ) {
    switch (filter) {
      case _OrdersInsightFilter.withCustomer:
        return (item.customerName ?? '').trim().isNotEmpty;
      case _OrdersInsightFilter.withoutCustomer:
        return (item.customerName ?? '').trim().isEmpty;
      case _OrdersInsightFilter.withAssignments:
        return item.assignmentSummary.trim().toLowerCase() != 'sin asignar';
      case _OrdersInsightFilter.withoutAssignments:
        return item.assignmentSummary.trim().toLowerCase() == 'sin asignar';
      case _OrdersInsightFilter.paid:
        return item.paymentStatus == WorkOrderPaymentStatusCatalog.paid;
      case _OrdersInsightFilter.unpaid:
        return item.paymentStatus != WorkOrderPaymentStatusCatalog.paid;
      case _OrdersInsightFilter.dueIn3Days:
        return _isDueWithinDays(item.dueAt, 3);
      case _OrdersInsightFilter.dueIn7Days:
        return _isDueWithinDays(item.dueAt, 7);
      case _OrdersInsightFilter.dueIn15Days:
        return _isDueWithinDays(item.dueAt, 15);
      case _OrdersInsightFilter.dueToday:
        return _isDueWithinDays(item.dueAt, 0);
      case _OrdersInsightFilter.withMaterialUsage:
        return item.hasMaterialUsage;
    }
  }

  bool _isDueWithinDays(DateTime? dueAt, int maxDays) {
    if (dueAt == null) {
      return false;
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final int days = dueDate.difference(today).inDays;
    return days >= 0 && days <= maxDays;
  }

  String _insightFilterLabel(_OrdersInsightFilter filter) {
    switch (filter) {
      case _OrdersInsightFilter.withCustomer:
        return 'Con cliente';
      case _OrdersInsightFilter.withoutCustomer:
        return 'Sin cliente';
      case _OrdersInsightFilter.withAssignments:
        return 'Con responsables';
      case _OrdersInsightFilter.withoutAssignments:
        return 'Sin asignar';
      case _OrdersInsightFilter.paid:
        return 'Cobrados';
      case _OrdersInsightFilter.unpaid:
        return 'Pend. cobro';
      case _OrdersInsightFilter.dueIn3Days:
        return 'Vence en 3 días';
      case _OrdersInsightFilter.dueIn7Days:
        return 'Vence en 7 días';
      case _OrdersInsightFilter.dueIn15Days:
        return 'Vence en 15 días';
      case _OrdersInsightFilter.dueToday:
        return 'Vence hoy';
      case _OrdersInsightFilter.withMaterialUsage:
        return 'Con consumo de materiales';
    }
  }

  List<String> _insightFilterLabels() {
    return _insightFilters.map(_insightFilterLabel).toList(growable: false);
  }

  String _summaryRangeLabel() {
    if (_summaryDateFrom == null || _summaryDateTo == null) {
      return 'Todo el historial';
    }
    return '${_dateOnly(_summaryDateFrom!)} - ${_dateOnly(_summaryDateTo!)}';
  }

  String _dateCriterionLabel() {
    return WorkOrderDateFilterCriterion.label(_dateCriterion);
  }

  String _statusFilterLabel() {
    switch (_statusFilter) {
      case WorkOrderStatusCatalog.pending:
        return 'Pendiente';
      case WorkOrderStatusCatalog.inProgress:
        return 'En producción';
      case WorkOrderStatusCatalog.ready:
        return 'Pendiente a entregar';
      case WorkOrderStatusCatalog.delivered:
        return 'Finalizado';
      case WorkOrderStatusCatalog.cancelled:
        return 'Cancelado';
      case 'all':
      default:
        return 'Todos';
    }
  }

  String _dateOnly(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _openPanelOrdersByStatus({
    required String title,
    required String subtitle,
    required String status,
  }) async {
    final PedidosLocalDataSource ds = ref.read(pedidosLocalDataSourceProvider);
    final DateTime? createdFrom =
        _summaryDateFrom == null ? null : _startOfDay(_summaryDateFrom!);
    final DateTime? createdTo = _summaryDateTo == null
        ? null
        : _startOfDay(_summaryDateTo!).add(const Duration(days: 1));
    try {
      final List<WorkOrderListItem> orders = await ds.listOrders(
        searchQuery: '',
        statusFilter: status,
        createdFrom: createdFrom,
        createdTo: createdTo,
        dateCriterion: _dateCriterion,
      );
      if (!mounted) {
        return;
      }
      await _openPanelOrdersView(
        title: title,
        subtitle: subtitle,
        orders: orders,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudieron cargar los pedidos del panel: $error');
    }
  }

  Future<void> _openPanelOrdersByInsight({
    required String title,
    required String subtitle,
    required _OrdersInsightFilter filter,
  }) async {
    final PedidosLocalDataSource ds = ref.read(pedidosLocalDataSourceProvider);
    final DateTime? createdFrom =
        _summaryDateFrom == null ? null : _startOfDay(_summaryDateFrom!);
    final DateTime? createdTo = _summaryDateTo == null
        ? null
        : _startOfDay(_summaryDateTo!).add(const Duration(days: 1));
    try {
      final List<WorkOrderListItem> baseOrders = await ds.listOrders(
        searchQuery: '',
        statusFilter: 'all',
        createdFrom: createdFrom,
        createdTo: createdTo,
        dateCriterion: _dateCriterion,
      );
      final List<WorkOrderListItem> orders = baseOrders
          .where(
              (WorkOrderListItem item) => _matchesInsightFilter(item, filter))
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      await _openPanelOrdersView(
        title: title,
        subtitle: subtitle,
        orders: orders,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudieron cargar los pedidos del panel: $error');
    }
  }

  Future<void> _openPanelOrdersByEmployee(
    WorkOrderEmployeeSummary employee,
  ) async {
    final PedidosLocalDataSource ds = ref.read(pedidosLocalDataSourceProvider);
    final DateTime? createdFrom =
        _summaryDateFrom == null ? null : _startOfDay(_summaryDateFrom!);
    final DateTime? createdTo = _summaryDateTo == null
        ? null
        : _startOfDay(_summaryDateTo!).add(const Duration(days: 1));
    try {
      final List<WorkOrderDetail?> details =
          await Future.wait<WorkOrderDetail?>(
        (await ds.listOrders(
          searchQuery: '',
          statusFilter: 'all',
          createdFrom: createdFrom,
          createdTo: createdTo,
          dateCriterion: _dateCriterion,
        ))
            .map((WorkOrderListItem item) => ds.getOrderById(item.id)),
      );
      final Set<String> matchingIds = details
          .whereType<WorkOrderDetail>()
          .where(
            (WorkOrderDetail detail) => detail.assignments.any(
              (WorkOrderAssignmentItem assignment) =>
                  assignment.employeeId.trim() ==
                  (employee.employeeId ?? '').trim(),
            ),
          )
          .map((WorkOrderDetail detail) => detail.id)
          .toSet();
      final List<WorkOrderListItem> orders = (await ds.listOrders(
        searchQuery: '',
        statusFilter: 'all',
        createdFrom: createdFrom,
        createdTo: createdTo,
        dateCriterion: _dateCriterion,
      ))
          .where((WorkOrderListItem item) => matchingIds.contains(item.id))
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      await _openPanelOrdersView(
        title: 'Pedidos de ${employee.employeeName}',
        subtitle:
            'Pedidos asignados a ${employee.employeeName} dentro del rango seleccionado.',
        orders: orders,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudieron cargar los pedidos del empleado: $error');
    }
  }

  Future<void> _openPanelOrdersView({
    required String title,
    required String subtitle,
    required List<WorkOrderListItem> orders,
  }) async {
    final AppCurrencyConfig currencyConfig =
        ref.read(currentAppConfigProvider).currencyConfig;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _PanelOrdersResultsPage(
          title: title,
          subtitle: subtitle,
          orders: orders,
          currencyConfig: currencyConfig,
          paymentDisplayConfig: _paymentDisplayConfig,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? session = ref.watch(currentSessionProvider);
    final AppCurrencyConfig currencyConfig =
        ref.watch(currentAppConfigProvider).currencyConfig;
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.ordersManage) ?? false;
    final WorkOrderDashboardSummary summary = _summary ??
        const WorkOrderDashboardSummary(
          pendingCount: 0,
          inProgressCount: 0,
          readyCount: 0,
          dueTodayCount: 0,
          paidCount: 0,
          unpaidCount: 0,
          withCustomerCount: 0,
          withoutCustomerCount: 0,
          withAssignmentsCount: 0,
          withoutAssignmentsCount: 0,
          dueIn3DaysCount: 0,
          dueIn7DaysCount: 0,
          dueIn15DaysCount: 0,
          materialUsageEntriesCount: 0,
          topConsumedMaterials: <WorkOrderMaterialConsumptionSummary>[],
          byType: <WorkOrderTypeSummary>[],
          byEmployee: <WorkOrderEmployeeSummary>[],
        );
    final List<WorkOrderListItem> visibleOrders = _visibleOrders();
    final List<String> insightFilterLabels = _insightFilterLabels();

    return AppScaffold(
      title: 'Pedidos',
      currentRoute: '/pedidos',
      showTopTabs: false,
      showBottomNavigationBar: false,
      useDefaultActions: false,
      onRefresh: _load,
      floatingActionButton: canManage
          ? AppAddActionButton(
              heroTag: 'orders-add-fab',
              currentRoute: '/pedidos',
              onPressed: _openForm,
            )
          : null,
      body: _loading && _summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: <Widget>[
                  const Text(
                    'Pedidos de impresion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF11141A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Organiza trabajos, controla su estado y asigna la produccion del taller.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WorkOrdersDashboardPanel(
                    summary: summary,
                    rangeLabel: _summaryRangeLabel(),
                    criterionLabel: _dateCriterionLabel(),
                    hasActiveRange:
                        _summaryDateFrom != null && _summaryDateTo != null,
                    onPickRange: _pickSummaryDateRange,
                    onPickCriterion: _pickDateCriterion,
                    onClearRange: _clearSummaryDateRange,
                    onMenuActionSelected: _handlePanelMenuAction,
                    onTapPending: () => _openPanelOrdersByStatus(
                      title: 'Pedidos pendientes',
                      subtitle:
                          'Pedidos del panel en estado pendiente para el rango seleccionado.',
                      status: WorkOrderStatusCatalog.pending,
                    ),
                    onTapInProgress: () => _openPanelOrdersByStatus(
                      title: 'Pedidos en producción',
                      subtitle:
                          'Pedidos actualmente en producción dentro del rango seleccionado.',
                      status: WorkOrderStatusCatalog.inProgress,
                    ),
                    onTapReady: () => _openPanelOrdersByStatus(
                      title: 'Pedidos por entregar',
                      subtitle:
                          'Pedidos listos para entrega dentro del rango seleccionado.',
                      status: WorkOrderStatusCatalog.ready,
                    ),
                    onTapDueToday: () => _openPanelOrdersByInsight(
                      title: 'Pedidos que vencen hoy',
                      subtitle:
                          'Pedidos del panel con entrega programada para hoy.',
                      filter: _OrdersInsightFilter.dueToday,
                    ),
                    onTapMaterialUsage: () => _openPanelOrdersByInsight(
                      title: 'Pedidos con consumo',
                      subtitle:
                          'Pedidos del panel con materiales consumidos en el rango actual.',
                      filter: _OrdersInsightFilter.withMaterialUsage,
                    ),
                    onTapPaid: () => _openPanelOrdersByInsight(
                      title: 'Pedidos cobrados',
                      subtitle:
                          'Pedidos del panel que ya fueron cobrados al cliente.',
                      filter: _OrdersInsightFilter.paid,
                    ),
                    onTapUnpaid: () => _openPanelOrdersByInsight(
                      title: 'Pedidos pendientes de cobro',
                      subtitle:
                          'Pedidos del panel que aun siguen pendientes de cobro.',
                      filter: _OrdersInsightFilter.unpaid,
                    ),
                    menuBusy: _exportingReport,
                  ),
                  const SizedBox(height: 18),
                  _SearchField(controller: _searchCtrl),
                  const SizedBox(height: 14),
                  WorkOrdersStatusTabs(
                    currentFilter: _statusFilter,
                    onChanged: (String value) {
                      if (_statusFilter == value) {
                        return;
                      }
                      setState(() => _statusFilter = value);
                      _load();
                    },
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Relacion con clientes'),
                  const SizedBox(height: 10),
                  WorkOrdersInsightGrid(
                    columns: 2,
                    children: <Widget>[
                      WorkOrdersBreakdownCard(
                        title: 'Con cliente',
                        value: summary.withCustomerCount.toString(),
                        subtitle: 'Pedidos asociados a un cliente.',
                        isSelected: _insightFilters
                            .contains(_OrdersInsightFilter.withCustomer),
                        onTap: () => _toggleInsightFilter(
                            _OrdersInsightFilter.withCustomer),
                      ),
                      WorkOrdersBreakdownCard(
                        title: 'Sin cliente',
                        value: summary.withoutCustomerCount.toString(),
                        subtitle: 'Pedidos pendientes de asociar.',
                        isSelected: _insightFilters.contains(
                          _OrdersInsightFilter.withoutCustomer,
                        ),
                        onTap: () => _toggleInsightFilter(
                          _OrdersInsightFilter.withoutCustomer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Asignacion operativa'),
                  const SizedBox(height: 10),
                  WorkOrdersInsightGrid(
                    columns: 2,
                    children: <Widget>[
                      WorkOrdersBreakdownCard(
                        title: 'Con responsables',
                        value: summary.withAssignmentsCount.toString(),
                        subtitle: 'Pedidos ya repartidos en el taller.',
                        isSelected: _insightFilters.contains(
                          _OrdersInsightFilter.withAssignments,
                        ),
                        onTap: () => _toggleInsightFilter(
                          _OrdersInsightFilter.withAssignments,
                        ),
                      ),
                      WorkOrdersBreakdownCard(
                        title: 'Sin asignar',
                        value: summary.withoutAssignmentsCount.toString(),
                        subtitle: 'Pedidos sin equipo definido.',
                        isSelected: _insightFilters.contains(
                          _OrdersInsightFilter.withoutAssignments,
                        ),
                        onTap: () => _toggleInsightFilter(
                          _OrdersInsightFilter.withoutAssignments,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Proximos vencimientos'),
                  const SizedBox(height: 10),
                  WorkOrdersInsightGrid(
                    columns: 3,
                    children: <Widget>[
                      WorkOrdersBreakdownCard(
                        title: '3 dias',
                        value: summary.dueIn3DaysCount.toString(),
                        subtitle: 'Requieren atencion inmediata.',
                        isSelected: _insightFilters
                            .contains(_OrdersInsightFilter.dueIn3Days),
                        onTap: () => _toggleInsightFilter(
                            _OrdersInsightFilter.dueIn3Days),
                      ),
                      WorkOrdersBreakdownCard(
                        title: '7 dias',
                        value: summary.dueIn7DaysCount.toString(),
                        subtitle: 'Semana actual de entrega.',
                        isSelected: _insightFilters
                            .contains(_OrdersInsightFilter.dueIn7Days),
                        onTap: () => _toggleInsightFilter(
                            _OrdersInsightFilter.dueIn7Days),
                      ),
                      WorkOrdersBreakdownCard(
                        title: '15 dias',
                        value: summary.dueIn15DaysCount.toString(),
                        subtitle: 'Ventana de referencia activa.',
                        isSelected: _insightFilters
                            .contains(_OrdersInsightFilter.dueIn15Days),
                        onTap: () => _toggleInsightFilter(
                          _OrdersInsightFilter.dueIn15Days,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Estado de cobro'),
                  const SizedBox(height: 10),
                  WorkOrdersInsightGrid(
                    columns: 2,
                    children: <Widget>[
                      WorkOrdersBreakdownCard(
                        title: 'Cobrados',
                        value: summary.paidCount.toString(),
                        subtitle: 'Pedidos ya cobrados al cliente.',
                        isSelected:
                            _insightFilters.contains(_OrdersInsightFilter.paid),
                        onTap: () =>
                            _toggleInsightFilter(_OrdersInsightFilter.paid),
                      ),
                      WorkOrdersBreakdownCard(
                        title: 'Pend. cobro',
                        value: summary.unpaidCount.toString(),
                        subtitle: 'Pedidos aun pendientes de cobro.',
                        isSelected: _insightFilters
                            .contains(_OrdersInsightFilter.unpaid),
                        onTap: () =>
                            _toggleInsightFilter(_OrdersInsightFilter.unpaid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Asignacion por empleado'),
                  const SizedBox(height: 10),
                  if (summary.byEmployee.isEmpty)
                    const _EmptyPanel(
                      message: 'No hay empleados asignados en este momento.',
                    )
                  else
                    ...summary.byEmployee.map((WorkOrderEmployeeSummary row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: WorkOrdersBreakdownCard(
                          title: row.employeeName,
                          value: row.total.toString(),
                          subtitle:
                              'Pend: ${row.pending} · Prod: ${row.inProgress} · Entrega: ${row.ready}',
                          onTap: row.employeeId == null ||
                                  row.employeeId!.trim().isEmpty
                              ? null
                              : () => _openPanelOrdersByEmployee(row),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _SectionTitle(
                          title: insightFilterLabels.isEmpty
                              ? 'Listado de pedidos'
                              : 'Listado de pedidos · ${insightFilterLabels.join(' + ')}',
                        ),
                      ),
                      if (_loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  if (insightFilterLabels.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.filter_alt_off_rounded,
                          size: 18,
                          color: Color(0xFF1152D4),
                        ),
                        label: Text(
                          'Limpiar filtros: ${insightFilterLabels.join(' + ')}',
                        ),
                        labelStyle: const TextStyle(
                          color: Color(0xFF1152D4),
                          fontWeight: FontWeight.w700,
                        ),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        backgroundColor: const Color(0xFFEFF6FF),
                        onPressed: () {
                          setState(() {
                            _insightFilters.clear();
                          });
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (visibleOrders.isEmpty)
                    const _EmptyPanel(
                      message:
                          'No hay pedidos para mostrar con los filtros actuales.',
                    )
                  else
                    ...visibleOrders.map((WorkOrderListItem item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WorkOrderListCard(
                          item: item,
                          currencyConfig: currencyConfig,
                          paymentDisplayConfig: _paymentDisplayConfig,
                          onTap: () => _openDetail(item.id),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

enum _OrdersInsightFilter {
  withCustomer,
  withoutCustomer,
  withAssignments,
  withoutAssignments,
  paid,
  unpaid,
  dueIn3Days,
  dueIn7Days,
  dueIn15Days,
  dueToday,
  withMaterialUsage,
}

class _PanelOrdersResultsPage extends StatelessWidget {
  const _PanelOrdersResultsPage({
    required this.title,
    required this.subtitle,
    required this.orders,
    required this.currencyConfig,
    required this.paymentDisplayConfig,
  });

  final String title;
  final String subtitle;
  final List<WorkOrderListItem> orders;
  final AppCurrencyConfig currencyConfig;
  final WorkOrderPaymentDisplayConfig paymentDisplayConfig;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      currentRoute: '/pedidos-panel-resultados',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        tooltip: 'Atras',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              '${orders.length} pedido${orders.length == 1 ? '' : 's'} encontrado${orders.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Color(0xFF1152D4),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const _EmptyPanel(
              message: 'No hay pedidos para mostrar en esta vista.',
            )
          else
            ...orders.map(
              (WorkOrderListItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WorkOrderListCard(
                  item: item,
                  currencyConfig: currencyConfig,
                  paymentDisplayConfig: paymentDisplayConfig,
                  onTap: () {
                    Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => PedidoDetailPage(orderId: item.id),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Buscar por folio, cliente, empleado o tipo...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1152D4)),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
