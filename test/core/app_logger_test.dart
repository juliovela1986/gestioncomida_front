import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestioncomida_front/core/app_logger.dart';

void main() {
  test('AppLogger.debug y error no lanzan', () {
    expect(() => AppLogger.debug('ticket payload', {'rawText': 'SECRET'}), returnsNormally);
    expect(() => AppLogger.info('flujo ok'), returnsNormally);
    expect(() => AppLogger.error('fallo', Exception('x'), StackTrace.current), returnsNormally);
  });

  test('showTechnicalOcrUi sigue kDebugMode del test binding', () {
    // flutter_test corre en debug → UI técnica permitida en tests.
    expect(AppLogger.showTechnicalOcrUi, isTrue);
    expect(kDebugMode, isTrue);
  });
}
