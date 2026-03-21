import 'package:flutter/material.dart';

class HomeDashboardEmpty extends StatelessWidget {
  const HomeDashboardEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('No hay datos para mostrar.'),
      ),
    );
  }
}
