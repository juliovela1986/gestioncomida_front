import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  static String get backendUrl =>
      _env('BACKEND_URL') ?? 'http://localhost:8081';

  static String get keycloakUrl =>
      _env('KEYCLOAK_URL') ?? 'http://localhost:8180';

  static String get keycloakRealm => '$keycloakUrl/realms/gestioncomida';
  static String get discoveryUrl => '$keycloakRealm/.well-known/openid-configuration';
}
