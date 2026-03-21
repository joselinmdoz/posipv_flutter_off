import 'package:flutter/material.dart';

class ClientsSearchField extends StatelessWidget {
  const ClientsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFE1E5EA),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.person_search_rounded,
            size: 21,
            color: Color(0xFF5D667A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
