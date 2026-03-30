import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/configuracion/presentation/configuracion_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class PosiPvApp extends ConsumerWidget {
  const PosiPvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp.router(
      title: 'POSIPV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
