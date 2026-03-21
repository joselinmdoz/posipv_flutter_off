import 'package:flutter/material.dart';

class ClientContactInfoCard extends StatelessWidget {
  const ClientContactInfoCard({
    super.key,
    this.address,
    this.company,
  });

  final String? address;
  final String? company;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Informacion de Contacto',
              style: TextStyle(
                fontSize: 34 / 2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF30384A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E9F0)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: <Widget>[
                _line(
                  icon: Icons.location_on_rounded,
                  label: 'Direccion Fiscal',
                  value:
                      (address ?? '').trim().isEmpty ? 'No definida' : address!,
                ),
                const SizedBox(height: 12),
                _line(
                  icon: Icons.business_rounded,
                  label: 'Empresa',
                  value: (company ?? '').trim().isEmpty
                      ? 'No especificada'
                      : company!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7486),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF11141A),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
