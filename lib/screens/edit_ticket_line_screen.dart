import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

class EditTicketLineScreen extends StatefulWidget {
  final TicketResponseDto initialTicket;
  final String lineIdToEdit;

  const EditTicketLineScreen({
    super.key,
    required this.initialTicket,
    required this.lineIdToEdit,
  });

  @override
  State<EditTicketLineScreen> createState() => _EditTicketLineScreenState();
}

class _EditTicketLineScreenState extends State<EditTicketLineScreen> {
  final TicketService _ticketService = TicketService();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  bool _isSaving = false;

  // La línea específica que estamos editando
  late TicketLineResponseDto _editingLine;

  @override
  void initState() {
    super.initState();
    // Encontramos la línea a editar dentro de la lista de líneas del ticket
    _editingLine = widget.initialTicket.lines.firstWhere((line) => line.id == widget.lineIdToEdit);
    
    _nameController = TextEditingController(
        text: _editingLine.productName ?? _editingLine.parsedText ?? '');
    _quantityController = TextEditingController(text: _editingLine.quantity ?? '');
    _priceController = TextEditingController(text: _editingLine.price ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    print('[EditTicketLine] 🔵 Iniciando guardado de cambios...');
    setState(() => _isSaving = true);
    
    try {
      // Mapeamos todas las líneas. Si es la que estamos editando, usamos los valores nuevos.
      // Si no, mantenemos los valores originales.
      final List<Map<String, dynamic>> updatedLines = widget.initialTicket.lines.map((line) {
        if (line.id == widget.lineIdToEdit) {
          // Es la línea que estamos editando: usamos los valores de los controladores.
          final quantity = double.tryParse(_quantityController.text) ?? 0.0;
          final price = double.tryParse(_priceController.text) ?? 0.0;
          return {
            'id': line.id,
            'productName': _nameController.text,
            'quantity': quantity,
            'price': price,
            'lineTotal': quantity * price, // Calculamos el nuevo total
          };
        } else {
          // No es la línea que editamos: devolvemos sus datos originales.
          return {
            'id': line.id,
            'productName': line.productName,
            'quantity': double.tryParse(line.quantity ?? '0') ?? 0.0,
            'price': double.tryParse(line.price ?? '0') ?? 0.0,
            'lineTotal': double.tryParse(line.lineTotal ?? '0') ?? 0.0,
          };
        }
      }).toList();

      final updatedData = {'lines': updatedLines};

      print('[EditTicketLine] 📦 Datos a actualizar: $updatedData');
      await _ticketService.updateTicket(widget.initialTicket.id, updatedData);
      print('[EditTicketLine] ✅ Actualización exitosa');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cambios guardados')),
        );
        Navigator.pop(context, true); // Devolvemos `true` para indicar que se debe recargar
      }
    } catch (e) {
      print('[EditTicketLine] ❌ Error al guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Texto Original OCR:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_editingLine.parsedText ?? 'N/A'),
                  const SizedBox(height: 8),
                  Text('Confianza: ${((_editingLine.confidence ?? 0) * 100).toInt()}%'),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blue,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
