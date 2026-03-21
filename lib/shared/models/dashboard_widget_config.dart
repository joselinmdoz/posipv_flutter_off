class DashboardWidgetDefinition {
  const DashboardWidgetDefinition({
    required this.key,
    required this.title,
    required this.description,
    this.defaultVisible = true,
  });

  final String key;
  final String title;
  final String description;
  final bool defaultVisible;
}

class DashboardWidgetLayout {
  const DashboardWidgetLayout({
    required this.visibleKeys,
    required this.orderedKeys,
  });

  final Set<String> visibleKeys;
  final List<String> orderedKeys;

  static DashboardWidgetLayout get defaults => DashboardWidgetLayout(
        visibleKeys: DashboardWidgetCatalog.defaultVisibleKeys,
        orderedKeys: DashboardWidgetCatalog.defaultOrderKeys,
      );

  DashboardWidgetLayout normalized() {
    final Set<String> allKeys = DashboardWidgetCatalog.allKeys;
    final List<String> normalizedOrder = <String>[];
    final Set<String> seen = <String>{};

    for (final String key in orderedKeys) {
      final String clean = key.trim();
      if (clean.isEmpty || !allKeys.contains(clean) || seen.contains(clean)) {
        continue;
      }
      seen.add(clean);
      normalizedOrder.add(clean);
    }

    for (final String key in DashboardWidgetCatalog.defaultOrderKeys) {
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);
      normalizedOrder.add(key);
    }

    final Set<String> normalizedVisible = visibleKeys
        .map((String key) => key.trim())
        .where((String key) => allKeys.contains(key))
        .toSet();

    return DashboardWidgetLayout(
      visibleKeys: normalizedVisible.isEmpty
          ? DashboardWidgetCatalog.defaultVisibleKeys
          : normalizedVisible,
      orderedKeys: normalizedOrder,
    );
  }

  List<String> get orderedVisibleKeys {
    final Set<String> visible = visibleKeys;
    return orderedKeys
        .where((String key) => visible.contains(key))
        .toList(growable: false);
  }

  DashboardWidgetLayout copyWith({
    Set<String>? visibleKeys,
    List<String>? orderedKeys,
  }) {
    return DashboardWidgetLayout(
      visibleKeys: visibleKeys ?? this.visibleKeys,
      orderedKeys: orderedKeys ?? this.orderedKeys,
    ).normalized();
  }
}

class DashboardWidgetKeys {
  const DashboardWidgetKeys._();

  static const String metrics = 'home.dashboard.metrics';
  static const String quickActions = 'home.dashboard.quick_actions';
  static const String recentActivity = 'home.dashboard.recent_activity';
}

class DashboardWidgetCatalog {
  const DashboardWidgetCatalog._();

  static const List<DashboardWidgetDefinition> definitions =
      <DashboardWidgetDefinition>[
    DashboardWidgetDefinition(
      key: DashboardWidgetKeys.metrics,
      title: 'Resumen de métricas',
      description: 'Ventas del día, pedidos y estado de stock.',
    ),
    DashboardWidgetDefinition(
      key: DashboardWidgetKeys.quickActions,
      title: 'Acciones rápidas',
      description: 'Accesos directos para vender y añadir stock.',
    ),
    DashboardWidgetDefinition(
      key: DashboardWidgetKeys.recentActivity,
      title: 'Actividad reciente',
      description: 'Últimas ventas registradas en el sistema.',
    ),
  ];

  static final Set<String> allKeys =
      definitions.map((DashboardWidgetDefinition item) => item.key).toSet();

  static final List<String> defaultOrderKeys =
      definitions.map((DashboardWidgetDefinition item) => item.key).toList();

  static final Set<String> defaultVisibleKeys = definitions
      .where((DashboardWidgetDefinition item) => item.defaultVisible)
      .map((DashboardWidgetDefinition item) => item.key)
      .toSet();

  static DashboardWidgetDefinition? byKey(String key) {
    final String clean = key.trim();
    for (final DashboardWidgetDefinition definition in definitions) {
      if (definition.key == clean) {
        return definition;
      }
    }
    return null;
  }
}
