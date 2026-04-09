import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/licensing/license_providers.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../../configuracion/presentation/configuracion_providers.dart';
import '../../data/consignaciones_local_datasource.dart';
import '../consignaciones_providers.dart';

class ConsignmentSaleDetailPage extends ConsumerStatefulWidget {
  const ConsignmentSaleDetailPage({
    super.key,
    required this.saleId,
    required this.canRegisterPayments,
  });

  final String saleId;
  final bool canRegisterPayments;

  @override
  ConsumerState<ConsignmentSaleDetailPage> createState() =>
      _ConsignmentSaleDetailPageState();
}

class _ConsignmentSaleDetailPageState
    extends ConsumerState<ConsignmentSaleDetailPage> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _txCtrl = TextEditingController();

  ConsignmentSaleDebtDetail? _detail;
  List<String> _methodCodes = <String>[];
  Set<String> _onlineMethodCodes = <String>{};
  Map<String, String> _paymentMethodLabelsByCode = <String, String>{};
  String _selectedMethod = 'cash';
  bool _loading = true;
  bool _saving = false;

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

  @override
  void dispose() {
    _amountCtrl.dispose();
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bool canSell = ref.read(currentLicenseStatusProvider).canSell;
    if (!canSell) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }
    try {
      final ConsignacionesLocalDataSource ds =
          ref.read(consignacionesLocalDataSourceProvider);
      final Future<List<AppPaymentMethodSetting>> paymentMethodsFuture = ref
          .read(configuracionLocalDataSourceProvider)
          .loadPaymentMethodSettings();
      final ConsignmentSaleDebtDetail? detail =
          await ds.loadSaleDebtDetail(widget.saleId);
      final ConsignmentPaymentMethodsConfig paymentConfig =
          await ds.loadPaymentMethodsConfig();
      List<AppPaymentMethodSetting> paymentSettings =
          const <AppPaymentMethodSetting>[];
      try {
        paymentSettings = await paymentMethodsFuture;
      } catch (_) {}
      if (!mounted) {
        return;
      }
      final List<String> methods = paymentConfig.methodCodes.isEmpty
          ? <String>['cash', 'transfer']
          : paymentConfig.methodCodes;
      setState(() {
        _detail = detail;
        _methodCodes = methods;
        _onlineMethodCodes = paymentConfig.onlineMethodCodes;
        _paymentMethodLabelsByCode =
            buildPaymentMethodLabelMap(paymentSettings);
        if (!methods.contains(_selectedMethod)) {
          _selectedMethod = methods.first;
        }
        if (!_onlineMethodCodes.contains(_selectedMethod)) {
          _txCtrl.clear();
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar la venta: $e');
    }
  }

  bool _requiresTransactionId(String method) {
    return _onlineMethodCodes.contains(method.trim().toLowerCase());
  }

  Future<void> _registerPayment() async {
    if (_saving || _detail == null) {
      return;
    }
    if (!ref.read(currentLicenseStatusProvider).canSell) {
      _show('La licencia no permite registrar pagos.');
      return;
    }
    final int? cents = _toCents(_amountCtrl.text);
    if (cents == null || cents <= 0) {
      _show('Ingresa un monto válido.');
      return;
    }
    if (cents > _detail!.sale.pendingCents) {
      _show('El monto supera el saldo pendiente.');
      return;
    }
    final String tx = _txCtrl.text.trim();
    if (_requiresTransactionId(_selectedMethod) && tx.isEmpty) {
      _show('Este método requiere ID de transacción.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(consignacionesLocalDataSourceProvider).registerDebtPayment(
            saleId: _detail!.sale.saleId,
            userId: ref.read(currentSessionProvider)?.userId ?? '',
            method: _selectedMethod,
            amountCents: cents,
            transactionId: tx,
            onlineMethodCodes: _onlineMethodCodes,
          );
      if (!mounted) {
        return;
      }
      _amountCtrl.clear();
      _txCtrl.clear();
      _show('Abono registrado correctamente.');
      await _load();
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo registrar el abono: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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

  String _money(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _qty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.0001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _date(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hh:$mm';
  }

  String _methodLabel(String method) {
    final String code = method.trim().toLowerCase();
    if (code.isEmpty) {
      return 'Metodo';
    }
    return _paymentMethodLabelsByCode[code] ?? defaultPaymentMethodLabel(code);
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final license = ref.watch(currentLicenseStatusProvider);
    final ConsignmentSaleDebtDetail? detail = _detail;
    final bool canRegisterPayments =
        widget.canRegisterPayments && license.canSell;
    return AppScaffold(
      title: 'Conciliar Venta',
      currentRoute: '/consignaciones',
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
            return;
          }
          context.go('/consignaciones');
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: license.canSell
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : detail == null
                  ? const Center(child: Text('No se encontró la venta.'))
                  : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        children: <Widget>[
                          _SectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  detail.sale.folio,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Fecha: ${_date(detail.sale.createdAt)}'),
                                Text('Cliente: ${detail.customerName}'),
                                if ((detail.customerPhone ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Text('Teléfono: ${detail.customerPhone}'),
                                Text('Almacén: ${detail.sale.warehouseName}'),
                                Text('Cajero: ${detail.sale.cashierUsername}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Resumen de deuda',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _row(
                                  'Total',
                                  _money(
                                    detail.sale.totalCents,
                                    detail.sale.currencySymbol,
                                  ),
                                ),
                                _row(
                                  'Pagado',
                                  _money(
                                    detail.sale.paidCents,
                                    detail.sale.currencySymbol,
                                  ),
                                ),
                                const Divider(height: 16),
                                _row(
                                  'Pendiente',
                                  _money(
                                    detail.sale.pendingCents,
                                    detail.sale.currencySymbol,
                                  ),
                                  highlight: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Productos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (detail.lines.isEmpty)
                                  const Text('Sin líneas.')
                                else
                                  ...detail.lines
                                      .map((ConsignmentSaleLine line) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  line.productName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  '${_qty(line.qty)} x ${_money(line.unitPriceCents, detail.sale.currencySymbol)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF94A3B8)
                                                        : const Color(
                                                            0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _money(
                                              line.lineTotalCents,
                                              detail.sale.currencySymbol,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SectionCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Pagos registrados',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (detail.payments.isEmpty)
                                  const Text('Aún no hay pagos.')
                                else
                                  ...detail.payments
                                      .map((ConsignmentPaymentRecord row) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(
                                              '${_methodLabel(row.method)}${(row.transactionId ?? '').trim().isNotEmpty ? ' • TX: ${row.transactionId!.trim()}' : ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _money(
                                              row.amountCents,
                                              detail.sale.currencySymbol,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SectionCard(
                            isDark: isDark,
                            child: canRegisterPayments
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Registrar abono',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedMethod,
                                        decoration: const InputDecoration(
                                          labelText: 'Método',
                                          isDense: true,
                                        ),
                                        items: _methodCodes
                                            .map(
                                              (String code) =>
                                                  DropdownMenuItem<String>(
                                                value: code,
                                                child: Text(_methodLabel(code)),
                                              ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (String? value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _selectedMethod = value;
                                            if (!_requiresTransactionId(
                                                value)) {
                                              _txCtrl.clear();
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      if (_requiresTransactionId(
                                          _selectedMethod)) ...<Widget>[
                                        TextField(
                                          controller: _txCtrl,
                                          decoration: const InputDecoration(
                                            labelText: 'ID de transacción',
                                            hintText: 'Ej. TX-123456',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      TextField(
                                        controller: _amountCtrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Monto',
                                          prefixText:
                                              '${detail.sale.currencySymbol} ',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed:
                                              _saving ? null : _registerPayment,
                                          icon: _saving
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.check_circle_outline,
                                                ),
                                          label: const Text('Registrar pago'),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'No tienes permisos de venta para registrar pagos de conciliación.',
                                  ),
                          ),
                        ],
                      ),
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

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
              color: highlight ? const Color(0xFFB91C1C) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.child,
  });

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFDDE5F2),
        ),
      ),
      child: child,
    );
  }
}
