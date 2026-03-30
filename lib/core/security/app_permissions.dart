class AppRoleIds {
  const AppRoleIds._();

  static const String admin = 'role-admin';
  static const String cashier = 'role-cashier';
}

class AppPermissionKeys {
  const AppPermissionKeys._();

  static const String homeView = 'home.view';

  static const String tpvView = 'tpv.view';
  static const String tpvManageTerminals = 'tpv.manage.terminals';
  static const String tpvManageEmployees = 'tpv.manage.employees';
  static const String tpvManageSessions = 'tpv.manage.sessions';

  static const String salesPos = 'sales.pos';
  static const String salesDirect = 'sales.direct';

  static const String inventoryView = 'inventory.view';
  static const String inventoryMovements = 'inventory.movements';

  static const String productsView = 'products.view';
  static const String productsManage = 'products.manage';

  static const String customersView = 'customers.view';
  static const String customersManage = 'customers.manage';

  static const String warehousesView = 'warehouses.view';
  static const String warehousesManage = 'warehouses.manage';

  static const String reportsIpv = 'reports.ipv';
  static const String reportsGeneral = 'reports.general';

  static const String settingsView = 'settings.view';
  static const String settingsCurrency = 'settings.currency';
  static const String settingsSecurity = 'settings.security';
  static const String settingsData = 'settings.data';
  static const String settingsLicense = 'settings.license';
  static const String settingsDashboardWidgets = 'settings.dashboard.widgets';

  static const String usersManage = 'users.manage';
}

class AppPermissionDefinition {
  const AppPermissionDefinition({
    required this.key,
    required this.module,
    required this.label,
    required this.description,
  });

  final String key;
  final String module;
  final String label;
  final String description;
}

class AppPermissionsCatalog {
  const AppPermissionsCatalog._();

  static const List<AppPermissionDefinition> definitions =
      <AppPermissionDefinition>[
    AppPermissionDefinition(
      key: AppPermissionKeys.homeView,
      module: 'Inicio',
      label: 'Ver panel principal',
      description: 'Acceder al resumen principal.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.tpvView,
      module: 'TPV',
      label: 'Ver TPV',
      description: 'Acceder al listado de TPV.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.tpvManageTerminals,
      module: 'TPV',
      label: 'Gestionar TPV',
      description: 'Crear, editar y desactivar TPV.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.tpvManageEmployees,
      module: 'TPV',
      label: 'Gestionar empleados',
      description: 'Crear y editar empleados de TPV.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.tpvManageSessions,
      module: 'TPV',
      label: 'Gestionar turnos',
      description: 'Abrir y cerrar turnos de TPV.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.salesPos,
      module: 'Ventas',
      label: 'Vender desde TPV',
      description: 'Realizar ventas en modo TPV.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.salesDirect,
      module: 'Ventas',
      label: 'Ventas directas',
      description: 'Realizar ventas directas por almacen.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.inventoryView,
      module: 'Inventario',
      label: 'Ver inventario',
      description: 'Acceder al listado de inventario.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.inventoryMovements,
      module: 'Inventario',
      label: 'Movimientos de inventario',
      description: 'Registrar y consultar movimientos.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.productsView,
      module: 'Productos',
      label: 'Ver productos',
      description: 'Acceder al catalogo de productos.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.productsManage,
      module: 'Productos',
      label: 'Gestionar productos',
      description: 'Crear, editar e inactivar productos.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.customersView,
      module: 'Clientes',
      label: 'Ver clientes',
      description: 'Acceder al modulo de clientes.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.customersManage,
      module: 'Clientes',
      label: 'Gestionar clientes',
      description: 'Crear, editar e inactivar clientes.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.warehousesView,
      module: 'Almacenes',
      label: 'Ver almacenes',
      description: 'Acceder al modulo de almacenes.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.warehousesManage,
      module: 'Almacenes',
      label: 'Gestionar almacenes',
      description: 'Crear, editar e inactivar almacenes.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.reportsIpv,
      module: 'Reportes',
      label: 'Ver IPV',
      description: 'Acceder a reportes IPV.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.reportsGeneral,
      module: 'Reportes',
      label: 'Ver reportes generales',
      description: 'Acceder al modulo de reportes generales.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.settingsView,
      module: 'Ajustes',
      label: 'Ver ajustes',
      description: 'Acceder al modulo de ajustes.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.settingsCurrency,
      module: 'Ajustes',
      label: 'Configurar monedas',
      description: 'Editar monedas y tasas de cambio.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.settingsSecurity,
      module: 'Ajustes',
      label: 'Configurar seguridad',
      description: 'Gestionar seguridad y contrasenas.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.settingsData,
      module: 'Ajustes',
      label: 'Gestionar datos',
      description: 'Importar/exportar y copias de seguridad.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.settingsLicense,
      module: 'Ajustes',
      label: 'Gestionar licencia',
      description: 'Visualizar y activar licencia.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.settingsDashboardWidgets,
      module: 'Ajustes',
      label: 'Configurar widgets dashboard',
      description: 'Administrar widgets visibles por usuario.',
    ),
    AppPermissionDefinition(
      key: AppPermissionKeys.usersManage,
      module: 'Usuarios',
      label: 'Gestionar usuarios y roles',
      description: 'Crear usuarios, roles y permisos.',
    ),
  ];

