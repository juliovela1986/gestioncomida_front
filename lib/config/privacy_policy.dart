import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URL pública HTTPS de la política (SCRUM-140).
/// Override: PRIVACY_POLICY_URL en `.env`.
class PrivacyPolicy {
  PrivacyPolicy._();

  static const String defaultUrl =
      'https://api-gestioncomida.duckdns.org/privacy.html';

  static String get url {
    final fromEnv = dotenv.env['PRIVACY_POLICY_URL'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return fromEnv.trim();
    }
    return defaultUrl;
  }
}
