import '../../shared/models/user_session.dart';
import 'app_permissions.dart';

class SessionAccess {
  const SessionAccess._();

  static bool hasPermission(UserSession? session, String permissionKey) {
    if (session == null) {
      return false;
    }
    return session.hasPermission(permissionKey);
  }

  static bool canAccessRoute(UserSession? session, String route) {
    final String? required = AppPermissionsCatalog.routePermissionMap[route];
    if (required == null) {
      return true;
    }
    return hasPermission(session, required);
  }

  static bool canManageRoute(UserSession? session, String route) {
    final String? required =
        AppPermissionsCatalog.routeManagePermissionMap[route];
    if (required == null) {
      return canAccessRoute(session, route);
    }
    return hasPermission(session, required);
  }

  static String firstAllowedRoute(UserSession? session) {
    if (session == null) {
      return '/login';
    }
    for (final String route in AppPermissionsCatalog.preferredHomeRoutes) {
      if (canAccessRoute(session, route)) {
        return route;
      }
    }
    return '/login';
  }
}
