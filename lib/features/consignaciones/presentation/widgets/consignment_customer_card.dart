import 'package:flutter/material.dart';

import '../../data/consignaciones_local_datasource.dart';
import 'consignment_sale_tile.dart';

class ConsignmentCustomerCard extends StatelessWidget {
  const ConsignmentCustomerCard({
    super.key,
    required this.customer,
    required this.primaryCurrencySymbol,
    required this.onOpenSale,
    required this.onReconcileCustomer,
    required this.onChangeSaleCustomer,
  });

  final ConsignmentCustomerDebt customer;
  final String primaryCurrencySymbol;
  final void Function(ConsignmentSaleDebt sale) onOpenSale;
  final VoidCallback onReconcileCustomer;
  final void Function(ConsignmentSaleDebt sale, String currentCustomerId)
      onChangeSaleCustomer;

  String _money(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFDDE5F2),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        iconColor: const Color(0xFF1152D4),
        collapsedIconColor: const Color(0xFF1152D4),
        title: Text(
          customer.customerName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          customer.customerPhone?.trim().isNotEmpty == true
              ? customer.customerPhone!.trim()
              : '${customer.sales.length} venta(s) pendiente(s)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        trailing: Text(
          _money(customer.pendingPrimaryCents, primaryCurrencySymbol),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFFB91C1C),
          ),
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Resumen',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      'Pagado ${_money(customer.totalPaidPrimaryCents, primaryCurrencySymbol)} de ${_money(customer.totalConsignedPrimaryCents, primaryCurrencySymbol)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReconcileCustomer,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Conciliar cliente'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...customer.sales.map(
            (ConsignmentSaleDebt sale) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ConsignmentSaleTile(
                sale: sale,
                onTap: () => onOpenSale(sale),
                onChangeCustomer: () =>
                    onChangeSaleCustomer(sale, customer.customerId),
              ),
            ),
          ),
          if (customer.paymentSummary.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'Pagos recientes',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            ...customer.paymentSummary.take(4).map(
                  (ConsignmentCustomerPaymentRecord row) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _date(row.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Text(
                          _money(row.amountCents, row.currencySymbol),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
