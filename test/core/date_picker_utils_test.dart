import 'package:flutter_test/flutter_test.dart';
import 'package:gestioncomida_front/core/date_picker_utils.dart';

void main() {
  group('buildSafeDatePickerConfig', () {
    test('clamp initialDate when it is after lastDate', () {
      final config = buildSafeDatePickerConfig(
        initialDate: DateTime(2026, 7, 28),
        firstDate: DateTime(2025, 4, 8),
        lastDate: DateTime(2026, 4, 8),
      );

      expect(config.initialDate, DateTime(2026, 4, 8));
      expect(config.firstDate, DateTime(2025, 4, 8));
      expect(config.lastDate, DateTime(2026, 4, 8));
    });

    test('clamp initialDate when it is before firstDate', () {
      final config = buildSafeDatePickerConfig(
        initialDate: DateTime(2024, 1, 1),
        firstDate: DateTime(2025, 4, 8),
        lastDate: DateTime(2026, 4, 8),
      );

      expect(config.initialDate, DateTime(2025, 4, 8));
    });

    test('collapse invalid range when firstDate is after lastDate', () {
      final config = buildSafeDatePickerConfig(
        initialDate: DateTime(2026, 7, 28),
        firstDate: DateTime(2026, 4, 10),
        lastDate: DateTime(2026, 4, 8),
      );

      expect(config.firstDate, DateTime(2026, 4, 8));
      expect(config.lastDate, DateTime(2026, 4, 8));
      expect(config.initialDate, DateTime(2026, 4, 8));
    });
  });
}

