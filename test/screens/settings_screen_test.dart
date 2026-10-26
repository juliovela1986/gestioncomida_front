import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gestioncomida_front/l10n/app_localizations.dart';
import 'package:gestioncomida_front/models/pending_expiration_item.dart';
import 'package:gestioncomida_front/screens/settings_screen.dart';
import 'package:gestioncomida_front/services/preferences_service.dart';

void main() {
  Widget buildTestApp({
    required Future<CleanupPreferencesResponseDto> Function() loadPreferences,
    required Future<CleanupPreferencesResponseDto> Function(CleanupPreferencesUpdateRequestDto request)
        updatePreferences,
    required Future<ExpiredPendingSummaryResponseDto> Function() loadSummary,
  }) {
    return ChangeNotifierProvider<PreferencesService>(
      create: (_) => PreferencesService(),
      child: MaterialApp(
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
        home: SettingsScreen(
          loadCleanupPreferences: loadPreferences,
          updateCleanupPreferences: updatePreferences,
          loadExpiredPendingSummary: loadSummary,
        ),
      ),
    );
  }

  group('SettingsScreen F1.4', () {
    testWidgets('carga y muestra preferencias cleanup y summary', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          loadPreferences: () async => const CleanupPreferencesResponseDto(
            reminderFrequency: CleanupReminderFrequency.weekly,
            reminderWeekday: 1,
            reminderTime: '09:00',
            trashRetentionDays: 7,
          ),
          updatePreferences: (request) async => const CleanupPreferencesResponseDto(
            reminderFrequency: CleanupReminderFrequency.weekly,
            reminderWeekday: 1,
            reminderTime: '09:00',
            trashRetentionDays: 7,
          ),
          loadSummary: () async => ExpiredPendingSummaryResponseDto(
            expiredPendingCount: 4,
            trashedCount: 2,
            nextReminderAt: DateTime.parse('2026-04-13T09:00:00Z'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Limpieza de caducados'), findsOneWidget);
      expect(find.text('Frecuencia de recordatorio'), findsOneWidget);
      expect(find.text('Semanal'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Caducados pendientes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Caducados pendientes'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('En papelera'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('guarda preferencias cleanup', (tester) async {
      CleanupPreferencesUpdateRequestDto? capturedRequest;

      await tester.pumpWidget(
        buildTestApp(
          loadPreferences: () async => const CleanupPreferencesResponseDto(
            reminderFrequency: CleanupReminderFrequency.weekly,
            reminderWeekday: 1,
            reminderTime: '09:00',
            trashRetentionDays: 7,
          ),
          updatePreferences: (request) async {
            capturedRequest = request;
            return const CleanupPreferencesResponseDto(
              reminderFrequency: CleanupReminderFrequency.weekly,
              reminderWeekday: 1,
              reminderTime: '09:00',
              trashRetentionDays: 7,
            );
          },
          loadSummary: () async => const ExpiredPendingSummaryResponseDto(
            expiredPendingCount: 0,
            trashedCount: 0,
            nextReminderAt: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Guardar'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.reminderFrequency, CleanupReminderFrequency.weekly);
      expect(capturedRequest!.trashRetentionDays, 7);
      expect(find.text('Preferencias de limpieza guardadas'), findsOneWidget);
    });
  });
}

