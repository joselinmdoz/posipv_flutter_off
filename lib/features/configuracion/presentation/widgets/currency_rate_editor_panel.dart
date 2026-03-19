import 'package:flutter/material.dart';

import '../../data/configuracion_local_datasource.dart';

class CurrencyRateEditorPanel extends StatelessWidget {
  const CurrencyRateEditorPanel({
    super.key,
    required this.enabled,
    required this.primaryCode,
    required this.currencies,
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.rateController,
    required this.onFromCurrencyChanged,
    required this.onToCurrencyChanged,
    required this.onApplyRate,
  });

  final bool enabled;
  final String primaryCode;
  final List<AppCurrencySetting> currencies;
  final String? fromCurrencyCode;
  final String? toCurrencyCode;
  final TextEditingController rateController;
  final ValueChanged<String?> onFromCurrencyChanged;
  final ValueChanged<String?> onToCurrencyChanged;
  final VoidCallback onApplyRate;

  @override
  Widget build(BuildContext context) {
    if (currencies.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Se necesitan al menos dos monedas para definir una tasa.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Define equivalencias entre dos monedas. Ejemplo recomendado: 1 USD = 380.00 CUP.',
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: fromCurrencyCode,
                    decoration: const InputDecoration(
                      labelText: 'Moneda 1',
                    ),
                    items: currencies
                        .map(
                          (AppCurrencySetting currency) =>
                              DropdownMenuItem<String>(
                            value: currency.code,
                            child: Text(
                              '${currency.code} (${currency.symbol})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: enabled ? onFromCurrencyChanged : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: toCurrencyCode,
                    decoration: const InputDecoration(
                      labelText: 'Moneda 2',
                    ),
                    items: currencies
                        .where((AppCurrencySetting c) =>
                            c.code != fromCurrencyCode)
                        .map(
                          (AppCurrencySetting currency) =>
                              DropdownMenuItem<String>(
                            value: currency.code,
                            child: Text(
                              '${currency.code} (${currency.symbol})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: enabled ? onToCurrencyChanged : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateController,
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Equivalencia',
                hintText: '1.0',
                helperText:
                    '1 ${fromCurrencyCode ?? '-'} = X ${toCurrencyCode ?? '-'}',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enabled ? onApplyRate : null,
                child: const Text('Aplicar tasa'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Moneda principal actual: $primaryCode',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Si una de las monedas es CUP, se mostrara como destino (Moneda 2) para facilitar lectura.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
