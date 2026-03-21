import 'package:flutter/material.dart';

import '../../data/clientes_local_datasource.dart';
import 'client_avatar.dart';

class ClientDetailProfileCard extends StatelessWidget {
  const ClientDetailProfileCard({
    super.key,
    required this.client,
  });

  final ClienteDetail client;

  @override
  Widget build(BuildContext context) {
    final String typeLabel = _typeLabel(client.customerType);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        children: <Widget>[
          ClientAvatar(
            name: client.fullName,
            imagePath: client.avatarPath,
            size: 124,
            showOnlineDot: client.customerType == 'frecuente',
          ),
          const SizedBox(height: 12),
          Text(
            client.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 44 / 2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11141A),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if ((client.identityNumber ?? '').trim().isNotEmpty) ...<Widget>[
                Text(
                  'Identidad: ${client.identityNumber!.trim()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF48546A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: client.isVip
                      ? const Color(0xFFDDE6FF)
                      : const Color(0xFFE9EDF3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  client.isVip ? 'CLIENTE VIP' : typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: client.isVip
                        ? const Color(0xFF2047A5)
                        : const Color(0xFF5D667A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'frecuente':
        return 'FRECUENTE';
      case 'mayorista':
        return 'MAYORISTA';
      case 'nuevo':
        return 'NUEVO';
      default:
        return 'GENERAL';
    }
  }
}
