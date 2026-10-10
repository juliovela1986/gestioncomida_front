# Documentacion del proyecto

Esta carpeta centraliza la documentacion activa y el historico del frontend.

## Estructura

- `docs/ESTADO_ACTUAL_APP.md`: estado real del frontend, flujos y pendientes.
- `docs/LOGGING_DEBUG_VS_PRODUCCION.md`: logs debug vs mensajes de usuario en producción (tickets/OCR).
- `docs/api/api-docs.yaml`: contrato OpenAPI del backend consumido por la app.
- `docs/setup/`: puesta en marcha y troubleshooting.
- `docs/backend/`: configuraciones y notas tecnicas de backend relevantes para el front.
- `docs/backend/BACKEND_CADUCADOS_CLEANUP_ENDPOINTS.md`: contrato propuesto de endpoints para ciclo de caducados y papelera.
- `docs/backend/DELTA_BACKEND_API_DOCS_CADUCADOS.md`: delta minimo entre API actual y requisitos de caducados para pasar a backend.
- `docs/funcional/`: guias funcionales todavia vigentes.
- `docs/funcional/ROADMAP_CICLO_CADUCADOS.md`: roadmap funcional del ciclo completo de caducados.
- `docs/funcional/EJECUCION_CADUCADOS_FRONT.md`: seguimiento operativo por incrementos y evidencia de pruebas.
- `docs/funcional/E2E_CIERRE_CADUCADOS_CLEANUP.md`: checklist manual final de validación end-to-end.
- `docs/archive/`: documentacion historica (puede estar desactualizada).

## Regla de mantenimiento

1. Todo documento nuevo debe vivir en `docs/`.
2. Si un documento deja de representar el estado actual, moverlo a `docs/archive/`.
3. Evitar duplicar guias de la misma funcionalidad en varios ficheros.

