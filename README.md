# gestioncomida_front

Frontend Flutter de GestionComida para gestionar inventario de alimentos, procesar tickets y controlar caducidades.

## Funcionalidades principales

- Carga de tickets por imagen, PDF y creación manual.
- Revisión y edición de líneas antes de sincronizar con inventario.
- Inventario por lotes con fechas de caducidad, alertas y papelera.
- Gestión de ubicaciones y catálogo de productos.
- Análisis de precios (resumen, tendencias y comparación por supermercado).
- Notificaciones push y gestión de preferencias de limpieza.

## Requisitos

- Flutter SDK estable.
- Android Studio o VS Code con plugins de Flutter/Dart.
- Backend de GestionComida disponible (API + Keycloak).

## Configuración rápida

1. Clona el repositorio.
2. Configura URLs de backend y auth en `lib/app_config.dart` según tu entorno.
3. Instala dependencias.

```bash
flutter pub get
```

## Arranque del frontend

```bash
flutter run
```

Para ejecutar en un dispositivo concreto:

```bash
flutter devices
flutter run -d <device_id>
```

## Stack técnico

- Flutter
- Dio (cliente HTTP)
- Keycloak (OIDC/JWT)
- Firebase Cloud Messaging
- Backend Spring Boot
