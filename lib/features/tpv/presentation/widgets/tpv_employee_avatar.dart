import 'dart:io';
import 'package:flutter/material.dart';

class TpvEmployeeAvatar extends StatelessWidget {
  final String? imagePath;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;

  const TpvEmployeeAvatar({
    super.key,
    required this.imagePath,
    required this.radius,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final String trimmedPath = (imagePath ?? '').trim();
    if (trimmedPath.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(Icons.badge_outlined, color: iconColor),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: Image.file(
          File(trimmedPath),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheWidth: (radius * 4).round(),
          errorBuilder: (_, __, ___) => Icon(
            Icons.badge_outlined,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
