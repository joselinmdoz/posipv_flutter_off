import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/licensing/license_models.dart';
import '../../core/licensing/license_providers.dart';
import '../../features/auth/presentation/auth_providers.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentRoute,
    this.onRefresh,
    this.floatingActionButton,
    this.showTopTabs = true,
    this.useDefaultActions = true,
    this.appBarActions,
    this.showDrawer = true,
    this.appBarLeading,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final String? currentRoute;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final bool showTopTabs;
  final bool useDefaultActions;
  final List<Widget>? appBarActions;
  final bool showDrawer;
  final Widget? appBarLeading;
  final Widget? bottomNavigationBar;

  static const List<_NavItem> _navItems = <_NavItem>[
    _NavItem('Principal', '/home', Icons.grid_view_rounded),
    _NavItem('TPV', '/tpv', Icons.storefront_rounded),
    _NavItem('Empleados', '/tpv-empleados', Icons.badge_outlined),
    _NavItem('Ventas', '/ventas-directas', Icons.point_of_sale_rounded),
    _NavItem('Inventario', '/inventario', Icons.inventory_2_outlined),
    _NavItem(
      'Movimientos',
      '/inventario-movimientos',
      Icons.swap_horiz_rounded,
    ),
    _NavItem('Productos', '/productos', Icons.shopping_bag_outlined),
    _NavItem('Almacenes', '/almacenes', Icons.warehouse_outlined),
    _NavItem('Reportes', '/reportes', Icons.bar_chart_rounded),
    _NavItem('IPV', '/ipv-reportes', Icons.table_chart_outlined),
    _NavItem('Licencia', '/licencia', Icons.verified_user_outlined),
    _NavItem('Ajustes', '/configuracion', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String activeRoute = currentRoute ?? _currentLocation(context);
    final ThemeData theme = Theme.of(context);
    final LicenseStatus licenseStatus = ref.watch(currentLicenseStatusProvider);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<Color> bodyGradient = isDark
        ? <Color>[theme.scaffoldBackgroundColor, const Color(0xFF0B1220)]
        : <Color>[theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF)];
    final Widget? licenseBanner =
        _buildLicenseBanner(context, licenseStatus, activeRoute);

    return Scaffold(
      drawer: showDrawer
          ? _buildDrawer(context, ref, activeRoute, licenseStatus)
          : null,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        leading: appBarLeading,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: _buildAppBarActions(context, ref),
      ),
      bottomNavigationBar: bottomNavigationBar ??
          (showTopTabs
              ? _buildBottomNav(context, activeRoute, licenseStatus)
              : null),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bodyGradient,
          ),
        ),
        child: Column(
          children: <Widget>[
            if (licenseBanner != null) licenseBanner,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, WidgetRef ref) {
    final List<Widget> actions = <Widget>[];
    if (useDefaultActions) {
      actions.addAll(<Widget>[
        IconButton(
          tooltip: 'Buscar',
          onPressed: () => _showSoon(context, 'Busqueda rapida proximamente.'),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Imprimir',
          onPressed: () =>
              _showSoon(context, 'Impresion de tickets proximamente.'),
          icon: const Icon(Icons.print_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          onSelected: (String value) {
            _onTopMenu(value, context, ref);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (onRefresh != null)
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Text('Actualizar vista'),
              ),
            const PopupMenuItem<String>(
              value: 'config',
              child: Text('Ir a configuracion'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Cerrar sesion'),
            ),
          ],
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ]);
    }
    if (appBarActions != null && appBarActions!.isNotEmpty) {
      actions.addAll(appBarActions!);
    }
    if (actions.isNotEmpty) {
      actions.add(const SizedBox(width: 4));
    }
    return actions;
  }

  Widget _buildTopTabs(
    BuildContext context,
    String activeRoute,
    LicenseStatus licenseStatus,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _navItems.map((_NavItem item) {
            final bool isActive = item.route == activeRoute;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _go(
                  context,
                  item.route,
                  activeRoute,
                  licenseStatus,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark
                            ? scheme.primary.withValues(alpha: 0.26)
                            : scheme.primary.withValues(alpha: 0.15))
                        : (isDark
                            ? scheme.surface.withValues(alpha: 0.88)
                            : scheme.surface),
                    border: Border.all(
                      color: isActive
                          ? scheme.primary.withValues(alpha: 0.5)
                          : scheme.outline.withValues(alpha: 0.8),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 16,
                        color:
                            isActive ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive ? scheme.primary : scheme.onSurface,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    String activeRoute,
    LicenseStatus licenseStatus,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    // Filter only main navigation items for bottom nav
    final List<_NavItem> bottomNavItems = <_NavItem>[
      _navItems[0], // Principal
      _navItems[5], // Productos
      _navItems[3], // Ventas
      _navItems[1], // TPV
      _navItems[11], // Ajustes
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bottomNavItems.map((_NavItem item) {
              final bool isActive = item.route == activeRoute;
              return Expanded(
                child: InkWell(
                  onTap: () =>
                      _go(context, item.route, activeRoute, licenseStatus),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          item.icon,
                          size: 24,
                          color: isActive
                              ? const Color(0xFF1152D4)
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF1152D4)
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    String activeRoute,
    LicenseStatus licenseStatus,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color drawerTitleColor = scheme.onSurface;
    final Color drawerSubtitleColor = scheme.onSurfaceVariant;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'POSIPV',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: drawerTitleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ventas y control offline',
                    style: TextStyle(fontSize: 14, color: drawerSubtitleColor),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                children: <Widget>[
                  for (final _NavItem item in _navItems)
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      selected: item.route == activeRoute,
                      selectedTileColor: isDark
                          ? scheme.primary.withValues(alpha: 0.2)
                          : scheme.primary.withValues(alpha: 0.12),
                      leading: Icon(item.icon),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: item.route == activeRoute
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _go(context, item.route, activeRoute, licenseStatus);
                      },
                    ),
                  // const SizedBox(height: 8),
                  // Divider(height: 1, color: theme.dividerColor),
                  // const SizedBox(height: 8),
                  // const Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  //   child: Text(
                  //     'Sincronizacion rapida',
                  //     style:
                  //         TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  //   ),
                  // ),
                  // StatefulBuilder(
                  //   builder: (BuildContext context, StateSetter setState) {
                  //     return SwitchListTile(
                  //       value: isTravelMode,
                  //       onChanged: (bool value) {
                  //         isTravelMode = value;
                  //         setState(() {});
                  //         _showSoon(context, 'Modo viaje aun no implementado.');
                  //       },
                  //       title: const Text('Modo viaje'),
                  //       secondary: const Icon(Icons.flight_takeoff_rounded),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: isDark
                    ? scheme.surface.withValues(alpha: 0.85)
                    : scheme.surface,
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Cerrar sesion'),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout(context, ref);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTopMenu(
    String value,
    BuildContext context,
    WidgetRef ref,
  ) async {
    switch (value) {
      case 'refresh':
        await onRefresh?.call();
        return;
      case 'config':
        if (_currentLocation(context) != '/configuracion') {
          context.go('/configuracion');
        }
        return;
      case 'logout':
        _logout(context, ref);
        return;
      default:
        return;
    }
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(localAuthServiceProvider).clearRememberedSession();
    ref.read(currentSessionProvider.notifier).state = null;
    context.go('/login');
  }

  void _go(
    BuildContext context,
    String route,
    String activeRoute,
    LicenseStatus licenseStatus,
  ) {
    if (activeRoute != route) {
      if (_isSalesRoute(route) && !licenseStatus.canSell) {
        _showSoon(
          context,
          'La licencia no permite usar el modulo de ventas.',
        );
        context.go('/configuracion');
        return;
      }
      context.go(route);
    }
  }

  String _currentLocation(BuildContext context) {
    return GoRouterState.of(context).uri.path;
  }

  static void _showSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget? _buildLicenseBanner(
    BuildContext context,
    LicenseStatus status,
    String activeRoute,
  ) {
    if (status.isLoading) {
      return null;
    }

    final int? daysRemaining = status.daysRemaining;
    final bool showTrialWarning =
        status.isTrial && daysRemaining != null && daysRemaining <= 3;
    if (!status.isBlocked && !showTrialWarning) {
      return null;
    }

    final ThemeData theme = Theme.of(context);
    final bool isBlocked = status.isBlocked;
    final Color background = isBlocked
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final Color foreground = isBlocked
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      color: background,
      child: Row(
        children: <Widget>[
          Icon(
            isBlocked ? Icons.lock_outline_rounded : Icons.timer_outlined,
            color: foreground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.message,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
          if (activeRoute != '/configuracion')
            TextButton(
              onPressed: () => context.go('/configuracion'),
              child: Text(
                'Activar',
                style: TextStyle(color: foreground),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSalesRoute(String route) {
    return route == '/ventas-pos' || route == '/ventas-directas';
  }
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}
