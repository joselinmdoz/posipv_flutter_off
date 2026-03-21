import 'package:flutter/material.dart';

class LoginLogoPanel extends StatelessWidget {
  const LoginLogoPanel({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDF4),
          width: 10,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFD8DBE0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              bottom: 34,
              child: Container(
                width: 90,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          Color(0xFF34B6F3),
                          Color(0xFF0B8AD9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
