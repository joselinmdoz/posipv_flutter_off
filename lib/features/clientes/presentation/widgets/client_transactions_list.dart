import 'package:flutter/material.dart';

import '../../data/clientes_local_datasource.dart';

class ClientTransactionsList extends StatelessWidget {
  const ClientTransactionsList({
    super.key,
    required this.transactions,
    required this.currencySymbol,
  });

  final List<ClienteTransactionItem> transactions;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Ultimas Transacciones',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF30384A),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: Color(0xFF1152D4),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E9F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: const Text(
              'Sin transacciones registradas para este cliente.',
              style: TextStyle(
                color: Color(0xFF6B7486),
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Column(
            children:
                transactions.take(5).toList().asMap().entries.map((entry) {
              final int index = entry.key;
              final ClienteTransactionItem row = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10),
                child: _transactionTile(row, index == 0),
              );
            }).toList(growable: false),
          ),
      ],
    );
  }

  Widget _transactionTile(ClienteTransactionItem row, bool highlight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: <Widget>[
          if (highlight)
            Container(
              width: 3,
              height: 48,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1152D4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          if (!highlight) const SizedBox(width: 2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(row.iconKey),
              color: const Color(0xFF1152D4),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF11141A),
                  ),
                ),
                Text(
                  _dateLabel(row.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7486),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$currencySymbol${(row.totalCents / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18 / 2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11141A),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String iconKey) {
    switch (iconKey) {
      case 'devices':
        return Icons.devices_rounded;
      case 'support':
        return Icons.support_agent_rounded;
      case 'receipt':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _dateLabel(DateTime date) {
    const List<String> months = <String>[
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final DateTime d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} de ${months[d.month - 1]}, ${d.year}';
  }
}
