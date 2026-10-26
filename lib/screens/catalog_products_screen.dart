import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/catalog_product.dart';
import 'edit_catalog_product_screen.dart';
import 'product_price_comparison_screen.dart';
import '../l10n/app_localizations.dart';

class CatalogProductsScreen extends StatefulWidget {
  const CatalogProductsScreen({super.key});

  @override
  State<CatalogProductsScreen> createState() => _CatalogProductsScreenState();
}

class _CatalogProductsScreenState extends State<CatalogProductsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<CatalogProduct> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/api/catalog-products');
      final List<dynamic> data = response.data;
      setState(() {
        _products = data.map((json) => CatalogProduct.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('error_loading', params: {'error': e.toString()})}')),
        );
      }
    }
  }

  List<CatalogProduct> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    
    return _products.where((p) {
      final name = p.name.toLowerCase();
      final brand = p.brand?.toLowerCase() ?? '';
      final category = p.category?.toLowerCase() ?? '';
      return name.contains(_searchQuery) || 
             brand.contains(_searchQuery) || 
             category.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogProducts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadProducts,
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
                      hintText: l10n.translate('catalog_search_hint'),
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
                              const Icon(Icons.inventory, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? l10n.noProductsFound
                                    : l10n.translate('no_catalog_products'),
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
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    product.name[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product.brand != null)
                                      Text('${l10n.translate('brand')}: ${product.brand}'),
                                    if (product.category != null)
                                      Text('${l10n.translate('category')}: ${product.category}'),
                                    if (product.isPerishable)
                                      Text(
                                        l10n.translate('perishable_with_days', params: {'days': product.shelfLifeDays.toString()}),
                                        style: const TextStyle(color: Colors.orange),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditCatalogProductScreen(product: product),
                                        ),
                                      );
                                      _loadProducts();
                                    } else if (value == 'prices') {
                                      if (mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductPriceComparisonScreen(
                                              productId: product.id,
                                              productName: product.name,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 18),
                                          const SizedBox(width: 8),
                                          Text(l10n.translate('edit', params: {})),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'prices',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.trending_up, size: 18),
                                          const SizedBox(width: 8),
                                          Text(l10n.viewPrices),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditCatalogProductScreen(product: product),
                                    ),
                                  );
                                  _loadProducts();
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
