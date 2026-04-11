# Granja Movil

Aplicacion Flutter del micro-ERP avicola. Esta app es la interfaz operativa que usa el personal de la granja para registrar produccion, consultar inventario, vender, manejar caja, atender pedidos y administrar recordatorios.

Consume la API del proyecto `granja-backend` y concentra la experiencia diaria de uso del sistema.

## Que significa este proyecto

La app representa el lado operativo del negocio. Desde aqui se hacen tareas como:

- iniciar sesion en el sistema
- registrar lotes y movimientos de aves
- capturar produccion diaria
- clasificar huevos por tamano
- revisar stock disponible
- vender producto y consultar clientes
- abrir o cerrar caja
- crear recordatorios
- administrar usuarios
- programar y entregar pedidos

## Stack tecnico

- Flutter
- Dart
- `provider` para estado global
- `http` para consumo de API
- `flutter_secure_storage` para token de autenticacion
- `flutter_local_notifications` para recordatorios locales
- `flutter_dotenv` para configuracion por entorno

## Relacion con el backend

Esta aplicacion depende del backend Laravel del repositorio `granja-backend`.

Flujo general:

1. El usuario inicia sesion.
2. La app guarda el token en almacenamiento seguro.
3. Cada modulo consume endpoints del backend usando ese token.
4. Los cambios de inventario, ventas, caja, pedidos y recordatorios se reflejan desde la API.

## Modulos visibles en la app

### 1. Autenticacion

- Login
- Mantener sesion
- Recuperacion de contrasena

### 2. Lotes

- Listado de lotes
- Alta y edicion
- Mortalidad
- Ajustes de aves

### 3. Productos

- Configuracion de tamanos
- Precios por tamano

### 4. Produccion

- Paso 1: recoleccion de huevos por lote
- Paso 2: limpieza y clasificacion
- Resumen diario
- Totales por lote
- Estadisticas
- Inventario disponible
- Huevos remanentes en mesa

### 5. Ventas y clientes

- Clientes
- Registro de venta
- Historial de ventas
- Cuentas por cobrar

### 6. Caja

- Caja activa
- Apertura y cierre
- Ingresos y egresos
- Historial de sesiones
- Rubros de egreso

### 7. Recordatorios

- Lista de recordatorios activos
- Historial
- Notificaciones locales en el dispositivo

### 8. Usuarios

- Perfil
- Lista de usuarios
- Formulario de usuarios

### 9. Pedidos

- Pedidos pendientes
- Historial
- Crear, editar, posponer o entregar pedidos

## Estructura principal

```text
granja-movil/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   └── services/
│   ├── features/
│   │   ├── auth/
│   │   ├── batches/
│   │   ├── cash/
│   │   ├── inventory/
│   │   ├── orders/
│   │   ├── products/
│   │   ├── production/
│   │   ├── reminders/
│   │   ├── sales/
│   │   └── users/
│   ├── shared/
│   └── main.dart
├── assets/
├── android/
├── ios/
├── web/
├── linux/
├── macos/
└── windows/
```

## Donde buscar cada cosa

- `lib/main.dart`: punto de entrada y registro global de providers.
- `lib/core/constants/api_constants.dart`: URLs base y rutas principales de API.
- `lib/core/services`: servicios compartidos como autenticacion y notificaciones.
- `lib/features/*/views`: pantallas.
- `lib/features/*/providers`: estado y coordinacion de UI.
- `lib/features/*/services`: llamadas HTTP al backend.
- `lib/features/*/models`: modelos de datos.

## Arquitectura funcional

Cada feature sigue, en general, esta idea:

- `views`: interfaz de usuario
- `providers`: estado, carga, errores y coordinacion de acciones
- `services`: consumo directo de la API
- `models`: parseo y representacion de datos

Eso hace que una persona nueva pueda entrar por modulo sin tener que entender toda la app de una vez.

## Configuracion por entorno

La app espera un archivo `.env` en la raiz del proyecto. Segun el codigo actual, se usan variables como:

```env
APP_NAME=
ENV_PLATFORM=
URL_MAC_SIMULATOR=
URL_ANDROID_EMULATOR=
URL_PHYSICAL_DEVICE=
API_BASE_URL=
```

`ENV_PLATFORM` selecciona que URL base usar:

- `1`: simulador en Mac
- `2`: emulador Android
- `3`: dispositivo fisico

Si una persona nueva va a correr la app, necesita ajustar estas rutas para que apunten al backend correcto.

## Instalacion local

```bash
flutter pub get
```

Luego ejecutar, por ejemplo:

```bash
flutter run
```

## Dependencias clave

Las dependencias mas relevantes para entender el proyecto son:

- `provider`: estado global
- `http`: llamadas al backend
- `flutter_secure_storage`: guardar token
- `flutter_dotenv`: cargar configuracion local
- `intl`: fechas y formatos
- `flutter_local_notifications`: recordatorios locales
- `fl_chart`: graficas de estadisticas

## Pantallas y experiencia general

La app arranca validando sesion. Si el usuario ya tiene token valido, entra al dashboard principal; si no, ve la pantalla de login.

Desde el dashboard se disparan varias cargas iniciales:

- recordatorios activos
- caja activa
- pedidos pendientes
- ventas

Esto indica que la app esta pensada para uso diario, no solo para administracion ocasional.

## Notas importantes para nuevos colaboradores

- Esta app no funciona aislada: necesita el backend corriendo.
- Gran parte de la logica visible depende de respuestas del backend, especialmente inventario, caja, ventas y pedidos.
- Hay notificaciones locales para recordatorios y pedidos.
- Muchas pantallas estan orientadas a operacion real, por lo que hay reglas del negocio reflejadas en texto, estados y flujos.

## Archivos utiles para entender el proyecto rapido

Si alguien nuevo necesita ubicarse rapido, estos archivos son un buen punto de entrada:

1. `lib/main.dart`
2. `lib/core/constants/api_constants.dart`
3. `lib/features/production/views/daily_production_screen.dart`
4. `lib/features/orders/views/orders_pending_screen.dart`
5. `lib/features/cash/providers/cash_provider.dart`

## Documentacion interna adicional

Hay dos archivos que ayudan a entender el contexto historico del proyecto:

- `tracker_granja.md`: seguimiento funcional del sistema
- `reglas.md`: reglas de trabajo y enfoque modular usados durante el desarrollo

Importante:

- `tracker_granja.md` parece estar parcialmente desactualizado respecto al codigo actual. Hay modulos que en el tracker aparecen pendientes pero ya tienen implementacion en la app y en el backend.

## Sobre pruebas

Existe un archivo `test/widget_test.dart`, pero actualmente corresponde al ejemplo inicial de Flutter y no representa el comportamiento real de la aplicacion. Si alguien nuevo va a trabajar seriamente en el proyecto, conviene considerar una estrategia de pruebas mas alineada con las features actuales.
