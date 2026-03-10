# POSIPV

Aplicacion movil offline-first para ventas, almacenes, stock y puntos de venta.

## Entorno Flutter instalado en este proyecto

- Flutter SDK: `3.41.4` en `.sdk/flutter`
- JDK local: `17.0.18` en `.sdk/jdk-17`
- Android SDK detectado: `/home/mdoz/Android/Sdk`
- Java usada por el proyecto: `JAVA_HOME=.sdk/jdk-17` (via `scripts/flutter_env.sh`)

Para cargar variables de entorno en tu terminal:

```bash
source scripts/flutter_env.sh
flutter --version
```

## Estado actual de validacion

- `flutter --version`: OK
- `flutter analyze`: OK (sin issues)
- `flutter test`: OK
- Build Android debug: OK
- Instalacion en dispositivo fisico (ADB): OK

## Estructura del proyecto

- `lib/app`: bootstrap, router y tema.
- `lib/core`: base de datos local, seguridad, backup y utilidades.
- `lib/shared`: modelos y widgets compartidos.
- `lib/features`: modulos funcionales por dominio.

## Modulos iniciales

- `auth`
- `productos`
- `inventario`
- `almacenes`
- `ventas_pos`
- `reportes`
- `configuracion`

## Proximos pasos

1. Continuar con CRUDs de productos, almacenes y stock usando tablas Drift ya creadas.
2. Conectar UI de POS al `SaleService` para registrar ventas reales desde pantalla.
3. Endurecer seguridad de credenciales (migrar hash a Argon2id).
4. Implementar backup/restauracion cifrada de la base local.
5. Agregar pruebas de integracion para flujo de venta y validacion de stock.

## Estado funcional actual

- DB local Drift operativa con tablas de negocio (usuarios, productos, almacenes, stock, ventas, pagos y auditoria).
- Login offline local habilitado:
  - Usuario inicial: `admin`
  - Clave inicial: `admin123`
- Servicio transaccional de ventas offline listo en `SaleService`:
  - valida stock
  - registra venta/items/pagos
  - descuenta inventario
  - crea movimientos y auditoria
