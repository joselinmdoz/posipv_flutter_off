import 'package:flutter/material.dart';

import '../../data/configuracion_local_datasource.dart';

class CurrencyRateTile extends StatelessWidget {
  const CurrencyRateTile({
    super.key,
    required this.currency,
    required this.primaryCode,
    required this.onEdit,
    required this.onSetPrimary,
    required this.onRemove,
  });

  final AppCurrencySetting currency;
  final String primaryCode;
  final VoidCallback onEdit;
  final VoidCallback onSetPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = currency.code == primaryCode;
    String subtitle = 'Moneda principal';
    if (!isPrimary) {
      final double safeRate =
          currency.rateToPrimary > 0 ? currency.rateToPrimary : 1;
      if (primaryCode == 'CUP' && currency.code != 'CUP') {
        subtitle = '1 ${currency.code} = ${(1 / safeRate).toStringAsFixed(2)} '
            '$primaryCode';
      } else {
        subtitle =
            '1 $primaryCode = ${safeRate.toStringAsFixed(2)} ${currency.code}';
      }
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(currency.symbol),
        ),
        title: Text(
          '${currency.code} (${currency.symbol})',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (String value) {
            switch (value) {
              case 'edit':
                onEdit();
                return;
              case 'primary':
                onSetPrimary();
                return;
              case 'remove':
                onRemove();
                return;
              default:
                return;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Editar'),
            ),
            if (!isPrimary)
              const PopupMenuItem<String>(
                value: 'primary',
                child: Text('Hacer principal'),
              ),
            if (!isPrimary)
              const PopupMenuItem<String>(
                value: 'remove',
                child: Text('Eliminar'),
              ),
          ],
        ),
      ),
    );
  }
}
