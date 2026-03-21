import 'package:flutter/material.dart';

class HomeDashboardLoading extends StatelessWidget {
  const HomeDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
