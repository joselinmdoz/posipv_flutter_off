import 'package:flutter/material.dart';

class SecurityStatusCard extends StatelessWidget {
  const SecurityStatusCard({
    super.key,
    required this.isEnabled,
    required this.isBusy,
  });

  final bool isEnabled;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color bgColor = isEnabled
        ? scheme.primaryContainer.withValues(alpha: 0.55)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final IconData icon =
        isEnabled ? Icons.lock_rounded : Icons.lock_open_rounded;
    final String title = isEnabled
        ? 'Contrasena de inicio activada'
        : 'Contrasena de inicio desactivada';
    final String subtitle = isEnabled
        ? 'La app pedira contrasena al abrirse.'
        : 'La app abrira directo sin pedir contrasena.';

    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 34, color: scheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2)),
          ],
        ),
      ),
    );
  }
}
