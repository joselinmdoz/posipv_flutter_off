# POSIPV + Odoo 18: arquitectura base de sincronización

## Objetivo
Mantener POSIPV como aplicación `offline-first` y habilitar una sincronización opcional con Odoo 18 sin acoplar la app móvil a las tablas operativas nativas de Odoo.

## Enfoque
- La app Flutter sigue escribiendo primero en SQLite local.
- Los cambios sincronizables se encolan en `sync_queue_entries`.
- Odoo recibe esos cambios en modelos espejo propios del addon `posipv`.
- La contabilidad y la integración profunda con módulos base de Odoo queda para una etapa posterior.

## Flutter
### Tablas nuevas
- `sync_queue_entries`
- `sync_runs`

### Capa nueva
- `lib/features/sync_cloud/data/cloud_sync_models.dart`
- `lib/features/sync_cloud/data/cloud_sync_local_datasource.dart`
- `lib/features/sync_cloud/data/odoo_api_client.dart`
- `lib/features/sync_cloud/data/cloud_sync_orchestrator.dart`
- `lib/features/sync_cloud/presentation/cloud_sync_settings_page.dart`

### Flujo
1. Configurar URL, base y etiqueta del dispositivo.
2. Registrar dispositivo con token bootstrap.
3. Guardar `api_key` segura en el dispositivo.
4. Encolar cambios locales para push manual o automático futuro.
5. Descargar catálogos espejo desde Odoo.

### Detalle importante
Odoo necesita contexto de base de datos HTTP antes de exponer correctamente las rutas del addon.
Por eso `OdooApiClient` primero visita `/web?db=<base>` y conserva la cookie antes de llamar a los endpoints JSON.

## Odoo
### Ruta del addon
`/home/mdoz/proyectos/odoo18/addons/posipv`

### Addon HTTP server-wide
`/home/mdoz/proyectos/odoo18/addons/posipv_api`

- Se carga como módulo `server_wide`.
- Publica las rutas HTTP públicas de sincronización.
- Delega la lógica en `posipv.sync.service`.
- Se diseñó así porque las rutas `auth='none'` deben existir incluso antes de que
  Odoo construya `request.env` con una base seleccionada.

### Módulo instalado
- Nombre técnico: `posipv`
- Base validada: `posipv`

### Endpoints
- `POST /posipv/api/v1/ping`
- `POST /posipv/api/v1/device/register`
- `POST /posipv/api/v1/pull/master-data`
- `POST /posipv/api/v1/pull/work-orders`
- `POST /posipv/api/v1/push/batch`

### Nota técnica importante
- Estas rutas están declaradas con `auth='none'`.
- El controlador resuelve `db` desde query string, payload o sesión.
- Luego abre manualmente `Registry(db)` y crea un `Environment` explícito.
- Esto evita los `404` y `500` que aparecen cuando Odoo intenta resolver la ruta
  antes de tener `request.env` listo para una base concreta.

### Modelos principales
- `posipv.backend.settings`
- `posipv.sync.device`
- `posipv.sync.log`
- `posipv.catalog.product`
- `posipv.catalog.customer`
- `posipv.catalog.employee`
- `posipv.catalog.warehouse`
- `posipv.catalog.terminal`
- `posipv.sale`
- `posipv.sale.line`
- `posipv.sale.payment`
- `posipv.stock.movement`
- `posipv.work.order`
- `posipv.work.order.task`

## Estado actual
- Addon copiado al path real de Odoo.
- Addon `posipv_api` creado para exponer la API pública de forma estable.
- Módulo `posipv` instalado en la base `posipv`.
- API `ping` validada por HTTP real en `http://127.0.0.1:8062`.
- API `pull/work-orders` validada por HTTP real devolviendo pedidos del taller.
- Flutter compila y analiza sin errores en la capa de sync cloud.

## Próximo paso recomendado
Implementar conectores reales desde los módulos Flutter hacia `enqueueChange(...)` para:
- ventas POS
- ventas directas
- movimientos de inventario
- pedidos/trabajos
- maestros críticos: productos, clientes, empleados, almacenes y TPV

Luego crear la primera sincronización end-to-end real:
1. registrar dispositivo
2. push de una venta
3. push de un movimiento
4. pull de catálogos actualizados
