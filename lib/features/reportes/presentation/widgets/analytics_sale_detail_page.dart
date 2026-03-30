import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/reportes_local_datasource.dart';
import '../reportes_providers.dart';

class AnalyticsSaleDetailPage extends ConsumerStatefulWidget {
  const AnalyticsSaleDetailPage({
    super.key,
    required this.saleId,
    required this.currencySymbol,
  });

  final String saleId;
  final String currencySymbol;

  @override
  ConsumerState<AnalyticsSaleDetailPage> createState() =>
      _AnalyticsSaleDetailPageState();
}

class _AnalyticsSaleDetailPageState
    extends ConsumerState<AnalyticsSaleDetailPage> {
  SalesAnalyticsSaleDetailStat? _detail;
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
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final SalesAnalyticsSaleDetailStat? detail = await ref
          .read(reportesLocalDataSourceProvider)
          .getSaleDetailForAnalytics(widget.saleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('No se pudo cargar detalle de venta: $e')),
        );
    }
  }

  String _money(int cents) {
    return '${widget.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
  }

  String _qty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.0001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _dateTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
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
        return clean.isEmpty ? 'Pago' : clean;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SalesAnalyticsSaleDetailStat? detail = _detail;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Detalle de Venta',
      currentRoute: '/reportes',
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
            return;
          }
          context.go('/reportes');
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(child: Text('No se encontró la venta.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                            detail.sale.folio,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Fecha: ${_dateTime(detail.sale.createdAt)}'),
                          Text('Canal: ${detail.sale.channel.toUpperCase()}'),
                          Text('Dependiente: ${detail.sale.cashierUsername}'),
                          Text('Almacén: ${detail.sale.warehouseName}'),
                          if ((detail.sale.terminalName ?? '')
                              .trim()
                              .isNotEmpty)
                            Text('TPV: ${detail.sale.terminalName}'),
                          Text(
                            'Cliente: ${detail.sale.customerName ?? 'Sin cliente'}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                          const Text(
                            'Productos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (detail.lines.isEmpty)
                            const Text('Sin productos.')
                          else
                            ...detail.lines.map(
                              (SalesAnalyticsSaleLineStat row) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            row.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'SKU: ${row.sku} · ${_qty(row.qty)} x ${_money(row.unitPriceCents)}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _money(row.lineTotalCents),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                          const Text(
                            'Pagos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (detail.payments.isEmpty)
                            const Text('Sin pagos registrados.')
                          else
                            ...detail.payments.map(
                              (SalesAnalyticsSalePaymentStat row) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            _paymentMethodLabel(row.method),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if ((row.transactionId ?? '')
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              'Código: ${row.transactionId}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _money(row.amountCents),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF263244)
                              : const Color(0xFFD8E0EC),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          _TotalRow(
                              label: 'Subtotal',
                              value: _money(detail.subtotalCents)),
                          _TotalRow(
                              label: 'Impuesto',
                              value: _money(detail.taxCents)),
                          const Divider(height: 16),
                          _TotalRow(
                            label: 'Total',
                            value: _money(detail.totalCents),
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color valueColor = highlight
        ? const Color(0xFF1152D4)
        : Theme.of(context).textTheme.bodyMedium?.color ??
            const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
