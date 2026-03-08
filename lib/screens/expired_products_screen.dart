import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/inventory_item.dart';

class ExpiredProductsScreen extends StatefulWidget {
  const ExpiredProductsScreen({super.key});

  @override
  State<ExpiredProductsScreen> createState() => _ExpiredProductsScreenState();
}

class _ExpiredProductsScreenState extends State<ExpiredProductsScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItemResponseDto> _expiredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpiredItems();
  }

  Future<void> _loadExpiredItems() async {
    setState(() => _isLoading = true);
    try {
      final allItems = await _inventoryService.getUserInventory();
      final now = DateTime.now();
      
      setState(() {
        _expiredItems = allItems.where((item) {
          if (item.expirationDate == null) return false;
          final expDate = DateTime.tryParse(item.expirationDate!);
          return expDate != null && expDate.isBefore(now);
        }).toList();
        
        _expiredItems.sort((a, b) {
          final dateA = DateTime.parse(a.expirationDate!);
          final dateB = DateTime.parse(b.expirationDate!);
          return dateA.compareTo(dateB);
        });
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(InventoryItemResponseDto item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${item.productName}" del inventario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _inventoryService.deleteItem(item.id);
        _loadExpiredItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e')),
          );
        }
      }
    }
  }

  String _getDaysExpired(String expirationDate) {
    final expDate = DateTime.parse(expirationDate);
    final now = DateTime.now();
    final days = now.difference(expDate).inDays;
    return days == 0 ? 'Hoy' : 'Hace $days día${days != 1 ? "s" : ""}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos Caducados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpiredItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expiredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        '¡No hay productos caducados!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _expiredItems.length,
                  itemBuilder: (context, index) {
                    final item = _expiredItems[index];
                    return Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.error, color: Colors.white),
                        ),
                        title: Text(
                          item.productName ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cantidad: ${item.quantity ?? "N/A"}'),
                            Text(
                              'Caducó: ${_getDaysExpired(item.expirationDate!)}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            Text('Fecha: ${item.expirationDate}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
