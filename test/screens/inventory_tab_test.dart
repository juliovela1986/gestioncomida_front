 import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestioncomida_front/l10n/app_localizations.dart';
import 'package:gestioncomida_front/models/pending_expiration_item.dart';
import 'package:gestioncomida_front/screens/inventory_tab.dart';

void main() {
  Widget buildTestApp({
    required Future<ExpiredPendingSummaryResponseDto> Function() loadSummary,
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
      home: InventoryTab(loadSummary: loadSummary),
    );
  }

  group('InventoryTab F1.4', () {
    testWidgets('muestra contadores de summary en subtitulos', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          loadSummary: () async => const ExpiredPendingSummaryResponseDto(
            expiredPendingCount: 5,
            trashedCount: 2,
            nextReminderAt: null,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pendientes: 5'), findsOneWidget);
      expect(find.text('En papelera: 2'), findsOneWidget);
    });
  });
}

