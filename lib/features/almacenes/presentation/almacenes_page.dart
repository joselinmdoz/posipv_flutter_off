import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AlmacenesPage extends StatelessWidget {
  const AlmacenesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'almacenes',
      body: Center(child: Text('Modulo almacenes')),
    );
  }
}
