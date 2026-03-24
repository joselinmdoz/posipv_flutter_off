import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/session_access.dart';
import '../../../shared/models/user_session.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import 'auth_providers.dart';
import 'widgets/login_unlock_form.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final bool _initializing = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _switchingTheme = false;

  static String _appVersionLabel() {
    const String buildName = String.fromEnvironment('FLUTTER_BUILD_NAME');
    const String buildNumber = String.fromEnvironment('FLUTTER_BUILD_NUMBER');
    if (buildName.isNotEmpty && buildNumber.isNotEmpty) {
      return 'Versión $buildName+$buildNumber';
    }
    if (buildName.isNotEmpty) {
      return 'Versión $buildName';
    }
    return 'Versión 0.1.0+1';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String username = _usernameCtrl.text.trim();
    final String password = _passwordCtrl.text;
    if (username.isEmpty || password.trim().isEmpty) {
      _showError('Completa usuario y contrasena.');
      return;
    }

    setState(() => _isLoading = true);
    UserSession? session;
    try {
      session = await ref.read(localAuthServiceProvider).login(
            username: username,
            password: password,
          );
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('No se pudo iniciar sesion: $error');
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (session == null) {
      _showError('Credenciales invalidas.');
      return;
    }

    ref.read(currentSessionProvider.notifier).state = session;
    _passwordCtrl.clear();
    context.go(SessionAccess.firstAllowedRoute(session));
  }

  Future<void> _toggleTheme() async {
    if (_switchingTheme) {
      return;
    }
    setState(() => _switchingTheme = true);
    try {
      final AppConfig current = ref.read(currentAppConfigProvider);
      final AppThemePreference nextPreference =
          current.themePreference == AppThemePreference.dark
              ? AppThemePreference.light
              : AppThemePreference.dark;
      await ref
          .read(appConfigControllerProvider.notifier)
          .save(current.copyWith(themePreference: nextPreference));
    } catch (error) {
      _showError('No se pudo cambiar el tema: $error');
    } finally {
      if (mounted) {
        setState(() => _switchingTheme = false);
      }
    }
  }

  void _showForgotPassword() {
    _showError(
      'Contacta al administrador para restablecer la contrasena.',
    );
  }

  void _showPrivacy() {
    _showError('Politica de privacidad disponible proximamente.');
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _switchingTheme ? null : _toggleTheme,
        heroTag: 'login-theme-toggle',
        elevation: 6,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor:
            isDark ? const Color(0xFFFACC15) : const Color(0xFF1E293B),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LoginUnlockForm(
                usernameController: _usernameCtrl,
                passwordController: _passwordCtrl,
                isLoading: _isLoading,
                obscurePassword: _obscurePassword,
                appVersionLabel: _appVersionLabel(),
                onSubmit: _login,
                onTogglePasswordVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                onForgotPasswordTap: _showForgotPassword,
                onPrivacyTap: _showPrivacy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
