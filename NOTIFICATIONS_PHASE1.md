# Sistema de Notificaciones - FASE 1 ✅

## Implementación Completada

### 1. Modelo de Notificación
**Archivo**: `lib/models/notification.dart`
- Representa `NotificationResponseDto` del backend
- Campos: id, inventoryItemId, channel, scheduledAt, status, reason, alertType, createdInstant

### 2. Servicio de Notificaciones
**Archivo**: `lib/services/notification_service.dart`

**Métodos**:
- `getUserNotifications()` - Obtiene todas las notificaciones del usuario (GET `/api/notifications/user`)
- `getUnreadCount()` - Cuenta notificaciones no leídas
- `markAsRead(notificationId)` - Marca notificación como leída (PUT `/api/notifications/{id}/mark-read`)

### 3. Pantalla de Notificaciones
**Archivo**: `lib/screens/notifications_screen.dart`

**Características**:
- Lista de notificaciones con pull-to-refresh
- Colores por tipo de alerta:
  - 🟠 EXPIRATION_WARNING (Naranja) - Próximo a caducar
  - 🔴 EXPIRED (Rojo) - Producto caducado
  - 🟡 LOW_STOCK (Ámbar) - Stock bajo
  - 🔵 Otros (Azul)
- Notificaciones no leídas destacadas con fondo de color
- Botón para marcar como leída
- Estado vacío con mensaje amigable

### 4. Badge en AppBar
**Archivo**: `lib/screens/home_screen.dart` (modificado)

**Características**:
- Icono de campana en AppBar
- Badge rojo con contador de notificaciones no leídas
- Muestra "9+" si hay más de 9 notificaciones
- Al tocar, navega a pantalla de notificaciones
- Se actualiza automáticamente al volver

### 5. Popup Automático al Inicio
**Archivo**: `lib/screens/home_screen.dart` (modificado)

**Características**:
- Se muestra automáticamente 500ms después de abrir la app
- Solo aparece si hay notificaciones sin leer
- Diálogo con icono de alerta naranja
- Opciones: "Después" o "Ver ahora"
- "Ver ahora" navega directamente a notificaciones

## Flujo de Usuario

1. **Usuario abre la app** → HomeScreen carga
2. **Sistema verifica notificaciones** → Llama a `/api/notifications/user`
3. **Si hay notificaciones sin leer**:
   - Badge rojo aparece en AppBar con contador
   - Popup automático se muestra después de 500ms
4. **Usuario puede**:
   - Ignorar popup y ver badge en AppBar
   - Tocar "Ver ahora" en popup
   - Tocar icono de campana en AppBar
5. **En pantalla de notificaciones**:
   - Ver lista completa de alertas
   - Marcar individualmente como leídas
   - Pull-to-refresh para actualizar
6. **Al volver a Home** → Badge se actualiza automáticamente

## Tipos de Alertas Soportados

| Tipo | Icono | Color | Descripción |
|------|-------|-------|-------------|
| EXPIRATION_WARNING | ⚠️ warning_amber | Naranja | Producto próximo a caducar (3 días antes) |
| EXPIRED | ❌ error | Rojo | Producto ya caducado |
| LOW_STOCK | 📦 inventory_2 | Ámbar | Stock bajo |
| Otros | 🔔 notifications | Azul | Notificaciones generales |

## Backend Requirements

El backend debe:
1. ✅ Implementar endpoint GET `/api/notifications/user`
2. ✅ Implementar endpoint PUT `/api/notifications/{id}/mark-read`
3. ✅ Crear notificaciones automáticamente cuando `alertDate` se alcanza
4. ⏳ Tarea cron diaria para verificar `alertDate` de items de inventario
5. ⏳ Crear notificación con `alertType=EXPIRATION_WARNING` cuando corresponda

## Próximos Pasos - FASE 2 🔔

### Firebase Cloud Messaging (FCM)
- Notificaciones push reales en Android/iOS
- Funcionan con app cerrada
- Configuración de Firebase
- Token FCM en backend
- Envío de push desde backend

### Configuración necesaria:
1. Crear proyecto en Firebase Console
2. Añadir app Android/iOS
3. Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
4. Instalar paquete `firebase_messaging`
5. Configurar permisos en AndroidManifest.xml
6. Implementar listener de notificaciones
7. Enviar token FCM al backend

## Testing

### Cómo probar FASE 1:
1. Asegurar que backend está corriendo
2. Crear items de inventario con `alertDate` en el pasado o hoy
3. Backend debe crear notificaciones automáticamente
4. Abrir app → Debe aparecer popup si hay notificaciones
5. Verificar badge en AppBar muestra contador correcto
6. Navegar a pantalla de notificaciones
7. Marcar notificaciones como leídas
8. Verificar que badge se actualiza

### Datos de prueba sugeridos:
```json
{
  "inventoryItemId": "uuid-del-item",
  "channel": "IN_APP",
  "scheduledAt": "2024-01-15T10:00:00",
  "status": "PENDING",
  "alertType": "EXPIRATION_WARNING",
  "reason": "El producto 'Leche Entera' caduca en 3 días"
}
```

## Notas Técnicas

- **Estado**: HomeScreen cambió de StatelessWidget a StatefulWidget para manejar estado de notificaciones
- **Refresh**: Badge se actualiza automáticamente al volver de NotificationsScreen
- **Error handling**: Fallos en carga de notificaciones son silenciosos (no interrumpen UX)
- **Performance**: Solo se carga contador en inicio, no polling continuo
- **UX**: Delay de 500ms en popup para evitar aparecer antes de que UI esté lista

## Dependencias Utilizadas

- `dio` - HTTP client (ya existente)
- `intl` - Formateo de fechas (ya existente)
- Flutter Material - UI components

## Archivos Modificados

- ✅ `lib/models/notification.dart` (nuevo)
- ✅ `lib/services/notification_service.dart` (nuevo)
- ✅ `lib/screens/notifications_screen.dart` (nuevo)
- ✅ `lib/screens/home_screen.dart` (modificado)

## Archivos Backend Requeridos

- ⏳ Cron job para verificar `alertDate` diariamente
- ⏳ Lógica para crear notificaciones automáticamente
- ✅ Endpoint `/api/notifications/user` (ya existe)
- ✅ Endpoint `/api/notifications/{id}/mark-read` (ya existe)
