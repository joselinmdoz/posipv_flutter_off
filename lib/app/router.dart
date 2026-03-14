import 'package:go_router/go_router.dart';

import '../features/almacenes/presentation/almacenes_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/configuracion/presentation/configuracion_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/inventario/presentation/inventario_page.dart';
import '../features/inventario/presentation/movimientos_inventario_page.dart';
import '../features/licencia/presentation/licencia_page.dart';
import '../features/productos/presentation/productos_page.dart';
import '../features/reportes/presentation/reportes_page.dart';
import '../features/reportes/presentation/ipv_reportes_page.dart';
import '../features/tpv/presentation/tpv_page.dart';
import '../features/ventas_directas/presentation/ventas_directas_page.dart';
import '../features/ventas_pos/presentation/ventas_pos_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/productos',
      builder: (context, state) => const ProductosPage(),
    ),
    GoRoute(
      path: '/almacenes',
      builder: (context, state) => const AlmacenesPage(),
    ),
    GoRoute(
      path: '/inventario',
      builder: (context, state) => const InventarioPage(),
    ),
    GoRoute(
      path: '/inventario-movimientos',
      builder: (context, state) => const MovimientosInventarioPage(),
    ),
    GoRoute(
      path: '/ventas-pos',
      builder: (context, state) => const VentasPosPage(),
    ),
    GoRoute(
      path: '/ventas-directas',
      builder: (context, state) => const VentasDirectasPage(),
    ),
    GoRoute(
      path: '/tpv',
      builder: (context, state) => const TpvPage(),
    ),
    GoRoute(
      path: '/tpv-empleados',
      builder: (context, state) => TpvEmployeesPage(
        openCreateOnLoad: state.uri.queryParameters['new'] == '1',
      ),
    ),
    GoRoute(
      path: '/reportes',
      builder: (context, state) => const ReportesPage(),
    ),
    GoRoute(
      path: '/ipv-reportes',
      builder: (context, state) => const IpvReportesPage(),
    ),
    GoRoute(
      path: '/configuracion',
      builder: (context, state) => const ConfiguracionPage(),
    ),
    GoRoute(
      path: '/licencia',
      builder: (context, state) => const LicenciaPage(),
    ),
  ],
);
