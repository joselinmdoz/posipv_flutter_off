import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppAddActionButton extends StatelessWidget {
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

  static const Map<String, String> _defaultTargetByRoute = <String, String>{
    '/inventario': '/inventario-movimientos',
  };

  void _handlePressed(BuildContext context) {
    if (onPressed != null) {
      onPressed!.call();
      return;
    }
    final String? nextRoute =
        targetRoute ?? _defaultTargetByRoute[currentRoute ?? ''];
    if (nextRoute == null || nextRoute.trim().isEmpty) {
      return;
    }
    context.go(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final Widget fab = FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => _handlePressed(context),
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
