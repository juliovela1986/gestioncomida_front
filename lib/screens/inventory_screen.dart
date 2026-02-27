import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/inventory_item.dart';
import 'edit_inventory_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItemResponseDto> _items = [];
  bool _isLoading = true;
  String? _selectedLocation;
  String _sortOrder = 'asc'; // 'asc' o 'desc'

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      final items = await _inventoryService.getUserInventory();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar inventario: $e')),
        );
      }
    }
  }

  List<InventoryItemResponseDto> get _filteredItems {
    var filtered = _selectedLocation == null 
        ? _items 
        : _items.where((item) => item.locationId == _selectedLocation).toList();
    
    // Ordenar por fecha de caducidad
    filtered.sort((a, b) {
      final dateA = a.expirationDate != null ? DateTime.tryParse(a.expirationDate!) : null;
      final dateB = b.expirationDate != null ? DateTime.tryParse(b.expirationDate!) : null;
      
      // Productos sin fecha van al final
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      
      return _sortOrder == 'asc' 
          ? dateA.compareTo(dateB) 
          : dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
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

  IconData _getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'DISPONIBLE':
        return Icons.check_circle;
      case 'PROXIMO_CADUCAR':
        return Icons.warning;
      case 'CADUCADO':
        return Icons.error;
      case 'ABIERTO':
        return Icons.lock_open;
      default:
        return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortOrder == 'asc' ? 'Más próximo primero' : 'Más lejano primero',
            onPressed: () {
              setState(() {
                _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedLocation,
                    hint: const Text('Todas las ubicaciones'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ..._items
                          .map((e) => e.locationId)
                          .toSet()
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc ?? 'Sin ubicación'),
                              )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedLocation = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Lista de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay productos en el inventario',
                                style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(item.status),
                                child: Icon(
                                  _getStatusIcon(item.status),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                item.productName ?? 'Sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.productBrand != null)
                                    Text('Marca: ${item.productBrand}'),
                                  Text('Cantidad: ${item.quantity ?? "N/A"}'),
                                  if (item.expirationDate != null)
                                    Text('Caduca: ${item.expirationDate}'),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditInventoryItemScreen(item: item),
                                  ),
                                );
                                if (result == true) {
                                  _loadInventory();
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
