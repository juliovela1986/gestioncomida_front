import 'package:flutter/foundation.dart';

/// Capas de log SCRUM-122: debug solo en `kDebugMode`; release sin dumps OCR/tokens.
class AppLogger {
  AppLogger._();

  /// Trazas técnicas (payloads, OCR, stacks). No-op en release.
  static void debug(String message, [Object? detail]) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[DEBUG] $message${detail != null ? ' | $detail' : ''}');
  }

  /// Info de flujo. Solo console en debug (UI lleva el mensaje al usuario).
  static void info(String message) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[INFO] $message');
  }

  /// Errores: console solo en debug (Crashlytics futuro).
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    final err = error != null ? ' | $error' : '';
    final st = stackTrace != null ? '\n$stackTrace' : '';
    // ignore: avoid_print
    print('[ERROR] $message$err$st');
  }

  /// UI «Ver texto OCR» / dumps raw: solo debug (o admin futuro).
  static bool get showTechnicalOcrUi => kDebugMode;
}
