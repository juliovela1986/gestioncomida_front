# Estado actual de la app (frontend)

Fecha de referencia: 2026-03-22

## Contexto de despliegue

- Backend desplegado en OVH Cloud.
- Desarrollo del frontend en local apuntando al backend remoto.
- Distribucion actual en APK de pruebas para recopilar tickets reales.

## Funcionalidades implementadas

- Autenticacion con Keycloak (login WebView + refresco de token).
- Procesamiento de tickets por:
  - imagen,
  - PDF,
  - creacion manual.
- Validacion de ticket:
  - edicion de lineas,
  - borrado/alta de lineas,
  - confirmacion de sincronizacion.
- Inventario:
  - productos agrupados,
  - lotes,
  - fechas de caducidad/alerta,
  - gestion de stock.
- Ubicaciones:
  - CRUD de ubicaciones,
  - seleccion de ubicacion al procesar ticket.
- Caducidades:
  - pantalla de productos caducados/proximos,
  - gestor de fechas por linea tras sincronizar ticket.
- Notificaciones:
  - listado de notificaciones,
  - marcado de leidas,
  - navegacion contextual.
- Push notifications:
  - registro de token FCM,
  - prueba de envio desde backend,
  - manejo foreground/background.
- Compras:
  - lista de la compra,
  - catalogo de productos.
- Extra:
  - estadisticas,
  - modo oscuro,
  - multidioma (es, en, ca, eu, gl).

## Navegacion principal observada

En `lib/screens/main_navigation_screen.dart`:

- Home
- Inventario
- Tickets
- Compras
- Mas

## Detalles detectados al revisar el front

- Ademas de lo comentado, tambien esta implementado historial de tickets y edicion puntual de lineas/elementos.
- Existe `lib/screens/home_screen.dart` pero la entrada activa parece ser `HomeTab` + `MainNavigationScreen`.
- Hay bastante documentacion historica: se ha movido a `docs/archive/` para no mezclar con el estado vigente.

## Limpieza de código completada

### Fecha: 2026-03-22

#### 1. ✅ Eliminación de pantallas legacy
- **Eliminado**: `lib/screens/home_screen.dart` (archivo no usado, existía `HomeTab` como alternativa activa)
- **Verificación**: No había referencias a `HomeScreen` en ningún archivo del proyecto

#### 2. ✅ Auditoría de logs
- **Resultado**: No se encontraron logs `print()` en servicios ni pantallas
- **Estado**: Código limpio en este aspecto

#### 3. ✅ Consolidación de documentación FCM
- **Creado**: `docs/FCM_SETUP_AND_MANAGEMENT.md`
- **Contenido consolidado**:
  - Configuración inicial de Firebase
  - Navegación desde notificaciones (foreground/background/terminated)
  - Tipos de notificaciones soportadas
  - Token registration en login
  - Token deletion en logout
  - Testing y verificación
  - Notas importantes
- **Archivos históricos**: Permanecen en `docs/archive/` para referencia

## Siguiente ciclo de mejoras

1. Considerar agregar más tests unitarios para servicios críticos
2. Revisar y optimizar imports no usados en archivos
3. Documentar patrones de estado management (provider)
4. Crear guía de contribución para futuros desarrolladores

