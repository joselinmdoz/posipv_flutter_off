import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_local_datasource.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../core/licensing/license_models.dart';
import '../../core/licensing/license_providers.dart';
import '../../core/security/app_permissions.dart';
import '../../core/security/session_access.dart';
import '../models/user_session.dart';
import '../../features/auth/presentation/auth_providers.dart';
import 'app_bottom_navigation.dart';

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
    this.showBottomNavigationBar,
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
  final bool? showBottomNavigationBar;

  static const List<_NavItem> _navItems = <_NavItem>[
    _NavItem(
      'Principal',
      '/home',
      Icons.home_rounded,
      AppPermissionKeys.homeView,
    ),
    _NavItem(
      'TPV',
      '/tpv',
      Icons.point_of_sale_rounded,
      AppPermissionKeys.tpvView,
    ),
    _NavItem(
      'Empleados',
      '/tpv-empleados',
      Icons.badge_outlined,
      AppPermissionKeys.tpvManageEmployees,
    ),
    _NavItem(
      'Ventas',
      '/ventas-directas',
      Icons.receipt_long_rounded,
      AppPermissionKeys.salesDirect,
    ),
    _NavItem(
      'Clientes',
      '/clientes',
      Icons.groups_rounded,
      AppPermissionKeys.customersView,
    ),
    _NavItem(
      'Inventario',
      '/inventario',
      Icons.inventory_2_outlined,
      AppPermissionKeys.inventoryView,
    ),
    _NavItem(
      'Movimientos',
      '/inventario-movimientos',
      Icons.swap_horiz_rounded,
      AppPermissionKeys.inventoryMovements,
    ),
    _NavItem(
      'Productos',
      '/productos',
      Icons.shopping_bag_outlined,
      AppPermissionKeys.productsView,
    ),
    _NavItem(
      'Almacenes',
      '/almacenes',
      Icons.warehouse_outlined,
      AppPermissionKeys.warehousesView,
    ),
    _NavItem(
      'Reportes',
      '/reportes',
      Icons.bar_chart_rounded,
      AppPermissionKeys.reportsGeneral,
    ),
    _NavItem(
      'IPV',
      '/ipv-reportes',
      Icons.table_chart_outlined,
      AppPermissionKeys.reportsIpv,
    ),
    _NavItem(
      'Usuarios y Roles',
      '/configuracion-usuarios',
      Icons.manage_accounts_outlined,
      AppPermissionKeys.usersManage,
    ),
    _NavItem(
      'Licencia',
      '/licencia',
      Icons.verified_user_outlined,
      AppPermissionKeys.settingsLicense,
    ),
    _NavItem(
      'Ajustes',
      '/configuracion',
      Icons.settings_outlined,
      AppPermissionKeys.settingsView,
    ),
  ];

  static const List<_NavItem> _bottomNavItems = <_NavItem>[
    _NavItem(
      'Principal',
      '/home',
      Icons.home_rounded,
      AppPermissionKeys.homeView,
    ),
    _NavItem(
      'TPV',
      '/tpv',
      Icons.point_of_sale_rounded,
      AppPermissionKeys.tpvView,
    ),
    _NavItem(
      'Ventas',
      '/ventas-directas',
      Icons.receipt_long_rounded,
      AppPermissionKeys.salesDirect,
    ),
    _NavItem(
      'Inventario',
      '/inventario',
      Icons.inventory_2_outlined,
      AppPermissionKeys.inventoryView,
    ),
    _NavItem(
      'Ajustes',
      '/configuracion',
      Icons.settings_outlined,
      AppPermissionKeys.settingsView,
    ),
  ];

  static const Set<String> _bottomNavHiddenRoutes = <String>{
    '/ventas-directas',
    '/ventas-pos',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSession? session = ref.watch(currentSessionProvider);
    if (session == null) {
      return const LoginPage();
    }

    final String activeRoute = currentRoute ?? _currentLocation(context);
    if (!SessionAccess.canAccessRoute(session, activeRoute)) {
      final String fallback = SessionAccess.firstAllowedRoute(session);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && _currentLocation(context) != fallback) {
          _showSoon(
            context,
            'No tienes permisos para acceder a esta pantalla.',
          );
          context.go(fallback);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ThemeData theme = Theme.of(context);
    final LicenseStatus licenseStatus = ref.watch(currentLicenseStatusProvider);
    final AsyncValue<AuthUserSummary?> userSummaryAsync =
        ref.watch(authUserSummaryByIdProvider(session.userId));
    final bool isDark = theme.brightness == Brightness.dark;
    final List<Color> bodyGradient = isDark
        ? <Color>[theme.scaffoldBackgroundColor, const Color(0xFF0B1220)]
        : <Color>[theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF)];
    final Widget? licenseBanner =
        _buildLicenseBanner(context, licenseStatus, activeRoute);
    final bool hideBottomNavByRoute =
        _bottomNavHiddenRoutes.contains(activeRoute);
    final List<_NavItem> bottomItems = _bottomNavItems
        .where((_NavItem item) => item.isAllowed(session))
        .where((_NavItem item) {
      if (_isGeneralReportsRoute(item.route) &&
          !licenseStatus.canAccessGeneralReports) {
        return false;
      }
      return true;
    }).toList(growable: false);
    final bool showBottomNav = !hideBottomNavByRoute &&
        bottomItems.isNotEmpty &&
        (showBottomNavigationBar ?? showTopTabs);

    final bool allowNativeBackPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: allowNativeBackPop,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _handleSystemBack(context, activeRoute, session);
      },
      child: Scaffold(
        drawer: showDrawer
            ? _buildDrawer(
                context,
                ref,
                activeRoute,
                licenseStatus,
                session,
                userSummaryAsync.valueOrNull,
              )
            : null,
        floatingActionButton: floatingActionButton,
        appBar: AppBar(
          leading: appBarLeading,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: _buildAppBarActions(context, ref, session),
        ),
        bottomNavigationBar: bottomNavigationBar ??
            (showBottomNav
                ? AppBottomNavigation(
                    items: bottomItems
                        .map(
                          (_NavItem item) => AppBottomNavigationItem(
                            label: item.label,
                            route: item.route,
                            icon: item.icon,
                          ),
                        )
                        .toList(),
                    activeRoute: activeRoute,
                    onRouteTap: (String route) => _go(
                      context,
                      route,
                      activeRoute,
                      licenseStatus,
                      session,
                    ),
                  )
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
      ),
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) {
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
            _onTopMenu(value, context, ref, session);
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

  Drawer _buildDrawer(
    BuildContext context,
    WidgetRef ref,
    String activeRoute,
    LicenseStatus licenseStatus,
    UserSession session,
    AuthUserSummary? userSummary,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Iterable<_NavItem> visibleNavItems = _navItems.where(
      (_NavItem item) {
        if (_isGeneralReportsRoute(item.route) &&
            !licenseStatus.canAccessGeneralReports) {
          return false;
        }
        if (!item.isAllowed(session)) {
          return false;
        }
        return true;
      },
    );

    final Color titleColor =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF0F47C6);
    final String employeeName = (userSummary?.employeeName ?? '').trim();
    final String displayName =
        employeeName.isNotEmpty ? employeeName : session.username;
    final String profileSubtitle = _drawerProfileSubtitle(userSummary, session);
    final String avatarPath = (userSummary?.employeeImagePath ?? '').trim();
    final bool hasAvatar =
        avatarPath.isNotEmpty && File(avatarPath).existsSync();

    return Drawer(
      width: 328,
      backgroundColor:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'POSIPV',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFFF2D5BD),
                                image: hasAvatar
                                    ? DecorationImage(
                                        image: FileImage(File(avatarPath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: !hasAvatar
                                  ? const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF475569),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF0B1220)
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profileSubtitle.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                children: <Widget>[
                  for (final _NavItem item in visibleNavItems) ...<Widget>[
                    if (item.route == '/ipv-reportes')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                    _DrawerNavTile(
                      icon: item.icon,
                      label: item.label,
                      selected: item.route == activeRoute,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        _go(
                          context,
                          item.route,
                          activeRoute,
                          licenseStatus,
                          session,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout(context, ref);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFB91C1C),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _drawerProfileSubtitle(AuthUserSummary? user, UserSession session) {
    final List<String> roleNames = user?.roleNames ?? session.roleNames;
    if (roleNames.isNotEmpty) {
      return roleNames.join(' • ');
    }
    final String role = session.role.trim();
    if (role.isNotEmpty) {
      return role;
    }
    return 'Gestión Ejecutiva';
  }

  Future<void> _onTopMenu(
    String value,
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) async {
    switch (value) {
      case 'refresh':
        await onRefresh?.call();
        return;
      case 'config':
        if (!SessionAccess.canAccessRoute(session, '/configuracion')) {
          _showSoon(
            context,
            'No tienes permisos para abrir ajustes.',
          );
          return;
        }
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
    UserSession session,
  ) {
    if (activeRoute != route) {
      if (!SessionAccess.canAccessRoute(session, route)) {
        _showSoon(
          context,
          'No tienes permisos para acceder a ese modulo.',
        );
        return;
      }
      if (_isSalesRoute(route) && !licenseStatus.canSell) {
        _showSoon(
          context,
          'La licencia no permite usar el modulo de ventas.',
        );
        context.go('/configuracion');
        return;
      }
      if (_isGeneralReportsRoute(route) &&
          !licenseStatus.canAccessGeneralReports) {
        _showSoon(
          context,
          'Modo demo: el modulo Reportes requiere licencia activa.',
        );
        context.go('/ipv-reportes');
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
    if (status.isLoading || !status.isBlocked) {
      return null;
    }

    final ThemeData theme = Theme.of(context);
    final Color background = status.isBlocked
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final Color foreground = status.isBlocked
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      color: background,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.lock_outline_rounded,
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

  bool _isGeneralReportsRoute(String route) {
    return route == '/reportes';
  }

  Future<void> _handleSystemBack(
    BuildContext context,
    String activeRoute,
    UserSession session,
  ) async {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final String fallback = _fallbackBackRoute(activeRoute, session);
    if (fallback.trim().isEmpty || fallback == activeRoute) {
      return;
    }
    if (_currentLocation(context) != fallback) {
      context.go(fallback);
    }
  }

  String _fallbackBackRoute(String activeRoute, UserSession session) {
    String candidate;
    switch (activeRoute) {
      case '/inventario-movimientos':
        candidate = '/inventario';
        break;
      case '/configuracion-seguridad':
      case '/configuracion-monedas':
      case '/configuracion-catalogos-producto':
      case '/configuracion-unidades-medida':
      case '/configuracion-tipos-unidad':
      case '/configuracion-dashboard-widgets':
      case '/configuracion-usuarios':
      case '/configuracion-roles':
      case '/configuracion-archivados':
      case '/sync-manual':
      case '/licencia':
        candidate = '/configuracion';
        break;
      case '/tpv-empleados':
      case '/perfil-empleado':
      case '/ventas-directas':
        candidate = '/home';
        break;
      case '/ventas-pos':
        candidate = '/tpv';
        break;
      default:
        candidate = '/home';
        break;
    }
    if (!SessionAccess.canAccessRoute(session, candidate)) {
      return SessionAccess.firstAllowedRoute(session);
    }
    return candidate;
  }
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF1152D4);
    final Color textColor = selected
        ? activeColor
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    )
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Icon(icon, color: textColor, size: 29),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(
    this.label,
    this.route,
    this.icon, [
    this.permissionKey,
  ]);

  final String label;
  final String route;
  final IconData icon;
  final String? permissionKey;

  bool isAllowed(UserSession session) {
    if (permissionKey == null || permissionKey!.trim().isEmpty) {
      return true;
    }
    return session.hasPermission(permissionKey!);
  }
}
