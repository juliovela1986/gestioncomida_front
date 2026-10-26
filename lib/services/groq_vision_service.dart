import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqVisionService {
  /// Modelo barato/rápido para parsear fechas por voz (tarea estrecha).
  /// Override: GROQ_DATE_MODEL en .env (p.ej. qwen/qwen3.8-27b).
  static const String defaultDateModel = 'openai/gpt-oss-20b';

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  String get _dateModel {
    final configured = dotenv.env['GROQ_DATE_MODEL']?.trim();
    if (configured != null && configured.isNotEmpty) return configured;
    return defaultDateModel;
  }

  Future<String?> processVoiceDate(String voiceText) async {
    if (_apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final model = _dateModel;
      print('DEBUG: Groq date model: $model');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': '''Extrae la fecha de caducidad en formato dd/mm/yyyy.
REGLAS:
- Solo responde la fecha (ej: 21/05/2026) o "NONE".
- Si no hay año, usa 2026.
- Si no hay día (ej: "abril del veintiséis" o "mayo"), usa el ÚLTIMO día de ese mes.
- El usuario puede decir el mes por nombre o por número (ej: "del cuatro" = abril).
- El año puede ser abreviado (ej: "veintiseis" = 2026).

EJEMPLOS:
- "veinticuatro del cuatro del veintiseis": 24/04/2026
- "uno del uno del veintiseis": 01/01/2026
- "doce de mayo": 12/05/2026
- "mayo del veintiseis": 31/05/2026
- "veintiocho de febrero": 28/02/2026

Texto a procesar: "$voiceText"'''
            }
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String result = data['choices'][0]['message']['content'].toString().trim();
        print('DEBUG: Groq answer: "$result"');

        // Intentar extraer solo la fecha dd/mm/yyyy si el modelo devuelve texto extra
        final RegExp dateRegExp = RegExp(r'(\d{1,2}/\d{1,2}/\d{4})');
        final match = dateRegExp.firstMatch(result);

        if (match != null) {
          return match.group(0);
        }

        return result.toUpperCase() == 'NONE' ? null : result;
      } else {
        print('DEBUG: Groq error status: ${response.statusCode}');
        print('DEBUG: Groq error body: ${response.body}');
      }
    } catch (e) {
      print('Error procesando voz con Groq: $e');
    }
    return null;
  }
}
