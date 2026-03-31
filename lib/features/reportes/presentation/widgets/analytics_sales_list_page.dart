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
    this.title = 'Total de ventas',
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
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AnalyticsSaleDetailPage(
          saleId: sale.saleId,
          currencySymbol: widget.currencySymbol,
        ),
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Colores basados en el HTML
    final Color primaryNavy = const Color(0xFF1E3A8A); // primary
    final Color accentBlue = const Color(0xFF3B82F6); // accent
    final Color backgroundPage =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF4); // slate-900 / slate-50
    final Color cardBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF); // slate-800 / white
    final Color borderCol =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0); // slate-700 / slate-200
    final Color textMuted =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // slate-400 / slate-500

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
        icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/ventas-pos'),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: Container(
        color: backgroundPage,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sales.isEmpty
                ? const Center(child: Text('No hay ventas en este período.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemBuilder: (BuildContext context, int index) {
                        final SalesAnalyticsSaleStat sale = _sales[index];
                        return _buildSaleCard(
                          context,
                          sale,
                          isDark,
                          primaryNavy,
                          accentBlue,
                          cardBg,
                          borderCol,
                          textMuted,
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemCount: _sales.length,
                    ),
                  ),
      ),
    );
  }

  Widget _buildSaleCard(
    BuildContext context,
    SalesAnalyticsSaleStat sale,
    bool isDark,
    Color primaryNavy,
    Color accentBlue,
    Color cardBg,
    Color borderCol,
    Color textMuted,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(sale),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Row 1: Folio and Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.folio,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? accentBlue : primaryNavy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateTime(sale.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE), // blue-100
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
                    ),
                    child: const Text(
                      'POS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E40AF), // blue-800
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Field Info
              _buildInfoRow('Dependiente:', sale.cashierUsername, textMuted, isDark),
              const SizedBox(height: 4),
              _buildInfoRow('Almacén:', sale.warehouseName, textMuted, isDark),
              const SizedBox(height: 4),
              _buildInfoRow(
                'Cliente:',
                sale.customerName ?? 'Sin cliente',
                textMuted,
                isDark,
                italic: sale.customerName == null,
              ),
              const SizedBox(height: 16),
              // Footer
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${sale.itemsCount} líneas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                    Text(
                      _money(sale.totalCents),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textMuted, bool isDark,
      {bool italic = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: italic
                  ? textMuted.withValues(alpha: 0.7)
                  : (isDark ? Colors.white : Colors.black87),
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
