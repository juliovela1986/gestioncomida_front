import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/grouped_inventory.dart';
import 'product_lots_screen.dart';
import '../l10n/app_localizations.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();
  List<GroupedInventoryResponse> _products = [];
  bool _isLoading = true;
  String _filter = 'all';
  String _locationFilter = 'all';
  String _sortOrder = 'asc';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    print('[InventoryScreen] 🔵 Iniciando carga de inventario agrupado');
    setState(() => _isLoading = true);
    try {
      final products = await _inventoryService.getGroupedInventory();
      print('[InventoryScreen] ✅ Productos cargados: ${products.length}');
      setState(() {
        _products = products;
        final hasSelectedLocation = _locationFilter == 'all' ||
            _availableLocations.any((location) => location == _locationFilter);
        if (!hasSelectedLocation) {
          _locationFilter = 'all';
        }
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

  List<String> get _availableLocations {
    final locations = _products
        .expand((product) => product.lots)
        .map((lot) => lot.locationName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    locations.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return locations;
  }

  List<GroupedInventoryResponse> get _filteredProducts {
    List<GroupedInventoryResponse> filtered;
    
    // Filtrar por tipo
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
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final name = p.productName.toLowerCase();
        final brand = p.productBrand?.toLowerCase() ?? '';
        return name.contains(_searchQuery) || brand.contains(_searchQuery);
      }).toList();
    }

    // Filtrar por ubicación seleccionada
    if (_locationFilter != 'all') {
      filtered = filtered.where((p) {
        return p.lots.any((lot) => lot.locationName == _locationFilter);
      }).toList();
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
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          IconButton(
            icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _sortOrder == 'asc' ? l10n.nearestFirst : l10n.farthestFirst,
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
                    Text(l10n.all),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'with_date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _filter == 'with_date' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    Text(l10n.withDate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'without_date',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: _filter == 'without_date' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    Text(l10n.withoutDate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'expired',
                child: Row(
                  children: [
                    Icon(Icons.error, color: _filter == 'expired' ? Colors.blue : null),
                    const SizedBox(width: 8),
                    Text(l10n.expired),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.location_on),
            tooltip: l10n.selectLocation,
            onSelected: (value) {
              setState(() => _locationFilter = value);
            },
            itemBuilder: (context) {
              final locations = _availableLocations;
              return [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.list, color: _locationFilter == 'all' ? Colors.blue : null),
                      const SizedBox(width: 8),
                      Text(l10n.all),
                    ],
                  ),
                ),
                ...locations.map(
                  (location) => PopupMenuItem(
                    value: location,
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: _locationFilter == location ? Colors.blue : null),
                        const SizedBox(width: 8),
                        Expanded(child: Text(location)),
                      ],
                    ),
                  ),
                ),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty 
                                    ? l10n.noProductsFound
                                    : l10n.noProducts,
                                style: const TextStyle(fontSize: 18, color: Colors.grey),
                              ),
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
                            
                            // Obtener ubicaciones únicas de todos los lotes
                            final locations = product.lots
                                .where((l) => l.locationName != null && l.locationName!.isNotEmpty)
                                .map((l) => l.locationName!)
                                .toSet()
                                .toList();
                            
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
                                    Text(l10n.unitsInLots(product.totalQuantity.toString(), product.lotCount)),
                                    if (locations.isNotEmpty)
                                      Text(
                                        '📍 ${locations.join(", ")}',
                                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                                      ),
                                    if (nextExpDate != null)
                                      Text(
                                        '${l10n.nextExpiration}: $nextExpDate${firstLot?.daysUntilExpiration != null ? " (${firstLot!.daysUntilExpiration! < 0 ? l10n.expiredLabel : l10n.inDays(firstLot.daysUntilExpiration!)})" : ""}',
                                        style: TextStyle(
                                          color: _getExpirationColor(nextExpDate, firstLot?.daysUntilExpiration),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (hasLotsWithoutDate)
                                      Text(l10n.lotsWithoutDate, style: const TextStyle(color: Colors.orange)),
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
                ),
              ],
            ),
    );
  }
}
