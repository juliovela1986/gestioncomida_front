import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expiration_management_response.dart';
import '../services/inventory_service.dart';
import '../services/ticket_service.dart';

class ExpirationDateManagerScreen extends StatefulWidget {
  final String ticketId;
  
  const ExpirationDateManagerScreen({super.key, required this.ticketId});

  @override
  State<ExpirationDateManagerScreen> createState() => _ExpirationDateManagerScreenState();
}

class _ExpirationDateManagerScreenState extends State<ExpirationDateManagerScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TicketService _ticketService = TicketService();
  
  List<ProductToManage> _products = [];
  Map<String, DateTime?> _selectedDates = {}; // ticketLineId -> fecha
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final response = await _ticketService.getExpirationManagement(widget.ticketId);
      print('[ExpirationManager] ✅ Respuesta: ${response.products.length} productos');
      
      // Filtrar solo productos que tienen newInventoryItemId (los que necesitan fecha)
      final productsNeedingDate = response.products
          .where((p) => p.newInventoryItemId.isNotEmpty)
          .toList();
      
      print('[ExpirationManager] 🎯 Productos que necesitan fecha: ${productsNeedingDate.length}');
      
      setState(() {
        _products = productsNeedingDate;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('[ExpirationManager] ❌ Error: $e');
      print('[ExpirationManager] 📍 StackTrace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1000)),
    );

    if (date != null) {
      setState(() {
        _selectedDates[_products[_currentIndex].ticketLineId] = date;
      });
    }
  }

  Future<void> _confirmSave() async {
    final currentProduct = _products[_currentIndex];
    final selectedDate = _selectedDates[currentProduct.ticketLineId];
    
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha primero')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Asignar fecha usando el nuevo endpoint
      await _ticketService.assignExpirationDates(widget.ticketId, [
        {
          'ticketLineId': currentProduct.ticketLineId,
          'expirationDate': DateFormat('yyyy-MM-dd').format(selectedDate),
        }
      ]);
      
      if (_currentIndex < _products.length - 1) {
        setState(() {
          _currentIndex++;
          _isSaving = false;
        });
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  void _skip() {
    if (_currentIndex < _products.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildProductCard(ProductToManage product) {
    final String productName = product.productName;
    final List<ExistingLot> existingLots = product.existingLots;
    final double quantity = product.newQuantity;
    final selectedDate = _selectedDates[product.ticketLineId];

    return Column(
      children: [
        Text(
          productName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text('Nueva Cantidad: $quantity'),
          backgroundColor: Colors.blue.shade50,
        ),
        const SizedBox(height: 24),
        
        if (existingLots.isNotEmpty) ...[
          const Text('Lotes existentes en inventario:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          ...existingLots.map((lot) => Card(
            color: Colors.orange.shade50,
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: Text('Caduca el: ${lot.expirationDate}'),
              subtitle: Text('Cantidad actual: ${lot.quantity}'),
            ),
          )),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Icon(Icons.add_circle_outline, color: Colors.blue),
          ),
        ],
        
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: selectedDate != null ? Colors.green : Colors.blue, width: 2),
          ),
          child: InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                children: [
                  const Text('ASIGNAR FECHA AL NUEVO LOTE', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    selectedDate == null 
                        ? 'Toca para seleccionar' 
                        : DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 22, 
                      color: selectedDate == null ? Colors.grey : Colors.green,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comparando Inventario')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Todo al día')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.done_all, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('No hay productos que necesiten fecha.'),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Producto ${_currentIndex + 1} de ${_products.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProductCard(_products[_currentIndex]),
            const SizedBox(height: 40),
            if (_isSaving)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                      child: const Text('Saltar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedDates[_products[_currentIndex].ticketLineId] != null ? _confirmSave : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('GUARDAR LOTE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
