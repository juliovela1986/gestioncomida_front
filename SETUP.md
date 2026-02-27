# 🚀 Instrucciones de Configuración

## 1. Instalar Dependencias

```bash
cd f:\GestionComida\gestioncomida_front
flutter pub get
```

## 2. Verificar Configuración

### Backend URL
Verifica que la URL del backend en `lib/services/api_client.dart` sea correcta:
```dart
baseUrl: 'http://192.168.1.143:8081'
```

### Keycloak URL
Verifica las URLs en `lib/services/auth_service.dart`:
```dart
final String _issuer = 'http://192.168.1.143:8180/realms/gestioncomida';
final String _discoveryUrl = 'http://192.168.1.143:8180/realms/gestioncomida/.well-known/openid-configuration';
```

## 3. Ejecutar la Aplicación

```bash
flutter run
```

## 4. Flujo de Uso

1. **Login**: Haz clic en "Iniciar Sesión"
2. **Autenticación**: Se abrirá WebView con Keycloak
3. **Home**: Después del login, verás la pantalla principal
4. **Subir Ticket**: 
   - Haz clic en "Subir Ticket"
   - Selecciona una imagen (cámara o galería)
   - Haz clic en "Procesar Ticket"
5. **Validar**: 
   - Revisa los productos detectados
   - Edita los que tengan errores (clic en el icono de editar)
   - Confirma y sincroniza al inventario

## 5. Estructura de Archivos Creados

```
lib/
├── main.dart                          ← Actualizado (Login limpio)
├── models/
│   ├── ticket.dart                    ← Actualizado
│   ├── catalog_product.dart           ← Actualizado
│   ├── inventory_item.dart            ← Actualizado
│   ├── location.dart                  ← Actualizado
│   └── notification.dart              ← Actualizado
├── services/
│   ├── ticket_service.dart            ← Actualizado
│   ├── catalog_product_service.dart   ← Nuevo
│   ├── inventory_service.dart         ← Nuevo
│   ├── location_service.dart          ← Nuevo
│   └── notification_service.dart      ← Nuevo
└── screens/
    ├── home_screen.dart               ← Nuevo
    ├── upload_ticket_screen.dart      ← Nuevo
    ├── ticket_validation_screen.dart  ← Nuevo
    └── edit_ticket_line_screen.dart   ← Nuevo
```

## 6. Troubleshooting

### Error: "No se puede conectar al backend"
- Verifica que el backend esté corriendo en `http://192.168.1.143:8081`
- Verifica que el dispositivo/emulador esté en la misma red

### Error: "Permisos de cámara denegados"
- En Android: Ve a Configuración → Apps → GestionComida → Permisos → Habilita Cámara

### Error: "Token expirado"
- Cierra sesión y vuelve a iniciar sesión

## 7. Próximas Mejoras

- [ ] Implementar endpoint PUT para actualizar líneas de ticket
- [ ] Añadir caché local de productos
- [ ] Implementar búsqueda de productos en el catálogo
- [ ] Añadir pantalla de inventario
- [ ] Implementar notificaciones push
