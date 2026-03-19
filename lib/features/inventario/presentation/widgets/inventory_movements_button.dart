import 'package:flutter/material.dart';

class InventoryMovementsButton extends StatelessWidget {
  const InventoryMovementsButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text('Movimientos'),
      ),
    );
  }
}
