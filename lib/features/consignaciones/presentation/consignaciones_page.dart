import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/licensing/license_providers.dart';
import '../../../core/security/app_permissions.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
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
      final ConsignmentDebtOverview data = await ref
          .read(consignacionesLocalDataSourceProvider)
          .loadDebtOverview();
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = data;
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
        (session?.hasPermission(AppPermissionKeys.salesPos) == true ||
            session?.hasPermission(AppPermissionKeys.salesDirect) == true);
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
