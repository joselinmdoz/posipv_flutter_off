import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../clientes/presentation/widgets/client_avatar.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../tpv/presentation/widgets/tpv_employee_avatar.dart';
import '../data/pedidos_local_datasource.dart';
import 'pedido_form_page.dart';
import 'pedido_task_form_page.dart';
import 'pedidos_providers.dart';
import 'widgets/work_order_payment_variants.dart';
import 'widgets/work_order_payment_management_page.dart';
import 'widgets/work_order_priority_badge.dart';
import 'widgets/work_order_status_badge.dart';
import 'widgets/work_order_task_card.dart';

class PedidoDetailPage extends ConsumerStatefulWidget {
  const PedidoDetailPage({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  ConsumerState<PedidoDetailPage> createState() => _PedidoDetailPageState();
}

class _PedidoDetailPageState extends ConsumerState<PedidoDetailPage> {
  WorkOrderDetail? _detail;
  WorkOrderPaymentDisplayConfig _paymentDisplayConfig =
      WorkOrderPaymentDisplayConfig.defaults;
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;

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
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      final ConfiguracionLocalDataSource configDs =
          ref.read(configuracionLocalDataSourceProvider);
      final List<dynamic> payload =
          await Future.wait<dynamic>(<Future<dynamic>>[
        ds.getOrderById(widget.orderId),
        configDs.loadWorkOrderPaymentDisplayConfig(),
      ]);
      final WorkOrderDetail? detail = payload[0] as WorkOrderDetail?;
      final WorkOrderPaymentDisplayConfig paymentConfig =
          payload[1] as WorkOrderPaymentDisplayConfig;
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _paymentDisplayConfig = paymentConfig;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar el pedido: $error');
    }
  }

