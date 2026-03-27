# Tracker de Desarrollo: Micro-ERP Avícola

## 1. Stack Tecnológico
- Frontend: Flutter (Dart)
- Backend: Laravel (PHP)
- Base de Datos: MySQL / PostgreSQL

## 2. Reglas de Negocio Centrales
- 1 Cartón = 30 huevos.
- La consolidación suma huevos útiles de distintos lotes y los convierte a cartones y unidades sueltas.
- Las mermas (huevos quebrados/farsa) cuentan para el % de postura del ave, pero NO para venta/inventario.
- Las aves tienen un ciclo de vida útil basado en su fecha de adquisición.

## 3. Estado de Desarrollo (Checklist de Módulos)

### Módulo 1: Autenticación y Seguridad [COMPLETADO]
- [x] Configuración inicial del proyecto (Flutter y Laravel).
- [x] Migraciones y modelos de Usuarios.
- [x] Login con validación de tokens (Sanctum/JWT).
- [x] Recuperación de contraseñas mediante enlaces tokenizados.
- [x] Logo y configuración dinámica (.env).


### Módulo 2: Gestión de Lotes (Inventario Vivo) [COMPLETADO]
- [x] CRUD de Lotes (Nombre, cantidad inicial, fecha adquisición).
- [x] Registro de bajas (mortalidad) para actualizar aves vivas de forma dinámica.
- [x] Listado dinámico con estadísticas de población.
- [x] Integración completa backend-frontend.

### Módulo 3: Configuración de Productos
- [ ] Catálogo de tamaños de huevo (Grande, Mediano, Pequeño).
- [ ] Asignación de precios fijos por tamaño.

### Módulo 4: Producción y Recolección Diaria
- [ ] Interfaz de ingreso de recolección (por lote, huevos útiles, mermas).
- [ ] Lógica de consolidación automática (Suma total -> Conversión a cartones de 30).

### Módulo 5: Caja y Finanzas
- [ ] Registro de ingresos (ventas por cartón/unidad).
- [ ] Registro de egresos (alimento, empaques, vitaminas).
- [ ] Flujo de caja (Ingresos - Egresos).

### Módulo 6: Recordatorios (Push Notifications)
- [ ] Programación de tareas (ej. lavar bebederos los lunes).
- [ ] Integración de notificaciones push para alertas en el dispositivo.

### Módulo 7: Estadísticas (Dashboard)
- [ ] Gráficos de producción histórica semanal/mensual.
- [ ] Cálculo de % de postura diario.