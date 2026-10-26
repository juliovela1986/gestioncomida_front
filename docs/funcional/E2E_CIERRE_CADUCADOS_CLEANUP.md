# E2E Cierre - Caducados/Cleanup

## Objetivo
Validar de extremo a extremo el flujo completo ya implementado en frontend:

1. Bandeja de caducados pendientes.
2. Acciones masivas (archivar, mover a papelera, posponer).
3. Papelera (listar, restaurar, eliminar definitivamente).
4. Preferencias de cleanup y resumen/badge.

## Alcance

Pantallas incluidas:
- `lib/screens/expired_products_screen.dart`
- `lib/screens/trash_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/inventory_tab.dart`

Gates automáticos ya validados:
- G1, G2, G3, G4 (ver `PLAN_TESTING.md`).

Este documento cubre la validación manual final del flujo funcional.

Invoke-RestMethod -Uri "$BASE_URL/api/inventory/expired-pending/summary" -Headers $HEADERS -Method GetInvoke-RestMethod -Uri "$BASE_URL/api/inventory/expired-pending/summary" -Headers $HEADERS -Method Get

## Checklist manual E2E

### E2E-01 - Bandeja de caducados pendientes
- [ ] Entrar en `Inventario` -> `Productos Caducados`.
- [ ] Verificar carga inicial sin errores.
- [ ] Verificar estado vacío cuando no hay datos.
- [ ] Verificar estado error + botón reintentar (si backend falla).
- [ ] Verificar refresh (icono y pull-to-refresh).

Resultado esperado:
- La bandeja responde en todos los estados (`loading`, `empty`, `error`, `data`) y no crashea.

### E2E-02 - Acciones masivas
- [ ] Seleccionar uno o varios items (long press + tap).
- [ ] Ejecutar `Archivar`.
- [ ] Ejecutar `Mover a papelera`.
- [ ] Ejecutar `Posponer` seleccionando fecha.
- [ ] Verificar mensaje para resultado parcial (`errors[]`) cuando aplique.
- [ ] Forzar un 400 y verificar `Reintentar`.

Resultado esperado:
- Todas las acciones aplican correctamente y refrescan la bandeja.
- El reintento no duplica operación (idempotencia por `clientRequestId`).

### E2E-03 - Papelera
- [ ] Abrir `Papelera` desde `Inventario` o desde bandeja.
- [ ] Verificar listado de items en `TRASHED`.
- [ ] Seleccionar items y `Restaurar`.
- [ ] Seleccionar items y `Eliminar definitivamente` (con confirmación).
- [ ] Verificar refresh y mensajes de resultado.

Resultado esperado:
- La papelera permite recuperar o eliminar definitivo sin inconsistencias.

### E2E-04 - Preferencias de cleanup
- [ ] Abrir `Configuración`.
- [ ] Verificar carga de frecuencia, día/hora y retención.
- [ ] Modificar valores y guardar.
- [ ] Reabrir pantalla y comprobar persistencia.

Resultado esperado:
- `GET/PUT /api/users/cleanup-preferences` funciona y persiste valores.

### E2E-05 - Summary y badge/dashboard
- [ ] Verificar en `Configuración` los campos de summary:
  - `expiredPendingCount`
  - `trashedCount`
  - `nextReminderAt`
- [ ] Verificar en `Inventario` subtítulos con contadores.
- [ ] Confirmar que `nextReminderAt` se muestra en horario local sin desfase.

Resultado esperado:
- `GET /api/inventory/expired-pending/summary` se refleja en UI correctamente.

## Evidencia mínima por caso

Para cada bloque E2E-01..E2E-05:
- Estado: `PASS` / `FAIL` / `BLOCKED`
- Fecha/hora
- Captura de pantalla
- Nota breve (1-2 líneas)

Opcional recomendado:
- Log de request/respuesta para casos de error global o parcial.

## Registro de ejecución

| Caso | Estado | Fecha | Evidencia | Observaciones |
|---|---|---|---|---|
| E2E-01 | - | - | - | - |
| E2E-02 | - | - | - | - |
| E2E-03 | - | - | - | - |
| E2E-04 | - | - | - | - |
| E2E-05 | - | - | - | - |

## Criterio de cierre final

Se considera cierre E2E aprobado cuando:
- [ ] E2E-01..E2E-05 en `PASS`.
- [ ] No hay bugs abiertos de severidad alta en el flujo caducados/cleanup.
- [ ] Evidencias registradas en este documento.
- [ ] Estado reflejado en `docs/funcional/EJECUCION_CADUCADOS_FRONT.md`.

