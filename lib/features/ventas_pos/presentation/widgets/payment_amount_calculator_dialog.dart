import 'package:flutter/material.dart';

enum _CalculatorMode { standard, denominations }

class PaymentAmountCalculatorDialog extends StatefulWidget {
  const PaymentAmountCalculatorDialog({
    super.key,
    required this.currencySymbol,
    required this.denominationsCents,
    this.initialAmountCents = 0,
  });

  final String currencySymbol;
  final List<int> denominationsCents;
  final int initialAmountCents;

  static Future<int?> show({
    required BuildContext context,
    required String currencySymbol,
    required List<int> denominationsCents,
    int initialAmountCents = 0,
  }) {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return PaymentAmountCalculatorDialog(
          currencySymbol: currencySymbol,
          denominationsCents: denominationsCents,
          initialAmountCents: initialAmountCents,
        );
      },
    );
  }

  @override
  State<PaymentAmountCalculatorDialog> createState() =>
      _PaymentAmountCalculatorDialogState();
}

class _PaymentAmountCalculatorDialogState
    extends State<PaymentAmountCalculatorDialog> {
  late final List<int> _denominations;
  late final Map<int, int> _countsByDenomination;
  _CalculatorMode _mode = _CalculatorMode.standard;
  late String _expression;

  @override
  void initState() {
    super.initState();
    _denominations = widget.denominationsCents
        .where((int value) => value > 0)
        .toSet()
        .toList()
      ..sort((int a, int b) => b.compareTo(a));
    _countsByDenomination = <int, int>{
      for (final int denomination in _denominations) denomination: 0,
    };
    _expression = (widget.initialAmountCents / 100).toStringAsFixed(2);
  }

  bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '*' || token == '/';
  }

  int _precedence(String operator) {
    if (operator == '*' || operator == '/') {
      return 2;
    }
    if (operator == '+' || operator == '-') {
      return 1;
    }
    return 0;
  }

  double? _evaluateExpression(String raw) {
    final String input = raw
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '')
        .trim();
    if (input.isEmpty) {
      return null;
    }

    final List<String> tokens = <String>[];
    String current = '';
    for (int i = 0; i < input.length; i++) {
      final String char = input[i];
      final bool isDigit = RegExp(r'[0-9.]').hasMatch(char);
      if (isDigit) {
        current += char;
        continue;
      }
      if (!_isOperator(char)) {
        return null;
      }
      if (char == '-' && (tokens.isEmpty && current.isEmpty)) {
        current = '-';
        continue;
      }
      if (char == '-' &&
          current.isEmpty &&
          tokens.isNotEmpty &&
          _isOperator(tokens.last)) {
        current = '-';
        continue;
      }
      if (current.isEmpty) {
        return null;
      }
      tokens.add(current);
      current = '';
      tokens.add(char);
    }
    if (current.isNotEmpty) {
      tokens.add(current);
    }
    if (tokens.isEmpty) {
      return null;
    }

    final List<double> values = <double>[];
    final List<String> operators = <String>[];

    void applyTopOperator() {
      if (values.length < 2 || operators.isEmpty) {
        throw StateError('invalid');
      }
      final double b = values.removeLast();
      final double a = values.removeLast();
      final String op = operators.removeLast();
      switch (op) {
        case '+':
          values.add(a + b);
          break;
        case '-':
          values.add(a - b);
          break;
        case '*':
          values.add(a * b);
          break;
        case '/':
          if (b.abs() < 0.000000001) {
            throw StateError('division_by_zero');
          }
          values.add(a / b);
          break;
      }
    }

    try {
      for (final String token in tokens) {
        if (_isOperator(token)) {
          while (operators.isNotEmpty &&
              _precedence(operators.last) >= _precedence(token)) {
            applyTopOperator();
          }
          operators.add(token);
          continue;
        }
        final double? number = double.tryParse(token);
        if (number == null || !number.isFinite) {
          return null;
        }
        values.add(number);
      }

      while (operators.isNotEmpty) {
        applyTopOperator();
      }
      if (values.length != 1) {
        return null;
      }
      return values.single;
    } catch (_) {
      return null;
    }
  }

  int get _denominationTotalCents {
    int total = 0;
    _countsByDenomination.forEach((int denomination, int count) {
      total += denomination * count;
    });
    return total;
  }

  void _appendToExpression(String token) {
    setState(() {
      if (token == 'C') {
        _expression = '';
        return;
      }
      if (token == 'DEL') {
        if (_expression.isEmpty) {
          return;
        }
        _expression = _expression.substring(0, _expression.length - 1);
        return;
      }
      if (token == '=') {
        final double? result = _evaluateExpression(_expression);
        if (result == null) {
          return;
        }
        _expression = result.toStringAsFixed(2);
        return;
      }
      final bool isOperator =
          token == '+' || token == '-' || token == '×' || token == '÷';
      if (isOperator) {
        if (_expression.isEmpty) {
          if (token == '-') {
            _expression = token;
          }
          return;
        }
        final String last = _expression[_expression.length - 1];
        final bool lastIsOperator =
            last == '+' || last == '-' || last == '×' || last == '÷';
        if (lastIsOperator) {
          _expression =
              _expression.substring(0, _expression.length - 1) + token;
          return;
        }
      }
      _expression += token;
    });
  }

  void _changeCount(int denomination, int delta) {
    final int current = _countsByDenomination[denomination] ?? 0;
    final int next = (current + delta).clamp(0, 99999);
    setState(() => _countsByDenomination[denomination] = next);
  }

  void _acceptValue() {
    int cents = 0;
    if (_mode == _CalculatorMode.standard) {
      final double? value = _evaluateExpression(_expression);
      if (value == null || !value.isFinite || value < 0) {
        return;
      }
      cents = (value * 100).round();
    } else {
      cents = _denominationTotalCents;
    }
    Navigator.of(context).pop(cents);
  }

  Widget _modeChip({
    required String label,
    required _CalculatorMode mode,
  }) {
    final bool selected = _mode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _mode = mode),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? const Color(0xFF1152D4) : null,
      ),
      selectedColor: const Color(0xFF1152D4).withValues(alpha: 0.14),
      side: BorderSide(
        color: selected ? const Color(0xFF1152D4) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _calcButton(String label) {
    final bool isAction = label == 'C' || label == 'DEL' || label == '=';
    final bool isOperator =
        label == '+' || label == '-' || label == '×' || label == '÷';
    final Color bg = isAction
        ? const Color(0xFF1D4ED8)
        : isOperator
            ? const Color(0xFF1152D4).withValues(alpha: 0.14)
            : const Color(0xFFF8FAFC);
    final Color fg = isAction
        ? Colors.white
        : isOperator
            ? const Color(0xFF1152D4)
            : const Color(0xFF0F172A);

    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: () => _appendToExpression(label),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isAction ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildStandardCalculator() {
    final List<String> buttons = <String>[
      'C',
      'DEL',
      '÷',
      '×',
      '7',
      '8',
      '9',
      '-',
      '4',
      '5',
      '6',
      '+',
      '1',
      '2',
      '3',
      '=',
      '0',
      '.',
    ];

    final double? evaluated = _evaluateExpression(_expression);
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _expression.isEmpty ? '0' : _expression,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                evaluated == null
                    ? '--'
                    : '${widget.currencySymbol}${evaluated.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: buttons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.4,
          ),
          itemBuilder: (_, int index) => _calcButton(buttons[index]),
        ),
      ],
    );
  }

  Widget _buildDenominationsCalculator() {
    if (_denominations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No hay denominaciones configuradas.'),
      );
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 280,
          child: ListView.separated(
            itemCount: _denominations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, int index) {
              final int denomination = _denominations[index];
              final int qty = _countsByDenomination[denomination] ?? 0;
              final int subtotal = denomination * qty;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${widget.currencySymbol}${(denomination / 100).toStringAsFixed(denomination % 100 == 0 ? 0 : 2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Subtotal: ${widget.currencySymbol}${(subtotal / 100).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeCount(denomination, -1),
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeCount(denomination, 1),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                for (final int denomination in _denominations) {
                  _countsByDenomination[denomination] = 0;
                }
              });
            },
            icon: const Icon(Icons.clear_rounded),
            label: const Text('Limpiar'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String preview = _mode == _CalculatorMode.standard
        ? (() {
            final double? value = _evaluateExpression(_expression);
            if (value == null || value < 0) {
              return '--';
            }
            return '${widget.currencySymbol}${value.toStringAsFixed(2)}';
          })()
        : '${widget.currencySymbol}${(_denominationTotalCents / 100).toStringAsFixed(2)}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Calculadora de monto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  _modeChip(
                    label: 'Normal',
                    mode: _CalculatorMode.standard,
                  ),
                  const SizedBox(width: 8),
                  _modeChip(
                    label: 'Denominaciones',
                    mode: _CalculatorMode.denominations,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_mode == _CalculatorMode.standard)
                _buildStandardCalculator()
              else
                _buildDenominationsCalculator(),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Valor: $preview',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _acceptValue,
                      child: const Text('Usar valor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
