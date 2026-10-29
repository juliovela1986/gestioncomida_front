import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Prefer business message from backend (`ErrorResponse.message`) over status codes / Dio noise.
String userFriendlyError(Object error, {String fallback = 'Ha ocurrido un error inesperado. Inténtalo de nuevo.'}) {
  if (error is AppException) {
    return error.message;
  }

  if (error is DioException) {
    final fromBody = _messageFromResponseBody(error.response?.data);
    if (fromBody != null) {
      return fromBody;
    }

    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 400:
        return 'La solicitud no es válida. Revisa los datos e inténtalo de nuevo.';
      case 401:
        return 'Tu sesión ha caducado. Inicia sesión de nuevo.';
      case 403:
        return 'No tienes permisos para realizar esta acción.';
      case 404:
        return 'No se ha encontrado la información solicitada.';
      case 409:
        return 'El elemento ya existe o entra en conflicto con otro registro.';
      case 415:
        return 'El formato del archivo no es compatible.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'El servidor no está disponible en este momento. Inténtalo más tarde.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'La conexión está tardando demasiado. Comprueba tu red e inténtalo de nuevo.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se ha podido conectar con el servidor. Comprueba tu conexión a internet.';
    }

    if (error.type == DioExceptionType.cancel) {
      return 'La operación fue cancelada.';
    }
  }

  return fallback;
}

String? _messageFromResponseBody(dynamic data) {
  if (data == null) return null;

  if (data is String) {
    final trimmed = data.trim();
    if (trimmed.isEmpty || trimmed.startsWith('<')) return null;
    if (_looksLikeTechnicalNoise(trimmed)) return null;
    return trimmed;
  }

  if (data is Map) {
    final message = data['message'] ?? data['error_description'] ?? data['detail'];
    if (message is String) {
      final trimmed = message.trim();
      if (trimmed.isEmpty) return null;
      if (_looksLikeTechnicalNoise(trimmed)) return null;
      return trimmed;
    }
  }

  return null;
}

bool _looksLikeTechnicalNoise(String value) {
  final lower = value.toLowerCase();
  return lower.contains('exception') ||
      lower.contains('stacktrace') ||
      lower.contains('org.springframework') ||
      lower.contains('java.') ||
      RegExp(r'\berror\.[a-z0-9_.]+\b', caseSensitive: false).hasMatch(value);
}
