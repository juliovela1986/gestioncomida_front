# SCRUM-121 — Ranking honesto + precios por artículo

**Contrato / spec completa (backend repo):**  
`gestioncomida/docs/DOC_TECNICA/CAMBIOS PEDIDOS DESDE EL FRONT/SHOPPING_LIST_COMPARE_RANKING_UX.md`  
**Jira:** https://juliovela86.atlassian.net/browse/SCRUM-121

## Qué implementar aquí (Flutter)

1. Si `rankingConclusive != true` → no crownear ganador; mostrar cobertura parcial.
2. Cada ítem expandible: `detail.prices` ordenados por precio (+ “sin precio”).
3. Archivo principal: `lib/screens/shopping_list_screen.dart` (`_buildRanking`, list tiles).

API ya envía `rankingConclusive`, `rankingPartialReason`, `detail[].prices[]`.
