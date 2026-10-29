# Branding — ScanTicketFresh

**Jira:** [SCRUM-142](https://juliovela86.atlassian.net/browse/SCRUM-142) **Finalizada**  
**Actualizado:** 2026-10-29

## Decisión

| Elemento | Valor |
|----------|--------|
| Nombre app (Play / UI) | **ScanTicketFresh** |
| Tagline | DIGITAL FRESHNESS (marketing; no en launcher) |
| Icono launcher | Símbolo ticket + manzana + scan, fondo **blanco sólido** (sin damero) |
| Icono in-app (login/home) | `scanticketfresh-icon-ui.png` (transparente, sin círculo) |
| Wordmark | `scanticketfresh-logo-horizontal-web.png` |

## Archivos canónicos

| Fichero | Uso |
|---------|-----|
| `scanticketfresh-icon-ui.png` | Login / home (Image.asset) |
| `scanticketfresh-icon-launcher-1024.png` | Fuente `flutter_launcher_icons` (blanco + logo) |
| `scanticketfresh-icon-symbol-1024.png` | Referencia (puede llevar círculo; **no** usar en UI) |
| `scanticketfresh-logo-horizontal-web.png` | Web / Play ficha / emails |

## Hecho técnico

1. Launcher regenerado sin damero (`dart run flutter_launcher_icons`).
2. UI: sustituido `Icons.restaurant_menu` por `icon-ui.png`.
3. `android:label` + l10n `app_title` → ScanTicketFresh.
4. Dominio: `scanticketfresh.com` (reservado / en uso ops).

## Pendiente Play

- Publicar política: back `docs/MVP/static/privacy.html` → URL HTTPS (SCRUM-140).
- No cambiar `applicationId` sin decisión explícita.
