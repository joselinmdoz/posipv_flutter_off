import 'package:go_router/go_router.dart';

import '../features/almacenes/presentation/almacenes_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/configuracion/presentation/configuracion_page.dart';
import '../features/configuracion/presentation/currency_settings_page.dart';
import '../features/configuracion/presentation/security_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/inventario/presentation/inventario_page.dart';
import '../features/inventario/presentation/movimientos_inventario_page.dart';
import '../features/licencia/presentation/licencia_page.dart';
import '../features/productos/presentation/productos_page.dart';
import '../features/reportes/presentation/reportes_page.dart';
import '../features/reportes/presentation/ipv_reportes_page.dart';
import '../features/tpv/presentation/tpv_page.dart';
import '../features/tpv/presentation/tpv_employees_page.dart';
import '../features/ventas_directas/presentation/ventas_directas_page.dart';
import '../features/ventas_pos/presentation/ventas_pos_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
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
          path: '/ventas-pos',
          builder: (context, state) => const VentasPosPage(),
        ),
        _branch(
          path: '/ventas-directas',
          builder: (context, state) => const VentasDirectasPage(),
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
          path: '/reportes',
          builder: (context, state) => const ReportesPage(),
        ),
        _branch(
          path: '/ipv-reportes',
          builder: (context, state) => const IpvReportesPage(),
        ),
        _branch(
          path: '/configuracion',
          builder: (context, state) => const ConfiguracionPage(),
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
  ],
);

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
