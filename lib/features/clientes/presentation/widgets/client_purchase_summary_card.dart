import 'package:flutter/material.dart';

class ClientPurchaseSummaryCard extends StatelessWidget {
  const ClientPurchaseSummaryCard({
    super.key,
    required this.totalCents,
    required this.lastPurchaseAt,
    required this.currencySymbol,
  });

  final int totalCents;
  final DateTime? lastPurchaseAt;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0E46BD), Color(0xFF1152D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'RESUMEN DE COMPRAS',
                  style: TextStyle(
                    color: Color(0xFFC7D7FF),
                    fontSize: 12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.payments_outlined,
                color: Colors.white.withValues(alpha: 0.74),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _money(totalCents),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46 / 2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inversion total acumulada',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    lastPurchaseAt == null ? '--' : _dateLabel(lastPurchaseAt!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Ultima compra',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(int cents) {
    return '$currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _dateLabel(DateTime date) {
    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final DateTime d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}, ${d.year}';
  }
}
