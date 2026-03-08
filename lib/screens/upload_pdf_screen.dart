import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../services/ticket_service.dart';
import '../models/ticket_processing_result.dart';
import 'ticket_validation_screen.dart';

class UploadPdfScreen extends StatefulWidget {
  const UploadPdfScreen({super.key});

  @override
  State<UploadPdfScreen> createState() => _UploadPdfScreenState();
}

class _UploadPdfScreenState extends State<UploadPdfScreen> {
  String? _fileName;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _fileName = _selectedFile!.name;
      });
    }
  }

  Future<void> _uploadPdf() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final ticketService = TicketService();
      
      // En Android usar path, en Web usar bytes
      final formData = FormData.fromMap({
        'file': _selectedFile!.path != null
            ? await MultipartFile.fromFile(
                _selectedFile!.path!,
                filename: _selectedFile!.name,
              )
            : MultipartFile.fromBytes(
                _selectedFile!.bytes!,
                filename: _selectedFile!.name,
              ),
      });

      final response = await ticketService.uploadTicket(formData);
      
      if (mounted) {
        if (response.statusCode == 200) {
          // Extraer ticketId de la respuesta
          final result = TicketProcessingResultDto.fromJson(response.data);
          final ticketId = result.metadata.id;
          
          // Navegar a validación del ticket
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TicketValidationScreen(ticketId: ticketId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusMessage}')),
          );
        }
      }
    } catch (e) {
      print('[UploadPDF] Error: $e');
      if (mounted) {
        String errorMessage = 'Error al subir PDF';
        
        if (e.toString().contains('409')) {
          errorMessage = 'Este ticket ya fue procesado anteriormente';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Sesión expirada. Por favor, inicia sesión de nuevo';
        } else if (e.toString().contains('415')) {
          errorMessage = 'Formato de archivo no soportado';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subir PDF'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              if (_fileName != null) ...[
                Text('Archivo seleccionado:', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
              ],
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickPdfFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Seleccionar PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              if (_selectedFile != null)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadPdf,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? 'Subiendo...' : 'Subir PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
