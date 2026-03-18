import 'package:flutter/material.dart';
import '../../../reportes/data/reportes_local_datasource.dart';

class HomeRecentActivity extends StatelessWidget {
  final List<RecentSaleStat> recentSales;
  // Podríamos incluir más cosas aquí (movimientos, cierres, etc.), 
  // pero el HTML mock mezcla ventas y entradas de stock. 
  // Vamos a usar la lista de ventas recientes por ahora y darle estilo similar.
  final String Function(int) moneyFormatter;

  const HomeRecentActivity({
    super.key,
    required this.recentSales,
    required this.moneyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVIDAD RECIENTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: 1.5,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1152D4),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ver Todo'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
            boxShadow: isDark
                ? <BoxShadow>[]
                : <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: recentSales.take(3).toList().asMap().entries.map((entry) {
              final int idx = entry.key;
              final RecentSaleStat sale = entry.value;
              return Column(
                children: [
                  _buildActivityItem(
                    title: 'Venta ${sale.folio}',
                    subtitle: 'Caja: ${sale.cashierUsername} • ID: ${sale.saleId}',
                    amount: moneyFormatter(sale.totalCents),
                    status: 'COMPLETADO',
                    isDark: isDark,
                  ),
                  if (idx < (recentSales.length > 3 ? 2 : recentSales.length - 1))
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String amount,
    required String status,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
