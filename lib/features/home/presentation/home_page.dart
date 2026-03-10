import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);

    return AppScaffold(
      title: 'POSIPV',
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Panel principal offline'),
            const SizedBox(height: 8),
            Text(
              session == null
                  ? 'Sesion no iniciada'
                  : 'Usuario: ${session.username} (${session.role})',
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                ref.read(currentSessionProvider.notifier).state = null;
                context.go('/login');
              },
              child: const Text('Cerrar sesion'),
            ),
          ],
        ),
      ),
    );
  }
}
