import 'dart:io';
import 'package:flutter/material.dart';

class TpvEmployeePhotoPicker extends StatelessWidget {
  const TpvEmployeePhotoPicker({
    super.key,
    required this.imagePath,
    required this.onPick,
    this.isDark = false,
    this.disabled = false,
  });

  final String? imagePath;
  final VoidCallback onPick;
  final bool isDark;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: disabled ? null : onPick,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: imagePath != null && imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(
                            File(imagePath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: 64,
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1152D4),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF1A202E) : Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1152D4).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FOTO DE PERFIL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class TpvFormTextField extends StatelessWidget {
  const TpvFormTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.isDark = false,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData? icon;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white54 : Colors.black45,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF1152D4)) : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1152D4), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
