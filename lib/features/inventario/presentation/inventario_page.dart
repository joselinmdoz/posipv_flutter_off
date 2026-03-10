import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class InventarioPage extends StatelessWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'inventario',
      body: Center(child: Text('Modulo inventario')),
    );
  }
}
