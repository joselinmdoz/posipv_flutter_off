import 'package:flutter/material.dart';

import '../../data/configuracion_local_datasource.dart';

class CurrencyEditorDialog extends StatefulWidget {
  const CurrencyEditorDialog({
    super.key,
    this.initialCurrency,
    required this.existingCodes,
  });

  final AppCurrencySetting? initialCurrency;
  final Set<String> existingCodes;

  @override
  State<CurrencyEditorDialog> createState() => _CurrencyEditorDialogState();
}

class _CurrencyEditorDialogState extends State<CurrencyEditorDialog> {
  static const String _customSymbolValue = '__custom__';
  static const List<_CurrencySymbolPreset> _symbolPresets =
      <_CurrencySymbolPreset>[
    _CurrencySymbolPreset(label: r'USD ($)', symbol: r'$'),
    _CurrencySymbolPreset(label: 'EUR (€)', symbol: '€'),
    _CurrencySymbolPreset(label: 'CUP (₱)', symbol: '₱'),
  ];
  static const Map<String, String> _commonSymbolByCode = <String, String>{
    'USD': r'$',
    'EUR': '€',
    'CUP': '₱',
  };

  late final TextEditingController _codeCtrl;
  late final TextEditingController _customSymbolCtrl;
  late String _selectedSymbolValue;
  String? _error;

  bool get _isEditing => widget.initialCurrency != null;

  @override
  void initState() {
    super.initState();
    final AppCurrencySetting? initial = widget.initialCurrency;
    _codeCtrl = TextEditingController(text: initial?.code ?? '');
    final String initialSymbol = (initial?.symbol ?? '').trim();
    if (initial == null) {
      _selectedSymbolValue = r'$';
      _customSymbolCtrl = TextEditingController();
    } else if (_isPresetSymbol(initialSymbol)) {
      _selectedSymbolValue = initialSymbol;
      _customSymbolCtrl = TextEditingController();
    } else {
      _selectedSymbolValue = _customSymbolValue;
      _customSymbolCtrl = TextEditingController(text: initialSymbol);
    }
    _codeCtrl.addListener(_syncCommonSymbolFromCode);
  }

  @override
  void dispose() {
    _codeCtrl.removeListener(_syncCommonSymbolFromCode);
    _codeCtrl.dispose();
    _customSymbolCtrl.dispose();
    super.dispose();
  }

  void _syncCommonSymbolFromCode() {
    if (_selectedSymbolValue == _customSymbolValue) {
      return;
    }
    final String code = _codeCtrl.text.trim().toUpperCase();
    final String? suggested = _commonSymbolByCode[code];
    if (suggested == null || suggested == _selectedSymbolValue) {
      return;
    }
    setState(() {
      _selectedSymbolValue = suggested;
    });
  }

  bool _isPresetSymbol(String value) {
    return _symbolPresets.any(
      (_CurrencySymbolPreset preset) => preset.symbol == value,
    );
  }

  String get _resolvedSymbol {
    if (_selectedSymbolValue == _customSymbolValue) {
      return _customSymbolCtrl.text.trim();
    }
    return _selectedSymbolValue.trim();
  }

  void _submit() {
    final String code = _codeCtrl.text.trim().toUpperCase();
    final String symbol = _resolvedSymbol;

    if (code.length != 3) {
      setState(() => _error = 'El codigo debe tener 3 letras.');
      return;
    }
    if (!_isEditing && widget.existingCodes.contains(code)) {
      setState(() => _error = 'Esa moneda ya existe en la lista.');
      return;
    }
    if (symbol.isEmpty) {
      setState(() => _error = 'El simbolo es obligatorio.');
      return;
    }

    Navigator.of(context).pop(
      AppCurrencySetting(
        code: code,
        symbol: symbol.length <= 3 ? symbol : symbol.substring(0, 3),
        rateToPrimary: widget.initialCurrency?.rateToPrimary ?? 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _isEditing ? 'Editar moneda' : 'Agregar moneda';
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            enabled: !_isEditing,
            decoration: const InputDecoration(
              labelText: 'Codigo (ISO)',
              hintText: 'USD',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSymbolValue,
            decoration: const InputDecoration(
              labelText: 'Simbolo',
            ),
            items: <DropdownMenuItem<String>>[
              ..._symbolPresets.map(
                (_CurrencySymbolPreset preset) => DropdownMenuItem<String>(
                  value: preset.symbol,
                  child: Text(preset.label),
                ),
              ),
              const DropdownMenuItem<String>(
                value: _customSymbolValue,
                child: Text('Personalizado'),
              ),
            ],
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedSymbolValue = value;
              });
            },
          ),
          if (_selectedSymbolValue == _customSymbolValue) ...<Widget>[
            const SizedBox(height: 8),
            TextField(
              controller: _customSymbolCtrl,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Simbolo personalizado',
                hintText: r'$, €, ₱',
              ),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
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
}

class _CurrencySymbolPreset {
  const _CurrencySymbolPreset({
    required this.label,
    required this.symbol,
  });

  final String label;
  final String symbol;
}