  Future<void> _openEdit() async {
    final WorkOrderDetail? detail = _detail;
    if (detail?.status == WorkOrderStatusCatalog.cancelled) {
      _show('Los pedidos cancelados no se pueden editar.');
      return;
    }
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PedidoFormPage(orderId: widget.orderId),
      ),
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _openAddTask() async {
    final WorkOrderDetail? detail = _detail;
    final session = ref.read(currentSessionProvider);
    if (session == null || _saving || detail == null) {
      return;
    }
    if (detail.status != WorkOrderStatusCatalog.inProgress) {
      _show(
        'Debes iniciar la producción para poder registrar trabajos realizados.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      final List<dynamic> bootstrap =
          await Future.wait<dynamic>(<Future<dynamic>>[
        ds.listProductOptions(),
        ds.listEmployeeOptions(),
        ds.listActiveTaskTypeOptions(),
        ds.listActiveTaskWorkerRoleOptions(),
      ]);
      if (!mounted) {
        return;
      }
      final WorkOrderTaskCreateInput? input =
          await Navigator.of(context).push<WorkOrderTaskCreateInput>(
        MaterialPageRoute<WorkOrderTaskCreateInput>(
          builder: (_) => PedidoTaskFormPage(
            productOptions: bootstrap[0] as List<WorkOrderProductOption>,
            employeeOptions: bootstrap[1] as List<WorkOrderEmployeeOption>,
            taskTypeOptions: bootstrap[2] as List<String>,
            taskWorkerRoleOptions: bootstrap[3] as List<String>,
          ),
        ),
      );
      if (input == null || !mounted) {
        return;
      }
      await ds.addTaskToOrder(
        orderId: widget.orderId,
        input: input,
        userId: session.userId,
      );
      _changed = true;
      await _load();
      _show('Trabajo agregado al pedido.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo registrar el trabajo: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _changeStatus(String status) async {
    final session = ref.read(currentSessionProvider);
    final WorkOrderDetail? detail = _detail;
    if (session == null ||
        detail == null ||
        _saving ||
        detail.status == status) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(pedidosLocalDataSourceProvider).updateOrderStatus(
            orderId: detail.id,
            status: status,
            userId: session.userId,
          );
      _changed = true;
      await _load();
      _show('Estado actualizado.');
    } catch (error) {
      _show('No se pudo actualizar el estado: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  WorkOrderPricingSnapshot _fallbackPricingSnapshot(
    AppCurrencyConfig currencyConfig,
  ) {
    return WorkOrderPricingSnapshot(
      capturedAt: DateTime.now(),
      primaryCurrencyCode: currencyConfig.primaryCurrencyCode,
      localCurrencyCode: _paymentDisplayConfig.localCurrencyCode,
      foreignCurrencyCode: _paymentDisplayConfig.foreignCurrencyCode,
      localCashFixedSurcharge: _paymentDisplayConfig.localCashFixedSurcharge,
      localTransferPercentSurcharge:
          _paymentDisplayConfig.localTransferPercentSurcharge,
      ratesByCode: <String, double>{
        for (final AppCurrencySetting row in currencyConfig.currencies)
          row.code.trim().toUpperCase(): row.rateToPrimary,
      },
    );
  }

  Future<void> _openPaymentManagement() async {
    final WorkOrderDetail? detail = _detail;
    final session = ref.read(currentSessionProvider);
    if (detail == null || session == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ConfiguracionLocalDataSource configDs =
          ref.read(configuracionLocalDataSourceProvider);
      final AppCurrencyConfig currencyConfig =
          ref.read(currentAppConfigProvider).currencyConfig;
      final List<AppPaymentMethodSetting> paymentMethods =
          await configDs.loadPaymentMethodSettings();
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      final WorkOrderPaymentUpdateInput? input =
          await Navigator.of(context).push<WorkOrderPaymentUpdateInput>(
        MaterialPageRoute<WorkOrderPaymentUpdateInput>(
          builder: (_) => WorkOrderPaymentManagementPage(
            orderFolio: detail.folio,
            orderTotals: detail.totalCosts,
            initialPricingSnapshot: detail.pricingSnapshot ??
                _fallbackPricingSnapshot(currencyConfig),
            initialPaymentLines: detail.paymentLines,
            currencyConfig: currencyConfig,
            paymentMethods: paymentMethods,
          ),
        ),
      );
      if (input == null || !mounted) {
        return;
      }
      setState(() => _saving = true);
      await ref.read(pedidosLocalDataSourceProvider).updateOrderPaymentDetails(
            orderId: detail.id,
            input: input,
            userId: session.userId,
          );
      _changed = true;
      await _load();
      _show('Pagos y cotización del pedido actualizados.');
    } catch (error) {
      if (mounted) {
        _show('No se pudo actualizar el cobro del pedido: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _cancelOrder() async {
    final WorkOrderDetail? detail = _detail;
    final session = ref.read(currentSessionProvider);
    if (detail == null || session == null || _saving) {
      return;
    }
    if (detail.status == WorkOrderStatusCatalog.cancelled) {
      _show('El pedido ya está cancelado.');
      return;
    }
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Cancelar pedido'),
            content: Text(
              'El pedido ${detail.folio} pasará a estado cancelado y dejará de estar operativo. Esta acción conservará el historial del pedido.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Volver'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancelar pedido'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    await _changeStatus(WorkOrderStatusCatalog.cancelled);
    if (mounted) {
      _show('Pedido cancelado.');
    }
  }

  Future<void> _deleteOrder() async {
    final WorkOrderDetail? detail = _detail;
    final session = ref.read(currentSessionProvider);
    if (detail == null || session == null || _saving) {
      return;
    }
    if (!session.isAdmin) {
      _show('Solo el administrador puede eliminar pedidos.');
      return;
    }
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Eliminar pedido'),
            content: Text(
              'Se eliminará definitivamente el pedido ${detail.folio} junto con sus trabajos realizados y evidencias asociadas. Esta acción no se puede deshacer.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Volver'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(pedidosLocalDataSourceProvider).deleteOrder(
            orderId: detail.id,
            userId: session.userId,
          );
      _changed = true;
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo eliminar el pedido: $error');
      setState(() => _saving = false);
    }
  }

  Future<void> _openEditTask(WorkOrderTaskItem task) async {
    final session = ref.read(currentSessionProvider);
    final WorkOrderDetail? detail = _detail;
    if (session == null || detail == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      final List<dynamic> bootstrap =
          await Future.wait<dynamic>(<Future<dynamic>>[
        ds.listProductOptions(),
        ds.listEmployeeOptions(),
        ds.listActiveTaskTypeOptions(),
        ds.listActiveTaskWorkerRoleOptions(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      final WorkOrderTaskCreateInput? input =
          await Navigator.of(context).push<WorkOrderTaskCreateInput>(
        MaterialPageRoute<WorkOrderTaskCreateInput>(
          builder: (_) => PedidoTaskFormPage(
            productOptions: bootstrap[0] as List<WorkOrderProductOption>,
            employeeOptions: bootstrap[1] as List<WorkOrderEmployeeOption>,
            taskTypeOptions: bootstrap[2] as List<String>,
            taskWorkerRoleOptions: bootstrap[3] as List<String>,
            initialTask: task,
          ),
        ),
      );
      if (input == null || !mounted) {
        return;
      }
      setState(() => _saving = true);
      await ds.updateTaskInOrder(
        orderId: detail.id,
        taskId: task.id,
        input: input,
        userId: session.userId,
      );
      _changed = true;
      await _load();
      _show('Trabajo actualizado.');
    } catch (error) {
      if (mounted) {
        _show('No se pudo actualizar el trabajo: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool _canGenerateDeliveryCertificate(String status) {
    return status == WorkOrderStatusCatalog.ready ||
        status == WorkOrderStatusCatalog.delivered;
  }

  Future<void> _exportDeliveryCertificate({required bool shareFile}) async {
    final WorkOrderDetail? detail = _detail;
    if (detail == null || _saving) {
      return;
    }
    if (!_canGenerateDeliveryCertificate(detail.status)) {
      _show(
        'El acta de entrega se habilita cuando el pedido está pendiente a entregar o finalizado.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final String path = await ref
          .read(workOrderDeliveryReportServiceProvider)
          .exportDeliveryCertificatePdf(detail: detail);
      if (!mounted) {
        return;
      }
      if (shareFile) {
        await Share.shareXFiles(
          <XFile>[XFile(path)],
          text: 'Acta de entrega ${detail.folio}',
          subject: 'Acta de entrega ${detail.folio}',
        );
      }
      _show(
        shareFile
            ? 'Acta lista para compartir o imprimir.'
            : 'Acta guardada en: $path',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo generar el acta de entrega: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteTask(WorkOrderTaskItem task) async {
    final session = ref.read(currentSessionProvider);
    final WorkOrderDetail? detail = _detail;
    if (session == null || detail == null || _saving) {
      return;
    }
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Eliminar trabajo realizado'),
            content: Text(
              'Se eliminará el trabajo "${task.title}" del pedido. Esta acción no se puede deshacer.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(pedidosLocalDataSourceProvider).deleteTaskFromOrder(
            orderId: detail.id,
            taskId: task.id,
            userId: session.userId,
          );
      _changed = true;
      await _load();
      _show('Trabajo eliminado.');
    } catch (error) {
      _show('No se pudo eliminar el trabajo: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _deleteTaskImage({
    required WorkOrderTaskItem task,
    required List<String> imagePaths,
  }) async {
    final WorkOrderDetail? detail = _detail;
    final session = ref.read(currentSessionProvider);
    if (detail == null || session == null || _saving) {
      return false;
    }
    setState(() => _saving = true);
    try {
      await ref.read(pedidosLocalDataSourceProvider).updateTaskImages(
            orderId: detail.id,
            taskId: task.id,
            imagePaths: imagePaths,
            userId: session.userId,
          );
      _changed = true;
      await _load();
      return true;
    } catch (error) {
      _show('No se pudo eliminar la imagen: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _reorderTaskImages({
    required WorkOrderTaskItem task,
    required List<String> imagePaths,
  }) async {
    final WorkOrderDetail? detail = _detail;
    final session = ref.read(currentSessionProvider);
    if (detail == null || session == null || _saving) {
      return false;
    }
    setState(() => _saving = true);
    try {
      await ref.read(pedidosLocalDataSourceProvider).updateTaskImages(
            orderId: detail.id,
            taskId: task.id,
            imagePaths: imagePaths,
            userId: session.userId,
          );
      _changed = true;
      await _load();
      _show('Orden de imágenes actualizado.');
      return true;
    } catch (error) {
      _show('No se pudo actualizar el orden: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
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

  void _close() {
    Navigator.of(context).pop(_changed);
  }

  Future<void> _openHistory() async {
    final WorkOrderDetail? detail = _detail;
    if (detail == null) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PedidoStatusHistoryPage(
          orderId: detail.id,
          orderFolio: detail.folio,
          dateTimeFormatter: _dateTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final AppCurrencyConfig currencyConfig =
        ref.watch(currentAppConfigProvider).currencyConfig;
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.ordersManage) ?? false;
    final bool canDelete = session?.isAdmin ?? false;
    final WorkOrderDetail? detail = _detail;
    final WorkOrderProductItem? firstItem =
        detail == null || detail.items.isEmpty ? null : detail.items.first;
    final List<WorkOrderPaymentValue> paymentVariants = detail == null
        ? const <WorkOrderPaymentValue>[]
        : detail.paymentValues.isEmpty
            ? buildWorkOrderPaymentVariants(
                totals: detail.totalCosts,
                currencyConfig: currencyConfig,
                paymentDisplayConfig: _paymentDisplayConfig,
              )
            : detail.paymentValues;

    return AppScaffold(
      title: 'Detalle de Pedido',
      currentRoute: '/pedidos',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      useDefaultActions: false,
      onRefresh: _load,
      appBarLeading: IconButton(
        onPressed: _close,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        if (canManage)
          TextButton.icon(
            onPressed:
                _loading || detail?.status == WorkOrderStatusCatalog.cancelled
                    ? null
                    : _openEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        if (detail != null)
          PopupMenuButton<_OrderAction>(
            onSelected: (_OrderAction action) {
              switch (action) {
                case _OrderAction.history:
                  _openHistory();
                  break;
                case _OrderAction.cancel:
                  _cancelOrder();
                  break;
                case _OrderAction.delete:
                  _deleteOrder();
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_OrderAction>>[
              const PopupMenuItem<_OrderAction>(
                value: _OrderAction.history,
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.history_rounded,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 10),
                    Text('Ver historial'),
                  ],
                ),
              ),
              if (canManage &&
                  detail.status != WorkOrderStatusCatalog.cancelled &&
                  detail.status != WorkOrderStatusCatalog.delivered)
                const PopupMenuItem<_OrderAction>(
                  value: _OrderAction.cancel,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.cancel_outlined,
                        color: Color(0xFFB91C1C),
                      ),
                      SizedBox(width: 10),
                      Text('Cancelar pedido'),
                    ],
                  ),
                ),
              if (canDelete)
                const PopupMenuItem<_OrderAction>(
                  value: _OrderAction.delete,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFB91C1C),
                      ),
                      SizedBox(width: 10),
                      Text('Eliminar pedido'),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(width: 8),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(child: Text('No se encontro el pedido.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: <Widget>[
                    if (_saving) const LinearProgressIndicator(minHeight: 3),
                    _OrderDetailHeroCard(
                      detail: detail,
                      firstItemName: firstItem?.productName,
                    ),
                    const SizedBox(height: 16),
                    if (canManage) ...<Widget>[
                      _ProcessActionPanel(
                        status: detail.status,
                        busy: _saving,
                        onAdvance: () => _changeStatus(
                          _nextStatus(detail.status),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (detail.status ==
                        WorkOrderStatusCatalog.cancelled) ...<Widget>[
                      const _TextPanel(
                        text:
                            'Este pedido está cancelado y quedó bloqueado para edición o cambios operativos.',
                      ),
                      const SizedBox(height: 18),
                    ],
                    _CommercialStatusPanel(
                      paymentStatus: detail.paymentStatus,
                      paidAt: detail.paidAt,
                      deliveredAt: detail.deliveredAt,
                      pricingSnapshot: detail.pricingSnapshot,
                      busy: _saving,
                      onManagePayment:
                          canManage ? _openPaymentManagement : null,
                    ),
                    const SizedBox(height: 18),
                    if (detail.paymentLines.isNotEmpty) ...<Widget>[
                      const _BlockTitle('Pagos registrados'),
                      const SizedBox(height: 10),
                      ...detail.paymentLines.map(
                        (WorkOrderRecordedPaymentLine line) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PaymentLineCard(
                            line: line,
                            formatMoney: _formatCents,
                            formatDateTime: _dateTime,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_canGenerateDeliveryCertificate(
                        detail.status)) ...<Widget>[
                      _DeliveryCertificatePanel(
                        busy: _saving,
                        onPrint: () =>
                            _exportDeliveryCertificate(shareFile: true),
                        onSavePdf: () =>
                            _exportDeliveryCertificate(shareFile: false),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const _BlockTitle('Cliente'),
                    const SizedBox(height: 10),
                    _ContactCard(
                      title: detail.customerName ?? 'Sin cliente asignado',
                      subtitle: [
                        if ((detail.customerCode ?? '').trim().isNotEmpty)
                          detail.customerCode!,
                        if ((detail.customerPhone ?? '').trim().isNotEmpty)
                          detail.customerPhone!,
                        if ((detail.customerEmail ?? '').trim().isNotEmpty)
                          detail.customerEmail!,
                      ].join(' · '),
                      leading: ClientAvatar(
                        name: detail.customerName ?? 'Cliente',
                        imagePath: null,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _BlockTitle('Productos solicitados'),
                    const SizedBox(height: 10),
                    ...detail.items.map(
                      (WorkOrderProductItem item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ListCard(
                          title: item.productName,
                          subtitle:
                              '${_qty(item.qty)} ${item.unitLabel} · ${item.productSku}',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _BlockTitle('Responsables asignados'),
                    const SizedBox(height: 10),
                    ...detail.assignments.map(
                      (WorkOrderAssignmentItem item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: <Widget>[
                              TpvEmployeeAvatar(
                                imagePath: item.employeeImagePath,
                                radius: 24,
                                backgroundColor: const Color(0xFFE2E8F0),
                                iconColor: const Color(0xFF475569),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.employeeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.roleName} · ${item.employeeCode}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: _BlockTitle('Trabajos realizados'),
                        ),
                        if (canManage)
                          FilledButton.icon(
                            onPressed: _saving ||
                                    detail.status !=
                                        WorkOrderStatusCatalog.inProgress
                                ? null
                                : _openAddTask,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Agregar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (canManage &&
                        detail.status !=
                            WorkOrderStatusCatalog.inProgress) ...<Widget>[
                      const _TextPanel(
                        text:
                            'Los trabajos realizados se habilitan cuando el pedido entra en producción.',
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (detail.tasks.isEmpty)
                      const _TextPanel(
                        text:
                            'Aun no se han registrado trabajos realizados para este pedido.',
                      )
                    else
                      ...detail.tasks.reversed.map(
                        (WorkOrderTaskItem task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WorkOrderTaskCard(
                            task: task,
                            canManageImages: canManage,
                            onEdit:
                                canManage ? () => _openEditTask(task) : null,
                            onDelete:
                                canManage ? () => _deleteTask(task) : null,
                            onDeleteImage: canManage
                                ? (List<String> imagePaths) => _deleteTaskImage(
                                      task: task,
                                      imagePaths: imagePaths,
                                    )
                                : null,
                            onReorderImages: canManage
                                ? (List<String> imagePaths) =>
                                    _reorderTaskImages(
                                      task: task,
                                      imagePaths: imagePaths,
                                    )
                                : null,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    const _BlockTitle('Valor del pedido'),
                    const SizedBox(height: 10),
                    if (detail.requestedCostLines.isEmpty)
                      const _TextPanel(
                        text:
                            'Aun no hay productos solicitados para calcular el valor del pedido.',
                      )
                    else ...<Widget>[
                      _InfoCard(
                        children: paymentVariants.isEmpty
                            ? detail.totalCosts
                                .map(
                                  (WorkOrderCostTotal row) => _InfoRow(
                                    label: row.currencyCode,
                                    value: _formatCents(
                                      row.totalCostCents,
                                      row.currencyCode,
                                    ),
                                  ),
                                )
                                .toList(growable: false)
                            : paymentVariants
                                .map(
                                  (WorkOrderPaymentValue row) => _InfoRow(
                                    label: row.label,
                                    value: _formatCents(
                                      row.amountCents,
                                      row.currencyCode,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                      ),
                      const SizedBox(height: 10),
                      ...detail.requestedCostLines.map(
                        (WorkOrderRequestedCostLine row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RequestedCostCard(
                            line: row,
                            formatMoney: _formatCents,
                            formatQty: _qty,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _BlockTitle('Costos de materiales y merma'),
                    const SizedBox(height: 10),
                    if (detail.materialCostLines.isEmpty)
                      const _TextPanel(
                        text:
                            'Aun no hay materiales consumidos para calcular los costos productivos de este pedido.',
                      )
                    else ...<Widget>[
                      _InfoCard(
                        children: detail.materialTotalCosts
                            .map(
                              (WorkOrderCostTotal row) => _InfoRow(
                                label: row.currencyCode,
                                value: _formatCents(
                                  row.totalCostCents,
                                  row.currencyCode,
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 10),
                      ...detail.materialCostLines.map(
                        (WorkOrderMaterialCostLine row) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MaterialCostCard(
                            line: row,
                            formatMoney: _formatCents,
                            formatQty: _qty,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _BlockTitle('Planificacion'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: <Widget>[
                        _InfoRow(
                          label: 'Creado',
                          value: _dateTime(detail.createdAt),
                        ),
                        _InfoRow(
                          label: 'Entrega',
                          value: detail.dueAt == null
                              ? 'Sin fecha'
                              : _dateTime(detail.dueAt!),
                        ),
                        _InfoRow(
                          label: 'Producción terminada',
                          value: detail.completedAt == null
                              ? 'Aun no'
                              : _dateTime(detail.completedAt!),
                        ),
                        _InfoRow(
                          label: 'Cobrado',
                          value: detail.paidAt == null
                              ? 'Aun no'
                              : _dateTime(detail.paidAt!),
                        ),
                        _InfoRow(
                          label: 'Finalizado',
                          value: detail.deliveredAt == null
                              ? 'Aun no'
                              : _dateTime(detail.deliveredAt!),
                        ),
                        _InfoRow(
                          label: 'Creado por',
                          value: detail.createdByUsername,
                        ),
                        _InfoRow(
                          label: 'Ultima edicion',
                          value: detail.updatedAt == null
                              ? 'Sin cambios'
                              : '${detail.updatedByUsername ?? 'Usuario'} · ${_dateTime(detail.updatedAt!)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if ((detail.description ?? '')
                        .trim()
                        .isNotEmpty) ...<Widget>[
                      const _BlockTitle('Descripcion del trabajo'),
                      const SizedBox(height: 10),
                      _TextPanel(text: detail.description!),
                      const SizedBox(height: 18),
                    ],
                    if ((detail.note ?? '').trim().isNotEmpty) ...<Widget>[
                      const _BlockTitle('Observaciones'),
                      const SizedBox(height: 10),
                      _TextPanel(text: detail.note!),
                    ],
                  ],
                ),
    );
  }

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatCents(int cents, String currencyCode) {
    final String symbol = _symbolFor(currencyCode);
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _symbolFor(String currencyCode) {
    switch (currencyCode.trim().toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'CUP':
        return '₱';
      default:
        return '${currencyCode.trim().toUpperCase()} ';
    }
  }

  String _dateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  String _nextStatus(String currentStatus) {
    switch (currentStatus) {
      case WorkOrderStatusCatalog.pending:
        return WorkOrderStatusCatalog.inProgress;
      case WorkOrderStatusCatalog.inProgress:
        return WorkOrderStatusCatalog.ready;
      case WorkOrderStatusCatalog.ready:
        return WorkOrderStatusCatalog.delivered;
      default:
        return currentStatus;
    }
  }
}

class PedidoStatusHistoryPage extends ConsumerStatefulWidget {
  const PedidoStatusHistoryPage({
    super.key,
    required this.orderId,
    required this.orderFolio,
    required this.dateTimeFormatter,
  });

  final String orderId;
  final String orderFolio;
  final String Function(DateTime value) dateTimeFormatter;

  @override
  ConsumerState<PedidoStatusHistoryPage> createState() =>
      _PedidoStatusHistoryPageState();
}

class _PedidoStatusHistoryPageState
    extends ConsumerState<PedidoStatusHistoryPage> {
  List<WorkOrderStatusHistoryEntry> _history = <WorkOrderStatusHistoryEntry>[];
  bool _loading = true;

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
    setState(() => _loading = true);
    try {
      final List<WorkOrderStatusHistoryEntry> history = await ref
          .read(pedidosLocalDataSourceProvider)
          .getOrderStatusHistory(widget.orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('No se pudo cargar el historial: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Historial del pedido',
      currentRoute: '/pedidos',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      useDefaultActions: false,
      onRefresh: _load,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Seguimiento del estado',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pedido ${widget.orderFolio}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_history.isEmpty)
                  const _TextPanel(
                    text:
                        'Aun no hay cambios registrados en el estado de este pedido.',
                  )
                else
                  ..._history.map(
                    (WorkOrderStatusHistoryEntry entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StatusHistoryCard(
                        entry: entry,
                        dateTimeFormatter: widget.dateTimeFormatter,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ProcessActionPanel extends StatelessWidget {
  const _ProcessActionPanel({
    required this.status,
    required this.busy,
    required this.onAdvance,
  });

  final String status;
  final bool busy;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final _ProcessActionConfig? config = _configFor(status);
    if (config == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  config.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: busy ? null : onAdvance,
            icon: Icon(config.icon),
            label: Text(config.buttonLabel),
          ),
        ],
      ),
    );
  }

  _ProcessActionConfig? _configFor(String status) {
    switch (status) {
      case WorkOrderStatusCatalog.pending:
        return const _ProcessActionConfig(
          title: 'Producción pendiente',
          subtitle:
              'Cuando el taller comience a trabajar este pedido, inicia la producción.',
          buttonLabel: 'Producir',
          icon: Icons.play_arrow_rounded,
        );
      case WorkOrderStatusCatalog.inProgress:
        return const _ProcessActionConfig(
          title: 'Pedido en producción',
          subtitle:
              'Registra los trabajos realizados y, cuando terminen, marca la producción como finalizada.',
          buttonLabel: 'Finalizar producción',
          icon: Icons.task_alt_rounded,
        );
      case WorkOrderStatusCatalog.ready:
        return const _ProcessActionConfig(
          title: 'Pendiente a entregar',
          subtitle:
              'El pedido ya está listo. Cuando lo entregues al cliente, finalízalo.',
          buttonLabel: 'Finalizar',
          icon: Icons.check_circle_outline_rounded,
        );
      default:
        return null;
    }
  }
}

class _ProcessActionConfig {
  const _ProcessActionConfig({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
}

class _CommercialStatusPanel extends StatelessWidget {
  const _CommercialStatusPanel({
    required this.paymentStatus,
    required this.paidAt,
    required this.deliveredAt,
    required this.pricingSnapshot,
    required this.busy,
    this.onManagePayment,
  });

  final String paymentStatus;
  final DateTime? paidAt;
  final DateTime? deliveredAt;
  final WorkOrderPricingSnapshot? pricingSnapshot;
  final bool busy;
  final VoidCallback? onManagePayment;

  @override
  Widget build(BuildContext context) {
    final bool isPaid = paymentStatus == WorkOrderPaymentStatusCatalog.paid;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaid ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Cobro y cotización',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _PaymentStatusBadge(status: paymentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPaid
                ? 'Este pedido ya quedó marcado como cobrado. La entrega puede ocurrir antes o después de ese cobro.'
                : 'Este pedido sigue pendiente de cobro. Puede entregarse aunque aún no se haya cobrado, o cobrarse antes de la entrega.',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetaTag(
                icon: Icons.payments_outlined,
                label: paidAt == null
                    ? 'Cobro: pendiente'
                    : 'Cobrado: ${_fmtDate(paidAt!)}',
              ),
              _MetaTag(
                icon: Icons.currency_exchange_rounded,
                label: pricingSnapshot == null
                    ? 'Cotización dinámica'
                    : 'Tasa fijada: ${_fmtDate(pricingSnapshot!.capturedAt)}',
              ),
              if (deliveredAt != null)
                _MetaTag(
                  icon: Icons.local_shipping_outlined,
                  label: 'Entregado: ${_fmtDate(deliveredAt!)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed:
                  busy || onManagePayment == null ? null : onManagePayment,
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Pagos y cotización'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }
}

class _PaymentLineCard extends StatelessWidget {
  const _PaymentLineCard({
    required this.line,
    required this.formatMoney,
    required this.formatDateTime,
  });

  final WorkOrderRecordedPaymentLine line;
  final String Function(int cents, String currencyCode) formatMoney;
  final String Function(DateTime value) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  line.methodLabel,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                formatMoney(line.enteredAmountCents, line.currencyCode),
                style: const TextStyle(
                  color: Color(0xFF1152D4),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${line.currencyCode} · ${formatDateTime(line.paidAt)}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((line.transactionId ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Transacción: ${line.transactionId}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if ((line.note ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                line.note!,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isPaid = status == WorkOrderPaymentStatusCatalog.paid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        WorkOrderPaymentStatusCatalog.label(status),
        style: TextStyle(
          color: isPaid ? const Color(0xFF047857) : const Color(0xFFB45309),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

enum _OrderAction {
  history,
  cancel,
  delete,
}

class _DeliveryCertificatePanel extends StatelessWidget {
  const _DeliveryCertificatePanel({
    required this.busy,
    required this.onPrint,
    required this.onSavePdf,
  });

  final bool busy;
  final VoidCallback onPrint;
  final VoidCallback onSavePdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Acta de entrega',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Genera el documento con los datos del cliente, el pedido y los trabajos realizados para su entrega.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: busy ? null : onPrint,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimir acta'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onSavePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Guardar PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusHistoryCard extends StatelessWidget {
  const _StatusHistoryCard({
    required this.entry,
    required this.dateTimeFormatter,
  });

  final WorkOrderStatusHistoryEntry entry;
  final String Function(DateTime value) dateTimeFormatter;

  @override
  Widget build(BuildContext context) {
    final String actor = (entry.changedByUsername ?? '').trim().isEmpty
        ? 'Sistema'
        : entry.changedByUsername!;
    final _HistoryStatusColors colors = _colorsFor(entry.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.softBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _iconFor(entry.status),
                            color: colors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.label,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$actor · ${dateTimeFormatter(entry.changedAt)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        WorkOrderStatusBadge(status: entry.status),
                      ],
                    ),
                    if ((entry.note ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.softBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.note!,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String status) {
    switch (status.trim()) {
      case WorkOrderStatusCatalog.inProgress:
        return Icons.play_circle_outline_rounded;
      case WorkOrderStatusCatalog.ready:
        return Icons.inventory_2_outlined;
      case WorkOrderStatusCatalog.delivered:
        return Icons.task_alt_rounded;
      case WorkOrderStatusCatalog.cancelled:
        return Icons.cancel_outlined;
      case WorkOrderStatusCatalog.pending:
      default:
        return Icons.schedule_rounded;
    }
  }

  _HistoryStatusColors _colorsFor(String status) {
    switch (status.trim()) {
      case WorkOrderStatusCatalog.inProgress:
        return const _HistoryStatusColors(
          accent: Color(0xFFB45309),
          softBackground: Color(0xFFFFF7ED),
        );
      case WorkOrderStatusCatalog.ready:
        return const _HistoryStatusColors(
          accent: Color(0xFF6D28D9),
          softBackground: Color(0xFFF5F3FF),
        );
      case WorkOrderStatusCatalog.delivered:
        return const _HistoryStatusColors(
          accent: Color(0xFF047857),
          softBackground: Color(0xFFECFDF5),
        );
      case WorkOrderStatusCatalog.cancelled:
        return const _HistoryStatusColors(
          accent: Color(0xFFB91C1C),
          softBackground: Color(0xFFFEF2F2),
        );
      case WorkOrderStatusCatalog.pending:
      default:
        return const _HistoryStatusColors(
          accent: Color(0xFF1152D4),
          softBackground: Color(0xFFEFF6FF),
        );
    }
  }
}

class _HistoryStatusColors {
  const _HistoryStatusColors({
    required this.accent,
    required this.softBackground,
  });

  final Color accent;
  final Color softBackground;
}

class _RequestedCostCard extends StatelessWidget {
  const _RequestedCostCard({
    required this.line,
    required this.formatMoney,
    required this.formatQty,
  });

  final WorkOrderRequestedCostLine line;
  final String Function(int cents, String currencyCode) formatMoney;
  final String Function(double value) formatQty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      line.productName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.productSku.trim().isEmpty
                          ? line.unitLabel
                          : '${line.productSku} · ${line.unitLabel}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMoney(line.totalCostCents, line.currencyCode),
                style: const TextStyle(
                  color: Color(0xFF1152D4),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Precio unitario',
            value: formatMoney(line.unitCostCents, line.currencyCode),
          ),
          _InfoRow(
            label:
                line.usesConsumedQty ? 'Área útil cobrada' : 'Cantidad cobrada',
            value: '${formatQty(line.billedQty)} ${line.unitLabel}',
          ),
          if (line.usesConsumedQty)
            _InfoRow(
              label: 'Cantidad solicitada',
              value: '${formatQty(line.orderedQty)} ${line.unitLabel}',
            ),
        ],
      ),
    );
  }
}

class _MaterialCostCard extends StatelessWidget {
  const _MaterialCostCard({
    required this.line,
    required this.formatMoney,
    required this.formatQty,
  });

  final WorkOrderMaterialCostLine line;
  final String Function(int cents, String currencyCode) formatMoney;
  final String Function(double value) formatQty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      line.productName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.productSku.trim().isEmpty
                          ? line.unitLabel
                          : '${line.productSku} · ${line.unitLabel}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(line.totalCostCents, line.currencyCode),
                style: const TextStyle(
                  color: Color(0xFF1152D4),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _CostPill(
                label:
                    'Costo unitario: ${formatMoney(line.unitCostCents, line.currencyCode)}',
              ),
              _CostPill(
                label: 'Consumo: ${formatQty(line.usedQty)} ${line.unitLabel}',
              ),
              _CostPill(
                label: 'Merma: ${formatQty(line.wasteQty)} ${line.unitLabel}',
                tint: const Color(0xFFFFF7ED),
                textColor: const Color(0xFFEA580C),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            children: <Widget>[
              _InfoRow(
                label: 'Costo por consumo',
                value: formatMoney(line.usedCostCents, line.currencyCode),
              ),
              _InfoRow(
                label: 'Costo por merma',
                value: formatMoney(line.wasteCostCents, line.currencyCode),
              ),
              _InfoRow(
                label: 'Costo total',
                value: formatMoney(line.totalCostCents, line.currencyCode),
                emphasize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  const _CostPill({
    required this.label,
    this.tint = const Color(0xFFF8FAFC),
    this.textColor = const Color(0xFF334155),
  });

  final String label;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrderDetailHeroCard extends StatelessWidget {
  const _OrderDetailHeroCard({
    required this.detail,
    required this.firstItemName,
  });

  final WorkOrderDetail detail;
  final String? firstItemName;

  @override
  Widget build(BuildContext context) {
    final WorkOrderStatusColors statusColors =
        workOrderStatusColorsFor(detail.status);
    final bool isCancelled = detail.status == WorkOrderStatusCatalog.cancelled;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isCancelled ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isCancelled
                ? const Color(0xFFB91C1C).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 7,
              decoration: BoxDecoration(
                color: statusColors.foreground,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? const Color(0xFFF8FAFC)
                            : statusColors.background.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCancelled
                              ? const Color(0xFFFECACA)
                              : statusColors.background,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        detail.folio,
                                        style: const TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    if (isCancelled) ...<Widget>[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'CANCELADO',
                                          style: TextStyle(
                                            color: Color(0xFFB91C1C),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  detail.title,
                                  style: TextStyle(
                                    color: isCancelled
                                        ? const Color(0xFF334155)
                                        : const Color(0xFF0F172A),
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    height: 1.04,
                                  ),
                                ),
                                if ((detail.customerName ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      detail.customerName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isCancelled
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF475569),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if ((firstItemName ?? '').trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      firstItemName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              WorkOrderStatusBadge(status: detail.status),
                              const SizedBox(height: 6),
                              WorkOrderPriorityBadge(priority: detail.priority),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _MetaTag(
                          icon: Icons.shopping_bag_outlined,
                          label:
                              '${detail.items.length} producto${detail.items.length == 1 ? '' : 's'}',
                        ),
                        _MetaTag(
                          icon: Icons.groups_rounded,
                          label:
                              '${detail.assignments.length} responsable${detail.assignments.length == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFFFAFCFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: _HeroInfoColumn(
                              title: 'Pedido',
                              value: _formatDate(detail.createdAt),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            color: const Color(0xFFE2E8F0),
                          ),
                          Expanded(
                            child: _HeroInfoColumn(
                              title: 'Entrega',
                              value: detail.dueAt == null
                                  ? 'Sin fecha'
                                  : _formatDate(detail.dueAt!),
                              color: detail.dueAt == null
                                  ? null
                                  : _deliveryTextColor(detail),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  Color? _deliveryTextColor(WorkOrderDetail detail) {
    final DateTime? dueAt = detail.dueAt;
    if (dueAt == null) {
      return null;
    }
    if (!WorkOrderStatusCatalog.activeStatuses.contains(detail.status)) {
      return null;
    }
    final DateTime now = DateTime.now();
    if (dueAt.isBefore(now)) {
      return const Color(0xFFB91C1C);
    }
    if (dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day) {
      return const Color(0xFFEA580C);
    }
    return null;
  }
}

class _HeroInfoColumn extends StatelessWidget {
  const _HeroInfoColumn({
    required this.title,
    required this.value,
    this.color,
  });

  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color ?? const Color(0xFF0F172A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.leading,
  });

  final String title;
  final String subtitle;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1152D4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: emphasize
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: emphasize
                    ? const Color(0xFF1152D4)
                    : const Color(0xFF0F172A),
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF334155),
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
