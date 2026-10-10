# AGENTS.md — GestionComida Frontend

Guía para agentes de IA que trabajan en este repositorio. Objetivo: **menos tokens, menos errores, diffs pequeños y correctos**.

---

## 1. Qué es este proyecto

**GestionComida** es la app móvil/multiplataforma (Flutter) del ecosistema de gestión de alimentos: tickets de compra (OCR + IA), inventario, precios históricos, comparativas, lista de compra y notificaciones push.

Stack principal: **Flutter · Dart 2.19+ · Dio · Provider · Firebase (FCM) · Keycloak (OAuth2/WebView) · flutter_secure_storage**.

Plataformas objetivo: **Android** (APK de pruebas), con soporte también en Windows/Linux/macOS/iOS.

---

## 2. Arquitectura (capas)

Flujo obligatorio — **no saltar capas**:

```
Screen / Tab (UI, estado local, navegación)
    ↓
Service (*_service.dart — llamadas API, orquestación)
    ↓
ApiClient (Dio singleton, JWT, refresh, Accept-Language)
    ↓
Backend REST (Spring Boot, puerto habitual 8081)
```

| Capa | Carpeta | Responsabilidad |
|------|---------|-----------------|
| UI | `lib/screens/` | Pantallas, tabs, flujos de usuario, `StatefulWidget` |
| Widgets reutilizables | `lib/widgets/` | Componentes compartidos entre pantallas |
| API | `lib/services/` | HTTP, parsing, lógica de integración con backend |
| Modelos | `lib/models/` | DTOs del backend: `fromJson` / `toJson` |
| Core | `lib/core/` | Excepciones, utilidades, globals (`navigatorKey`) |
| Config | `lib/app_config.dart` | URLs backend/Keycloak |
| i18n | `lib/l10n/` | Cadenas localizadas (es, en, ca, eu, gl) |
| Auth | `lib/services/auth_service.dart` | OAuth2 PKCE, tokens en secure storage |
| Preferencias | `lib/services/preferences_service.dart` | Tema, idioma (`ChangeNotifier` + Provider) |

**Pantallas clave de navegación** (`main_navigation_screen.dart`):
- `home_tab`, `inventory_tab`, `tickets_tab` / `tickets_history_screen`, `shopping_tab`, `more_tab`

**Servicios por dominio:**
- `ticket_service`, `inventory_service`, `catalog_product_service`, `location_service`
- `price_insights_service`, `notification_service`, `fcm_service`, `menu_service`
- `groq_vision_service` — OCR local vía Groq Vision (clave en `.env`)
- `preferences_service`, `cleanup_preferences_service`, `notification_refresh_service`

---

## 3. Contrato API, modelos y persistencia local

> **El front consume el backend; no define el esquema de BD.** Los cambios de contrato se reflejan en modelos + servicios.

### Reglas al integrar API

1. **Consultar primero** `docs/api/api-docs.yaml` (OpenAPI del backend).
2. Si el endpoint es nuevo o cambia, revisar también `docs/backend/` y `docs/funcional/` por especificaciones pendientes.
3. **Modelo** en `lib/models/`: alinear nombres de campos JSON con el DTO del backend; mantener campos legacy opcionales (`?`) si el backend aún los envía.
4. **Servicio** en `lib/services/`: un método por operación REST; usar `_apiClient.dio` (no instanciar Dio aparte).
5. **Pantalla**: solo presentación y estado de UI; sin URLs ni lógica HTTP embebida.
6. Si falta endpoint en backend, documentar el delta en `docs/backend/` antes de improvisar mocks en producción.

### Cuándo NO hace falta tocar modelos

- Cambios solo de UI (layout, colores, navegación).
- Refactors internos de pantalla sin cambio de payload.
- Textos → actualizar `lib/l10n/app_localizations.dart` (y variantes por idioma si existen).

### Persistencia local (no confundir con BD)

| Almacén | Uso |
|---------|-----|
| `flutter_secure_storage` | Access/refresh tokens OAuth |
| `shared_preferences` | Preferencias de usuario, flags de cleanup |
| `.env` (asset) | `GROQ_API_KEY` y secretos de build — **no commitear** valores reales |

### Plantilla mínima de modelo

