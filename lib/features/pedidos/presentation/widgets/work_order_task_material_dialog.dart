import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_searchable_select_field.dart';
import '../../data/pedidos_local_datasource.dart';

class WorkOrderTaskMaterialDialog extends StatefulWidget {
  const WorkOrderTaskMaterialDialog({
    super.key,
    required this.options,
    this.initialItem,
    this.titleOverride,
    this.quantityLabel,
  });

  final List<WorkOrderProductOption> options;
  final WorkOrderTaskMaterialItem? initialItem;
  final String? titleOverride;
  final String? quantityLabel;

  @override
  State<WorkOrderTaskMaterialDialog> createState() =>
      _WorkOrderTaskMaterialDialogState();
}

class _WorkOrderTaskMaterialDialogState
    extends State<WorkOrderTaskMaterialDialog> {
  static const String _none = '__none__';

  late final TextEditingController _qtyCtrl;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  String _selectedProductId = _none;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: _formatQty(widget.initialItem?.qty ?? 1),
    );
    _widthCtrl = TextEditingController(
      text: _formatNullable(widget.initialItem?.widthMeters),
    );
    _heightCtrl = TextEditingController(
      text: _formatNullable(widget.initialItem?.heightMeters),
    );
    _selectedProductId = widget.initialItem?.productId ?? _none;
    _recalculateArea();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
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

  bool get _usesSquareMeters {
    final WorkOrderProductOption? product = _selectedProduct;
    if (product == null) {
      return false;
    }
    final String unit = product.unitMeasure.trim().toLowerCase();
    return unit.contains('m2') ||
        unit.contains('m²') ||
        unit.contains('metro cuadrado') ||
        unit.contains('metros cuadrados');
  }

  double get _widthValue => _parse(_widthCtrl.text);
  double get _heightValue => _parse(_heightCtrl.text);

  void _recalculateArea() {
    if (!_usesSquareMeters) {
      return;
    }
    final double width = _widthValue;
    final double height = _heightValue;
    if (width > 0 && height > 0) {
      _qtyCtrl.text = _formatQty(_roundTo2(width * height));
    } else {
      _qtyCtrl.text = '';
    }
  }

  void _submit() {
    final WorkOrderProductOption? product = _selectedProduct;
    if (product == null) {
      setState(() => _error = 'Selecciona un material o producto.');
      return;
    }
    double qty = _roundTo2(_parse(_qtyCtrl.text));
    double? widthMeters;
    double? heightMeters;
    double? areaSqm;
    if (_usesSquareMeters) {
      widthMeters = _roundTo2(_widthValue);
      heightMeters = _roundTo2(_heightValue);
      if (widthMeters <= 0 || heightMeters <= 0) {
        setState(() => _error = 'Indica ancho y largo para calcular el area.');
        return;
      }
      areaSqm = _roundTo2(widthMeters * heightMeters);
      qty = areaSqm;
    }
    if (qty <= 0) {
      setState(() => _error = 'La cantidad debe ser mayor que 0.');
      return;
    }
    Navigator.of(context).pop(
      WorkOrderTaskMaterialItem(
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        unitLabel: product.unitMeasure,
        qty: qty,
        widthMeters: widthMeters,
        heightMeters: heightMeters,
        areaSqm: areaSqm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.titleOverride ??
            (widget.initialItem == null
                ? 'Agregar material'
                : 'Editar material'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSearchableSelectField<String>(
              label: 'Producto o material',
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
                  _recalculateArea();
                });
              },
            ),
            const SizedBox(height: 12),
            if (_usesSquareMeters) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _widthCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(_recalculateArea),
                      decoration: const InputDecoration(
                        labelText: 'Ancho (m)',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _heightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(_recalculateArea),
                      decoration: const InputDecoration(
                        labelText: 'Largo (m)',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyCtrl,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Area calculada',
                  hintText: '0.00',
                  suffixText: 'm²',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else
              TextField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.quantityLabel ?? 'Cantidad utilizada',
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

  double _parse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _roundTo2(double value) {
    return (value * 100).round() / 100;
  }

  String _formatQty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatNullable(double? value) {
    if (value == null || value <= 0) {
      return '';
    }
    return _formatQty(value);
  }
}
