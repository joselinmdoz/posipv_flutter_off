import 'package:flutter/material.dart';

import '../../data/configuracion_local_datasource.dart';

class PaymentMethodsConfigDialog extends StatefulWidget {
  const PaymentMethodsConfigDialog({
    super.key,
    required this.initialMethods,
  });

  final List<AppPaymentMethodSetting> initialMethods;

  @override
  State<PaymentMethodsConfigDialog> createState() =>
      _PaymentMethodsConfigDialogState();
}

class _PaymentMethodsConfigDialogState
    extends State<PaymentMethodsConfigDialog> {
  late final List<AppPaymentMethodSetting> _methods;

  @override
  void initState() {
    super.initState();
    _methods = widget.initialMethods
        .map(
          (AppPaymentMethodSetting row) => AppPaymentMethodSetting(
            code: row.code,
            isOnline: row.isOnline,
          ),
        )
        .toList(growable: true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestion de metodos de pago'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Marca como online los metodos que deben solicitar ID de transaccion al cobrar.',
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _methods.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final AppPaymentMethodSetting method = _methods[index];
                  return SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: method.isOnline,
                    title: Text(_labelForCode(method.code)),
                    subtitle: Text(
                      method.isOnline
                          ? 'Solicita ID de transaccion'
                          : 'No solicita ID de transaccion',
                    ),
                    onChanged: (bool value) {
                      setState(() {
                        _methods[index] = method.copyWith(isOnline: value);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_methods);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String _labelForCode(String code) {
    switch (code.trim().toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'wallet':
        return 'Billetera';
      case 'consignment':
        return 'Consignación';
      default:
        return code.trim().isEmpty ? 'Metodo' : code.trim();
    }
  }
}
