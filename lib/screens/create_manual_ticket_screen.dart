import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_manual_create.dart';
import '../models/location.dart';
import '../services/ticket_service.dart';
import '../services/location_service.dart';
import 'ticket_validation_screen.dart';

class CreateManualTicketScreen extends StatefulWidget {
  const CreateManualTicketScreen({super.key});

  @override
  State<CreateManualTicketScreen> createState() => _CreateManualTicketScreenState();
}

class _CreateManualTicketScreenState extends State<CreateManualTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TicketService _ticketService = TicketService();
  final LocationService _locationService = LocationService();
  
  final _supermarketController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  String? _selectedLocationId;
  List<LocationResponseDto> _locations = [];
  List<_LineItem> _lines = [_LineItem()];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _locationService.getUserLocations();
      setState(() => _locations = locations);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_purchaseDate),
      );
      if (time != null) {
        setState(() {
          _purchaseDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _addLine() {
    setState(() => _lines.add(_LineItem()));
  }

  void _removeLine(int index) {
    if (_lines.length > 1) {
      setState(() => _lines.removeAt(index));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final request = TicketManualCreateRequest(
        supermarketName: _supermarketController.text.trim(),
        purchaseDatetime: _purchaseDate.toUtc().toIso8601String(),
        locationId: _selectedLocationId,
        lines: _lines.map((l) => TicketLineCreate(
          productName: l.nameController.text.trim(),
          quantity: double.parse(l.quantityController.text),
          price: l.priceController.text.isNotEmpty ? double.parse(l.priceController.text) : null,
          lineTotal: l.totalController.text.isNotEmpty ? double.parse(l.totalController.text) : null,
        )).toList(),
      );

      final ticket = await _ticketService.createManualTicket(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ticket creado exitosamente')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TicketValidationScreen(ticketId: ticket.id),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Ticket Manual'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _supermarketController,
              decoration: const InputDecoration(
                labelText: 'Supermercado *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Fecha y hora de compra'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_purchaseDate)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Ubicación (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin ubicación')),
                ..._locations.map((loc) => DropdownMenuItem(
                  value: loc.id,
                  child: Text(loc.name),
                )),
              ],
              onChanged: (v) => setState(() => _selectedLocationId = v),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addLine,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._lines.asMap().entries.map((entry) {
              final index = entry.key;
              final line = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Producto ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (_lines.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeLine(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: line.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: line.quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v?.trim().isEmpty ?? true) return 'Requerido';
                                if (double.tryParse(v!) == null) return 'Número inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: line.priceController,
                              decoration: const InputDecoration(
                                labelText: 'Precio',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: line.totalController,
                              decoration: const InputDecoration(
                                labelText: 'Total',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
                backgroundColor: Colors.green,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('CREAR TICKET', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _supermarketController.dispose();
    for (var line in _lines) {
      line.dispose();
    }
    super.dispose();
  }
}

class _LineItem {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final totalController = TextEditingController();

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    totalController.dispose();
  }
}
