import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_searchable_select_field.dart';
import '../../data/pedidos_local_datasource.dart';

class WorkOrderProductItemDialog extends StatefulWidget {
  const WorkOrderProductItemDialog({
    super.key,
    required this.options,
    this.initialItem,
  });

  final List<WorkOrderProductOption> options;
  final WorkOrderProductItem? initialItem;

  @override
  State<WorkOrderProductItemDialog> createState() =>
      _WorkOrderProductItemDialogState();
}

class _WorkOrderProductItemDialogState
    extends State<WorkOrderProductItemDialog> {
  static const String _none = '__none__';

  late final TextEditingController _qtyCtrl;
  String _selectedProductId = _none;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: _formatQty(widget.initialItem?.qty ?? 1),
    );
    _selectedProductId = widget.initialItem?.productId ?? _none;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  WorkOrderProductOption? get _selectedProduct {
    for (final WorkOrderProductOption option in widget.options) {
      if (option.id == _selectedProductId) {
        return option;
      }
    }
    return null;
  }

  void _submit() {
    final WorkOrderProductOption? product = _selectedProduct;
    if (product == null) {
      setState(() => _error = 'Selecciona un producto.');
      return;
    }
    final double qty = _roundTo2(double.tryParse(
          _qtyCtrl.text.trim().replaceAll(',', '.'),
        ) ??
        0);
    if (qty <= 0) {
      setState(() => _error = 'La cantidad debe ser mayor que 0.');
      return;
    }
    Navigator.of(context).pop(
      WorkOrderProductItem(
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        unitLabel: product.unitMeasure,
        qty: qty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialItem == null ? 'Agregar producto' : 'Editar producto',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSearchableSelectField<String>(
              label: 'Producto',
              value: _selectedProductId,
              hintText: 'Selecciona un producto',
              options: <AppSearchableSelectOption<String>>[
                const AppSearchableSelectOption<String>(
                  value: _none,
                  label: 'Seleccionar',
                ),
                ...widget.options.map(
                  (WorkOrderProductOption option) =>
                      AppSearchableSelectOption<String>(
                    value: option.id,
                    label: option.name,
                    subtitle: '${option.sku} · ${option.unitMeasure}',
                    searchText:
                        '${option.name} ${option.sku} ${option.unitMeasure}',
                  ),
                ),
              ],
              onChanged: (String value) {
                setState(() {
                  _selectedProductId = value;
                  _error = '';
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad',
                hintText: '1',
                helperText: _selectedProduct == null
                    ? null
                    : 'Unidad: ${_selectedProduct!.unitMeasure}',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String _formatQty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  double _roundTo2(double value) {
    return (value * 100).round() / 100;
  }
}
