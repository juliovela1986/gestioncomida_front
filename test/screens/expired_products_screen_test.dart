import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestioncomida_front/l10n/app_localizations.dart';
import 'package:gestioncomida_front/models/pending_expiration_item.dart';
import 'package:gestioncomida_front/screens/expired_products_screen.dart';

void main() {
  Widget buildTestApp({
    required Future<List<ExpiredPendingItemDto>> Function() loader,
    Future<ExpiredPendingBulkActionResponseDto> Function(
      ExpiredPendingBulkActionRequestDto request,
    )?
    executor,
    Future<DateTime?> Function(BuildContext context)? pickSnoozeDate,
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
      home: ExpiredProductsScreen(
        loadExpiredPendingItems: loader,
        executeBulkAction: executor,
        pickSnoozeDate: pickSnoozeDate,
      ),
    );
  }

  ExpiredPendingItemDto sampleItem(
    String id,
    String name, {
    String locationName = 'Nevera',
    int daysExpired = 5,
    String expirationDate = '2026-04-01',
  }) {
    return ExpiredPendingItemDto(
      id: id,
      productName: name,
      expirationDate: expirationDate,
      daysExpired: daysExpired,
      status: 'EXPIRED_PENDING',
      locationId: 'loc-$id',
      locationName: locationName,
    );
  }

  group('ExpiredProductsScreen F1.x', () {
    testWidgets('muestra loading inicial y luego lista de caducados pendientes', (
      tester,
    ) async {
      final completer = Completer<List<ExpiredPendingItemDto>>();

      await tester.pumpWidget(buildTestApp(loader: () => completer.future));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([
        sampleItem('1', 'Leche entera'),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('Leche entera'), findsOneWidget);
      expect(find.text('Nevera'), findsOneWidget);
      expect(find.text('Caducado hace 5 días'), findsOneWidget);
      expect(find.text('Fecha: 01/04/2026'), findsOneWidget);
    });

    testWidgets('muestra estado vacio cuando no hay items pendientes', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(loader: () async => []));
      await tester.pumpAndSettle();

      expect(find.text('No hay productos caducados pendientes'), findsOneWidget);
      expect(find.text('Desliza hacia abajo para refrescar'), findsOneWidget);
    });

    testWidgets('muestra error y permite reintentar', (tester) async {
      var calls = 0;

      Future<List<ExpiredPendingItemDto>> loader() async {
        calls++;
        if (calls == 1) {
          throw Exception('fallo temporal');
        }
        return [];
      }

      await tester.pumpWidget(buildTestApp(loader: loader));
      await tester.pumpAndSettle();

      expect(
        find.text('Ha ocurrido un error inesperado. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Refrescar'), findsWidgets);

      await tester.tap(find.text('Refrescar').last);
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('No hay productos caducados pendientes'), findsOneWidget);
    });

    testWidgets('permite refresco manual desde app bar', (tester) async {
      var calls = 0;

      Future<List<ExpiredPendingItemDto>> loader() async {
        calls++;
        if (calls == 1) {
          return [
            sampleItem('1', 'Yogur', expirationDate: '2026-04-02', daysExpired: 4),
          ];
        }

        return [
          sampleItem('2', 'Queso', expirationDate: '2026-04-03', daysExpired: 3),
        ];
      }

      await tester.pumpWidget(buildTestApp(loader: loader));
      await tester.pumpAndSettle();

      expect(find.text('Yogur'), findsOneWidget);
      expect(find.text('Queso'), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('Yogur'), findsNothing);
      expect(find.text('Queso'), findsOneWidget);
    });

    testWidgets('permite seleccionar y archivar items', (tester) async {
      var items = <ExpiredPendingItemDto>[sampleItem('1', 'Leche entera')];
      ExpiredPendingBulkActionRequestDto? capturedRequest;

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => items,
          executor: (request) async {
            capturedRequest = request;
            items = [];
            return const ExpiredPendingBulkActionResponseDto(
              requested: 1,
              processed: 1,
              updated: 1,
              skipped: 0,
              errors: [],
              idempotentReplay: false,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Leche entera'));
      await tester.pumpAndSettle();

      expect(find.text('1 seleccionados'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.action, ExpiredPendingBulkActionType.archive);
      expect(capturedRequest!.itemIds, ['1']);
      expect(capturedRequest!.clientRequestId, isNotEmpty);
      expect(find.text('No hay productos caducados pendientes'), findsOneWidget);
    });

    testWidgets('permite mover a papelera desde menu de acciones', (tester) async {
      ExpiredPendingBulkActionRequestDto? capturedRequest;

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => [sampleItem('1', 'Leche entera')],
          executor: (request) async {
            capturedRequest = request;
            return const ExpiredPendingBulkActionResponseDto(
              requested: 1,
              processed: 1,
              updated: 1,
              skipped: 0,
              errors: [],
              idempotentReplay: false,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Leche entera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mover a papelera'));
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.action, ExpiredPendingBulkActionType.moveToTrash);
    });

    testWidgets('permite posponer usando fecha seleccionada', (tester) async {
      ExpiredPendingBulkActionRequestDto? capturedRequest;

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => [sampleItem('1', 'Leche entera')],
          executor: (request) async {
            capturedRequest = request;
            return const ExpiredPendingBulkActionResponseDto(
              requested: 1,
              processed: 1,
              updated: 1,
              skipped: 0,
              errors: [],
              idempotentReplay: false,
            );
          },
          pickSnoozeDate: (_) async => DateTime(2026, 4, 20),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Leche entera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Posponer'));
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.action, ExpiredPendingBulkActionType.snooze);
      expect(capturedRequest!.snoozeUntil, '2026-04-20');
    });

    testWidgets('muestra resultado parcial cuando la respuesta incluye errors[]', (
      tester,
    ) async {
      var items = <ExpiredPendingItemDto>[
        sampleItem('1', 'Leche entera'),
        sampleItem('2', 'Yogur'),
      ];

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => items,
          executor: (request) async {
            items = [sampleItem('2', 'Yogur')];
            return const ExpiredPendingBulkActionResponseDto(
              requested: 2,
              processed: 2,
              updated: 1,
              skipped: 1,
              errors: ['No se pudo procesar un item'],
              idempotentReplay: false,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Leche entera'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yogur'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      expect(
        find.text('Se procesaron 1 de 2 elementos. 1 error(es).'),
        findsOneWidget,
      );
      expect(find.text('Yogur'), findsOneWidget);
    });

    testWidgets('reintenta con el mismo clientRequestId tras error global', (
      tester,
    ) async {
      var items = <ExpiredPendingItemDto>[sampleItem('1', 'Leche entera')];
      final requests = <ExpiredPendingBulkActionRequestDto>[];

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => items,
          executor: (request) async {
            requests.add(request);

            if (requests.length == 1) {
              throw DioException(
                requestOptions: RequestOptions(path: '/api/inventory/expired-pending/actions'),
                response: Response(
                  requestOptions: RequestOptions(path: '/api/inventory/expired-pending/actions'),
                  statusCode: 400,
                  data: const {
                    'requested': 1,
                    'processed': 0,
                    'updated': 0,
                    'skipped': 0,
                    'errors': ['Petición inválida'],
                    'idempotentReplay': false,
                  },
                ),
                type: DioExceptionType.badResponse,
              );
            }

            items = [];
            return const ExpiredPendingBulkActionResponseDto(
              requested: 1,
              processed: 1,
              updated: 1,
              skipped: 0,
              errors: [],
              idempotentReplay: true,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Leche entera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pumpAndSettle();

      expect(
        find.text('La solicitud no es válida. Revisa los datos e inténtalo de nuevo.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(requests.length, 2);
      expect(requests[0].clientRequestId, requests[1].clientRequestId);
      expect(find.text('No hay productos caducados pendientes'), findsOneWidget);
    });
  });
}

