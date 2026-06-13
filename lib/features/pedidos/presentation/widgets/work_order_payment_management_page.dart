import 'package:flutter/material.dart';

import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/pedidos_local_datasource.dart';
import 'work_order_payment_variants.dart';

class WorkOrderPaymentManagementPage extends StatefulWidget {
  const WorkOrderPaymentManagementPage({
    super.key,
    required this.orderFolio,
    required this.orderTotals,
    required this.initialPricingSnapshot,
    required this.initialPaymentValues,
    required this.initialPaymentLines,
    required this.currencyConfig,
    required this.paymentMethods,
  });

  final String orderFolio;
  final List<WorkOrderCostTotal> orderTotals;
  final WorkOrderPricingSnapshot initialPricingSnapshot;
  final List<WorkOrderPaymentValue> initialPaymentValues;
  final List<WorkOrderRecordedPaymentLine> initialPaymentLines;
  final AppCurrencyConfig currencyConfig;
  final List<AppPaymentMethodSetting> paymentMethods;

  @override
  State<WorkOrderPaymentManagementPage> createState() =>
      _WorkOrderPaymentManagementPageState();
}

class _WorkOrderPaymentManagementPageState
    extends State<WorkOrderPaymentManagementPage> {
  late DateTime _paidAt;
  late String _localCurrencyCode;
  late String _foreignCurrencyCode;
  late final TextEditingController _fixedCtrl;
  late final TextEditingController _transferCtrl;
  final Map<String, TextEditingController> _rateCtrls =
      <String, TextEditingController>{};
  final List<_PaymentLineDraft> _lines = <_PaymentLineDraft>[];

  @override
  void initState() {
    super.initState();
    _paidAt = widget.initialPaymentLines.isNotEmpty
        ? widget.initialPaymentLines.last.paidAt
        : DateTime.now();
    _localCurrencyCode =
        widget.initialPricingSnapshot.localCurrencyCode.trim().toUpperCase();
    _foreignCurrencyCode =
        widget.initialPricingSnapshot.foreignCurrencyCode.trim().toUpperCase();
    _fixedCtrl = TextEditingController(
      text: widget.initialPricingSnapshot.localCashFixedSurcharge
          .toStringAsFixed(2),
    );
    _transferCtrl = TextEditingController(
      text: widget.initialPricingSnapshot.localTransferPercentSurcharge
          .toStringAsFixed(2),
    );
    for (final AppCurrencySetting currency in _allCurrencies) {
      _rateCtrls[currency.code] = TextEditingController(
        text: _roundRatePrecision(
          widget.initialPricingSnapshot.ratesByCode[currency.code] ??
              currency.rateToPrimary,
        ).toString(),
      );
    }
    _lines.addAll(
      widget.initialPaymentLines.map(
        (WorkOrderRecordedPaymentLine line) =>
            _PaymentLineDraft.fromModel(line),
      ),
    );
  }

  @override
  void dispose() {
    _fixedCtrl.dispose();
    _transferCtrl.dispose();
    for (final TextEditingController controller in _rateCtrls.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<AppCurrencySetting> get _allCurrencies {
    final Map<String, AppCurrencySetting> byCode = <String, AppCurrencySetting>{
      for (final AppCurrencySetting currency
          in widget.currencyConfig.currencies)
        currency.code.trim().toUpperCase(): currency,
    };
    for (final MapEntry<String, double> entry
        in widget.initialPricingSnapshot.ratesByCode.entries) {
      final String code = entry.key.trim().toUpperCase();
      byCode.putIfAbsent(
        code,
        () => AppCurrencySetting(
          code: code,
          symbol: widget.currencyConfig.symbolForCode(code),
          rateToPrimary: entry.value,
        ),
      );
    }
    return byCode.values.toList(growable: false)
      ..sort((AppCurrencySetting a, AppCurrencySetting b) {
        if (a.code == widget.initialPricingSnapshot.primaryCurrencyCode) {
          return -1;
        }
        if (b.code == widget.initialPricingSnapshot.primaryCurrencyCode) {
          return 1;
        }
        return a.code.compareTo(b.code);
      });
  }

  WorkOrderPricingSnapshot get _draftSnapshot {
    final Map<String, double> rates = <String, double>{};
    for (final AppCurrencySetting currency in _allCurrencies) {
      final double parsed = double.tryParse(
            (_rateCtrls[currency.code]?.text.trim() ?? '').replaceAll(',', '.'),
          ) ??
          currency.rateToPrimary;
      rates[currency.code] = _roundRatePrecision(parsed <= 0 ? 1 : parsed);
    }
    final String primary =
        widget.initialPricingSnapshot.primaryCurrencyCode.trim().toUpperCase();
    rates[primary] = 1;
    return WorkOrderPricingSnapshot(
      capturedAt: DateTime.now(),
      primaryCurrencyCode: primary,
      localCurrencyCode: _localCurrencyCode,
      foreignCurrencyCode: _foreignCurrencyCode,
      localCashFixedSurcharge: _roundTo2(
        double.tryParse(_fixedCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      ),
      localTransferPercentSurcharge: _roundTo2(
        double.tryParse(_transferCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      ),
      ratesByCode: rates,
    );
  }

  List<WorkOrderPaymentValue> get _previewValues {
    return buildWorkOrderPaymentVariantsFromSnapshot(
      totals: widget.orderTotals,
      pricingSnapshot: _draftSnapshot,
    );
  }

  List<WorkOrderRecordedPaymentLine> get _previewPaymentLines => _lines
      .map(
        (_PaymentLineDraft line) => line.toModel(
          widget.paymentMethods,
          _draftSnapshot,
        ),
      )
      .where(
        (WorkOrderRecordedPaymentLine line) => line.enteredAmountCents > 0,
      )
      .toList(growable: false);

  int get _paidComparableCents => computeWorkOrderComparablePaidCents(
        lines: _previewPaymentLines,
        pricingSnapshot: _draftSnapshot,
      );

  String get _derivedPaymentStatus => deriveWorkOrderPaymentStatus(
        lines: _previewPaymentLines,
        pricingSnapshot: _draftSnapshot,
        paymentValues: _previewValues,
        totals: widget.orderTotals,
      );

  String get _comparableCurrencyCode =>
      _draftSnapshot.localCurrencyCode.trim().toUpperCase().isEmpty
          ? _draftSnapshot.primaryCurrencyCode.trim().toUpperCase()
          : _draftSnapshot.localCurrencyCode.trim().toUpperCase();

  int _remainingForVariant(WorkOrderPaymentValue row) {
    final int paidInRowCurrency = _convertComparableToCurrency(
      amountCents: _paidComparableCents,
      sourceCurrencyCode: _comparableCurrencyCode,
      targetCurrencyCode: row.currencyCode,
    );
    final int remaining = row.amountCents - paidInRowCurrency;
    return remaining <= 0 ? 0 : remaining;
  }

  int _convertComparableToCurrency({
    required int amountCents,
    required String sourceCurrencyCode,
    required String targetCurrencyCode,
  }) {
    final String source = sourceCurrencyCode.trim().toUpperCase();
    final String target = targetCurrencyCode.trim().toUpperCase();
    if (amountCents <= 0) {
      return 0;
    }
    if (source == target) {
      return amountCents;
    }
    final String primary =
        _draftSnapshot.primaryCurrencyCode.trim().toUpperCase();
    final double sourceRate = _draftSnapshot.ratesByCode[source] ?? 1;
    final double targetRate = _draftSnapshot.ratesByCode[target] ?? 1;
    final double sourceAmount = amountCents / 100;
    final double amountInPrimary = source == primary
        ? sourceAmount
        : sourceAmount / (sourceRate <= 0 ? 1 : sourceRate);
    final double targetAmount =
        target == primary ? amountInPrimary : amountInPrimary * targetRate;
    return (targetAmount * 100).round();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPaidAt() async {
    final DateTime base = _paidAt;
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(base.year - 2),
      lastDate: DateTime(base.year + 2),
      initialDate: base,
      helpText: 'Fecha del cobro',
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _paidAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _editLine({int? index}) async {
    final _PaymentLineDraft base = index == null
        ? _PaymentLineDraft.empty(
            _defaultMethodCode,
            paidAt: _paidAt,
          )
        : _lines[index];
    final _PaymentLineDraft? edited = await showDialog<_PaymentLineDraft>(
      context: context,
      builder: (BuildContext context) => _PaymentLineDialog(
        initial: base,
        paymentMethods: widget.paymentMethods,
        currencies: _allCurrencies,
        suggestedValues: _previewValues,
        pricingSnapshot: _draftSnapshot,
      ),
    );
    if (edited == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _lines.add(edited);
      } else {
        _lines[index] = edited;
      }
      _paidAt = edited.paidAt;
    });
  }

  String get _defaultMethodCode {
    if (widget.paymentMethods.isEmpty) {
      return 'cash';
    }
    return widget.paymentMethods.first.code;
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  void _save() {
    final WorkOrderPricingSnapshot snapshot = _draftSnapshot;
    if (_localCurrencyCode.trim().isEmpty ||
        _foreignCurrencyCode.trim().isEmpty) {
      _show('Debes definir las monedas de cobro.');
      return;
    }
    if (_localCurrencyCode == _foreignCurrencyCode) {
      _show('La moneda local y la extranjera deben ser distintas.');
      return;
    }
    final List<WorkOrderRecordedPaymentLine> lines = _previewPaymentLines;
    Navigator.of(context).pop(
      WorkOrderPaymentUpdateInput(
        paymentStatus: _derivedPaymentStatus,
        pricingSnapshot: snapshot,
        paymentLines: lines,
        paidAt: lines.isNotEmpty ? _paidAt : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pagos y cotización',
      currentRoute: '/pedidos-cobro',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        TextButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
        const SizedBox(width: 8),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: <Widget>[
          _SectionCard(
            title: 'Estado del cobro',
            subtitle: widget.orderFolio,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _paymentStatusHint(_derivedPaymentStatus),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusPill(
                      label: WorkOrderPaymentStatusCatalog.label(
                        _derivedPaymentStatus,
                      ),
                      status: _derivedPaymentStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('Fecha del cobro'),
                  subtitle: Text(
                    _fmtDateTime(_paidAt),
                  ),
                  trailing: OutlinedButton(
                    onPressed: _pickPaidAt,
                    child: const Text('Elegir'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Valores del pedido',
            subtitle: 'Total y saldo pendiente según la cotización del pedido.',
            child: Column(
              children: _previewValues.map(
                (WorkOrderPaymentValue row) {
                  final int remainingCents = _remainingForVariant(row);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      row.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _previewPaymentLines.isEmpty
                          ? 'Pendiente: ${_formatMoney(row.amountCents, row.currencyCode)}'
                          : 'Pendiente: ${_formatMoney(remainingCents, row.currencyCode)}',
                      style: TextStyle(
                        color: remainingCents <= 0
                            ? const Color(0xFF047857)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: Text(
                      _formatMoney(row.amountCents, row.currencyCode),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1152D4),
                      ),
                    ),
                  );
                },
              ).toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Pagos registrados',
            subtitle: 'Puedes registrar varias líneas con distintos métodos.',
            action: FilledButton.icon(
              onPressed: () => _editLine(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir pago'),
            ),
            child: _lines.isEmpty
                ? const Text(
                    'Aun no se han registrado líneas de pago para este pedido.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    children: _lines.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final _PaymentLineDraft line = entry.value;
                      final WorkOrderRecordedPaymentLine previewLine =
                          line.toModel(widget.paymentMethods, _draftSnapshot);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => _editLine(index: index),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _removeLine(index),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatMoney(line.amountCents, line.currencyCode)} · ${line.currencyCode}',
                              style: const TextStyle(
                                color: Color(0xFF1152D4),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (previewLine.primaryCurrencyCode !=
                                previewLine.currencyCode) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                'Equiv. ${previewLine.primaryCurrencyCode}: ${_formatMoney(previewLine.equivalentAmountCents, previewLine.primaryCurrencyCode)}',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tasa aplicada: 1 ${previewLine.currencyCode} = ${previewLine.appliedRateToPrimary.toStringAsFixed(2)} ${previewLine.primaryCurrencyCode}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              _fmtDateTime(line.paidAt),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((line.transactionId ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Transacción: ${line.transactionId}',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if ((line.quoteLabel ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Variante usada: ${line.quoteLabel}',
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if ((line.note ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  line.note!,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(int cents, String currencyCode) {
    final String symbol = widget.currencyConfig.symbolForCode(currencyCode);
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _fmtDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  double _roundTo2(double value) => (value * 100).round() / 100;

  double _roundRatePrecision(double value) =>
      (value * 100000000).round() / 100000000;
}

String _paymentStatusHint(String status) {
  switch (status) {
    case WorkOrderPaymentStatusCatalog.paid:
      return 'La suma de los pagos ya cubre el valor del pedido.';
    case WorkOrderPaymentStatusCatalog.partial:
      return 'El pedido tiene pagos registrados, pero todavía no cubren el valor total.';
    case WorkOrderPaymentStatusCatalog.unpaid:
    default:
      return 'El pedido seguirá pendiente de pago hasta que registres al menos una línea de pago.';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
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
              if (action != null) ...<Widget>[
                const SizedBox(width: 12),
                action!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg}) palette = _paymentStatusPalette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

({Color bg, Color fg}) _paymentStatusPalette(String status) {
  switch (status) {
    case WorkOrderPaymentStatusCatalog.paid:
      return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF047857));
    case WorkOrderPaymentStatusCatalog.partial:
      return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    case WorkOrderPaymentStatusCatalog.unpaid:
    default:
      return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
  }
}

class _PaymentLineDraft {
  const _PaymentLineDraft({
    required this.methodCode,
    required this.methodLabel,
    required this.currencyCode,
    required this.amountCents,
    required this.paidAt,
    this.quoteLabel,
    this.transactionId,
    this.note,
  });

  factory _PaymentLineDraft.empty(
    String methodCode, {
    DateTime? paidAt,
  }) {
    return _PaymentLineDraft(
      methodCode: methodCode,
      methodLabel: defaultPaymentMethodLabel(methodCode),
      currencyCode: 'CUP',
      amountCents: 0,
      paidAt: paidAt ?? DateTime.now(),
    );
  }

  factory _PaymentLineDraft.fromModel(WorkOrderRecordedPaymentLine line) {
    return _PaymentLineDraft(
      methodCode: line.methodCode,
      methodLabel: line.methodLabel,
      currencyCode: line.currencyCode,
      amountCents: line.enteredAmountCents,
      paidAt: line.paidAt,
      quoteLabel: line.quoteLabel,
      transactionId: line.transactionId,
      note: line.note,
    );
  }

  final String methodCode;
  final String methodLabel;
  final String currencyCode;
  final int amountCents;
  final DateTime paidAt;
  final String? quoteLabel;
  final String? transactionId;
  final String? note;

  WorkOrderRecordedPaymentLine toModel(
    List<AppPaymentMethodSetting> methods,
    WorkOrderPricingSnapshot pricingSnapshot,
  ) {
    final AppPaymentMethodSetting? selected =
        methods.cast<AppPaymentMethodSetting?>().firstWhere(
              (AppPaymentMethodSetting? item) => item?.code == methodCode,
              orElse: () => null,
            );
    final String primaryCurrencyCode =
        pricingSnapshot.primaryCurrencyCode.trim().toUpperCase();
    final double rateToPrimary = _paymentLineRateToPrimary(
      currencyCode: currencyCode,
      pricingSnapshot: pricingSnapshot,
    );
    final int equivalentAmountCents = _paymentLineEquivalentToPrimary(
      amountCents: amountCents,
      currencyCode: currencyCode,
      pricingSnapshot: pricingSnapshot,
    );
    return WorkOrderRecordedPaymentLine(
      methodCode: methodCode,
      methodLabel: selected?.label ?? methodLabel,
      currencyCode: currencyCode,
      enteredAmountCents: amountCents,
      primaryCurrencyCode: primaryCurrencyCode,
      equivalentAmountCents: equivalentAmountCents,
      appliedRateToPrimary: rateToPrimary,
      paidAt: paidAt,
      quoteLabel: quoteLabel,
      pricingCapturedAt: pricingSnapshot.capturedAt,
      transactionId: transactionId,
      note: note,
    );
  }
}

class _PaymentLineDialog extends StatefulWidget {
  const _PaymentLineDialog({
    required this.initial,
    required this.paymentMethods,
    required this.currencies,
    required this.suggestedValues,
    required this.pricingSnapshot,
  });

  final _PaymentLineDraft initial;
  final List<AppPaymentMethodSetting> paymentMethods;
  final List<AppCurrencySetting> currencies;
  final List<WorkOrderPaymentValue> suggestedValues;
  final WorkOrderPricingSnapshot pricingSnapshot;

  @override
  State<_PaymentLineDialog> createState() => _PaymentLineDialogState();
}

class _PaymentLineDialogState extends State<_PaymentLineDialog> {
  late String _methodCode;
  late String _currencyCode;
  late DateTime _paidAt;
  late String? _quoteLabel;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _transactionCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _methodCode = widget.initial.methodCode;
    _currencyCode = widget.initial.currencyCode;
    _paidAt = widget.initial.paidAt;
    _quoteLabel = widget.initial.quoteLabel;
    _amountCtrl = TextEditingController(
      text: (widget.initial.amountCents / 100).toStringAsFixed(2),
    );
    _transactionCtrl =
        TextEditingController(text: widget.initial.transactionId ?? '');
    _noteCtrl = TextEditingController(text: widget.initial.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _transactionCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _requiresTransactionId {
    final AppPaymentMethodSetting? method = widget.paymentMethods
        .cast<AppPaymentMethodSetting?>()
        .firstWhere((AppPaymentMethodSetting? row) => row?.code == _methodCode,
            orElse: () => null);
    return method?.isOnline ?? false;
  }

  int get _parsedAmountCents =>
      (((double.tryParse(_amountCtrl.text.trim()) ?? 0) * 100)).round();

  WorkOrderPricingSnapshot get _pricingSnapshot => widget.pricingSnapshot;

  String get _primaryCurrencyCode =>
      _pricingSnapshot.primaryCurrencyCode.trim().toUpperCase();

  int get _equivalentAmountCents => _paymentLineEquivalentToPrimary(
        amountCents: _parsedAmountCents < 0 ? 0 : _parsedAmountCents,
        currencyCode: _currencyCode,
        pricingSnapshot: _pricingSnapshot,
      );

  double get _appliedRateToPrimary => _paymentLineRateToPrimary(
        currencyCode: _currencyCode,
        pricingSnapshot: _pricingSnapshot,
      );

  void _applySuggestedValue(WorkOrderPaymentValue value) {
    setState(() {
      _currencyCode = value.currencyCode;
      _amountCtrl.text = (value.amountCents / 100).toStringAsFixed(2);
      _quoteLabel = value.label;
      final String lowerLabel = value.label.toLowerCase();
      if (lowerLabel.contains('transfer')) {
        final AppPaymentMethodSetting? transfer =
            widget.paymentMethods.cast<AppPaymentMethodSetting?>().firstWhere(
                  (AppPaymentMethodSetting? row) =>
                      (row?.code ?? '').trim().toLowerCase() == 'transfer',
                  orElse: () => null,
                );
        if (transfer != null) {
          _methodCode = transfer.code;
        }
      } else if (lowerLabel.contains('efectivo')) {
        final AppPaymentMethodSetting? cash =
            widget.paymentMethods.cast<AppPaymentMethodSetting?>().firstWhere(
                  (AppPaymentMethodSetting? row) =>
                      (row?.code ?? '').trim().toLowerCase() == 'cash',
                  orElse: () => null,
                );
        if (cash != null) {
          _methodCode = cash.code;
        }
      }
    });
  }

  Future<void> _pickPaidAt() async {
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime(_paidAt.year - 2),
      lastDate: DateTime(_paidAt.year + 2),
      initialDate: _paidAt,
      helpText: 'Fecha del pago',
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_paidAt),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _paidAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save() {
    final int amountCents = _parsedAmountCents;
    if (amountCents <= 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Introduce un monto válido.')),
        );
      return;
    }
    if (_requiresTransactionId && _transactionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Este método requiere ID de transacción.'),
          ),
        );
      return;
    }
    final AppPaymentMethodSetting? method = widget.paymentMethods
        .cast<AppPaymentMethodSetting?>()
        .firstWhere((AppPaymentMethodSetting? row) => row?.code == _methodCode,
            orElse: () => null);
    Navigator.of(context).pop(
      _PaymentLineDraft(
        methodCode: _methodCode,
        methodLabel: method?.label ?? defaultPaymentMethodLabel(_methodCode),
        currencyCode: _currencyCode,
        amountCents: amountCents,
        paidAt: _paidAt,
        quoteLabel: _quoteLabel,
        transactionId: _transactionCtrl.text.trim().isEmpty
            ? null
            : _transactionCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Línea de pago'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              key: ValueKey<String>('method-$_methodCode'),
              initialValue: _methodCode,
              decoration: const InputDecoration(labelText: 'Método'),
              items: widget.paymentMethods
                  .map(
                    (AppPaymentMethodSetting method) =>
                        DropdownMenuItem<String>(
                      value: method.code,
                      child: Text(method.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _methodCode = value;
                  _quoteLabel = null;
                });
              },
            ),
            const SizedBox(height: 12),
            if (widget.suggestedValues.isNotEmpty) ...<Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Usar valor calculado del pedido',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.suggestedValues
                    .map(
                      (WorkOrderPaymentValue value) => ActionChip(
                        label: Text(
                          '${value.label}: ${(value.amountCents / 100).toStringAsFixed(2)}',
                        ),
                        onPressed: () => _applySuggestedValue(value),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              key: ValueKey<String>('currency-$_currencyCode'),
              initialValue: _currencyCode,
              decoration: const InputDecoration(labelText: 'Moneda'),
              items: widget.currencies
                  .map(
                    (AppCurrencySetting currency) => DropdownMenuItem<String>(
                      value: currency.code,
                      child: Text('${currency.code} (${currency.symbol})'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _currencyCode = value;
                  _quoteLabel = null;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto'),
              onChanged: (_) {
                if (_quoteLabel != null) {
                  setState(() => _quoteLabel = null);
                } else {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Resumen de la línea',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Equivalente en $_primaryCurrencyCode: ${_formatMoney(_equivalentAmountCents, _primaryCurrencyCode)}',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tasa aplicada: 1 $_currencyCode = ${_appliedRateToPrimary.toStringAsFixed(2)} $_primaryCurrencyCode',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((_quoteLabel ?? '').trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Variante usada: $_quoteLabel',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _transactionCtrl,
              decoration: InputDecoration(
                labelText: _requiresTransactionId
                    ? 'ID de transacción'
                    : 'Referencia de pago',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Nota'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Fecha del pago'),
              subtitle: Text(_fmtDateTime(_paidAt)),
              trailing: OutlinedButton(
                onPressed: _pickPaidAt,
                child: const Text('Elegir'),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String _fmtDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  String _formatMoney(int cents, String currencyCode) {
    final AppCurrencySetting? setting =
        widget.currencies.cast<AppCurrencySetting?>().firstWhere(
              (AppCurrencySetting? row) => row?.code == currencyCode,
              orElse: () => null,
            );
    final String symbol = setting?.symbol ?? '${currencyCode.toUpperCase()} ';
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
  }
}

double _paymentLineRateToPrimary({
  required String currencyCode,
  required WorkOrderPricingSnapshot pricingSnapshot,
}) {
  final String source = currencyCode.trim().toUpperCase();
  final String primary =
      pricingSnapshot.primaryCurrencyCode.trim().toUpperCase();
  if (source == primary) {
    return 1;
  }
  final double sourceRate = pricingSnapshot.ratesByCode[source] ?? 1;
  final double safeRate = sourceRate <= 0 ? 1 : sourceRate;
  return ((1 / safeRate) * 100).round() / 100;
}

int _paymentLineEquivalentToPrimary({
  required int amountCents,
  required String currencyCode,
  required WorkOrderPricingSnapshot pricingSnapshot,
}) {
  final String source = currencyCode.trim().toUpperCase();
  final String primary =
      pricingSnapshot.primaryCurrencyCode.trim().toUpperCase();
  if (source == primary) {
    return amountCents;
  }
  final double sourceRate = pricingSnapshot.ratesByCode[source] ?? 1;
  final double safeRate = sourceRate <= 0 ? 1 : sourceRate;
  final double sourceAmount = amountCents / 100;
  final double amountInPrimary = sourceAmount / safeRate;
  return (amountInPrimary * 100).round();
}
