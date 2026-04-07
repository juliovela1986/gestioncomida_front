class AppConfig {
  //static const String backendUrl = 'http://192.168.1.143:8081';
  //static const String keycloakUrl = 'http://192.168.1.143:8180';
  //static const String keycloakUrl = 'https://julio86.myqnapcloud.com';
  //static const String backendUrl = 'https://julio86.myqnapcloud.com:8444';
// 1. Tu API de Spring Boot a través del Proxy HTTPS
static const String backendUrl = 'https://api-gestioncomida.duckdns.org';
// 2. Tu Servidor de Autenticación Keycloak a través del Proxy HTTPS
static const String keycloakUrl = 'https://auth-gestioncomida.duckdns.org';

  static String get keycloakRealm => '$keycloakUrl/realms/gestioncomida';
  static String get discoveryUrl => '$keycloakRealm/.well-known/openid-configuration';
}

