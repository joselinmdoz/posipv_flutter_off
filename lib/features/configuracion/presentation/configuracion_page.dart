import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'configuracion',
      body: Center(child: Text('Modulo configuracion')),
    );
  }
}
