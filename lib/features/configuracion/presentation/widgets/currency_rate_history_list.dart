import 'package:flutter/material.dart';

import '../../data/configuracion_local_datasource.dart';

class CurrencyRateHistoryList extends StatelessWidget {
  const CurrencyRateHistoryList({
    super.key,
    required this.history,
  });

  final List<AppExchangeRateHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aun no hay historial de tasas de cambio.'),
        ),
      );
    }

    final List<AppExchangeRateHistoryEntry> recent =
        history.length <= 20 ? history : history.sublist(0, 20);
    return Card(
      child: Column(
        children: recent.map((AppExchangeRateHistoryEntry entry) {
          final double safeRate = entry.rateToBase > 0 ? entry.rateToBase : 1;
          final String titleText = entry.baseCurrencyCode == 'CUP' &&
                  entry.currencyCode != 'CUP'
              ? '1 ${entry.currencyCode} = ${(1 / safeRate).toStringAsFixed(2)} ${entry.baseCurrencyCode}'
              : '1 ${entry.baseCurrencyCode} = ${safeRate.toStringAsFixed(2)} ${entry.currencyCode}';
          return ListTile(
            dense: true,
            leading: const Icon(Icons.history_rounded),
            title: Text(titleText),
            subtitle: Text(_formatDateTime(entry.changedAt.toLocal())),
          );
        }).toList(),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    final String hh = date.hour.toString().padLeft(2, '0');
    final String mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
