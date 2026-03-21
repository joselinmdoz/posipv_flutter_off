import 'package:flutter/material.dart';

import '../../../../shared/models/dashboard_widget_config.dart';

class DashboardWidgetReorderList extends StatelessWidget {
  const DashboardWidgetReorderList({
    super.key,
    required this.orderedKeys,
    required this.visibleKeys,
    required this.enabled,
    required this.onReorder,
  });

  final List<String> orderedKeys;
  final Set<String> visibleKeys;
  final bool enabled;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: orderedKeys.length,
      onReorder: enabled ? onReorder : (_, __) {},
      itemBuilder: (BuildContext context, int index) {
        final String widgetKey = orderedKeys[index];
        final DashboardWidgetDefinition? definition =
            DashboardWidgetCatalog.byKey(widgetKey);
        final bool visible = visibleKeys.contains(widgetKey);

        return Card(
          key: ValueKey<String>('dashboard-widget-order-$widgetKey'),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(_iconForKey(widgetKey)),
            title: Text(
              definition?.title ?? widgetKey,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(visible ? 'Visible en dashboard' : 'Oculto'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: visible
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    visible ? 'Visible' : 'Oculto',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: visible
                          ? const Color(0xFF0F7A35)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: index,
                  enabled: enabled,
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
