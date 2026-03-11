import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  });

  final String title;
  final Widget body;
  final String? currentRoute;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final bool showTopTabs;

  static const List<_NavItem> _navItems = <_NavItem>[
    _NavItem('Principal', '/home', Icons.grid_view_rounded),
    _NavItem('Ventas', '/ventas-pos', Icons.point_of_sale_rounded),
    _NavItem('Inventario', '/inventario', Icons.inventory_2_outlined),
    _NavItem('Productos', '/productos', Icons.shopping_bag_outlined),
    _NavItem('Almacenes', '/almacenes', Icons.warehouse_outlined),
    _NavItem('Reportes', '/reportes', Icons.bar_chart_rounded),
    _NavItem('Ajustes', '/configuracion', Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String activeRoute = currentRoute ?? _currentLocation(context);

    return Scaffold(
      drawer: _buildDrawer(context, ref, activeRoute),
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Buscar',
            onPressed: () =>
                _showSoon(context, 'Busqueda rapida proximamente.'),
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
          const SizedBox(width: 4),
        ],
        bottom: showTopTabs
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _buildTopTabs(context, activeRoute),
              )
            : null,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFF4F1FA), Color(0xFFECE8F4)],
          ),
        ),
        child: body,
      ),
    );
  }

  Widget _buildTopTabs(BuildContext context, String activeRoute) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1A000000))),
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
                onTap: () => _go(context, item.route, activeRoute),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFDDD5F4)
                        : const Color(0xFFEDE8F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        item.icon,
                        size: 16,
                        color: const Color(0xFF4A3F73),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF3A3354),
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

  Drawer _buildDrawer(BuildContext context, WidgetRef ref, String activeRoute) {
    bool isTravelMode = false;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'POSIPV',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4C4376),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ventas y control offline',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5C5970)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                      selectedTileColor: const Color(0xFFE2DBF6),
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
                        _go(context, item.route, activeRoute);
                      },
                    ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Sincronizacion rapida',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return SwitchListTile(
                        value: isTravelMode,
                        onChanged: (bool value) {
                          isTravelMode = value;
                          setState(() {});
                          _showSoon(context, 'Modo viaje aun no implementado.');
                        },
                        title: const Text('Modo viaje'),
                        secondary: const Icon(Icons.flight_takeoff_rounded),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: const Color(0xFFF4EFFB),
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
    ref.read(currentSessionProvider.notifier).state = null;
    context.go('/login');
  }

  void _go(BuildContext context, String route, String activeRoute) {
    if (activeRoute != route) {
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
}

class _NavItem {
  const _NavItem(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}
