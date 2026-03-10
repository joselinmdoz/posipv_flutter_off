import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class PosiPvApp extends StatelessWidget {
  const PosiPvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'POSIPV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
