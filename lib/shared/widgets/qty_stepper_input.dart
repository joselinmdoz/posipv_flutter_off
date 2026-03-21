import 'dart:async';

import 'package:flutter/material.dart';

class QtyStepperInput extends StatefulWidget {
  const QtyStepperInput({
    super.key,
    required this.value,
    required this.onSubmittedValue,
    this.onIncrement,
    this.onDecrement,
    this.canIncrement = true,
    this.canDecrement = true,
    this.enabled = true,
    this.decimals = 0,
    this.height = 38,
    this.filledAddButton = true,
  });

  final double value;
  final ValueChanged<double> onSubmittedValue;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool canIncrement;
  final bool canDecrement;
  final bool enabled;
  final int decimals;
  final double height;
  final bool filledAddButton;

  @override
  State<QtyStepperInput> createState() => _QtyStepperInputState();
}

class _QtyStepperInputState extends State<QtyStepperInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _commitDebounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant QtyStepperInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus) {
      return;
    }
    if ((oldWidget.value - widget.value).abs() <= 0.000001) {
      return;
    }
    _controller.text = _formatValue(widget.value);
  }

  @override
  void dispose() {
    _commitDebounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      return;
    }
    _commitDebounce?.cancel();
    _commitTextValue();
  }

  String _formatValue(double value) {
    if (widget.decimals > 0) {
      return value.toStringAsFixed(widget.decimals);
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _commitTextValue() {
    final String raw = _controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) {
      _controller.text = _formatValue(widget.value);
      return;
    }
    final double? parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      _controller.text = _formatValue(widget.value);
      return;
    }
    widget.onSubmittedValue(parsed);
  }

  void _scheduleCommit() {
    _commitDebounce?.cancel();
    _commitDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      _commitTextValue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: <Widget>[
          _QtyActionButton(
            icon: Icons.remove_rounded,
            enabled: widget.enabled && widget.canDecrement,
            filled: false,
            onTap: widget.onDecrement,
            isDark: isDark,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) => _scheduleCommit(),
                onSubmitted: (_) => _commitTextValue(),
                onTap: () {
                  _controller.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _controller.text.length,
                  );
                },
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          _QtyActionButton(
            icon: Icons.add_rounded,
            enabled: widget.enabled && widget.canIncrement,
            filled: widget.filledAddButton,
            onTap: widget.onIncrement,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _QtyActionButton extends StatelessWidget {
  const _QtyActionButton({
    required this.icon,
    required this.enabled,
    required this.filled,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final bool enabled;
  final bool filled;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: double.infinity,
          decoration: BoxDecoration(
            color: filled
                ? const Color(0xFF1152D4)
                : (isDark ? Colors.transparent : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: filled
                ? null
                : Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: filled
                ? Colors.white
                : (enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
          ),
        ),
      ),
    );
  }
}
