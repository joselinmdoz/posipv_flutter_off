import 'package:flutter/material.dart';

import '../../data/consignaciones_local_datasource.dart';
import 'consignment_sale_tile.dart';

class ConsignmentCustomerCard extends StatelessWidget {
  const ConsignmentCustomerCard({
    super.key,
    required this.customer,
    required this.primaryCurrencySymbol,
    required this.onOpenSale,
  });

  final ConsignmentCustomerDebt customer;
  final String primaryCurrencySymbol;
  final void Function(ConsignmentSaleDebt sale) onOpenSale;

  String _money(int cents, String symbol) {
    return '$symbol${(cents / 100).toStringAsFixed(2)}';
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
        children: customer.sales
            .map(
              (ConsignmentSaleDebt sale) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ConsignmentSaleTile(
                  sale: sale,
                  onTap: () => onOpenSale(sale),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
