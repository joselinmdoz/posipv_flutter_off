import 'dart:io';

import 'package:flutter/material.dart';

class ClientAvatar extends StatelessWidget {
  const ClientAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.size = 64,
    this.showOnlineDot = false,
  });

  final String name;
  final String? imagePath;
  final double size;
  final bool showOnlineDot;

  @override
  Widget build(BuildContext context) {
    final String path = (imagePath ?? '').trim();
    final bool hasImage = path.isNotEmpty && File(path).existsSync();

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFE6EAF0),
            border: Border.all(color: const Color(0xFFD6DEE8)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: hasImage
                ? Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallback(),
                  )
                : _buildFallback(),
          ),
        ),
        if (showOnlineDot)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallback() {
    final String initials = _initials(name);
    if (initials.isEmpty) {
      return const Icon(Icons.person_rounded, color: Color(0xFF6B7280));
    }
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _initials(String value) {
    final List<String> tokens = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String token) => token.trim().isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return '';
    }
    if (tokens.length == 1) {
      return _firstChar(tokens.first).toUpperCase();
    }
    return '${_firstChar(tokens.first)}${_firstChar(tokens.last)}'
        .toUpperCase();
  }

  String _firstChar(String value) {
    final Iterable<int> runes = value.runes;
    if (runes.isEmpty) {
      return '';
    }
    return String.fromCharCode(runes.first);
  }
}
