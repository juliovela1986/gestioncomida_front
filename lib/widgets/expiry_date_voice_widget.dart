import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';
import '../services/groq_vision_service.dart';

class ExpiryDateVoiceWidget extends StatefulWidget {
  final Function(DateTime) onDateDetected;
  final VoidCallback onFallback;

  const ExpiryDateVoiceWidget({
    required this.onDateDetected,
    required this.onFallback,
    super.key,
  });

  @override
  State<ExpiryDateVoiceWidget> createState() => _ExpiryDateVoiceWidgetState();
}

class _ExpiryDateVoiceWidgetState extends State<ExpiryDateVoiceWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GroqVisionService _groqService = GroqVisionService();
  bool _isListening = false;
  bool _isProcessing = false;
  String _status = 'Pulsa el micro y di la fecha';
  String _recognizedWords = '';

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('Speech Status: $val'),
        onError: (val) => debugPrint('Speech Error: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _status = 'Escuchando...';
          _recognizedWords = '';
        });
        _speech.listen(
          localeId: 'es_ES',
          onResult: (val) async {
            setState(() => _recognizedWords = val.recognizedWords);
            if (val.finalResult) {
              _processVoiceInput(val.recognizedWords);
            }
          },
        );
      } else {
        setState(() => _status = 'El micrófono no está disponible');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _processVoiceInput(String text) async {
    print('DEBUG: Voice recognized: "$text"');
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _status = 'Analizando fecha...';
    });

    try {
      final detectedStr = await _groqService.processVoiceDate(text);
      print('DEBUG: Extracted date string from Groq: "$detectedStr"');
      if (detectedStr != null) {
        DateTime? date = _parseDate(detectedStr);
        if (date != null) {
          widget.onDateDetected(date);
          return;
        }
      }
      setState(() {
        _status = 'No se reconoció una fecha válida.\nInténtalo de nuevo.';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error al procesar: $e';
        _isProcessing = false;
      });
    }
  }

  DateTime? _parseDate(String text) {
    try {
      // Groq devuelve dd/mm/yyyy
      return DateFormat('dd/MM/yyyy').parse(text);
    } catch (e) {
      debugPrint('Error parseando fecha: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Dictar Fecha de Caducidad',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _buildMicButton(),
          const SizedBox(height: 20),
          Text(
            _isListening ? 'Escuchando: $_recognizedWords' : _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isListening ? Colors.blueAccent : Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          TextButton.icon(
            onPressed: widget.onFallback,
            icon: const Icon(Icons.calendar_month, color: Colors.blue),
            label: const Text('Introducir manualmente', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isListening)
          const SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
        GestureDetector(
          onTap: _listen,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isListening ? Colors.redAccent : Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.redAccent : Colors.blue).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        if (_isProcessing)
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }
}
