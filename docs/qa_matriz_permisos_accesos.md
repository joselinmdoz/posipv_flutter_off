# Matriz QA de Permisos y Accesos

Fecha: 2026-03-27  
Base: `lib/core/security/app_permissions.dart`, `lib/core/security/session_access.dart`

## 1) Roles base (comportamiento esperado)

| Rol | Permisos esperados |
| --- | --- |
| `admin` | Todos los permisos (`allKeys`) |
| `cashier` | `home.view`, `tpv.view`, `tpv.manage.sessions`, `sales.pos`, `customers.view`, `customers.manage`, `reports.ipv` |

Nota QA: validar también un rol personalizado para cada permiso crítico (`products.manage`, `warehouses.manage`, `tpv.manage.terminals`, `settings.data`), porque fueron reforzados recientemente.

## 2) Matriz permiso -> pantallas -> acciones

| Permiso | Pantallas/rutas | Acciones que deben habilitarse |
| --- | --- | --- |
| `home.view` | `/home`, `/perfil-empleado` | Ver panel principal y perfil de empleado. |
| `tpv.view` | `/tpv` | Ver listado de terminales y operar flujo de sesión según acceso al TPV. |
| `tpv.manage.terminals` | `/tpv` | Crear TPV, editar TPV y desactivar TPV. |
| `tpv.manage.employees` | `/tpv-empleados` | Crear/editar empleados TPV. |
| `tpv.manage.sessions` | `/sync-manual` | Ejecutar sincronización manual de sesión/turno. |
| `sales.pos` | `/ventas-pos` | Vender desde POS. |
| `sales.direct` | `/ventas-directas` | Vender en módulo de ventas directas. |
| `customers.view` | `/clientes`, `/consignaciones` | Ver clientes y listado de consignaciones. |
| `customers.manage` | `/clientes` | Crear/editar clientes. |
| `inventory.view` | `/inventario` | Ver inventario. |
| `inventory.movements` | `/inventario-movimientos` | Registrar y administrar movimientos. |
| `products.view` | `/productos` | Ver catálogo de productos. |
| `products.manage` | `/productos` | Crear/editar/dar de baja productos. |
| `warehouses.view` | `/almacenes` | Ver almacenes y detalle de stock. |
| `warehouses.manage` | `/almacenes` | Crear/editar/eliminar almacenes. |
| `reports.general` | `/reportes` | Ver analítica de ventas (si licencia lo permite). |
| `reports.ipv` | `/ipv-reportes` | Ver reportes IPV. |
| `settings.view` | `/configuracion` | Ver módulo Ajustes. |
| `settings.data` | `/configuracion` | Editar información del negocio, transacciones, métodos de pago, gestión de datos. |
| `settings.currency` | `/configuracion-monedas` | Gestionar moneda y tasas. |
| `settings.security` | `/configuracion-seguridad` | Configurar seguridad/contraseña. |
| `settings.dashboard.widgets` | `/configuracion-dashboard-widgets` | Configurar widgets del dashboard. |
| `settings.license` | `/licencia` | Ver/gestionar licencia. |
| `users.manage` | `/configuracion-usuarios`, `/configuracion-roles`, `/configuracion-archivados` | Gestionar usuarios, roles y accesos a archivados. |
| `products.manage` | `/configuracion-catalogos-producto`, `/configuracion-unidades-medida`, `/configuracion-tipos-unidad` | Administrar catálogos y unidades de producto. |

## 3) Reglas reforzadas (validar explícitamente)

1. En `/productos`, usuario sin `products.manage`:
- No ve botón `+`.
- No puede abrir edición por tap de tarjeta.
- Si llega al formulario por navegación indirecta, ve bloqueo y no puede guardar.

2. En `/almacenes`, usuario sin `warehouses.manage`:
- No ve botón `+`.
- No ve menú de editar/eliminar en tarjetas.
- Si llega al form o detalle, no puede guardar cambios.

3. En `/tpv`, usuario sin `tpv.manage.terminals`:
- No ve botón `+`.
- No ve acción de editar/desactivar en menú de tarjeta.
- Si llega al formulario de TPV por navegación indirecta, no puede guardar.

4. En `/configuracion`, usuario sin `settings.data`:
- No puede abrir “Información del negocio”.
- No puede abrir “Configuración de transacciones”.
- Sí puede ver Ajustes (si tiene `settings.view`) y usar solo opciones permitidas por permisos específicos.

## 4) Matriz rápida esperada para `cashier` (rol por defecto)

| Módulo | Esperado |
| --- | --- |
| Inicio (`/home`) | Permitido |
| TPV (`/tpv`) | Permitido (solo operación, sin gestionar terminales) |
| Sync manual (`/sync-manual`) | Permitido |
| Ventas POS (`/ventas-pos`) | Permitido |
| Ventas directas (`/ventas-directas`) | Denegado |
| Consignaciones (`/consignaciones`) | Permitido |
| Clientes (`/clientes`) | Permitido (incluye gestionar clientes) |
| Inventario (`/inventario`) | Denegado |
| Movimientos (`/inventario-movimientos`) | Denegado |
| Productos (`/productos`) | Denegado |
| Almacenes (`/almacenes`) | Denegado |
| Reportes generales (`/reportes`) | Denegado |
| IPV (`/ipv-reportes`) | Permitido |
| Ajustes (`/configuracion`) | Denegado |
| Usuarios/Roles | Denegado |
| Licencia | Denegado |

## 5) Checklist QA (ejecución sugerida)

1. Login como `admin` y confirmar acceso total (rutas + acciones de escritura).
2. Login como `cashier` y confirmar denegaciones por ruta.
3. Crear rol “visor_productos” (`products.view` sin `products.manage`) y validar que no pueda editar/crear/baja productos.
4. Crear rol “visor_almacenes” (`warehouses.view` sin `warehouses.manage`) y validar que no pueda crear/editar/eliminar.
5. Crear rol “operador_tpv” (`tpv.view` sin `tpv.manage.terminals`) y validar que no pueda crear/editar/desactivar TPV.
6. Crear rol “ajustes_lectura” (`settings.view` sin `settings.data`) y validar bloqueo de edición en negocio/transacciones.

## 6) Criterio de aceptación

Una prueba falla si ocurre cualquiera de estos casos:

- Se permite una acción de escritura sin permiso `*.manage` correspondiente.
- Se muestra botón de acción (crear/editar/eliminar) cuando no debe mostrarse.
- Se permite navegación a una ruta protegida sin el permiso requerido.
- El bloqueo visual existe pero la acción aún se ejecuta.
