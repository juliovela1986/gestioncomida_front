class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

class SessionExpiredException extends AppException {
  const SessionExpiredException([super.message = 'Tu sesión ha caducado. Inicia sesión de nuevo.']);
}

