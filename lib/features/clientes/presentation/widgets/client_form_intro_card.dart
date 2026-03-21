import 'package:flutter/material.dart';

class ClientFormIntroCard extends StatelessWidget {
  const ClientFormIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Registro de Perfil',
            style: TextStyle(
              fontSize: 48 / 2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11141A),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Complete la informacion detallada para mantener una base de datos de clientes organizada y profesional. La segmentacion permite aplicar tarifas diferenciadas automaticamente.',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          SizedBox(height: 16),
          _StatusLine(
            icon: Icons.person_add_alt_1_rounded,
            title: 'ESTADO',
            value: 'Nuevo Ingreso',
            accent: Color(0xFF1152D4),
          ),
          SizedBox(height: 10),
          _StatusLine(
            icon: Icons.verified_user_rounded,
            title: 'VALIDACION',
            value: 'Datos en Tiempo Real',
            accent: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFDDE6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: Color(0xFF30384A),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18 / 1.2,
                  color: Color(0xFF11141A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
