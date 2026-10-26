# Ejecucion Front - Caducados/Cleanup

## Objetivo
Seguimiento operativo del desarrollo frontend por incrementos, con validacion continua y evidencia de pruebas.

## Regla de trabajo
1. Implementar un solo incremento cada vez.
2. Ejecutar pruebas del gate correspondiente.
3. Registrar resultado y evidencia.
4. Solo entonces pasar al siguiente incremento.

## Tablero de ejecucion

| Incremento | Scope | Estado | Responsable | Inicio | Fin | Gate | Evidencia |
|---|---|---|---|---|---|---|---|
| F1.1 | Bandeja caducados pendientes | DONE | - | 2026-04-06 | 2026-04-06 | G1 | Widget tests + validacion estatica |
| F1.2 | Acciones masivas (archive/trash/snooze) | DONE | - | 2026-04-06 | 2026-04-06 | G2 | Widget tests + validacion estatica |
| F1.3 | Papelera (listar/restaurar/borrar) | DONE | - | 2026-04-06 | 2026-04-06 | G3 | Widget tests + validacion estatica |
| F1.4 | Preferencias + summary dashboard | DONE | - | 2026-04-06 | 2026-04-06 | G4 | Widget tests + validacion estatica |

Estados permitidos: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE`.

## Checklist por incremento

### F1.1 - Bandeja
- [x] UI lista de caducados integrada en navegación.
- [x] Soporta carga, vacío y error.
- [x] Pull-to-refresh funcional.
- [x] G1 validado con pruebas automatizadas.

### F1.2 - Bulk actions
- [x] Selección múltiple y acciones por lote.
- [x] Manejo de respuesta parcial (`errors[]`) en UI.
- [x] Manejo de error global `400`.
- [x] Reintento seguro con `clientRequestId`.

### F1.3 - Papelera
- [x] Listado de papelera funcional.
- [x] Restaurar items funcional.
- [x] Eliminar definitivo con confirmación.
- [x] Mensajes de resultado y refresh.

### F1.4 - Preferencias + summary
- [x] Pantalla de preferencias conectada a backend.
- [x] Persistencia y recarga correcta.
- [x] Badge/resumen con `expiredPendingCount`, `trashedCount`.
- [x] `nextReminderAt` mostrado correctamente en UTC/local.

## Registro de pruebas y evidencias

| Fecha | Incremento | Resultado | Defectos | Evidencia |
|---|---|---|---|---|
| 2026-04-06 | F1.1 | G1 aprobado | 11 infos `avoid_print` preexistentes en `inventory_service.dart` | `flutter test test/screens/expired_products_screen_test.dart` + `flutter analyze` |
| 2026-04-06 | F1.2 | G2 aprobado | 11 infos `avoid_print` preexistentes en `inventory_service.dart` | `flutter test test/screens/expired_products_screen_test.dart` + `flutter analyze` |
| 2026-04-06 | F1.3 | G3 aprobado | 12 infos preexistentes fuera del scope (`inventory_service.dart`, `main.dart`) | `flutter test test/screens/trash_screen_test.dart` + batería cleanup + `flutter analyze` |
| 2026-04-06 | F1.4 | G4 aprobado | 11 infos `avoid_print` preexistentes en `inventory_service.dart` | `flutter test` suite cleanup + `flutter analyze` |

Tipos de evidencia recomendada:
- Capturas de pantalla.
- Logs relevantes (front/backend).
- Video corto de flujo completo.
- Referencia a PR/commit.

## Bloqueos y decisiones

| Fecha | Tipo | Descripcion | Accion | Estado |
|---|---|---|---|---|
| - | - | - | - | - |

Tipos sugeridos: `API`, `UI`, `QA`, `Negocio`.

## Criterio de cierre del flujo
- [x] F1.1, F1.2, F1.3 y F1.4 en `DONE`.
- [x] Gates G1..G4 aprobados.
- [ ] Sin bugs abiertos de severidad alta.
- [ ] Documentacion actualizada (`ROADMAP_CICLO_CADUCADOS.md`, `PLAN_TESTING.md`).

## Cierre manual E2E

Checklist final en `docs/funcional/E2E_CIERRE_CADUCADOS_CLEANUP.md`.

