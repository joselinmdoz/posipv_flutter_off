import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class ProductosPage extends StatelessWidget {
  const ProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'productos',
      body: Center(child: Text('Modulo productos')),
    );
  }
}