  static final Set<String> allKeys =
      definitions.map((AppPermissionDefinition item) => item.key).toSet();

  static final Set<String> defaultCashierPermissions = <String>{
    AppPermissionKeys.homeView,
    AppPermissionKeys.tpvView,
    AppPermissionKeys.tpvManageSessions,
    AppPermissionKeys.salesPos,
    AppPermissionKeys.customersView,
    AppPermissionKeys.customersManage,
    AppPermissionKeys.reportsIpv,
  };

  static const Map<String, String> routePermissionMap = <String, String>{
    '/home': AppPermissionKeys.homeView,
    '/perfil-empleado': AppPermissionKeys.homeView,
    '/tpv': AppPermissionKeys.tpvView,
    '/sync-manual': AppPermissionKeys.tpvManageSessions,
    '/tpv-empleados': AppPermissionKeys.tpvManageEmployees,
    '/ventas-pos': AppPermissionKeys.salesPos,
    '/ventas-directas': AppPermissionKeys.salesDirect,
    '/consignaciones': AppPermissionKeys.customersView,
    '/clientes': AppPermissionKeys.customersView,
    '/inventario': AppPermissionKeys.inventoryView,
    '/inventario-movimientos': AppPermissionKeys.inventoryMovements,
    '/productos': AppPermissionKeys.productsView,
    '/almacenes': AppPermissionKeys.warehousesView,
    '/reportes': AppPermissionKeys.reportsGeneral,
    '/ipv-reportes': AppPermissionKeys.reportsIpv,
    '/configuracion': AppPermissionKeys.settingsView,
    '/configuracion-seguridad': AppPermissionKeys.settingsSecurity,
    '/configuracion-monedas': AppPermissionKeys.settingsCurrency,
    '/configuracion-catalogos-producto': AppPermissionKeys.productsManage,
    '/configuracion-unidades-medida': AppPermissionKeys.productsManage,
    '/configuracion-tipos-unidad': AppPermissionKeys.productsManage,
    '/configuracion-archivados': AppPermissionKeys.usersManage,
    '/configuracion-usuarios': AppPermissionKeys.usersManage,
    '/configuracion-roles': AppPermissionKeys.usersManage,
    '/configuracion-dashboard-widgets':
        AppPermissionKeys.settingsDashboardWidgets,
    '/licencia': AppPermissionKeys.settingsLicense,
  };

  static const Map<String, String> routeManagePermissionMap = <String, String>{
    '/tpv': AppPermissionKeys.tpvManageTerminals,
    '/productos': AppPermissionKeys.productsManage,
    '/almacenes': AppPermissionKeys.warehousesManage,
    '/clientes': AppPermissionKeys.customersManage,
    '/configuracion': AppPermissionKeys.settingsData,
  };

  static const List<String> preferredHomeRoutes = <String>[
    '/home',
    '/tpv',
    '/ventas-pos',
    '/ventas-directas',
    '/clientes',
    '/inventario',
    '/productos',
    '/almacenes',
    '/ipv-reportes',
    '/configuracion',
  ];
}
