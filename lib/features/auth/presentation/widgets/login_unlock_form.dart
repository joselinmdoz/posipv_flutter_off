import 'package:flutter/material.dart';

import 'login_footer_section.dart';
import 'login_input_field.dart';
import 'login_logo_panel.dart';

class LoginUnlockForm extends StatelessWidget {
  const LoginUnlockForm({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
    required this.onForgotPasswordTap,
    required this.onPrivacyTap,
    required this.appVersionLabel,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgotPasswordTap;
  final VoidCallback onPrivacyTap;
  final String appVersionLabel;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          const SizedBox(height: 36),
          LoginLogoPanel(isDark: isDark),
          const SizedBox(height: 64),
          Text(
            'Iniciar sesion',
            style: TextStyle(
              fontSize: 72 / 2,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0E1630),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Acceda con sus credenciales de usuario.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22 / 2,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF95A3B8) : const Color(0xFF5D6E8A),
            ),
          ),
          const SizedBox(height: 56),
          LoginInputField(
            controller: usernameController,
            hintText: 'Usuario',
            prefixIcon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          LoginInputField(
            controller: passwordController,
            hintText: 'Contrasena',
            prefixIcon: Icons.lock_rounded,
            obscureText: obscurePassword,
            suffixIcon: obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            onSuffixTap: onTogglePasswordVisibility,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 68,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1152D4),
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: const Color(0xFF1152D4).withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                isLoading ? 'Validando...' : 'Entrar',
                style: const TextStyle(
                  fontSize: 44 / 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          LoginFooterSection(
            onForgotPasswordTap: onForgotPasswordTap,
            onPrivacyTap: onPrivacyTap,
            appVersionLabel: appVersionLabel,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