```dart
class FooResponseDto {
  final String id;
  final String? legacyField;

  FooResponseDto({required this.id, this.legacyField});

  factory FooResponseDto.fromJson(Map<String, dynamic> json) {
    return FooResponseDto(
      id: json['id'] as String,
      legacyField: json['legacyField'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (legacyField != null) 'legacyField': legacyField,
  };
}
```

Tras el modelo: método en `*_service.dart` + consumo en pantalla + (si aplica) test widget.

---

## 4. Metodología de trabajo

### Antes de codificar

1. **Leer el código existente** del módulo (convenciones de nombres, patrones).
2. Si hay doc en `docs/`, `docs/funcional/` o `docs/backend/`, leerla primero. Estado general: `docs/ESTADO_ACTUAL_APP.md`.
3. Acotar el alcance: **un problema, un diff mínimo**.

### Al implementar

| Hacer | No hacer |
|-------|----------|
| Reutilizar `ApiClient`, servicios y widgets existentes | Reimplementar HTTP o auth duplicada |
| Usar `userFriendlyError()` para mensajes al usuario | Mostrar stack traces o errores Dio crudos |
| Mantener compatibilidad con campos JSON legacy | Asumir que el backend ya tiene un endpoint sin verificar |
| Tests widget/unit en `test/` del área tocada | Tests triviales que no aportan |
| Strings de UI en `app_localizations` | Hardcodear textos en español en widgets |
| Ejecutar `flutter test` del área modificada | Asumir que compila sin verificar |
| Registrar cambios relevantes en `docs/REGISTRO_CAMBIOS.md` solo si el usuario lo pide o es hito grande | Editar docs masivos no pedidos |

### Commits y PRs

- **No commitear** salvo petición explícita del usuario.
- No incluir secretos (`.env` con claves reales, `google-services.json` con credenciales de prod).
- Mensajes de commit: qué y por qué, en español o inglés según el repo.

---

## 5. Eficiencia de tokens (reglas para el agente)

### Exploración

- **Grep/Glob primero**, Read después — no leer ficheros enteros si basta una búsqueda.
- Leer solo las secciones relevantes (`offset`/`limit` en ficheros grandes).
- No repetir lecturas del mismo archivo en un turno.
- Paralelizar búsquedas independientes.

### Implementación

- **Diff mínimo**: no reformatear ni tocar código no relacionado.
- No crear abstracciones para una sola línea reutilizada.
- No generar documentación extensa salvo que se pida.
- Preferir editar archivos existentes antes que crear nuevos.
- Un cambio de API consumida = Model + Service + Screen(s) + (opcional) test + comprobar `api-docs.yaml`.

### Respuestas al usuario

- Prosa concisa; citar código con formato ` ```startLine:endLine:path ``` `.
- No repetir en prosa lo que ya está en el diff.
- Resumir al final qué cambió y qué tests se ejecutaron.

### Tests

```powershell
# PowerShell (Windows)
cd F:\GestionComida\gestioncomida_front
flutter test test/screens/inventory_tab_test.dart
flutter test test/core/date_picker_utils_test.dart
flutter analyze
```

Ejecutar solo los tests del área modificada antes de dar por cerrada la tarea.

---

## 6. Convenciones de código

- **Dart** con `flutter_lints`; SDK `>=2.19.0 <3.0.0` (ver `pubspec.yaml`).
- Modelos: sufijo `*Dto` o nombre alineado al backend; parsing defensivo con `as Type?` y listas vacías por defecto.
- Servicios: clase con `final ApiClient _apiClient = ApiClient();`; paths bajo `/api/...`.
- Errores: lanzar/capturar `AppException` / `SessionExpiredException`; en UI usar `userFriendlyError()`.
- Estado global ligero: `Provider` + `ChangeNotifier` (`PreferencesService`); evitar añadir otro state manager sin necesidad.
- Navegación: rutas en `main.dart` + tabs en `MainNavigationScreen`; `navigatorKey` en `app_globals.dart` para deep links/FCM.
- i18n: añadir claves en `AppLocalizations` para textos visibles al usuario.
- Auth: tokens vía `AuthService`; el `ApiClient` gestiona refresh en 401.
- Subidas (imagen/PDF): respetar `multipart` y el manejo especial de sesión expirada en `ApiClient`.
- Logs: el proyecto usa `print` con prefijos `[ServiceName]`; no eliminar logs de depuración existentes salvo que se pida limpieza.

