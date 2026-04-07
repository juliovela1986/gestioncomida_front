import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestioncomida_front/l10n/app_localizations.dart';
import 'package:gestioncomida_front/models/pending_expiration_item.dart';
import 'package:gestioncomida_front/screens/trash_screen.dart';

void main() {
  Widget buildTestApp({
    required Future<List<ExpiredPendingItemDto>> Function() loader,
    Future<ExpiredPendingBulkActionResponseDto> Function(InventoryTrashBulkRequestDto request)?
        restoreExecutor,
    Future<ExpiredPendingBulkActionResponseDto> Function(InventoryTrashBulkRequestDto request)?
        deleteExecutor,
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
      home: TrashScreen(
        loadTrashItems: loader,
        restoreItems: restoreExecutor,
        deleteItems: deleteExecutor,
      ),
    );
  }

  ExpiredPendingItemDto sampleItem(String id, String name) {
    return ExpiredPendingItemDto(
      id: id,
      productName: name,
      expirationDate: '2026-04-01',
      daysExpired: 5,
      status: 'TRASHED',
      locationId: 'loc-$id',
      locationName: 'Nevera',
    );
  }

  group('TrashScreen F1.3', () {
    testWidgets('muestra lista de papelera', (tester) async {
      await tester.pumpWidget(
        buildTestApp(loader: () async => [sampleItem('1', 'Leche entera')]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leche entera'), findsOneWidget);
      expect(find.text('Nevera'), findsOneWidget);
      expect(find.text('TRASHED'), findsOneWidget);
    });

    testWidgets('muestra estado vacio', (tester) async {
      await tester.pumpWidget(buildTestApp(loader: () async => []));
      await tester.pumpAndSettle();

      expect(find.text('No hay elementos en la papelera'), findsOneWidget);
    });

    testWidgets('permite restaurar items seleccionados', (tester) async {
      var items = <ExpiredPendingItemDto>[sampleItem('1', 'Leche entera')];
      InventoryTrashBulkRequestDto? capturedRequest;

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => items,
          restoreExecutor: (request) async {
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
      await tester.tap(find.byIcon(Icons.restore_from_trash_outlined));
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.itemIds, ['1']);
      expect(find.text('No hay elementos en la papelera'), findsOneWidget);
    });

    testWidgets('permite eliminar definitivamente con confirmacion', (tester) async {
      var items = <ExpiredPendingItemDto>[sampleItem('1', 'Leche entera')];
      InventoryTrashBulkRequestDto? capturedRequest;

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => items,
          deleteExecutor: (request) async {
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
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar definitivamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Eliminar definitivamente'));
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.itemIds, ['1']);
      expect(find.text('No hay elementos en la papelera'), findsOneWidget);
    });

    testWidgets('permite refresh manual desde app bar', (tester) async {
      var calls = 0;

      Future<List<ExpiredPendingItemDto>> loader() async {
        calls++;
        if (calls == 1) {
          return [sampleItem('1', 'Leche entera')];
        }
        return [sampleItem('2', 'Yogur')];
      }

      await tester.pumpWidget(buildTestApp(loader: loader));
      await tester.pumpAndSettle();

      expect(find.text('Leche entera'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('Yogur'), findsOneWidget);
    });

    testWidgets('muestra error global y permite reintento en restore', (tester) async {
      var items = <ExpiredPendingItemDto>[sampleItem('1', 'Leche entera')];
      final requests = <InventoryTrashBulkRequestDto>[];

      await tester.pumpWidget(
        buildTestApp(
          loader: () async => items,
          restoreExecutor: (request) async {
            requests.add(request);
            if (requests.length == 1) {
              throw DioException(
                requestOptions: RequestOptions(path: '/api/inventory/trash/restore'),
                response: Response(
                  requestOptions: RequestOptions(path: '/api/inventory/trash/restore'),
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
              idempotentReplay: false,
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Leche entera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.restore_from_trash_outlined));
      await tester.pumpAndSettle();

      expect(
        find.text('La solicitud no es válida. Revisa los datos e inténtalo de nuevo.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(requests.length, 2);
      expect(requests[0].itemIds, requests[1].itemIds);
      expect(find.text('No hay elementos en la papelera'), findsOneWidget);
    });
  });
}

