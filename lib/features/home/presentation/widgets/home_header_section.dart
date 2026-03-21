import 'package:flutter/material.dart';

import '../../../../shared/models/user_session.dart';

class HomeHeaderSection extends StatelessWidget {
  final UserSession? session;
  final String? displayName;

  const HomeHeaderSection({
    super.key,
    required this.session,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final String username =
        (displayName ?? session?.username ?? 'Usuario').trim();
    final DateTime now = DateTime.now();

    final List<String> days = [
      'LUNES',
      'MARTES',
      'MIÉRCOLES',
      'JUEVES',
      'VIERNES',
      'SÁBADO',
      'DOMINGO',
    ];
    final List<String> months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];

    final String dayName = days[now.weekday - 1];
    final String monthName = months[now.month - 1];
    final String dateStr = '$dayName, ${now.day} DE $monthName';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $username 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aquí tienes el resumen de tu negocio hoy.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
