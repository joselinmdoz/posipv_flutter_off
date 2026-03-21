import 'package:flutter/material.dart';

import '../../../../shared/models/dashboard_widget_config.dart';

class DashboardWidgetToggleTile extends StatelessWidget {
  const DashboardWidgetToggleTile({
    super.key,
    required this.definition,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final DashboardWidgetDefinition definition;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        secondary: Icon(_iconForKey(definition.key)),
        title: Text(
          definition.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(definition.description),
      ),
    );
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case DashboardWidgetKeys.quickActions:
        return Icons.flash_on_rounded;
      case DashboardWidgetKeys.recentActivity:
        return Icons.timeline_rounded;
      case DashboardWidgetKeys.metrics:
      default:
        return Icons.dashboard_customize_rounded;
    }
  }
}
