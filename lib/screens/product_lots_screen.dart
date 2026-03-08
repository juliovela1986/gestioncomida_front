import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grouped_inventory.dart';
import '../services/inventory_service.dart';

class ProductLotsScreen extends StatefulWidget {
  final GroupedInventoryResponse product;

  const ProductLotsScreen({super.key, required this.product});

  @override
  State<ProductLotsScreen> createState() => _ProductLotsScreenState();
}

class _ProductLotsScreenState extends State<ProductLotsScreen> {
  final InventoryService _inventoryService = InventoryService();

  Color _getLotColor(LotDetail lot) {
    if (lot.expirationDate == null) return Colors.grey;
    if (lot.daysUntilExpiration == null) return Colors.grey;
    if (lot.daysUntilExpiration! < 0) return Colors.red;
    if (lot.daysUntilExpiration! <= 3) return Colors.orange;
    return Colors.green;
  }

  IconData _getLotIcon(LotDetail lot) {
    if (lot.expirationDate == null) return Icons.help_outline;
    if (lot.daysUntilExpiration == null) return Icons.help_outline;
    if (lot.daysUntilExpiration! < 0) return Icons.error;
    if (lot.daysUntilExpiration! <= 3) return Icons.warning;
    return Icons.check_circle;
  }

  Future<void> _deleteLot(LotDetail lot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lote'),
        content: Text(
          '¿Eliminar este lote?\n\n'
          'Cantidad: ${lot.quantity} uds\n'
          '${lot.expirationDate != null ? "Caduca: ${lot.expirationDate}" : "Sin fecha de caducidad"}',
        ),
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
        await _inventoryService.deleteItem(lot.inventoryItemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Lote eliminado')),
          );
          Navigator.pop(context);
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

  Future<void> _editExpirationDate(LotDetail lot) async {
    final currentDate = lot.expirationDate != null 
        ? DateTime.tryParse(lot.expirationDate!) 
        : DateTime.now().add(const Duration(days: 7));

    final newDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1000)),
    );

    if (newDate != null) {
      try {
        await _inventoryService.updateItem(lot.inventoryItemId, {
          'expirationDate': DateFormat('yyyy-MM-dd').format(newDate),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Fecha actualizada')),
          );
          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.productName),
      ),
      body: Column(
        children: [
          // Resumen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.productName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (widget.product.productBrand != null)
                  Text(widget.product.productBrand!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Total: ${widget.product.totalQuantity} unidades',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${widget.product.lotCount} lote(s)'),
              ],
            ),
          ),
          // Lista de lotes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.product.lots.length,
              itemBuilder: (context, index) {
                final lot = widget.product.lots[index];
                return Card(
                  color: _getLotColor(lot).withOpacity(0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getLotColor(lot),
                      child: Icon(_getLotIcon(lot), color: Colors.white),
                    ),
                    title: Text(
                      '${lot.quantity} unidades',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lot.expirationDate != null) ...[
                          Text('Caduca: ${lot.expirationDate}'),
                          if (lot.daysUntilExpiration != null)
                            Text(
                              lot.daysUntilExpiration! < 0
                                  ? 'Caducado hace ${-lot.daysUntilExpiration!} días'
                                  : 'En ${lot.daysUntilExpiration} días',
                              style: TextStyle(
                                color: _getLotColor(lot),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ] else
                          const Text('⚠️ Sin fecha de caducidad', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Editar fecha'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Eliminar lote', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editExpirationDate(lot);
                        } else if (value == 'delete') {
                          _deleteLot(lot);
                        }
                      },
                    ),
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
