import 'package:flutter/material.dart';

import '../../data/consignaciones_local_datasource.dart';

class ConsignmentSaleTile extends StatelessWidget {
  const ConsignmentSaleTile({
    super.key,
    required this.sale,
    required this.onTap,
  });

  final ConsignmentSaleDebt sale;
  final VoidCallback onTap;

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  _money(sale.pendingCents, sale.currencySymbol),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _date(sale.createdAt),
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${sale.channel == 'pos' ? 'POS' : 'DIRECTA'} • ${sale.warehouseName}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Pagado ${_money(sale.paidCents, sale.currencySymbol)} / Total ${_money(sale.totalCents, sale.currencySymbol)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Conciliar',
                  style: TextStyle(
                    color: Color(0xFF1152D4),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
