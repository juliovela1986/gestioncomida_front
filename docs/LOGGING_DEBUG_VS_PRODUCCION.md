# Logging: debug vs producción (tickets / OCR)

**Fecha:** 2026-10-10  
**Jira:** [SCRUM-122](https://juliovela86.atlassian.net/browse/SCRUM-122)  
**Ámbito:** Flutter `gestioncomida_front` (prioridad: flujo ticket OCR; luego resto de `print`).

---

## Problema

Hoy hay muchos `print(...)` en servicios y pantallas de ticket:

| Sitio (ejemplos) | Qué saca |
|------------------|----------|
| `TicketService.getTicketById` | Payload completo JSON (líneas OCR, rawText…) |
| `ticket_validation_screen` | Trazas de carga/validación + banner “Ver texto OCR” |
| `upload_ticket_screen` | Response data del upload |
| `ApiClient` / `AuthService` / `FCM` | Tokens parciales, URLs, bodies |

Eso es **útil en desarrollo** (consola / logcat). En **producción** el usuario común:

- No entiende dumps OCR / JSON.
- Puede ver datos sensibles en logcat (si el build no strippea `print`).
- Necesita mensajes accionables: *vuelve a capturar según la guía* o *reporta al administrador*.

---

## Objetivo

Dos capas claras:

| Modo | Nivel | Qué ve el usuario / logcat |
|------|-------|----------------------------|
| **Debug** (`kDebugMode` / profile opcional) | DEBUG | Trazas técnicas: OCR raw, payloads, IDs, stack |
| **Release / producción** | INFO (y errores user-friendly) | SnackBars / diálogos claros; **sin** dump OCR ni JSON crudo |

No se trata de “apagar logs”, sino de **cambiar el contenido y el canal**:

- Debug → `AppLogger.debug` / `developer.log` (solo si `kDebugMode`).
- Prod → `AppLogger.info` / UI: mensaje humano + enlace a guía de captura.

---

## Diseño propuesto

### 1. `AppLogger` (`lib/core/app_logger.dart`)

```dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message, [Object? detail]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[DEBUG] $message${detail != null ? ' | $detail' : ''}');
    }
  }

  static void info(String message) {
    // Visible en release solo si se decide (Logcat filtrable) o no-op + analytics.
    if (kDebugMode) print('[INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? st]) {
    // Errores: siempre se puede enviar a Crashlytics; print solo en debug.
    if (kDebugMode) print('[ERROR] $message | $error\n$st');
  }
}
```

Regla: **sustituir `print`/`debugPrint` sueltos** por `AppLogger.*`.  
Nunca loguear tokens JWT completos ni `rawText` OCR en release.

### 2. UI tickets (validación / upload)

| Situación | Debug | Producción |
|-----------|-------|------------|
| Ticket bien parseado | Log detalle líneas | Nada (o toast breve “Ticket listo”) |
| OCR vacío / confianza baja | Dump `rawText` + banner técnico | Banner: *No se han podido leer bien los productos. Vuelve a capturar la foto siguiendo la guía de captura (luz, enfoque, ticket completo). Si el problema continúa, reporta al administrador.* |
| Error de red / 5xx | Stack + body | *No se pudo procesar el ticket. Inténtalo de nuevo. Si persiste, contacta al administrador.* |
| Botón “Ver texto OCR” | Visible en debug (y quizá flag admin) | **Oculto** en release salvo rol ADMIN / menú oculto |

Copy i18n (claves nuevas, ej.):

- `ticket_ocr_failed_user`
- `ticket_ocr_retry_guide`
- `ticket_report_admin`

Enlazar guía existente de captura (doc/assets en app o URL ayuda).

### 3. Builds

- `flutter run` / debug APK → capa DEBUG activa.
- `flutter build apk --release` → solo mensajes usuario + (opcional) Crashlytics.

Opcional futuro: `AppConfig.enableVerboseLogs` forzado en staging.

---

## Alcance de implementación (checklist)

1. [ ] Crear `AppLogger` + regla en `AGENTS.md`.
2. [ ] Migrar `TicketService`, `upload_ticket_screen`, `ticket_validation_screen` (prioridad).
3. [ ] Ocultar / acotar “Ver texto OCR” y “Texto Original OCR” en release.
4. [ ] Copy usuario + i18n + enlace a guía de captura.
5. [ ] Barrido resto: `ApiClient`, Auth, FCM, Inventory (misma regla).
6. [ ] Test: en debug se ve dump; en release (widget/`kDebugMode` mock) no aparece raw OCR.

Fuera de alcance inicial: backend logging (SLF4J ya tiene niveles).

---

## Criterios de aceptación

1. En **release**, al abrir/validar un ticket no se imprime el payload OCR completo en logcat.
2. Si el OCR falla o no genera líneas, el usuario ve mensaje accionable (recaptura + guía / reportar admin), no jerga “OCR/confianza”.
3. En **debug**, las trazas actuales (o equivalentes) siguen disponibles vía `AppLogger.debug`.
4. Documentación (`este MD` + nota en `AGENTS.md`) alineada con Jira.

---

## Relacionado

- Flujo validación ticket / `rawText` en `ticket_validation_screen.dart`
- Guía captura (añadir enlace concreto al implementar)
- Soft launch / builds release (SCRUM-98)
