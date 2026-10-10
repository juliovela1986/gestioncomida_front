import 'package:dio/dio.dart';

import 'app_exception.dart';

String userFriendlyError(Object error, {String fallback = 'Ha ocurrido un error inesperado. Inténtalo de nuevo.'}) {
  if (error is AppException) {
    return error.message;
  }

  if (error is DioException) {
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

