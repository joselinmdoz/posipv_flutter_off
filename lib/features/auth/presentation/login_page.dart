import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/user_session.dart';
import 'auth_providers.dart';
import 'widgets/login_unlock_form.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _checkingLockStatus = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _prepareScreen();
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepareScreen() async {
    final authService = ref.read(localAuthServiceProvider);
    try {
      await authService.ensureDefaultAdmin();
      final bool appLockEnabled = await authService.isAppLockEnabled();
      if (!mounted) {
        return;
      }

      if (!appLockEnabled) {
        final session = await authService.createOfflineSession();
        if (!mounted) {
          return;
        }
        ref.read(currentSessionProvider.notifier).state = session;
        context.go('/home');
        return;
      }

      setState(() => _checkingLockStatus = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _checkingLockStatus = false);
      _showError('No se pudo preparar el acceso offline: $error');
    }
  }

  Future<void> _unlock() async {
    final String password = _passwordCtrl.text;
    if (password.trim().isEmpty) {
      _showError('Completa la contrasena.');
      return;
    }

    setState(() => _isLoading = true);
    UserSession? session;
    try {
      session = await ref
          .read(localAuthServiceProvider)
          .unlockWithAppPassword(password);
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('No se pudo validar el acceso: $error');
      return;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (session == null) {
      _showError('Contrasena invalida.');
      return;
    }

    ref.read(currentSessionProvider.notifier).state = session;
    _passwordCtrl.clear();
    if (mounted) {
      context.go('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLockStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LoginUnlockForm(
              passwordController: _passwordCtrl,
              isLoading: _isLoading,
              onSubmit: _unlock,
            ),
          ),
        ),
      ),
    );
  }
}
