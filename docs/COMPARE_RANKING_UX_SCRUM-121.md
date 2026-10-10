# SCRUM-121 — Ranking honesto + precios por artículo

**Contrato / spec completa (backend repo):**  
`gestioncomida/docs/DOC_TECNICA/CAMBIOS PEDIDOS DESDE EL FRONT/SHOPPING_LIST_COMPARE_RANKING_UX.md`  
**Jira:** https://juliovela86.atlassian.net/browse/SCRUM-121

## Estado

**Implementado 2026-10-10** en `lib/screens/shopping_list_screen.dart`.

1. Si `rankingConclusive != true` → título “Cobertura parcial”, sin crownear; orden por cobertura.
2. Ítem expandible: `detail.prices` ordenados + supers conocidos sin precio.
3. Test: `test/screens/shopping_list_screen_test.dart` (SCRUM-121).

API: `rankingConclusive`, `rankingPartialReason`, `detail[].prices[]`.
