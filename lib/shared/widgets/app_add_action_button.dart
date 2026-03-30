import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/security/session_access.dart';
import '../../features/auth/presentation/auth_providers.dart';

class AppAddActionButton extends ConsumerWidget {
  const AppAddActionButton({
    super.key,
    this.currentRoute,
    this.targetRoute,
    this.onPressed,
    this.icon = Icons.add_rounded,
    this.iconSize = 32,
    this.backgroundColor = const Color(0xFF1152D4),
    this.foregroundColor = Colors.white,
    this.margin,
    this.heroTag,
    this.enforceManagePermission = true,
  });

  final String? currentRoute;
  final String? targetRoute;
  final VoidCallback? onPressed;
  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry? margin;
  final Object? heroTag;
  final bool enforceManagePermission;

  static const Map<String, String> _defaultTargetByRoute = <String, String>{
    '/inventario': '/inventario-movimientos',
  };

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handlePressed(BuildContext context, WidgetRef ref) {
    final session = ref.read(currentSessionProvider);
    final String route = (currentRoute ?? '').trim();
    if (enforceManagePermission &&
        route.isNotEmpty &&
        !SessionAccess.canManageRoute(session, route)) {
      _show(context, 'No tienes permisos para crear o editar en este módulo.');
      return;
    }

    if (onPressed != null) {
      onPressed!.call();
      return;
    }
    final String? nextRoute =
        targetRoute ?? _defaultTargetByRoute[currentRoute ?? ''];
    if (nextRoute == null || nextRoute.trim().isEmpty) {
      return;
    }
    if (!SessionAccess.canAccessRoute(session, nextRoute)) {
      _show(context, 'No tienes permisos para abrir esa pantalla.');
      return;
    }
    context.go(nextRoute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget fab = FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => _handlePressed(context, ref),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: Icon(icon, size: iconSize),
    );

    if (margin == null) {
      return fab;
    }
    return Container(
      margin: margin,
      child: fab,
    );
  }
}
