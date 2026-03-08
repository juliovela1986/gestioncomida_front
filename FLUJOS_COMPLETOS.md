# Flujos Completos de la Aplicación

## 📋 Índice de Guías

1. **NAVEGACION_TICKET_PROCESADO.md** - Navegación después de procesar PDF
2. **IMPLEMENTACION_FECHAS_CADUCIDAD.md** - Gestión de fechas de caducidad
3. **CRUD_UBICACIONES.md** - CRUD completo de ubicaciones

---

## 🎯 Flujo Principal: Procesar Ticket → Inventario

### Paso 1: Upload y procesamiento
```
Usuario selecciona PDF/imagen
  ↓
POST /api/tickets/upload
  ↓
Backend procesa con OCR + IA
  ↓
Retorna TicketProcessingResultDto con ticketId
  ↓
Frontend navega a TicketDetailScreen(ticketId)
```

### Paso 2: Revisión del ticket
```
Usuario revisa productos y cantidades
  ↓
Puede editar líneas si es necesario:
  - PUT /api/tickets/{ticketId}/lines/{lineId}
  - DELETE /api/tickets/{ticketId}/lines/{lineId}
  - POST /api/tickets/{ticketId}/lines
  ↓
Usuario presiona "Añadir al inventario"
```

### Paso 3: Sincronización a inventario
```
POST /api/tickets/{ticketId}/sync-inventory
  ↓
Backend crea/actualiza:
  - CatalogProduct (si no existe)
  - InventoryItem (con cantidades)
  ↓
Frontend navega a ExpirationDateManagerScreen
```

### Paso 4: Gestión de fechas de caducidad
```
GET /api/inventory/pending-expiration
  ↓
Retorna items sin fecha de caducidad
  ↓
Usuario asigna fechas una a una:
  - Calendario manual
  - Foto del producto (OCR futuro)
  - Saltar (sin caducidad)
  ↓
PUT /api/inventory/{id} con expirationDate
  ↓
Finalizar → Volver a inventario
```

---

## 🏠 Flujo: Gestión de Ubicaciones

### Crear ubicación
```
Usuario abre pantalla de ubicaciones
  ↓
Presiona botón "+"
  ↓
Ingresa nombre y tipo
  ↓
POST /api/locations
  ↓
Ubicación creada
```

### Usar ubicación
```
Al procesar ticket:
  - Seleccionar ubicación destino (opcional)
  
Al añadir item manual:
  - Seleccionar ubicación (requerido)
  
Al mover item:
  - PUT /api/inventory/{id} con nuevo locationId
```

---

## 📦 Flujo: Añadir Item Manual al Inventario

```
Usuario presiona "Añadir item"
  ↓
Busca producto en catálogo:
  - GET /api/catalog-products/search/by-name?name=...
  ↓
Si no existe:
  - POST /api/catalog-products/search-or-create
  ↓
Selecciona ubicación:
  - GET /api/locations
  ↓
Ingresa cantidad y fecha de caducidad
  ↓
POST /api/inventory
  ↓
Item añadido al inventario
```

---

## 🔔 Flujo: Notificaciones de Caducidad

```
Backend (Job programado):
  - Revisa items próximos a caducar
  - Crea notificaciones automáticas
  ↓
Frontend:
  - GET /api/notifications/user
  - Muestra badge con contador
  ↓
Usuario abre notificación:
  - PUT /api/notifications/{id}/mark-read
  - Navega al item de inventario
```

---

## 📊 Endpoints por Módulo

### Tickets
- `POST /api/tickets/upload` - Procesar PDF/imagen
- `GET /api/tickets` - Listar tickets (paginado)
- `GET /api/tickets/{id}` - Detalle de ticket
- `PUT /api/tickets/{id}` - Actualizar ticket
- `DELETE /api/tickets/{id}` - Eliminar ticket
- `POST /api/tickets/{id}/sync-inventory` - Sincronizar a inventario
- `POST /api/tickets/{id}/lines` - Añadir línea
- `PUT /api/tickets/{id}/lines/{lineId}` - Actualizar línea
- `DELETE /api/tickets/{id}/lines/{lineId}` - Eliminar línea

### Inventario
- `GET /api/inventory` - Listar mi inventario
- `POST /api/inventory` - Crear item
- `GET /api/inventory/{id}` - Detalle de item
- `PUT /api/inventory/{id}` - Actualizar item
- `DELETE /api/inventory/{id}` - Eliminar item
- `GET /api/inventory/pending-expiration` - Items sin fecha de caducidad

### Ubicaciones
- `GET /api/locations` - Listar mis ubicaciones
- `POST /api/locations` - Crear ubicación
- `GET /api/locations/{id}` - Detalle de ubicación
- `PUT /api/locations/{id}` - Actualizar ubicación
- `DELETE /api/locations/{id}` - Eliminar ubicación
- `GET /api/locations/by-name?name=...` - Buscar por nombre
- `GET /api/locations/exists?name=...` - Verificar existencia

### Catálogo de Productos
- `GET /api/catalog-products` - Listar todos
- `POST /api/catalog-products` - Crear producto
- `GET /api/catalog-products/{id}` - Detalle de producto
- `PUT /api/catalog-products/{id}` - Actualizar producto
- `DELETE /api/catalog-products/{id}` - Eliminar producto
- `POST /api/catalog-products/search-or-create` - Buscar o crear (deduplicación)
- `GET /api/catalog-products/search/by-name?name=...` - Buscar por nombre
- `GET /api/catalog-products/search/by-brand?brand=...` - Buscar por marca
- `GET /api/catalog-products/exists?name=...&brand=...` - Verificar existencia

### Notificaciones
- `GET /api/notifications/user` - Mis notificaciones
- `POST /api/notifications` - Crear notificación
- `GET /api/notifications/{id}` - Detalle de notificación
- `PUT /api/notifications/{id}` - Actualizar notificación
- `DELETE /api/notifications/{id}` - Eliminar notificación
- `PUT /api/notifications/{id}/mark-read` - Marcar como leída
- `PUT /api/notifications/{id}/mark-sent` - Marcar como enviada
- `PUT /api/notifications/{id}/mark-failed?reason=...` - Marcar como fallida
- `GET /api/notifications/by-status/{status}` - Por estado
- `GET /api/notifications/by-alert-type/{type}` - Por tipo
- `GET /api/notifications/by-inventory-item/{id}` - Por item

---

## 🎨 Pantallas Principales

1. **HomeScreen** - Dashboard con resumen
2. **TicketUploadScreen** - Subir PDF/imagen
3. **TicketDetailScreen** - Detalle y edición de ticket
4. **ExpirationDateManagerScreen** - Asignar fechas de caducidad
5. **InventoryScreen** - Lista de items en inventario
6. **InventoryItemDetailScreen** - Detalle de item
7. **LocationsScreen** - CRUD de ubicaciones
8. **NotificationsScreen** - Lista de notificaciones
9. **CatalogProductsScreen** - Catálogo de productos

---

## 🔐 Autenticación

Todos los endpoints requieren JWT token de Keycloak:
```
Authorization: Bearer <token>
```

---

## 🚀 Próximas Mejoras

1. **OCR de fechas de caducidad** - Escanear fecha desde foto del producto
2. **Estadísticas de consumo** - Gráficos de productos más consumidos
3. **Listas de compra** - Generar lista basada en stock bajo
4. **Compartir inventario** - Inventario familiar compartido
5. **Recetas sugeridas** - Basadas en productos próximos a caducar
