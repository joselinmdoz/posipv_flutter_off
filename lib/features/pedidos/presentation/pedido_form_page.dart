import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_searchable_select_field.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../clientes/presentation/cliente_form_page.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../configuracion/presentation/work_order_task_worker_roles_settings_page.dart';
import '../data/pedidos_local_datasource.dart';
import 'pedidos_providers.dart';
import 'widgets/work_order_assignment_dialog.dart';
import 'widgets/work_order_product_item_dialog.dart';

class PedidoFormPage extends ConsumerStatefulWidget {
  const PedidoFormPage({
    super.key,
    this.orderId,
  });

  final String? orderId;

  bool get isEditing => (orderId ?? '').trim().isNotEmpty;

  @override
  ConsumerState<PedidoFormPage> createState() => _PedidoFormPageState();
}

class _PedidoFormPageState extends ConsumerState<PedidoFormPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _fixedCtrl;
  late final TextEditingController _transferCtrl;

  bool _loading = true;
  bool _saving = false;
  String _status = WorkOrderStatusCatalog.pending;
  String _priority = WorkOrderPriorityCatalog.normal;
  String? _selectedCustomerId;
  DateTime? _createdAt;
  DateTime? _dueAt;
  bool _dueAtManuallyEdited = false;

  List<WorkOrderCustomerOption> _customerOptions = <WorkOrderCustomerOption>[];
  List<WorkOrderEmployeeOption> _employeeOptions = <WorkOrderEmployeeOption>[];
  List<WorkOrderProductOption> _productOptions = <WorkOrderProductOption>[];
  List<String> _taskWorkerRoleOptions = <String>[];
  List<WorkOrderProductItem> _items = <WorkOrderProductItem>[];
  List<WorkOrderAssignmentItem> _assignments = <WorkOrderAssignmentItem>[];
  final Map<String, TextEditingController> _rateCtrls =
      <String, TextEditingController>{};
  String _localCurrencyCode = 'CUP';
  String _foreignCurrencyCode = 'USD';

  static const String _noneOption = '__none__';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descriptionCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
    _fixedCtrl = TextEditingController();
    _transferCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _noteCtrl.dispose();
    _fixedCtrl.dispose();
    _transferCtrl.dispose();
    for (final TextEditingController controller in _rateCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      final ConfiguracionLocalDataSource configDs =
          ref.read(configuracionLocalDataSourceProvider);
      final AppCurrencyConfig currencyConfig =
          ref.read(currentAppConfigProvider).currencyConfig;
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        ds.listCustomerOptions(),
        ds.listEmployeeOptions(),
        ds.listProductOptions(),
        ds.listActiveTaskWorkerRoleOptions(),
        configDs.loadWorkOrderPaymentDisplayConfig(),
        widget.isEditing
            ? ds.getOrderById(widget.orderId!)
            : Future<WorkOrderDetail?>.value(null),
      ]);

      final List<WorkOrderCustomerOption> customers =
          results[0] as List<WorkOrderCustomerOption>;
      final List<WorkOrderEmployeeOption> employees =
          results[1] as List<WorkOrderEmployeeOption>;
      final List<WorkOrderProductOption> products =
          results[2] as List<WorkOrderProductOption>;
      final List<String> taskWorkerRoles = results[3] as List<String>;
      final WorkOrderPaymentDisplayConfig paymentConfig =
          results[4] as WorkOrderPaymentDisplayConfig;
      final WorkOrderDetail? detail = results[5] as WorkOrderDetail?;
      final WorkOrderPricingSnapshot initialPricingSnapshot =
          detail?.pricingSnapshot ??
              _fallbackPricingSnapshot(
                currencyConfig: currencyConfig,
                paymentConfig: paymentConfig,
              );

      if (!mounted) {
        return;
      }

      if (detail != null) {
        _titleCtrl.text = detail.title;
        _descriptionCtrl.text = detail.description ?? '';
        _noteCtrl.text = detail.note ?? '';
        _status = detail.status;
        _priority = detail.priority;
        _createdAt = detail.createdAt;
        _dueAt =
            detail.dueAt ?? _defaultIndicativeDueDate(base: detail.createdAt);
        _dueAtManuallyEdited = detail.dueAt != null;
        _selectedCustomerId = detail.customerId;
        _items = List<WorkOrderProductItem>.of(detail.items);
        _assignments = List<WorkOrderAssignmentItem>.of(detail.assignments);
      } else {
        _createdAt = _defaultCreatedAt();
        _dueAt = _defaultIndicativeDueDate(base: _createdAt);
        _dueAtManuallyEdited = false;
      }
      _applyPricingSnapshot(
        snapshot: initialPricingSnapshot,
        currencyConfig: currencyConfig,
      );

      setState(() {
        _customerOptions = customers;
        _employeeOptions = employees;
        _productOptions = products;
        _taskWorkerRoleOptions = taskWorkerRoles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo abrir el formulario: $error');
    }
  }

  Future<void> _createCustomerQuick() async {
    final String? createdId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ClienteFormPage(
          returnCreatedClientIdOnCreate: true,
        ),
      ),
    );
    if (createdId == null || !mounted) {
      return;
    }
    final List<WorkOrderCustomerOption> refreshed =
        await ref.read(pedidosLocalDataSourceProvider).listCustomerOptions();
    if (!mounted) {
      return;
    }
    setState(() {
      _customerOptions = refreshed;
      _selectedCustomerId = createdId;
    });
  }

  Future<void> _pickDueDate() async {
    final DateTime? picked = await _pickDateTime(
      initialDate: _dueAt ?? _defaultIndicativeDueDate(base: _createdAt),
      helpText: 'Seleccionar fecha indicativa',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _dueAt = picked;
      _dueAtManuallyEdited = true;
    });
  }

  Future<void> _pickCreatedAt() async {
    final DateTime? picked = await _pickDateTime(
      initialDate: _createdAt ?? _defaultCreatedAt(),
      helpText: 'Seleccionar fecha del pedido',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _createdAt = picked;
      if (!_dueAtManuallyEdited) {
        _dueAt = _defaultIndicativeDueDate(base: picked);
      }
    });
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initialDate,
    required String helpText,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      helpText: helpText,
    );
    if (date == null || !mounted) {
      return null;
    }
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!mounted) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? initialTime.hour,
      time?.minute ?? initialTime.minute,
    );
  }

  Future<void> _editProductItem([int? index]) async {
    final WorkOrderProductItem? created =
        await showDialog<WorkOrderProductItem>(
      context: context,
      builder: (_) => WorkOrderProductItemDialog(
        options: _productOptions,
        initialItem: index == null ? null : _items[index],
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _items = <WorkOrderProductItem>[..._items, created];
      } else {
        final List<WorkOrderProductItem> next =
            List<WorkOrderProductItem>.of(_items);
        next[index] = created;
        _items = next;
      }
    });
  }

  Future<void> _editAssignment([int? index]) async {
    final WorkOrderAssignmentItem? created =
        await showDialog<WorkOrderAssignmentItem>(
      context: context,
      builder: (_) => WorkOrderAssignmentDialog(
        options: _employeeOptions,
        roleOptions: _taskWorkerRoleOptions,
        initialItem: index == null ? null : _assignments[index],
        onManageRoles: _openManageTaskWorkerRoles,
      ),
    );
    if (created == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _assignments = <WorkOrderAssignmentItem>[..._assignments, created];
      } else {
        final List<WorkOrderAssignmentItem> next =
            List<WorkOrderAssignmentItem>.of(_assignments);
        next[index] = created;
        _assignments = next;
      }
    });
  }

  Future<List<String>> _openManageTaskWorkerRoles() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const WorkOrderTaskWorkerRolesSettingsPage(),
      ),
    );
    if (!mounted) {
      return _taskWorkerRoleOptions;
    }
    final List<String> refreshed = await ref
        .read(pedidosLocalDataSourceProvider)
        .listActiveTaskWorkerRoleOptions();
    if (!mounted || refreshed.isEmpty) {
      return _taskWorkerRoleOptions;
    }
    setState(() {
      _taskWorkerRoleOptions = List<String>.of(refreshed);
    });
    return refreshed;
  }

  WorkOrderPricingSnapshot _fallbackPricingSnapshot({
    required AppCurrencyConfig currencyConfig,
    required WorkOrderPaymentDisplayConfig paymentConfig,
  }) {
    return WorkOrderPricingSnapshot(
      capturedAt: DateTime.now(),
      primaryCurrencyCode: currencyConfig.primaryCurrencyCode,
      localCurrencyCode: paymentConfig.localCurrencyCode,
      foreignCurrencyCode: paymentConfig.foreignCurrencyCode,
      localCashFixedSurcharge: paymentConfig.localCashFixedSurcharge,
      localTransferPercentSurcharge:
          paymentConfig.localTransferPercentSurcharge,
      ratesByCode: <String, double>{
        for (final AppCurrencySetting row in currencyConfig.currencies)
          row.code.trim().toUpperCase(): row.rateToPrimary,
      },
    );
  }

  List<AppCurrencySetting> _allCurrencies(AppCurrencyConfig currencyConfig) {
    final Map<String, AppCurrencySetting> byCode = <String, AppCurrencySetting>{
      for (final AppCurrencySetting currency in currencyConfig.currencies)
        currency.code.trim().toUpperCase(): currency,
    };
    for (final MapEntry<String, TextEditingController> entry
        in _rateCtrls.entries) {
      byCode.putIfAbsent(
        entry.key,
        () => AppCurrencySetting(
          code: entry.key,
          symbol: currencyConfig.symbolForCode(entry.key),
          rateToPrimary:
              double.tryParse(entry.value.text.trim().replaceAll(',', '.')) ??
                  1,
        ),
      );
    }
    return byCode.values.toList(growable: false)
      ..sort((AppCurrencySetting a, AppCurrencySetting b) {
        final String primary =
            currencyConfig.primaryCurrencyCode.trim().toUpperCase();
        if (a.code.trim().toUpperCase() == primary) {
          return -1;
        }
        if (b.code.trim().toUpperCase() == primary) {
          return 1;
        }
        return a.code.compareTo(b.code);
      });
  }

  void _applyPricingSnapshot({
    required WorkOrderPricingSnapshot snapshot,
    required AppCurrencyConfig currencyConfig,
  }) {
    _localCurrencyCode = snapshot.localCurrencyCode.trim().toUpperCase();
    _foreignCurrencyCode = snapshot.foreignCurrencyCode.trim().toUpperCase();
    _fixedCtrl.text = snapshot.localCashFixedSurcharge.toStringAsFixed(2);
    _transferCtrl.text =
        snapshot.localTransferPercentSurcharge.toStringAsFixed(2);

    final Set<String> nextCodes = <String>{
      for (final AppCurrencySetting currency in currencyConfig.currencies)
        currency.code.trim().toUpperCase(),
      ...snapshot.ratesByCode.keys.map(
        (String code) => code.trim().toUpperCase(),
      ),
    }..removeWhere((String code) => code.isEmpty);

    final Set<String> staleCodes = _rateCtrls.keys
        .where((String code) => !nextCodes.contains(code))
        .toSet();
    for (final String code in staleCodes) {
      _rateCtrls.remove(code)?.dispose();
    }

    for (final String code in nextCodes) {
      final AppCurrencySetting? currency = currencyConfig.currencyByCode(code);
      final double rate =
          snapshot.ratesByCode[code] ?? currency?.rateToPrimary ?? 1;
      final TextEditingController controller = _rateCtrls.putIfAbsent(
        code,
        () => TextEditingController(),
      );
      controller.text = rate.toStringAsFixed(6);
    }
  }

  WorkOrderPricingSnapshot _draftPricingSnapshot(
      AppCurrencyConfig currencyConfig) {
    final String primary =
        currencyConfig.primaryCurrencyCode.trim().toUpperCase();
    final Map<String, double> rates = <String, double>{};
    for (final AppCurrencySetting currency in _allCurrencies(currencyConfig)) {
      final double parsed = double.tryParse(
            (_rateCtrls[currency.code]?.text.trim() ?? '').replaceAll(',', '.'),
          ) ??
          currency.rateToPrimary;
      rates[currency.code.trim().toUpperCase()] = parsed <= 0 ? 1 : parsed;
    }
    rates[primary] = 1;
    String local = _localCurrencyCode.trim().toUpperCase();
    String foreign = _foreignCurrencyCode.trim().toUpperCase();
    if (local.isEmpty) {
      local = primary == 'CUP' ? 'CUP' : primary;
    }
    if (foreign.isEmpty || foreign == local) {
      foreign = rates.keys.firstWhere(
        (String code) => code != local,
        orElse: () => local == 'USD' ? 'CUP' : 'USD',
      );
    }
    if (foreign == local) {
      foreign = local == primary ? 'USD' : primary;
    }
    return WorkOrderPricingSnapshot(
      capturedAt: _createdAt ?? DateTime.now(),
      primaryCurrencyCode: primary,
      localCurrencyCode: local,
      foreignCurrencyCode: foreign,
      localCashFixedSurcharge:
          double.tryParse(_fixedCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      localTransferPercentSurcharge:
          double.tryParse(_transferCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      ratesByCode: rates,
    );
  }

  void _removeItem(int index) {
    setState(() {
      final List<WorkOrderProductItem> next =
          List<WorkOrderProductItem>.of(_items);
      next.removeAt(index);
      _items = next;
    });
  }

  void _removeAssignment(int index) {
    setState(() {
      final List<WorkOrderAssignmentItem> next =
          List<WorkOrderAssignmentItem>.of(_assignments);
      next.removeAt(index);
      _assignments = next;
    });
  }

  Future<void> _save() async {
    final session = ref.read(currentSessionProvider);
    final AppCurrencyConfig currencyConfig =
        ref.read(currentAppConfigProvider).currencyConfig;
    if (session == null) {
      _show('No hay sesion activa.');
      return;
    }
    if (_items.isEmpty) {
      _show('Debes agregar al menos un producto al pedido.');
      return;
    }
    if (_saving) {
      return;
    }
    final WorkOrderPricingSnapshot pricingSnapshot =
        _draftPricingSnapshot(currencyConfig);
    if (pricingSnapshot.localCurrencyCode ==
        pricingSnapshot.foreignCurrencyCode) {
      _show('La moneda local y la moneda extranjera deben ser distintas.');
      return;
    }

    setState(() => _saving = true);
    try {
      final WorkOrderUpsertInput input = WorkOrderUpsertInput(
        title: _titleCtrl.text.trim(),
        workType: 'General',
        status: widget.isEditing ? _status : WorkOrderStatusCatalog.pending,
        priority: _priority,
        items: _items,
        assignments: _assignments,
        createdAt: _createdAt ?? _defaultCreatedAt(),
        pricingSnapshot: pricingSnapshot,
        customerId: _normalizeOption(_selectedCustomerId),
        description: _descriptionCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        dueAt: _dueAt ?? _defaultIndicativeDueDate(base: _createdAt),
      );

      final PedidosLocalDataSource ds =
          ref.read(pedidosLocalDataSourceProvider);
      if (widget.isEditing) {
        await ds.updateOrder(
          orderId: widget.orderId!,
          input: input,
          userId: session.userId,
        );
      } else {
        await ds.createOrder(
          input: input,
          userId: session.userId,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar el pedido: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _normalizeOption(String? value) {
    if (value == null || value == _noneOption) {
      return null;
    }
    return value;
  }

  DateTime _defaultCreatedAt() {
    final DateTime now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
  }

  DateTime _defaultIndicativeDueDate({DateTime? base}) {
    final DateTime source = base ?? _defaultCreatedAt();
    return DateTime(
      source.year,
      source.month,
      source.day,
      source.hour,
      source.minute,
    ).add(const Duration(days: 15));
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppCurrencyConfig currencyConfig =
        ref.watch(currentAppConfigProvider).currencyConfig;
    final List<AppCurrencySetting> currencies = _allCurrencies(currencyConfig);
    final bool canManage = ref.watch(currentSessionProvider)?.hasPermission(
              AppPermissionKeys.ordersManage,
            ) ??
        false;

    return AppScaffold(
      title: widget.isEditing ? 'Editar pedido' : 'Nuevo pedido',
      currentRoute: '/pedidos',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      useDefaultActions: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).pop(false),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 3),
                _IntroCard(isEditing: widget.isEditing),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Cliente',
                  children: <Widget>[
                    AppSearchableSelectField<String>(
                      label: 'Cliente del pedido',
                      value: _selectedCustomerId ?? _noneOption,
                      hintText: 'Selecciona un cliente',
                      options: <AppSearchableSelectOption<String>>[
                        const AppSearchableSelectOption<String>(
                          value: _noneOption,
                          label: 'Sin cliente',
                          subtitle: 'Pedido no asociado',
                        ),
                        ..._customerOptions.map(
                          (WorkOrderCustomerOption item) =>
                              AppSearchableSelectOption<String>(
                            value: item.id,
                            label: item.name,
                            subtitle: item.phone ?? item.email ?? item.code,
                            searchText:
                                '${item.name} ${item.code} ${item.phone ?? ''} ${item.email ?? ''}',
                          ),
                        ),
                      ],
                      onChanged: canManage
                          ? (String value) {
                              setState(() => _selectedCustomerId = value);
                            }
                          : (_) {},
                    ),
                    if (canManage) ...<Widget>[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _saving ? null : _createCustomerQuick,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Crear cliente rapido'),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Productos solicitados',
                  actionLabel: canManage ? 'Agregar producto' : null,
                  onAction: canManage && !_saving ? _editProductItem : null,
                  children: <Widget>[
                    if (_items.isEmpty)
                      const _EmptyHint(
                        'Aun no has agregado productos al pedido.',
                      )
                    else
                      ..._items.asMap().entries.map(
                            (MapEntry<int, WorkOrderProductItem> entry) =>
                                Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EditableSummaryCard(
                                title: entry.value.productName,
                                subtitle:
                                    '${_qty(entry.value.qty)} ${entry.value.unitLabel} · ${entry.value.productSku}',
                                onEdit: canManage && !_saving
                                    ? () => _editProductItem(entry.key)
                                    : null,
                                onDelete: canManage && !_saving
                                    ? () => _removeItem(entry.key)
                                    : null,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Equipo asignado',
                  actionLabel: canManage ? 'Agregar empleado' : null,
                  onAction: canManage && !_saving ? _editAssignment : null,
                  children: <Widget>[
                    if (_assignments.isEmpty)
                      const _EmptyHint(
                        'Puedes dejar este pedido sin empleados asignados por ahora.',
                      )
                    else
                      ..._assignments.asMap().entries.map(
                            (MapEntry<int, WorkOrderAssignmentItem> entry) =>
                                Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EditableSummaryCard(
                                title: entry.value.employeeName,
                                subtitle:
                                    '${entry.value.roleName} · ${entry.value.employeeCode}',
                                onEdit: canManage && !_saving
                                    ? () => _editAssignment(entry.key)
                                    : null,
                                onDelete: canManage && !_saving
                                    ? () => _removeAssignment(entry.key)
                                    : null,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Informacion del pedido',
                  children: <Widget>[
                    const _FieldLabel('Titulo o referencia interna'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleCtrl,
                      enabled: canManage && !_saving,
                      decoration: _inputDecoration(
                        'Opcional. Si lo dejas vacio se genera automaticamente',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Proceso y entrega',
                  children: <Widget>[
                    const _FieldLabel('Fecha del pedido'),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: canManage && !_saving ? _pickCreatedAt : null,
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.event_available_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _dateTime(_createdAt ?? _defaultCreatedAt()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Por defecto toma la fecha y hora actual, pero puedes ajustarla al momento real en que se registró el pedido.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Prioridad'),
                    const SizedBox(height: 8),
                    _ChoiceWrap(
                      values: WorkOrderPriorityCatalog.all,
                      currentValue: _priority,
                      labelBuilder: WorkOrderPriorityCatalog.label,
                      enabled: canManage && !_saving,
                      onChanged: (String value) {
                        setState(() => _priority = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Fecha indicativa de entrega'),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: canManage && !_saving ? _pickDueDate : null,
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.event_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _dateTime(_dueAt ??
                                      _defaultIndicativeDueDate(
                                        base: _createdAt,
                                      )),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dueAtManuallyEdited
                          ? 'Fecha ajustada manualmente. Sirve solo como referencia interna para planificar la entrega.'
                          : 'Se propone automaticamente a 15 dias desde la fecha del pedido y funciona solo como referencia interna.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Cotizacion fijada',
                  children: <Widget>[
                    const Text(
                      'El pedido conserva su propia tasa de cambio. Puedes ajustarla aqui y luego modificarla de nuevo desde cobro y cotizacion si lo necesitas.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Monedas de cobro'),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                        final bool stackFields = constraints.maxWidth < 520;
                        final Widget localField =
                            DropdownButtonFormField<String>(
                          initialValue: _localCurrencyCode,
                          isExpanded: true,
                          decoration: _inputDecoration('Moneda local'),
                          items: currencies
                              .map(
                                (AppCurrencySetting currency) =>
                                    DropdownMenuItem<String>(
                                  value: currency.code,
                                  child: Text(
                                    '${currency.code} (${currency.symbol})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: canManage && !_saving
                              ? (String? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() => _localCurrencyCode = value);
                                }
                              : null,
                        );
                        final Widget foreignField =
                            DropdownButtonFormField<String>(
                          initialValue: _foreignCurrencyCode,
                          isExpanded: true,
                          decoration: _inputDecoration('Moneda extranjera'),
                          items: currencies
                              .map(
                                (AppCurrencySetting currency) =>
                                    DropdownMenuItem<String>(
                                  value: currency.code,
                                  child: Text(
                                    '${currency.code} (${currency.symbol})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: canManage && !_saving
                              ? (String? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() => _foreignCurrencyCode = value);
                                }
                              : null,
                        );
                        if (stackFields) {
                          return Column(
                            children: <Widget>[
                              localField,
                              const SizedBox(height: 12),
                              foreignField,
                            ],
                          );
                        }
                        return Row(
                          children: <Widget>[
                            Expanded(child: localField),
                            const SizedBox(width: 12),
                            Expanded(child: foreignField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Tasas congeladas del pedido'),
                    const SizedBox(height: 8),
                    ...currencies.map(
                      (AppCurrencySetting currency) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: _rateCtrls[currency.code],
                          enabled: canManage && !_saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            currency.code == currencyConfig.primaryCurrencyCode
                                ? '${currency.code} se mantiene como 1.00 por ser la moneda principal'
                                : 'Tasa hacia ${currencyConfig.primaryCurrencyCode}',
                          ).copyWith(
                            labelText: '${currency.code} (${currency.symbol})',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ejemplo: si la principal es CUP y 1 USD = 650 CUP, la tasa de USD debe quedar como 0.001538.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _fixedCtrl,
                            enabled: canManage && !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                              'Recargo fijo al convertir a efectivo local',
                            ).copyWith(labelText: 'Recargo efectivo local'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _transferCtrl,
                            enabled: canManage && !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _inputDecoration(
                              'Porcentaje extra sobre el total local',
                            ).copyWith(labelText: 'Recargo transferencia %'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Detalles adicionales',
                  children: <Widget>[
                    const _FieldLabel('Descripcion'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionCtrl,
                      enabled: canManage && !_saving,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _inputDecoration(
                        'Especifica acabados, colores, referencias o instrucciones...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Observaciones'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      enabled: canManage && !_saving,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Notas internas para el taller...',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: canManage && !_saving ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1152D4),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    widget.isEditing ? 'Guardar cambios' : 'Crear pedido',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
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

  String _dateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1152D4)),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.isEditing,
  });

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1152D4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isEditing ? 'Actualiza el pedido' : 'Registra un nuevo pedido',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selecciona los productos solicitados, vincula el cliente y deja lista la referencia de entrega del pedido.',
            style: TextStyle(
              color: Color(0xFFDCE7FF),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if ((actionLabel ?? '').trim().isNotEmpty)
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.currentValue,
    required this.labelBuilder,
    required this.onChanged,
    required this.enabled,
  });

  final List<String> values;
  final String currentValue;
  final String Function(String value) labelBuilder;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((String value) {
        final bool selected = currentValue == value;
        return ChoiceChip(
          selected: selected,
          label: Text(labelBuilder(value)),
          labelStyle: TextStyle(
            color: selected ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color:
                  selected ? const Color(0xFF1152D4) : const Color(0xFFE2E8F0),
            ),
          ),
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFF1152D4),
          onSelected: enabled ? (_) => onChanged(value) : null,
        );
      }).toList(growable: false),
    );
  }
}

class _EditableSummaryCard extends StatelessWidget {
  const _EditableSummaryCard({
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
