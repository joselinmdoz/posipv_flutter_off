import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _rememberSession = true;
  bool _checkingRememberedSession = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(localAuthServiceProvider).ensureDefaultAdmin();
      await _tryRestoreRememberedSession();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryRestoreRememberedSession() async {
    final session =
        await ref.read(localAuthServiceProvider).restoreRememberedSession();
    if (!mounted) {
      return;
    }
    if (session != null) {
      ref.read(currentSessionProvider.notifier).state = session;
      context.go('/home');
      return;
    }
    setState(() => _checkingRememberedSession = false);
  }

  Future<void> _login() async {
    final String username = _usernameCtrl.text.trim();
    final String password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      _showError('Completa usuario y contrasena.');
      return;
    }

    setState(() => _isLoading = true);
    final session = await ref.read(localAuthServiceProvider).login(
          username: username,
          password: password,
        );
    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (session == null) {
      _showError('Credenciales invalidas.');
      return;
    }

    ref.read(currentSessionProvider.notifier).state = session;
    await ref.read(localAuthServiceProvider).persistSession(
          session: session,
          rememberOnDevice: _rememberSession,
        );
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
    if (_checkingRememberedSession) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Usuario'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contrasena'),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _rememberSession,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Recordar sesion en este dispositivo'),
                  onChanged: _isLoading
                      ? null
                      : (bool? value) {
                          setState(() => _rememberSession = value ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: Text(_isLoading ? 'Validando...' : 'Entrar'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Usuario inicial: admin / admin123',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
