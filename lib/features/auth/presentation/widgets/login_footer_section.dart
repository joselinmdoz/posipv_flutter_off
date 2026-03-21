import 'package:flutter/material.dart';

class LoginFooterSection extends StatelessWidget {
  const LoginFooterSection({
    super.key,
    required this.onForgotPasswordTap,
    required this.onPrivacyTap,
    required this.appVersionLabel,
  });

  final VoidCallback onForgotPasswordTap;
  final VoidCallback onPrivacyTap;
  final String appVersionLabel;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: <Widget>[
        TextButton(
          onPressed: onForgotPasswordTap,
          child: const Text(
            'Olvidé mi contraseña',
            style: TextStyle(
              fontSize: 44 / 2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1152D4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              appVersionLabel,
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark ? const Color(0xFF93A1B5) : const Color(0xFF95A3B8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '•',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? const Color(0xFF93A1B5)
                      : const Color(0xFF95A3B8),
                ),
              ),
            ),
            InkWell(
              onTap: onPrivacyTap,
              child: Text(
                'Privacidad',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? const Color(0xFF93A1B5)
                      : const Color(0xFF95A3B8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
