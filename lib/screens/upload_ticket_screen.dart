import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/ticket_service.dart';
import 'ticket_validation_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadTicketScreen extends StatefulWidget {
  const UploadTicketScreen({super.key});

  @override
  State<UploadTicketScreen> createState() => _UploadTicketScreenState();
}

class _UploadTicketScreenState extends State<UploadTicketScreen> {
  final TicketService _ticketService = TicketService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadTicket() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Por favor selecciona una imagen');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_selectedImage!.path),
      });
      
      final response = await _ticketService.uploadTicket(formData);
      
      print('[Upload] Response status: ${response.statusCode}');
      print('[Upload] Response data: ${response.data}');
      
      if (response.statusCode == 200 && mounted) {
        // Intentar obtener el ID del ticket de diferentes estructuras posibles
        String? ticketId;
        
        if (response.data is Map) {
          // Intentar metadata.id
          ticketId = response.data['metadata']?['id'];
          
          // Si no existe, intentar id directamente
          ticketId ??= response.data['id'];
        }
        
        if (ticketId != null) {
          print('[Upload] Ticket ID obtenido: $ticketId');
          
          // Parsear las líneas del response
          final linesData = response.data['lines'] as List?;
          final lines = linesData?.map((e) => {
            'id': e['id'],
            'productId': e['productId'],
            'productName': e['productName'],
            'parsedText': e['parsedText'],
            'confidence': e['confidence'],
            'quantity': e['quantity'],
            'price': e['price'],
            'lineTotal': e['lineTotal'],
          }).toList() ?? [];
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TicketValidationScreen(
                ticketId: ticketId!,
                initialTicketData: response.data,
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Error: No se pudo obtener el ID del ticket';
            _isUploading = false;
          });
        }
      }
    } on DioException catch (e) {
      print('[Upload] DioException: ${e.message}');
      print('[Upload] Status code: ${e.response?.statusCode}');
      print('[Upload] Response: ${e.response?.data}');
      
      if (mounted) {
        String errorMessage = 'Error al procesar el ticket';
        
        if (e.response?.statusCode == 409) {
          errorMessage = 'Este ticket ya fue procesado anteriormente';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Sesión expirada. Por favor, inicia sesión de nuevo';
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'Acceso denegado. Verifica tus permisos';
        } else if (e.response?.statusCode == 415) {
          errorMessage = 'Formato de archivo no soportado';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        
        setState(() {
          _errorMessage = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      print('[Upload] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error inesperado al procesar el ticket'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        
        setState(() {
          _errorMessage = null;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImage != null)
              Expanded(
                child: Image.file(_selectedImage!, fit: BoxFit.contain),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No hay imagen seleccionada'),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadTicket,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.green,
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Procesar Ticket', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