---

## 7. Mapa rápido de dominios

| Dominio | Pantalla(s) principal(es) | Servicio |
|---------|---------------------------|----------|
| Tickets | `upload_ticket_screen`, `upload_pdf_screen`, `ticket_validation_screen`, `tickets_history_screen`, `create_manual_ticket_screen` | `ticket_service` |
| Inventario | `inventory_tab`, `inventory_screen`, `product_lots_screen`, `edit_inventory_item_screen` | `inventory_service` |
| Catálogo | `catalog_products_screen`, `edit_catalog_product_screen` | `catalog_product_service` |
| Caducidades | `expiration_date_manager_screen`, `expired_products_screen`, `trash_screen` | `inventory_service`, `ticket_service` |
| Ubicaciones | `locations_screen` | `location_service` |
| Price Insights | `price_insights_screen`, `product_price_comparison_screen`, `statistics_screen` | `price_insights_service` |
| Lista compra | `shopping_list_screen`, `shopping_tab` | (API vía servicios existentes) |
| Notificaciones | `notifications_screen` | `notification_service`, `fcm_service` |
| Ajustes | `settings_screen`, `more_tab` | `preferences_service` |
| Auth | `login_webview_screen` | `auth_service` |

Documentación útil:
- `docs/api/api-docs.yaml` — contrato OpenAPI del backend
- `docs/ESTADO_ACTUAL_APP.md` — estado real del front y flujos
- `docs/LOGGING_DEBUG_VS_PRODUCCION.md` — capa debug vs mensajes usuario en release (tickets/OCR)
- `docs/funcional/` — especificaciones funcionales vigentes
- `docs/backend/` — deltas y requisitos de API pendientes en backend
- `docs/setup/FIREBASE_SETUP.md` — configuración FCM
- `lib/INTEGRACION_GUIA.dart` — notas de integración en código

### Logging (obligatorio)

- **Debug** (`kDebugMode`): `AppLogger.debug` — payloads OCR, JSON, trazas de flujo.
- **Release**: mensajes accionables al usuario (recapturar según guía / reportar admin); **nunca** dump `rawText` OCR ni tokens en `print`.
- No usar `print` suelto en código nuevo. Detalle: `docs/LOGGING_DEBUG_VS_PRODUCCION.md`.

---

## 8. Checklist antes de cerrar una tarea

- [ ] ¿Cambia el contrato API? → Model + Service + comprobar `docs/api/api-docs.yaml`
- [ ] ¿Endpoint nuevo en backend? → Verificar que existe o documentar delta en `docs/backend/`
- [ ] ¿Nueva pantalla o flujo? → Screen + Service + rutas/navegación + strings i18n
- [ ] ¿Error visible al usuario? → `userFriendlyError()` / `AppException` (release: copy humano, no OCR/JSON)
- [ ] ¿Trazas nuevas? → `AppLogger.debug` solo en debug; sin `print` de payloads en release
- [ ] ¿Preferencia o token? → `preferences_service` / `auth_service`, no `SharedPreferences` directo para secrets
- [ ] `flutter test` y/o `flutter analyze` del área afectada pasan
- [ ] Diff acotado, sin `android/build/` ni artefactos generados

---

## 9. Configuración y variables (referencia)

| Variable / config | Dónde |
|-------------------|-------|
| `GROQ_API_KEY` | `.env` (local, no commitear claves) |
| `backendUrl`, `keycloakUrl` | `lib/app_config.dart` |
| Firebase / FCM | `android/app/google-services.json`, `docs/setup/FIREBASE_SETUP.md` |
| Red Android cleartext | `android/app/src/main/res/xml/network_security_config.xml` |

Backend habitual en dev: **8081**. Keycloak: **8180**. Ajustar `AppConfig` según entorno local o remoto (OVH).

---

## 10. Relación con el backend

Repositorio backend hermano: `gestioncomida` (Spring Boot). Reglas de agente del backend en su propio `AGENTS.md`.

Cuando un cambio requiere API nueva:
1. Especificar contrato en `docs/backend/` (delta o propuesta).
2. Implementar en backend (Liquibase + Controller + Service…).
3. Actualizar `docs/api/api-docs.yaml` en este repo cuando el backend despliegue el cambio.
4. Implementar Model + Service + Screen en el front.
