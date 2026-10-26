import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../models/location.dart';
import '../services/ticket_service.dart';
import '../widgets/expiry_date_voice_widget.dart';

class EditTicketLineScreen extends StatefulWidget {
  final TicketResponseDto initialTicket;
  final String lineIdToEdit;

  /// Ubicaciones disponibles (pasadas desde TicketValidationScreen para no repetir llamada)
  final List<LocationResponseDto> locations;

  /// Pre-asignaciones previas (si el usuario ya las había fijado antes)
  final String? initialLocationId;
  final DateTime? initialExpirationDate;
  final DateTime? initialAlertDate;

  const EditTicketLineScreen({
    super.key,
    required this.initialTicket,
    required this.lineIdToEdit,
    this.locations = const [],
    this.initialLocationId,
    this.initialExpirationDate,
    this.initialAlertDate,
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

  late TicketLineResponseDto _editingLine;

  String? _locationId;
  DateTime? _expirationDate;
  DateTime? _alertDate;

  @override
  void initState() {
    super.initState();
    _editingLine = widget.initialTicket.lines.firstWhere((l) => l.id == widget.lineIdToEdit);

    _nameController = TextEditingController(text: _editingLine.productName ?? _editingLine.parsedText ?? '');
    _quantityController = TextEditingController(text: _editingLine.quantity ?? '');
    _priceController = TextEditingController(text: _editingLine.price ?? '');

    _locationId = widget.initialLocationId;
    _expirationDate = widget.initialExpirationDate;
    _alertDate = widget.initialAlertDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isExpiration}) async {
    final initial = isExpiration
        ? (_expirationDate ?? DateTime.now().add(const Duration(days: 7)))
        : (_alertDate ?? (_expirationDate?.subtract(const Duration(days: 3)) ?? DateTime.now().add(const Duration(days: 4))));

    final lastDate = isExpiration
        ? DateTime.now().add(const Duration(days: 3650))
        : (_expirationDate ?? DateTime.now().add(const Duration(days: 3650)));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: lastDate,
    );
    if (date == null) return;

    setState(() {
      if (isExpiration) {
        _expirationDate = date;
        // Sugerir fecha de alerta 3 días antes si aún no hay una
        if (_alertDate == null) {
          _alertDate = date.subtract(const Duration(days: 3));
        }
      } else {
        _alertDate = date;
      }
    });
  }

  void _showExpiryVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpiryDateVoiceWidget(
        onDateDetected: (date) {
          setState(() {
            _expirationDate = date;
            if (_alertDate == null) {
              _alertDate = date.subtract(const Duration(days: 3));
            }
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fecha reconocida: ${DateFormat('dd/MM/yyyy').format(date)}')),
          );
        },
        onFallback: () {
          Navigator.pop(context);
          _pickDate(isExpiration: true);
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    print('[EditTicketLine] 🔵 Guardando cambios...');
    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> updatedLines = widget.initialTicket.lines.map((line) {
        if (line.id == widget.lineIdToEdit) {
          final quantity = double.tryParse(_quantityController.text) ?? 0.0;
          final price = double.tryParse(_priceController.text) ?? 0.0;
          return {
            'id': line.id,
            'productName': _nameController.text,
            'quantity': quantity,
            'price': price,
            'lineTotal': quantity * price,
          };
        } else {
          return {
            'id': line.id,
            'productName': line.productName,
            'quantity': double.tryParse(line.quantity ?? '0') ?? 0.0,
            'price': double.tryParse(line.price ?? '0') ?? 0.0,
            'lineTotal': double.tryParse(line.lineTotal ?? '0') ?? 0.0,
          };
        }
      }).toList();

      await _ticketService.updateTicket(widget.initialTicket.id, {'lines': updatedLines});
      print('[EditTicketLine] ✅ Actualización exitosa');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cambios guardados')),
        );
        // Devolvemos los datos extra (ubicación/caducidad/alerta) al padre
        Navigator.pop(context, {
          'saved': true,
          'locationId': _locationId,
          'expirationDate': _expirationDate,
          'alertDate': _alertDate,
        });
      }
    } catch (e) {
      print('[EditTicketLine] ❌ Error al guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Campos básicos ─────────────────────────────────────────────
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Producto',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio (€)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Datos de inventario (opcionales)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),

            // ── Ubicación ──────────────────────────────────────────────────
            if (widget.locations.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                initialValue: _locationId,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: Colors.green),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin ubicación específica'),
                  ),
                  ...widget.locations.map(
                    (loc) => DropdownMenuItem<String?>(
                      value: loc.id,
                      child: Text(loc.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _locationId = v),
              ),
              const SizedBox(height: 12),
            ],

            // ── Fecha de caducidad ─────────────────────────────────────────
            ListTile(
              tileColor: _expirationDate != null ? Colors.blue.shade50 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: Icon(
                Icons.event,
                color: _expirationDate != null ? Colors.blue : Colors.grey,
              ),
              title: const Text('Fecha de caducidad'),
              subtitle: Text(
                _expirationDate != null
                    ? fmt.format(_expirationDate!)
                    : 'Toca para seleccionar (opcional)',
                style: TextStyle(
                  color: _expirationDate != null ? Colors.blue.shade700 : Colors.grey,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.blue),
                    onPressed: _showExpiryVoiceInput,
                  ),
                  if (_expirationDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _expirationDate = null;
                        _alertDate = null;
                      }),
                    ),
                ],
              ),
              onTap: () => _pickDate(isExpiration: true),
            ),
            const SizedBox(height: 8),

            // ── Fecha de alerta ────────────────────────────────────────────
            ListTile(
              tileColor: _alertDate != null ? Colors.orange.shade50 : Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: Icon(
                Icons.notifications_active,
                color: _alertDate != null ? Colors.orange : Colors.grey,
              ),
              title: const Text('Fecha de alerta'),
              subtitle: Text(
                _alertDate != null
                    ? fmt.format(_alertDate!)
                    : 'Toca para seleccionar (opcional)',
                style: TextStyle(
                  color: _alertDate != null ? Colors.orange.shade700 : Colors.grey,
                ),
              ),
              trailing: _alertDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _alertDate = null),
                    )
                  : null,
              onTap: () => _expirationDate == null
                  ? ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Primero selecciona la fecha de caducidad')),
                    )
                  : _pickDate(isExpiration: false),
            ),

            const SizedBox(height: 20),

            // ── Info OCR ───────────────────────────────────────────────────
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
                  const SizedBox(height: 4),
                  Text('Confianza: ${((_editingLine.confidence ?? 0) * 100).toInt()}%'),
                ],
              ),
            ),

            const SizedBox(height: 24),
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
