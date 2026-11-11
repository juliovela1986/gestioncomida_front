# Parking lot post-MVP — 2026-11-11

Fuente: chat WhatsApp (10/11/2026). **No implementar durante soft-launch / cierre MVP.**  
Épica [SCRUM-177](https://juliovela86.atlassian.net/browse/SCRUM-177) · label `post-mvp`  
- [SCRUM-178](https://juliovela86.atlassian.net/browse/SCRUM-178) agente/skills  
- [SCRUM-179](https://juliovela86.atlassian.net/browse/SCRUM-179) control de gastos  
- [SCRUM-180](https://juliovela86.atlassian.net/browse/SCRUM-180) nutrición

---

## 1. Agente IA sobre la app (estilo Alexa skills)

**Idea:** que un agente/IA beba de los datos de ScanTicket Fresh y pueda **manejar la app por comandos** (“añade leche a la lista”, “¿qué caduca esta semana?”, “compara precios de la lista”).

**Enfoque técnico (borrador):**
- Capa de **skills/tools** HTTP (o OpenAPI tools) sobre endpoints existentes + algunos de acción idempotentes.
- Auth: token de usuario / device link / OAuth scoped (no compartir JWT de sesión de la app a terceros a ciegas).
- Capacidades candidatas v1: inventario (consulta), caducados, lista de la compra (CRUD), compare-batch (estado), preferencias supers/CP (lectura).
- Escrituras peligrosas (borrar cuenta, borrar ticket) → confirmación explícita / fuera de scope v1.
- UX: chat in-app o canal externo (WhatsApp/Assistant) que delegue al mismo skill set.

**Relacionado:** API actual ya cubre gran parte de lectura/acción; falta contrato “agent-friendly” (schemas estables, errores i18n, rate limit).

Ticket: [SCRUM-178](https://juliovela86.atlassian.net/browse/SCRUM-178).

---

## 2. Control de gastos

Ya documentado en detalle: [`CONTROL_GASTO_MENSUAL.md`](./CONTROL_GASTO_MENSUAL.md). Ticket: [SCRUM-179](https://juliovela86.atlassian.net/browse/SCRUM-179).

Resumen: gasto mensual por tickets, evolución mes a mes, desglose por supermercado, tendencias.

---

## 3. Clasificación nutricional

**Idea:** clasificar productos/lotes o líneas de ticket por perfil nutricional (macros, Nutri-Score-like, alérgenos, “saludable vs ultraprocesado”) y mostrar insights en inventario / lista.

**Notas:**
- Fuentes posibles: Open Food Facts, etiquetado OCR, enriquecimiento catálogo maestro.
- Disclaimers legales/salud obligatorios; no consejo médico.
- Dependencias: calidad de `master_product` / matching ticket ↔ catálogo.

Ticket: [SCRUM-180](https://juliovela86.atlassian.net/browse/SCRUM-180).

---

## Orden sugerido post-MVP (no comprometido)

1. Control de gasto (datos ya en tickets).
2. Skills/agente (reutiliza API; alto diferenciador).
3. Nutrición (más datos externos + disclaimers).
