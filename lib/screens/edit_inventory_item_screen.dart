import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../models/location.dart';
import '../services/inventory_service.dart';
import '../services/location_service.dart';

class EditInventoryItemScreen extends StatefulWidget {
  final InventoryItemResponseDto item;

  const EditInventoryItemScreen({
    super.key,
    required this.item,
  });

  @override
  State<EditInventoryItemScreen> createState() => _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState extends State<EditInventoryItemScreen> {
  final InventoryService _inventoryService = InventoryService();
  final LocationService _locationService = LocationService();
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  late TextEditingController _expirationDateController;
  late TextEditingController _alertDateController;
  bool _isSaving = false;
  List<LocationResponseDto> _locations = [];
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _expirationDateController = TextEditingController(text: widget.item.expirationDate ?? '');
    _alertDateController = TextEditingController(text: widget.item.alertDate ?? '');
    _selectedLocationId = widget.item.locationId;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _locationService.getUserLocations();
      setState(() => _locations = locations);
    } catch (e) {
      print('Error al cargar ubicaciones: $e');
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    _expirationDateController.dispose();
    _alertDateController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final updatedData = {
        'quantity': _quantityController.text,
        'expirationDate': _expirationDateController.text,
        'alertDate': _alertDateController.text,
        'notes': _notesController.text,
        if (_selectedLocationId != null) 'locationId': _selectedLocationId,
      };

      await _inventoryService.updateItem(widget.item.id, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cambios guardados')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
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

  void _reduceQuantity(double amount) {
    final currentQuantity = double.tryParse(_quantityController.text) ?? 0;
    final newQuantity = (currentQuantity - amount).clamp(0, double.infinity);
    setState(() {
      _quantityController.text = newQuantity.toString();
    });
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expirationDateController.text = picked.toIso8601String().split('T')[0];
        // Calcular automáticamente alertDate = expirationDate - 3 días
        final alertDate = picked.subtract(const Duration(days: 3));
        _alertDateController.text = alertDate.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _selectAlertDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _alertDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Color _getStatusColor() {
    switch (widget.item.status?.toUpperCase()) {
      case 'DISPONIBLE':
        return Colors.green;
      case 'PROXIMO_CADUCAR':
        return Colors.orange;
      case 'CADUCADO':
        return Colors.red;
      case 'ABIERTO':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        backgroundColor: _getStatusColor(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información del producto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productName ?? 'Sin nombre',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (widget.item.productBrand != null)
                      Text('Marca: ${widget.item.productBrand}',
                          style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: _getStatusColor()),
                        const SizedBox(width: 8),
                        Text(widget.item.status ?? 'Sin estado'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ubicación
            const Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              hint: const Text('Selecciona una ubicación'),
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location.id,
                  child: Text(location.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedLocationId = value);
              },
            ),
            const SizedBox(height: 16),

            // Cantidad
            const Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: 'unidades',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => _reduceQuantity(1),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 36),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('-1'),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => _reduceQuantity(0.5),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(60, 36),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('-0.5'),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.item.initialQuantity != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Cantidad inicial: ${widget.item.initialQuantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // Fecha de caducidad
            const Text('Fecha de Caducidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _expirationDateController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectExpirationDate,
                ),
              ),
              readOnly: true,
              onTap: _selectExpirationDate,
            ),
            const SizedBox(height: 16),

            // Fecha de alerta
            const Text('Fecha de Alerta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Se te notificará en esta fecha',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alertDateController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectAlertDate,
                ),
                helperText: 'Calculada automáticamente (3 días antes)',
              ),
              readOnly: true,
              onTap: _selectAlertDate,
            ),
            const SizedBox(height: 16),

            // Notas
            const Text('Notas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Añade notas sobre el producto...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Botón guardar
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
