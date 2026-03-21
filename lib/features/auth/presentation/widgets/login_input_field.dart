import 'package:flutter/material.dart';

class LoginInputField extends StatelessWidget {
  const LoginInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.textInputAction,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      autocorrect: false,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 22,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF95A3B8),
          size: 28,
        ),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixTap,
                icon: Icon(
                  suffixIcon,
                  color: const Color(0xFF95A3B8),
                  size: 28,
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD8E0EB), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD8E0EB), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF1152D4), width: 2),
        ),
      ),
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF172034),
      ),
    );
  }
}
