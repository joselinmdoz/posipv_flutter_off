import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ReportesPage extends StatelessWidget {
  const ReportesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'reportes',
      body: Center(child: Text('Modulo reportes')),
    );
  }
}
