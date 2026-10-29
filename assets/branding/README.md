# Branding — ScanTicketFresh

**Jira:** [SCRUM-142](https://juliovela86.atlassian.net/browse/SCRUM-142)  
**Actualizado:** 2026-10-28

## Decisión

| Elemento | Valor |
|----------|--------|
| Nombre app (Play / UI) | **ScanTicketFresh** |
| Tagline | DIGITAL FRESHNESS (web / material marketing; no en launcher) |
| Icono launcher | **Solo símbolo** (ticket + manzana + scan), sin wordmark |
| Wordmark horizontal | **Web, emails, docs, ficha Play, redes** → `scanticketfresh-logo-horizontal-web.png` |
| Rediseño UI mockups Gemini | Fuera de alcance (post soft launch) |

## Archivos

| Fichero | Contenido |
|---------|-----------|
| `scanticketfresh-logo-horizontal-web.png` | **Canónico web/marketing:** símbolo + ScanTicketFresh + DIGITAL FRESHNESS |
| `scanticketfresh-logo-full.png` | Variante anterior rescate Gemini (mismo concepto; preferir horizontal-web) |
| `scanticketfresh-icon-symbol.png` | **Launcher:** solo símbolo (aún falta 1024×1024 transparente) |
| `scanticketfresh-proposals-ABCD-gemini.png` | Panel A–D propuestas Gemini (referencia) |
| `ref-frescura-digital-propuesta-A.png` | Variante “FRESCURA DIGITAL” (no es el nombre elegido) |
| `ref-alt-viewfinder-REJECTED.png` | Alternativa recibida (viewfinder + ticket 3D) — **descartada**; nos quedamos con el símbolo ticket+manzana |

## Pendiente técnico

1. ~~Exportar icono 1024×1024~~ → `scanticketfresh-icon-symbol-1024.png` (símbolo centrado, canvas 1024).
2. Generar mipmaps / AppIcon: `dart run flutter_launcher_icons` (config en `pubspec.yaml`).
3. ~~`android:label` + `app_title` l10n → ScanTicketFresh~~ (hecho 2026-10-29).
4. **No** cambiar `applicationId` sin decisión explícita (rompe updates si ya hay APK amigos).

## Origen

No estaba en el repo; recuperado de conversación Gemini “Logo Design Proposals…” (2026-10-28).

## Dominios (RDAP 2026-10-28)

Nombre comercial **cerrado: ScanTicketFresh**.

| Dominio | RDAP |
|---------|------|
| `scanticketfresh.com` | **Disponible** (404) → **reservar ya** |
| `scanticketfresh.es` | Disponible (confirmar en registrador .es) |
| `scanticketfresh.app` | Disponible |
| `scanticketfresh.net` / `.io` | Disponibles (opcionales) |
| `digitalfreshness.com` | Ocupado (DNS) |

Prioridad: **`.com`** (+ `.es` si quieres mercado España). Privacy WHOIS on. Existe producto ajeno `scanticket.io`.
