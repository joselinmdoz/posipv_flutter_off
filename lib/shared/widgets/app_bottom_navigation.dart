import 'package:flutter/material.dart';

import 'app_bottom_navigation_button.dart';

class AppBottomNavigationItem {
  const AppBottomNavigationItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    required this.activeRoute,
    required this.onRouteTap,
  });

  final List<AppBottomNavigationItem> items;
  final String activeRoute;
  final ValueChanged<String> onRouteTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

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
            children: items.map((AppBottomNavigationItem item) {
              return Expanded(
                child: AppBottomNavigationButton(
                  label: item.label,
                  icon: item.icon,
                  isDark: isDark,
                  isActive: activeRoute == item.route,
                  onTap: () => onRouteTap(item.route),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
