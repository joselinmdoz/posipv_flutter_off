import 'package:flutter/material.dart';

class ClientQuickCreateCard extends StatelessWidget {
  const ClientQuickCreateCard({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD2D9E3),
          style: BorderStyle.solid,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E8EF),
              borderRadius: BorderRadius.circular(999),
            ),
            child:
                const Icon(Icons.group_add_rounded, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nuevo Prospecto?',
            style: TextStyle(
              fontSize: 20 / 2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11141A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega rapidamente un contacto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7486),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE1E5EA),
              foregroundColor: const Color(0xFF1152D4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'CREAR ACCESO RAPIDO',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
