import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/licensing/license_models.dart';
import '../core/licensing/license_providers.dart';
import '../core/security/session_access.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/almacenes/presentation/almacenes_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/configuracion/presentation/configuracion_page.dart';
import '../features/configuracion/presentation/archived_data_page.dart';
import '../features/configuracion/presentation/dashboard_widgets_settings_page.dart';
import '../features/configuracion/presentation/currency_settings_page.dart';
import '../features/configuracion/presentation/measurement_units_settings_page.dart';
import '../features/configuracion/presentation/measurement_unit_types_settings_page.dart';
import '../features/configuracion/presentation/payment_methods_settings_page.dart';
import '../features/configuracion/presentation/product_catalog_settings_page.dart';
import '../features/configuracion/presentation/security_page.dart';
import '../features/auth/presentation/user_access_management_page.dart';
import '../features/auth/presentation/role_permissions_management_page.dart';
import '../features/clientes/presentation/clientes_page.dart';
import '../features/consignaciones/presentation/consignaciones_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/home/presentation/home_recent_activity_page.dart';
import '../features/inventario/presentation/inventario_page.dart';
import '../features/inventario/presentation/movimientos_inventario_page.dart';
import '../features/licencia/presentation/licencia_page.dart';
import '../features/productos/presentation/productos_page.dart';
import '../features/compras/presentation/compras_page.dart';
import '../features/reportes/presentation/reportes_page.dart';
import '../features/reportes/presentation/ipv_reportes_page.dart';
import '../features/reportes/presentation/ipv_manual_page.dart';
import '../features/reportes/presentation/lots_status_page.dart';
import '../features/sync_manual/presentation/manual_sync_page.dart';
import '../features/tpv/presentation/tpv_page.dart';
import '../features/tpv/presentation/tpv_employees_page.dart';
import '../features/tpv/presentation/employee_profile_page.dart';
import '../features/ventas_directas/presentation/ventas_directas_page.dart';
import '../features/ventas_pos/presentation/ventas_pos_page.dart';
import '../shared/models/user_session.dart';

