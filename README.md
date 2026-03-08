# gestioncomida_front

Organizador inteligente de alimentos con procesamiento automático de tickets de compra.

## 🚀 Características

- 📸 **Procesamiento de tickets**: Sube fotos o PDFs de tickets de compra y procesa automáticamente con OCR + IA
- 📦 **Gestión de inventario**: Control completo de tus alimentos con fechas de caducidad
- 📍 **Ubicaciones**: Organiza tus alimentos por ubicación (nevera, despensa, congelador, etc.)
- 🔔 **Notificaciones**: Alertas automáticas de productos próximos a caducar
- 📋 **Catálogo de productos**: Base de datos de productos con deduplicación automática

## 📚 Documentación

### 🎯 Guías Principales

1. **[RESUMEN_EJECUTIVO.md](RESUMEN_EJECUTIVO.md)** - 📊 Resumen completo de la implementación
2. **[GUIA_DE_USO.md](GUIA_DE_USO.md)** - 📱 Manual de usuario con ejemplos
3. **[CHECKLIST.md](CHECKLIST.md)** - ✅ Verificación de implementación

### 📖 Guías Técnicas

4. **[FLUJOS_COMPLETOS.md](FLUJOS_COMPLETOS.md)** - 📍 Resumen de todos los flujos de la aplicación
5. **[NAVEGACION_TICKET_PROCESADO.md](NAVEGACION_TICKET_PROCESADO.md)** - Navegación después de procesar PDF
6. **[IMPLEMENTACION_FECHAS_CADUCIDAD.md](IMPLEMENTACION_FECHAS_CADUCIDAD.md)** - Gestión de fechas de caducidad
7. **[CRUD_UBICACIONES.md](CRUD_UBICACIONES.md)** - CRUD completo de ubicaciones
8. **[IMPLEMENTACION_COMPLETADA.md](IMPLEMENTACION_COMPLETADA.md)** - Detalles técnicos de implementación
9. **[api-docs.yaml](api-docs.yaml)** - Especificación OpenAPI completa

### Flujo Principal

```
Upload PDF → Revisar Ticket → Sincronizar a Inventario → Asignar Fechas de Caducidad
```

Ver detalles completos en [FLUJOS_COMPLETOS.md](FLUJOS_COMPLETOS.md)

## 🛠️ Tecnologías

- **Flutter** - Framework de desarrollo
- **Dio** - Cliente HTTP
- **Keycloak** - Autenticación JWT
- **Backend API** - Spring Boot (puerto 8081)

## 💻 Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
