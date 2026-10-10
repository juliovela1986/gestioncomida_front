import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestioncomida_front/l10n/app_localizations.dart';
import 'package:gestioncomida_front/models/shopping_list_comparison.dart';
import 'package:gestioncomida_front/models/shopping_list_item.dart';
import 'package:gestioncomida_front/screens/shopping_list_screen.dart';

void main() {
  ShoppingListItemDto item(String id, String name) {
    return ShoppingListItemDto(id: id, name: name, quantity: 1);
  }

  ShoppingListPageDto pageOf(List<ShoppingListItemDto> items, {int number = 0}) {
    return ShoppingListPageDto(
      content: items,
      totalElements: items.length,
      totalPages: 1,
      number: number,
      size: 5,
      first: number == 0,
      last: true,
      empty: items.isEmpty,
    );
  }

  Widget buildApp({
    required ShoppingListPageLoader loader,
    ShoppingListCompareBatchExecutor? compareBatch,
    Duration pollInterval = const Duration(milliseconds: 20),
    Duration pollTimeout = const Duration(seconds: 2),
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('ca'),
        Locale('eu'),
        Locale('gl'),
      ],
      locale: const Locale('es'),
      home: ShoppingListScreen(
        loadPage: loader,
        compareBatch: compareBatch,
        pollInterval: pollInterval,
        pollTimeout: pollTimeout,
      ),
    );
  }

  Future<void> setPhoneViewport(WidgetTester tester) async {
    // Viewport de teléfono: el ranking no debe comerse toda la lista en tests.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('ShoppingListScreen SCRUM-46', () {
    testWidgets('carga página paginada y muestra ítems', (tester) async {
      await tester.pumpWidget(
        buildApp(
          loader: ({required page, required size}) async => pageOf([
            item('1', 'Leche'),
            item('2', 'Pan'),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leche'), findsOneWidget);
      expect(find.text('Pan'), findsOneWidget);
      expect(find.textContaining('Pág. 1/1'), findsOneWidget);
      expect(find.text('Comparar esta página'), findsOneWidget);
    });

    testWidgets('poll pending → ready y muestra ranking + estado por ítem', (
      tester,
    ) async {
      await setPhoneViewport(tester);
      var calls = 0;

      await tester.pumpWidget(
        buildApp(
          loader: ({required page, required size}) async =>
              pageOf([item('a', 'Arroz'), item('b', 'Huevos')]),
          compareBatch: (request) async {
            calls++;
            if (calls == 1) {
              return ShoppingListComparisonResponseDto(
                itemsCompared: 2,
                staleItems: 0,
                processedCount: 2,
                skippedCount: 0,
                readyCount: 1,
                pendingCount: 1,
                unavailableCount: 0,
                jobsEnqueued: 1,
                ranking: const [
                  SupermarketRankingDto(
                    supermarket: 'Mercadona',
                    totalPrice: 1.2,
                    itemsFound: 1,
                    itemsMissing: 1,
                    resolved: 1,
                    total: 2,
                  ),
                ],
                detail: [
                  ShoppingListItemComparisonDetailDto(
                    itemId: 'a',
                    productName: 'Arroz',
                    status: CompareItemStatus.ready,
                    prices: const [
                      ShoppingListPriceDto(
                        supermarket: 'Mercadona',
                        avgUnitPrice: 1.2,
                        samples: 1,
                        deltaVsCheapestPct: 0,
                        deltaVsCheapestAmount: 0,
                      ),
                    ],
                  ),
                  const ShoppingListItemComparisonDetailDto(
                    itemId: 'b',
                    productName: 'Huevos',
                    status: CompareItemStatus.pending,
                    message: 'Refreshing',
                  ),
                ],
              );
            }

            return ShoppingListComparisonResponseDto(
              itemsCompared: 2,
              staleItems: 0,
              processedCount: 2,
              skippedCount: 0,
              readyCount: 2,
              pendingCount: 0,
              unavailableCount: 0,
              jobsEnqueued: 0,
              ranking: const [
                SupermarketRankingDto(
                  supermarket: 'Mercadona',
                  totalPrice: 3.0,
                  itemsFound: 2,
                  itemsMissing: 0,
                  resolved: 2,
                  total: 2,
                ),
                SupermarketRankingDto(
                  supermarket: 'Dia',
                  totalPrice: 3.5,
                  itemsFound: 2,
                  itemsMissing: 0,
                  resolved: 2,
                  total: 2,
                ),
              ],
              detail: [
                ShoppingListItemComparisonDetailDto(
                  itemId: 'a',
                  productName: 'Arroz',
                  status: CompareItemStatus.ready,
                  prices: const [
                    ShoppingListPriceDto(
                      supermarket: 'Mercadona',
                      avgUnitPrice: 1.2,
                      samples: 1,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                  ],
                ),
                ShoppingListItemComparisonDetailDto(
                  itemId: 'b',
                  productName: 'Huevos',
                  status: CompareItemStatus.ready,
                  prices: const [
                    ShoppingListPriceDto(
                      supermarket: 'Mercadona',
                      avgUnitPrice: 1.8,
                      samples: 1,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comparar esta página'));
      await tester.pump();
      expect(find.textContaining('Buscando'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      expect(calls, greaterThanOrEqualTo(2));
      expect(find.text('Precios listos'), findsNWidgets(2));
      expect(find.text('Ranking acumulado'), findsOneWidget);
      expect(find.text('Mercadona'), findsWidgets);
      expect(find.text('Comparativa lista'), findsOneWidget);
    });

    testWidgets('pending con precios muestra copy orientativo', (tester) async {
      await tester.pumpWidget(
        buildApp(
          loader: ({required page, required size}) async =>
              pageOf([item('1', 'Leche')]),
          compareBatch: (request) async {
            return ShoppingListComparisonResponseDto(
              itemsCompared: 1,
              staleItems: 0,
              processedCount: 1,
              skippedCount: 0,
              readyCount: 0,
              pendingCount: 1,
              unavailableCount: 0,
              jobsEnqueued: 1,
              detail: [
                ShoppingListItemComparisonDetailDto(
                  itemId: '1',
                  productName: 'Leche',
                  status: CompareItemStatus.pending,
                  prices: const [
                    ShoppingListPriceDto(
                      supermarket: 'Mercadona',
                      avgUnitPrice: 1.1,
                      samples: 1,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                  ],
                ),
              ],
            );
          },
          pollTimeout: const Duration(milliseconds: 50),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comparar esta página'));
      await tester.pump();
      expect(find.textContaining('orientativo'), findsWidgets);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
    });

    testWidgets('muestra copy Carrefour unavailable sin romper el resto', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          loader: ({required page, required size}) async =>
              pageOf([item('1', 'Leche'), item('2', 'Cafe')]),
          compareBatch: (request) async {
            return ShoppingListComparisonResponseDto(
              itemsCompared: 2,
              staleItems: 0,
              processedCount: 2,
              skippedCount: 0,
              readyCount: 1,
              pendingCount: 0,
              unavailableCount: 1,
              jobsEnqueued: 0,
              ranking: const [
                SupermarketRankingDto(
                  supermarket: 'Mercadona',
                  totalPrice: 1.0,
                  itemsFound: 1,
                  itemsMissing: 1,
                  resolved: 1,
                  total: 2,
                ),
              ],
              detail: [
                ShoppingListItemComparisonDetailDto(
                  itemId: '1',
                  productName: 'Leche',
                  status: CompareItemStatus.ready,
                  prices: const [
                    ShoppingListPriceDto(
                      supermarket: 'Mercadona',
                      avgUnitPrice: 1.0,
                      samples: 2,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                  ],
                ),
                const ShoppingListItemComparisonDetailDto(
                  itemId: '2',
                  productName: 'Cafe',
                  status: CompareItemStatus.unavailable,
                  message: 'Carrefour session expired',
                ),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comparar esta página'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Carrefour no disponible ahora'),
        findsOneWidget,
      );
      expect(find.text('Precios listos'), findsOneWidget);
      expect(find.textContaining('sin precio'), findsOneWidget);
    });

    testWidgets('SCRUM-121: ranking no concluyente sin crownear + precios por ítem', (
      tester,
    ) async {
      await setPhoneViewport(tester);
      await tester.pumpWidget(
        buildApp(
          loader: ({required page, required size}) async =>
              pageOf([item('1', 'Manzanas'), item('2', 'Leche')]),
          compareBatch: (request) async {
            return ShoppingListComparisonResponseDto(
              itemsCompared: 2,
              staleItems: 0,
              processedCount: 2,
              skippedCount: 0,
              readyCount: 2,
              pendingCount: 0,
              unavailableCount: 0,
              jobsEnqueued: 0,
              rankingConclusive: false,
              rankingPartialReason: 'Cobertura desigual entre supermercados',
              cheapestSupermarket: null,
              ranking: const [
                // Total más bajo pero cobertura 1/2 → no debe crownearse.
                SupermarketRankingDto(
                  supermarket: 'Hipercor',
                  totalPrice: 2.55,
                  itemsFound: 1,
                  itemsMissing: 1,
                  resolved: 1,
                  total: 2,
                ),
                SupermarketRankingDto(
                  supermarket: 'Ahorramas',
                  totalPrice: 7.5,
                  itemsFound: 2,
                  itemsMissing: 0,
                  resolved: 2,
                  total: 2,
                ),
                SupermarketRankingDto(
                  supermarket: 'Alcampo',
                  totalPrice: 0,
                  itemsFound: 0,
                  itemsMissing: 2,
                  resolved: 0,
                  total: 2,
                ),
              ],
              detail: [
                ShoppingListItemComparisonDetailDto(
                  itemId: '1',
                  productName: 'Manzanas',
                  status: CompareItemStatus.ready,
                  prices: const [
                    ShoppingListPriceDto(
                      supermarket: 'Ahorramas',
                      avgUnitPrice: 4.99,
                      samples: 1,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                    ShoppingListPriceDto(
                      supermarket: 'Hipercor',
                      avgUnitPrice: 2.55,
                      samples: 1,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                  ],
                ),
                ShoppingListItemComparisonDetailDto(
                  itemId: '2',
                  productName: 'Leche',
                  status: CompareItemStatus.ready,
                  prices: const [
                    ShoppingListPriceDto(
                      supermarket: 'Ahorramas',
                      avgUnitPrice: 2.51,
                      samples: 1,
                      deltaVsCheapestPct: 0,
                      deltaVsCheapestAmount: 0,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comparar esta página'));
      await tester.pumpAndSettle();

      expect(find.text('Cobertura parcial — no comparable'), findsOneWidget);
      expect(find.text('Cobertura desigual entre supermercados'), findsOneWidget);
      expect(find.text('Ranking acumulado'), findsNothing);
      // Híbrido: cobertura parcial → ranking plegado (preview + productos visibles).
      expect(find.textContaining('supers · toca'), findsOneWidget);
      expect(find.text('Manzanas'), findsOneWidget);
      expect(find.text('Ver todos los supers'), findsOneWidget);

      // Preview (2 filas): Ahorramas (2/2) por encima de Hipercor (1/2).
      final ahorramas = tester.getTopLeft(find.text('Ahorramas').first);
      final hipercor = tester.getTopLeft(find.text('Hipercor').first);
      expect(ahorramas.dy < hipercor.dy, isTrue);

      // Expandir Manzanas → precios ordenados + sin precio para supers faltantes.
      await tester.ensureVisible(find.text('Manzanas'));
      await tester.tap(find.text('Manzanas'));
      await tester.pumpAndSettle();
      expect(find.text('Precios por supermercado'), findsOneWidget);
      expect(find.text('2.55 €'), findsWidgets);
      expect(find.text('4.99 €'), findsOneWidget);
      expect(find.text('sin precio'), findsWidgets);
    });
  });

  group('AccumulatedRanking', () {
    test('acumula totales entre lotes distintos y reemplaza el mismo lote', () {
      final acc = AccumulatedRanking();
      acc.upsertBatch('a|b', const [
        SupermarketRankingDto(
          supermarket: 'Mercadona',
          totalPrice: 2,
          itemsFound: 2,
          itemsMissing: 0,
          resolved: 2,
          total: 2,
        ),
      ]);
      acc.upsertBatch('c|d', const [
        SupermarketRankingDto(
          supermarket: 'Mercadona',
          totalPrice: 3,
          itemsFound: 2,
          itemsMissing: 0,
          resolved: 2,
          total: 2,
        ),
        SupermarketRankingDto(
          supermarket: 'Dia',
          totalPrice: 4,
          itemsFound: 2,
          itemsMissing: 0,
          resolved: 2,
          total: 2,
        ),
      ]);

      var ranking = acc.build();
      // Orden ascendente por total: Dia(4) < Mercadona(5)
      expect(ranking.first.supermarket, 'Dia');
      expect(ranking.first.totalPrice, 4);
      expect(ranking.last.supermarket, 'Mercadona');
      expect(ranking.last.totalPrice, 5);

      // Re-poll mismo lote: sustituye, no suma otra vez.
      acc.upsertBatch('c|d', const [
        SupermarketRankingDto(
          supermarket: 'Mercadona',
          totalPrice: 1,
          itemsFound: 2,
          itemsMissing: 0,
          resolved: 2,
          total: 2,
        ),
        SupermarketRankingDto(
          supermarket: 'Dia',
          totalPrice: 1.5,
          itemsFound: 2,
          itemsMissing: 0,
          resolved: 2,
          total: 2,
        ),
      ]);
      ranking = acc.build();
      expect(ranking.first.supermarket, 'Dia');
      expect(ranking.first.totalPrice, 1.5);
      expect(ranking.last.totalPrice, 3); // 2 + 1
    });
  });
}