final Provider<ValueNotifier<int>> _routerRefreshProvider =
    Provider<ValueNotifier<int>>((Ref ref) {
  final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  ref.listen<UserSession?>(currentSessionProvider,
      (UserSession? _, UserSession? __) {
    notifier.value++;
  });
  ref.listen<LicenseStatus>(currentLicenseStatusProvider,
      (LicenseStatus? _, LicenseStatus __) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);
  return notifier;
});

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refreshListenable =
      ref.watch(_routerRefreshProvider);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final String route = state.uri.path;
      final UserSession? session = ref.read(currentSessionProvider);
      final LicenseStatus license = ref.read(currentLicenseStatusProvider);
      final bool isPublicRoute = route == '/splash' || route == '/login';

      if (session == null) {
        return isPublicRoute ? null : '/login';
      }

      if (route == '/login' || route == '/splash') {
        final String fallback = SessionAccess.firstAllowedRoute(session);
        return fallback == '/login' ? '/home' : fallback;
      }

      if (!SessionAccess.canAccessRoute(session, route)) {
        final String fallback = SessionAccess.firstAllowedRoute(session);
        if (fallback == route) {
          return null;
        }
        return fallback;
      }

      if (_isLicenseRestrictedSalesRoute(route) && !license.canSell) {
        final String fallback = _licenseFallbackRoute(session);
        if (fallback == route) {
          return null;
        }
        return fallback;
      }

      if ((route == '/reportes' || route == '/reportes-lotes') &&
          !license.canAccessGeneralReports) {
        if (SessionAccess.canAccessRoute(session, '/ipv-reportes')) {
          return '/ipv-reportes';
        }
        final String fallback = _licenseFallbackRoute(session);
        if (fallback == route) {
          return null;
        }
        return fallback;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: <StatefulShellBranch>[
          _branch(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          _branch(
            path: '/productos',
            builder: (context, state) => const ProductosPage(),
          ),
          _branch(
            path: '/almacenes',
            builder: (context, state) => const AlmacenesPage(),
          ),
          _branch(
            path: '/inventario',
            builder: (context, state) => const InventarioPage(),
          ),
          _branch(
            path: '/inventario-movimientos',
            builder: (context, state) => const MovimientosInventarioPage(),
          ),
          _branch(
            path: '/compras',
            builder: (context, state) => const ComprasPage(),
          ),
          _branch(
            path: '/ventas-pos',
            builder: (context, state) => const VentasPosPage(),
          ),
          _branch(
            path: '/ventas-directas',
            builder: (context, state) => const VentasDirectasPage(),
          ),
          _branch(
            path: '/consignaciones',
            builder: (context, state) => const ConsignacionesPage(),
          ),
          _branch(
            path: '/clientes',
            builder: (context, state) => const ClientesPage(),
          ),
          _branch(
            path: '/tpv',
            builder: (context, state) => const TpvPage(),
          ),
          _branch(
            path: '/tpv-empleados',
            builder: (context, state) => TpvEmployeesPage(
              openCreateOnLoad: state.uri.queryParameters['new'] == '1',
            ),
          ),
          _branch(
            path: '/perfil-empleado',
            builder: (context, state) => const EmployeeProfilePage(),
          ),
          _branch(
            path: '/reportes',
            builder: (context, state) => const ReportesPage(),
          ),
          _branch(
            path: '/ipv-reportes',
            builder: (context, state) => const IpvReportesPage(),
          ),
          _branch(
            path: '/ipv-manual',
            builder: (context, state) => const IpvManualPage(),
          ),
          _branch(
            path: '/configuracion',
            builder: (context, state) => const ConfiguracionPage(),
          ),
          _branch(
            path: '/configuracion-usuarios',
            builder: (context, state) => const UserAccessManagementPage(),
          ),
          _branch(
            path: '/configuracion-roles',
            builder: (context, state) => const RolePermissionsManagementPage(),
          ),
          _branch(
            path: '/configuracion-dashboard-widgets',
            builder: (context, state) => const DashboardWidgetsSettingsPage(),
          ),
          _branch(
            path: '/licencia',
            builder: (context, state) => const LicenciaPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/configuracion-seguridad',
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: '/configuracion-monedas',
        builder: (context, state) => const CurrencySettingsPage(),
      ),
      GoRoute(
        path: '/configuracion-catalogos-producto',
        builder: (context, state) => const ProductCatalogSettingsPage(),
      ),
      GoRoute(
        path: '/configuracion-unidades-medida',
        builder: (context, state) => const MeasurementUnitsSettingsPage(),
      ),
      GoRoute(
        path: '/configuracion-tipos-unidad',
        builder: (context, state) => const MeasurementUnitTypesSettingsPage(),
      ),
      GoRoute(
        path: '/configuracion-archivados',
        builder: (context, state) => const ArchivedDataPage(),
      ),
      GoRoute(
        path: '/configuracion-metodos-pago',
        builder: (context, state) => const PaymentMethodsSettingsPage(),
      ),
      GoRoute(
        path: '/sync-manual',
        builder: (context, state) => const ManualSyncPage(),
      ),
      GoRoute(
        path: '/reportes-lotes',
        builder: (context, state) => const LotsStatusPage(),
      ),
      GoRoute(
        path: '/home-actividad-reciente',
        builder: (context, state) => const HomeRecentActivityPage(),
      ),
    ],
  );
});

bool _isLicenseRestrictedSalesRoute(String route) {
  return route == '/ventas-pos' ||
      route == '/ventas-directas' ||
      route == '/consignaciones';
}

String _licenseFallbackRoute(UserSession session) {
  const List<String> candidates = <String>[
    '/licencia',
    '/configuracion',
    '/home',
    '/tpv',
    '/clientes',
    '/inventario',
    '/productos',
    '/almacenes',
    '/ipv-reportes',
    '/configuracion-usuarios',
  ];

  for (final String route in candidates) {
    if (SessionAccess.canAccessRoute(session, route)) {
      return route;
    }
  }

  final String firstAllowed = SessionAccess.firstAllowedRoute(session);
  if (firstAllowed == '/reportes' ||
      _isLicenseRestrictedSalesRoute(firstAllowed)) {
    return '/login';
  }
  return firstAllowed;
}

StatefulShellBranch _branch({
  required String path,
  required GoRouterWidgetBuilder builder,
}) {
  return StatefulShellBranch(
    routes: <RouteBase>[
      GoRoute(
        path: path,
        builder: builder,
      ),
    ],
  );
}
