# Roadmap de despliegue en Google Play Store

## Objetivo
Definir un plan claro para publicar `gestioncomida_front` en Google Play de forma segura, con pruebas previas, checklist de cumplimiento y despliegue gradual.

## Contexto actual
- Front Flutter operativo con APK de pruebas generada.
- Version actual en `pubspec.yaml`: `1.0.1+3`.
- Configuracion Android en `android/app/build.gradle.kts`.
- Actualmente release usa firma debug (solo valido para pruebas, no recomendado para publicacion final).

## Entregables del plan
1. Artefacto de publicacion: AAB firmado en release.
2. Ficha completa en Play Console.
3. Publicacion en pista interna/cerrada y validacion.
4. Rollout gradual a produccion.

## Fase 0 - Preparacion (Dia 0)
### Checklist
- [ ] Confirmar `applicationId` definitivo (no debe cambiar tras publicar).
- [ ] Revisar permisos Android y justificar cada uno.
- [ ] Verificar entorno de backend para produccion.
- [ ] Confirmar politica de privacidad publica (URL estable).

### Resultado esperado
- Base estable para preparar el release sin bloqueos de ultima hora.

## Fase 1 - Firma release y versionado (Dia 1)
### Tareas tecnicas
- [ ] Crear keystore de release (almacen seguro, backup cifrado).
- [ ] Crear `android/key.properties` local (fuera de git).
- [ ] Configurar `signingConfigs.release` en `android/app/build.gradle.kts`.
- [ ] Reemplazar `signingConfig = signingConfigs.getByName("debug")` en `release`.
- [ ] Incrementar version en `pubspec.yaml` (`versionName` y `versionCode`).

### Validacion
- [ ] Build release local sin errores.
- [ ] Firma verificada correctamente.

## Fase 2 - Build de publicacion y smoke tests (Dia 1-2)
### Build
- [ ] Generar AAB:
  - `flutter build appbundle --release`
- [ ] Generar APK opcional para QA manual:
  - `flutter build apk --release`

### Smoke tests minimos
- [ ] Login/refresh token.
- [ ] Carga de tickets (manual y/o archivo).
- [ ] Validacion y sincronizacion inventario.
- [ ] Caducados/papelera.
- [ ] Notificaciones y navegacion base.
- [ ] Analisis de precios (pantallas y llamadas API).

### Criterio de salida
- [ ] Sin bloqueantes funcionales P0/P1.

## Fase 3 - Play Console setup (Dia 2-3)
### Ficha de la app
- [ ] Nombre de app y descripcion corta/larga.
- [ ] Icono de alta calidad.
- [ ] Capturas de pantalla (telefono, y tablet si aplica).
- [ ] Categoria y datos de contacto.

### Cumplimiento
- [ ] Data safety completado.
- [ ] Clasificacion por edades (content rating).
- [ ] Politica de privacidad enlazada y valida.
- [ ] Declaraciones de permisos sensibles (si aplica).

### Publicacion
- [ ] Subir AAB.
- [ ] Resolver warnings de Play Console.

## Fase 4 - Testing en pistas (Dia 3-5)
### Internal testing
- [ ] Crear release interna.
- [ ] Invitar testers internos.
- [ ] Recoger feedback funcional y de estabilidad.

### Closed testing (recomendado)
- [ ] Abrir grupo cerrado (usuarios de confianza).
- [ ] Ejecutar bateria de pruebas real de uso diario.
- [ ] Corregir incidencias criticas antes de produccion.

### Criterio de salida
- [ ] Crash-free alto en pruebas.
- [ ] Sin incidencias bloqueantes abiertas.

## Fase 5 - Produccion con rollout gradual (Semana 2)
### Estrategia sugerida
1. 10% usuarios (24h)
2. 25% usuarios (24h)
3. 50% usuarios (24h)
4. 100% usuarios

### Monitorizacion por tramo
- [ ] Crashes/ANR.
- [ ] Errores backend en endpoints criticos.
- [ ] Reseñas y feedback de usuarios.
- [ ] KPIs de uso (sesiones, tickets procesados, retencion).

### Regla de seguridad
- [ ] Pausar rollout si aparecen errores P0/P1 o degradacion fuerte.

## Fase 6 - Post-lanzamiento (Semana 2+)
### Operacion
- [ ] Revisar incidencias de primera semana.
- [ ] Priorizar hotfixes.
- [ ] Programar patch release (x.y.z+code).

### Mejora continua
- [ ] Preparar backlog de mejoras para proxima version.
- [ ] Definir cadencia de release (quincenal/mensual).

## Matriz de riesgos
1. Firma release mal configurada -> rechazo o build invalido.
2. Declaraciones de privacidad incompletas -> bloqueo de publicacion.
3. Cambios de backend no compatibles -> errores en runtime.
4. Rollout demasiado agresivo -> impacto amplio ante bug.

## Plan de rollback
- [ ] Pausar rollout desde Play Console.
- [ ] Mantener version previa estable disponible.
- [ ] Publicar hotfix con incremento de versionCode.

## Roadmap temporal resumido
### Semana 1
- D1: Firma release + versionado + build AAB.
- D2: Smoke tests y ajustes.
- D3: Ficha Play + compliance.
- D4-D5: Internal/Closed testing.

### Semana 2
- D1: Produccion 10%.
- D2: 25%.
- D3: 50%.
- D4: 100% si estable.
- D5: Revisión post-lanzamiento y backlog.

## Criterio de "Go Live"
- [ ] AAB firmado release correcto.
- [ ] Checklist Play completado al 100%.
- [ ] QA funcional sin bloqueantes.
- [ ] Plan de rollback definido y probado.

