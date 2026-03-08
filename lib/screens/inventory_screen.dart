import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/grouped_inventory.dart';
import 'product_lots_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<GroupedInventoryResponse> _products = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'with_date', 'without_date', 'expired'
  String _sortOrder = 'asc'; // 'asc' = más próximo primero, 'desc' = más lejano primero

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    print('[InventoryScreen] 🔵 Iniciando carga de inventario agrupado');
    setState(() => _isLoading = true);
    try {
      final products = await _inventoryService.getGroupedInventory();
      print('[InventoryScreen] ✅ Productos cargados: ${products.length}');
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('[InventoryScreen] ❌ Error al cargar: $e');
      print('[InventoryScreen] 📍 StackTrace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<GroupedInventoryResponse> get _filteredProducts {
    final now = DateTime.now();
    
    List<GroupedInventoryResponse> filtered;
    switch (_filter) {
      case 'with_date':
        filtered = _products.where((p) => p.lots.any((l) => l.expirationDate != null)).toList();
        break;
      
      case 'without_date':
        filtered = _products.where((p) => p.lots.any((l) => l.expirationDate == null)).toList();
        break;
      
      case 'expired':
        filtered = _products.where((p) => p.lots.any((l) => 
          l.daysUntilExpiration != null && l.daysUntilExpiration! < 0
        )).toList();
        break;
      
      case 'all':
      default:
        filtered = _products;
    }
    
    // Ordenar por fecha de caducidad
    filtered.sort((a, b) {
      final dateA = a.nextExpirationDate != null ? DateTime.tryParse(a.nextExpirationDate!) : null;
      final dateB = b.nextExpirationDate != null ? DateTime.tryParse(b.nextExpirationDate!) : null;
      
      // Sin fecha van al final
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      
      return _sortOrder == 'asc' ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
    
    return filtered;
  }

  Color _getExpirationColor(String? expirationDate, int? daysUntil) {
    if (expirationDate == null) return Colors.grey;
    if (daysUntil == null) return Colors.grey;
    if (daysUntil < 0) return Colors.red;
    if (daysUntil <= 3) return Colors.orange;
    return Colors.green;
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, color: _filter == 'all' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    const Text('Todos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'with_date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _filter == 'with_date' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    const Text('Con fecha'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'without_date',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: _filter == 'without_date' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    const Text('Sin fecha'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'expired',
                child: Row(
                  children: [
                    Icon(Icons.error, color: _filter == 'expired' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    const Text('Caducados'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay productos', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final hasLotsWithoutDate = product.lots.any((l) => l.expirationDate == null);
                    final nextExpDate = product.nextExpirationDate;
                    final firstLot = product.lots.isNotEmpty ? product.lots.first : null;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getExpirationColor(nextExpDate, firstLot?.daysUntilExpiration),
                          child: Text(
                            '${product.lotCount}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          product.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.productBrand != null)
                              Text('${product.productBrand}'),
                            Text('Total: ${product.totalQuantity} uds en ${product.lotCount} lote(s)'),
                            if (nextExpDate != null)
                              Text(
                                'Próximo: $nextExpDate${firstLot?.daysUntilExpiration != null ? " (${firstLot!.daysUntilExpiration! < 0 ? "caducado" : "en ${firstLot.daysUntilExpiration} días"})" : ""}',
                                style: TextStyle(
                                  color: _getExpirationColor(nextExpDate, firstLot?.daysUntilExpiration),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (hasLotsWithoutDate)
                              const Text('⚠️ Tiene lotes sin fecha', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductLotsScreen(product: product),
                            ),
                          );
                          _loadInventory();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
