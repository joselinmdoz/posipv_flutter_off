import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/reportes_local_datasource.dart';
import '../reportes_providers.dart';
import 'analytics_sale_detail_page.dart';

class AnalyticsSalesListPage extends ConsumerStatefulWidget {
  const AnalyticsSalesListPage({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.currencySymbol,
    this.title = 'Ventas del período',
    this.channel,
    this.paymentMethodKey,
    this.dependentKey,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String currencySymbol;
  final String title;
  final String? channel;
  final String? paymentMethodKey;
  final String? dependentKey;

  @override
  ConsumerState<AnalyticsSalesListPage> createState() =>
      _AnalyticsSalesListPageState();
}

class _AnalyticsSalesListPageState
    extends ConsumerState<AnalyticsSalesListPage> {
  List<SalesAnalyticsSaleStat> _sales = <SalesAnalyticsSaleStat>[];
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
      final List<SalesAnalyticsSaleStat> rows = await ref
          .read(reportesLocalDataSourceProvider)
          .listSalesForAnalyticsRange(
            fromDate: widget.fromDate,
            toDate: widget.toDate,
            limit: 1000,
            channel: widget.channel,
            paymentMethodKey: widget.paymentMethodKey,
            dependentKey: widget.dependentKey,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _sales = rows;
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
          SnackBar(content: Text('No se pudo cargar ventas: $e')),
        );
    }
  }

  String _money(int cents) {
    return '${widget.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
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

  Future<void> _openDetail(SalesAnalyticsSaleStat sale) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalyticsSaleDetailPage(
          saleId: sale.saleId,
          currencySymbol: widget.currencySymbol,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: widget.title,
      currentRoute: '/reportes',
      showDrawer: false,
      onRefresh: _load,
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
          : _sales.isEmpty
              ? const Center(child: Text('No hay ventas en este período.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemBuilder: (BuildContext context, int index) {
                      final SalesAnalyticsSaleStat sale = _sales[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openDetail(sale),
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF263244)
                                    : const Color(0xFFD8E0EC),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        sale.folio,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        color: sale.channel == 'pos'
                                            ? const Color(0xFFE0EBFF)
                                            : const Color(0xFFDCFCE7),
                                      ),
                                      child: Text(
                                        sale.channel == 'pos'
                                            ? 'POS'
                                            : 'DIRECTA',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: sale.channel == 'pos'
                                              ? const Color(0xFF1152D4)
                                              : const Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _dateTime(sale.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Dependiente: ${sale.cashierUsername}'),
                                Text('Almacén: ${sale.warehouseName}'),
                                Text(
                                  'Cliente: ${sale.customerName ?? 'Sin cliente'}',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      '${sale.itemsCount} líneas',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _money(sale.totalCents),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _sales.length,
                  ),
                ),
    );
  }
}
