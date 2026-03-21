import 'package:flutter/material.dart';

class ClientAdminNoteCard extends StatelessWidget {
  const ClientAdminNoteCard({
    super.key,
    required this.note,
  });

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFDBCF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_rounded,
              color: Color(0xFF8A2C00),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Observacion del Administrador',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A1805),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$note"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    height: 1.35,
                    color: Color(0xFF4B230D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
