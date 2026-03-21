import 'package:flutter/material.dart';

class ClientQuickContactPanel extends StatelessWidget {
  const ClientQuickContactPanel({
    super.key,
    this.phone,
    this.email,
  });

  final String? phone;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: <Widget>[
          _line(
            icon: Icons.call_rounded,
            value: (phone ?? '').trim().isEmpty ? 'Sin telefono' : phone!,
          ),
          const SizedBox(height: 10),
          _line(
            icon: Icons.mail_rounded,
            value: (email ?? '').trim().isEmpty ? 'Sin correo' : email!,
          ),
        ],
      ),
    );
  }

  Widget _line({
    required IconData icon,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF1152D4), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19 / 2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
