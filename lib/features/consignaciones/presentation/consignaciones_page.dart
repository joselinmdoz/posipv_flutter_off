import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../core/security/app_permissions.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../clientes/data/clientes_local_datasource.dart';
import '../../clientes/presentation/clientes_providers.dart';
import '../../clientes/presentation/widgets/sale_customer_picker_dialog.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/consignaciones_local_datasource.dart';
import 'consignaciones_providers.dart';
import 'widgets/consignment_customer_card.dart';
import 'widgets/consignment_sale_detail_page.dart';

class ConsignacionesPage extends ConsumerStatefulWidget {
  const ConsignacionesPage({super.key});

  @override
  ConsumerState<ConsignacionesPage> createState() => _ConsignacionesPageState();
}

class _ConsignacionesPageState extends ConsumerState<ConsignacionesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  ConsignmentDebtOverview? _overview;
  List<String> _methodCodes = <String>['cash', 'transfer'];
  Set<String> _onlineMethodCodes = <String>{};
  Map<String, String> _paymentMethodLabelsByCode = <String, String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ConsignacionesLocalDataSource ds =
          ref.read(consignacionesLocalDataSourceProvider);
      final Future<ConsignmentDebtOverview> overviewFuture =
          ds.loadDebtOverview();
      final Future<ConsignmentPaymentMethodsConfig> paymentConfigFuture =
          ds.loadPaymentMethodsConfig();
      final Future<List<AppPaymentMethodSetting>> paymentSettingsFuture = ref
          .read(configuracionLocalDataSourceProvider)
          .loadPaymentMethodSettings();

      final ConsignmentDebtOverview data = await overviewFuture;
      ConsignmentPaymentMethodsConfig paymentConfig =
          const ConsignmentPaymentMethodsConfig(
        methodCodes: <String>['cash', 'transfer'],
        onlineMethodCodes: <String>{},
      );
      List<AppPaymentMethodSetting> paymentSettings =
          const <AppPaymentMethodSetting>[];
      try {
        paymentConfig = await paymentConfigFuture;
      } catch (_) {}
      try {
        paymentSettings = await paymentSettingsFuture;
      } catch (_) {}
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = data;
        _methodCodes = paymentConfig.methodCodes.isEmpty
            ? <String>['cash', 'transfer']
            : paymentConfig.methodCodes;
        _onlineMethodCodes = paymentConfig.onlineMethodCodes;
        _paymentMethodLabelsByCode =
            buildPaymentMethodLabelMap(paymentSettings);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar consignaciones: $e');
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

  String _money(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  List<ConsignmentCustomerDebt> _filteredCustomers() {
    final ConsignmentDebtOverview? overview = _overview;
    if (overview == null) {
      return const <ConsignmentCustomerDebt>[];
    }
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return overview.customers;
    }
    return overview.customers.where((ConsignmentCustomerDebt customer) {
      if (customer.customerName.toLowerCase().contains(query)) {
        return true;
      }
      if ((customer.customerPhone ?? '').toLowerCase().contains(query)) {
        return true;
      }
      return customer.sales.any((ConsignmentSaleDebt sale) {
        return sale.folio.toLowerCase().contains(query);
      });
    }).toList(growable: false);
  }

  Future<void> _openSaleDetail(ConsignmentSaleDebt sale) async {
    final UserSession? session = ref.read(currentSessionProvider);
    final bool hasLicenseToSell =
        ref.read(currentLicenseStatusProvider).canSell;
    final bool canRegister = hasLicenseToSell &&
        (session?.hasPermission(AppPermissionKeys.consignmentsReconcile) ==
            true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConsignmentSaleDetailPage(
          saleId: sale.saleId,
          canRegisterPayments: canRegister,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _load();
  }

  Future<void> _changeSaleCustomer(
    ConsignmentSaleDebt sale,
    String currentCustomerId,
  ) async {
    final UserSession? session = ref.read(currentSessionProvider);
    final bool hasLicenseToSell =
        ref.read(currentLicenseStatusProvider).canSell;
    final bool canEdit = hasLicenseToSell &&
        (session?.hasPermission(AppPermissionKeys.consignmentsReconcile) ==
            true);
    if (!canEdit) {
      _show('No tienes permisos para editar consignaciones.');
      return;
    }
    final String userId = (session?.userId ?? '').trim();
    if (userId.isEmpty) {
      _show('No se pudo identificar el usuario actual.');
      return;
    }

    List<ClienteListItem> customers = const <ClienteListItem>[];
    try {
      customers = await ref
          .read(clientesLocalDataSourceProvider)
          .listClients(limit: 500);
    } catch (e) {
      _show('No se pudo cargar la lista de clientes: $e');
      return;
    }
    if (customers.isEmpty) {
      _show('No hay clientes activos para seleccionar.');
      return;
    }

    if (!mounted) {
      return;
    }
    final ClienteListItem? selected = await showDialog<ClienteListItem>(
      context: context,
      builder: (BuildContext context) => SaleCustomerPickerDialog(
        customers: customers,
        initialSelectedId:
            currentCustomerId.trim().isEmpty ? null : currentCustomerId.trim(),
      ),
    );
    if (selected == null) {
      return;
    }
    if (selected.id == currentCustomerId.trim()) {
      _show('La venta ya está asociada a ese cliente.');
      return;
    }

    try {
      await ref
          .read(consignacionesLocalDataSourceProvider)
          .reassignConsignmentSaleCustomer(
            saleId: sale.saleId,
            newCustomerId: selected.id,
            userId: userId,
          );
      if (!mounted) {
        return;
      }
      _show('Cliente de la consignación actualizado correctamente.');
      await _load();
    } catch (e) {
      _show('No se pudo cambiar el cliente: $e');
    }
  }

  bool _canRegisterCustomerPayments() {
    final UserSession? session = ref.read(currentSessionProvider);
    final bool hasLicenseToSell =
        ref.read(currentLicenseStatusProvider).canSell;
    return hasLicenseToSell &&
        (session?.hasPermission(AppPermissionKeys.consignmentsReconcile) ==
            true);
  }

  bool _requiresTransactionId(String methodCode) {
    return _onlineMethodCodes.contains(methodCode.trim().toLowerCase());
  }

  String _methodLabel(String methodCode) {
    final String code = methodCode.trim().toLowerCase();
    if (code.isEmpty) {
      return 'Metodo';
    }
    return _paymentMethodLabelsByCode[code] ?? defaultPaymentMethodLabel(code);
  }

  int? _toCents(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    final double? value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }
    return (value * 100).round();
  }

  Future<void> _openCustomerReconcileDialog(
      ConsignmentCustomerDebt customer) async {
    if (!_canRegisterCustomerPayments()) {
      _show('No tienes permisos para conciliar consignaciones.');
      return;
    }
    final String userId = ref.read(currentSessionProvider)?.userId ?? '';
    if (userId.trim().isEmpty) {
      _show('No se pudo identificar el usuario actual.');
      return;
    }
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController txCtrl = TextEditingController();
    bool saving = false;
    String selectedMethod = _methodCodes.isEmpty ? 'cash' : _methodCodes.first;

    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (
              BuildContext context,
              void Function(void Function()) setStateDialog,
            ) {
              final bool requiresTx = _requiresTransactionId(selectedMethod);
              return AlertDialog(
                title: Text('Conciliar ${customer.customerName}'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Pendiente: ${_money(customer.pendingPrimaryCents, _overview?.primaryCurrencySymbol ?? '\$')}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Método de pago',
                          isDense: true,
                        ),
                        items: _methodCodes
                            .map(
                              (String method) => DropdownMenuItem<String>(
                                value: method,
                                child: Text(_methodLabel(method)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: saving
                            ? null
                            : (String? value) {
                                if (value == null) {
                                  return;
                                }
                                setStateDialog(() {
                                  selectedMethod = value;
                                  if (!_requiresTransactionId(value)) {
                                    txCtrl.clear();
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 8),
                      if (requiresTx) ...<Widget>[
                        TextField(
                          controller: txCtrl,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'ID de transacción',
                            hintText: 'Ej. TX-123456',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: amountCtrl,
                        enabled: !saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Monto a abonar',
                          prefixText:
                              '${_overview?.primaryCurrencySymbol ?? '\$'} ',
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final int? amountCents = _toCents(amountCtrl.text);
                            if (amountCents == null || amountCents <= 0) {
                              _show('Ingresa un monto válido.');
                              return;
                            }
                            if (amountCents > customer.pendingPrimaryCents) {
                              _show(
                                'El monto supera el saldo pendiente del cliente.',
                              );
                              return;
                            }
                            final String tx = txCtrl.text.trim();
                            if (requiresTx && tx.isEmpty) {
                              _show('Este método requiere ID de transacción.');
                              return;
                            }
                            setStateDialog(() => saving = true);
                            try {
                              await ref
                                  .read(consignacionesLocalDataSourceProvider)
                                  .registerCustomerDebtPayment(
                                    customerId: customer.customerId,
                                    userId: userId,
                                    method: selectedMethod,
                                    amountPrimaryCents: amountCents,
                                    transactionId: tx,
                                    onlineMethodCodes: _onlineMethodCodes,
                                  );
                              if (!mounted) {
                                return;
                              }
                              if (!dialogContext.mounted) {
                                return;
                              }
                              Navigator.of(dialogContext).pop();
                              _show('Abono registrado correctamente.');
                              await _load();
                            } catch (e) {
                              if (!mounted) {
                                return;
                              }
                              _show('No se pudo registrar el abono: $e');
                              setStateDialog(() => saving = false);
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Registrar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      amountCtrl.dispose();
      txCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final license = ref.watch(currentLicenseStatusProvider);
    final ConsignmentDebtOverview? overview = _overview;
    final List<ConsignmentCustomerDebt> customers = _filteredCustomers();

    return AppScaffold(
      title: 'Consignaciones',
      currentRoute: '/consignaciones',
      onRefresh: _load,
      body: license.canSell
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : overview == null
                  ? const Center(child: Text('No hay datos de consignación.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFDDE5F2),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              _metricRow(
                                'Clientes con deuda',
                                '${overview.customersCount}',
                              ),
                              const SizedBox(height: 6),
                              _metricRow(
                                'Ventas pendientes',
                                '${overview.pendingSalesCount}',
                              ),
                              const SizedBox(height: 6),
                              _metricRow(
                                'Saldo total (aprox.)',
                                _money(
                                  overview.totalPendingPrimaryCents,
                                  overview.primaryCurrencySymbol,
                                ),
                                highlight: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Buscar cliente o folio...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFDDE5F2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFDDE5F2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (customers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                              child:
                                  Text('No hay clientes con deuda pendiente.'),
                            ),
                          )
                        else
                          ...customers.map(
                            (ConsignmentCustomerDebt customer) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ConsignmentCustomerCard(
                                customer: customer,
                                primaryCurrencySymbol:
                                    overview.primaryCurrencySymbol,
                                onOpenSale: _openSaleDetail,
                                onReconcileCustomer: () =>
                                    _openCustomerReconcileDialog(customer),
                                onChangeSaleCustomer: _changeSaleCustomer,
                              ),
                            ),
                          ),
                      ],
                    ))
          : _buildLicenseBlockedBody(license.message),
    );
  }

  Widget _buildLicenseBlockedBody(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_outline_rounded, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Consignaciones bloqueadas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool highlight = false}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: highlight ? const Color(0xFF0F172A) : null,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: highlight ? const Color(0xFF1152D4) : null,
          ),
        ),
      ],
    );
  }
}
