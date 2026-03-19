import 'package:flutter/material.dart';

class LoginUnlockForm extends StatelessWidget {
  const LoginUnlockForm({
    super.key,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.lock_outline_rounded, size: 54),
        const SizedBox(height: 12),
        const Text(
          'Aplicacion protegida',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Introduce tu contrasena para iniciar sesion.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Contrasena'),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: Text(isLoading ? 'Validando...' : 'Entrar'),
          ),
        ),
      ],
    );
  }
}
