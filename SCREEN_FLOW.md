# Flujo de Pantallas - Gestión Comida

## 📱 Flujo Completo

```
┌─────────────────┐
│  LoginPage      │  ← Pantalla inicial con autenticación Keycloak
│  (main.dart)    │
└────────┬────────┘
         │ Login exitoso
         ▼
┌─────────────────┐
│  HomeScreen     │  ← Pantalla principal después del login
│                 │  - Botón "Subir Ticket"
└────────┬────────┘
         │ Click en "Subir Ticket"
         ▼
┌─────────────────┐
│ UploadTicket    │  ← Seleccionar imagen (cámara/galería)
│ Screen          │  - Procesar con OCR + IA
└────────┬────────┘
         │ Ticket procesado
         ▼
┌─────────────────┐
│ TicketValidation│  ← Revisar líneas del ticket
│ Screen          │  - Ver confianza de cada producto
│                 │  - Editar productos incorrectos
│                 │  - Confirmar y sincronizar
└────────┬────────┘
         │ Click en "Editar" (opcional)
         ▼
┌─────────────────┐
│ EditTicketLine  │  ← Editar manualmente
│ Screen          │  - Nombre del producto
│                 │  - Cantidad
│                 │  - Precio
└────────┬────────┘
         │ Guardar cambios
         ▼
┌─────────────────┐
│ Volver a        │
│ Validation      │
└────────┬────────┘
         │ Click en "Confirmar y Sincronizar"
         ▼
┌─────────────────┐
│ Sincronización  │  ← Productos añadidos al catálogo
│ al Inventario   │    e inventario
└─────────────────┘
```

## 🎯 Características Implementadas

### 1. **LoginPage** (main.dart)
- Autenticación con Keycloak usando OAuth2 + PKCE
- Interfaz limpia y simple
- Redirección automática a HomeScreen tras login exitoso

### 2. **HomeScreen**
- Pantalla principal después del login
- Botón para subir ticket
- Botón de logout

### 3. **UploadTicketScreen**
- Selección de imagen desde cámara o galería
- Preview de la imagen seleccionada
- Procesamiento del ticket con OCR + IA
- Manejo de errores

### 4. **TicketValidationScreen**
- Muestra información del ticket (supermercado, fecha, etc.)
- Lista de productos detectados
- Indicador de confianza por producto (verde >70%, naranja <70%)
- Botón para editar cada línea
- Botón para confirmar y sincronizar al inventario

### 5. **EditTicketLineScreen**
- Edición manual de productos
- Campos: nombre, cantidad, precio
- Muestra el texto original del OCR
- Muestra el nivel de confianza

## 🔧 Próximos Pasos

1. **Ejecutar**: `flutter pub get` para instalar `image_picker`
2. **Permisos Android**: Añadir permisos de cámara en AndroidManifest.xml
3. **Implementar API de actualización**: Endpoint PUT para actualizar líneas de ticket
4. **Añadir validaciones**: Validar campos antes de guardar
5. **Mejorar UX**: Añadir loading states y mejores mensajes de error

## 📝 Notas

- El flujo está diseñado para ser intuitivo y guiar al usuario paso a paso
- La validación permite corregir errores del OCR antes de sincronizar
- Los productos con baja confianza se marcan visualmente para revisión
