class AppConfig {
  //static const String keycloakUrl = 'http://julio86.myqnapcloud.com:8180';
  //static const String backendUrl = 'http://julio86.myqnapcloud.com:8081';
  static const String backendUrl = 'http://192.168.1.143:8081';
  static const String keycloakUrl = 'http://192.168.1.143:8180';
  static String get keycloakRealm => '$keycloakUrl/realms/gestioncomida';
  static String get discoveryUrl => '$keycloakRealm/.well-known/openid-configuration';
}

