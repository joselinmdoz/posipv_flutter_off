import 'package:flutter/material.dart';

class SecurityActionsPanel extends StatelessWidget {
  const SecurityActionsPanel({
    super.key,
    required this.isEnabled,
    required this.isBusy,
    required this.onEnable,
    required this.onChange,
    required this.onDisable,
  });

  final bool isEnabled;
  final bool isBusy;
  final VoidCallback onEnable;
  final VoidCallback onChange;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isBusy ? null : onEnable,
          icon: const Icon(Icons.lock_person_rounded),
          label: const Text('Activar contrasena'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: isBusy ? null : onChange,
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('Cambiar contrasena'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onDisable,
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('Desactivar contrasena'),
        ),
      ],
    );
  }
}
