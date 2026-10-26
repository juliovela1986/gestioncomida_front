import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final InventoryService _inventoryService = InventoryService();
  bool _isLoading = true;
  
  int _totalProducts = 0;
  int _totalLots = 0;
  double _totalQuantity = 0;
  int _expiredCount = 0;
  int _expiringIn3Days = 0;
  int _withoutDateCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final products = await _inventoryService.getGroupedInventory();
      
      int totalProducts = products.length;
      int totalLots = 0;
      double totalQuantity = 0;
      int expired = 0;
      int expiring = 0;
      int withoutDate = 0;

      for (var product in products) {
        totalLots += product.lotCount;
        totalQuantity += product.totalQuantity;
        
        for (var lot in product.lots) {
          if (lot.expirationDate == null) {
            withoutDate++;
          } else if (lot.daysUntilExpiration != null) {
            if (lot.daysUntilExpiration! < 0) {
              expired++;
            } else if (lot.daysUntilExpiration! <= 3) {
              expiring++;
            }
          }
        }
      }

      setState(() {
        _totalProducts = totalProducts;
        _totalLots = totalLots;
        _totalQuantity = totalQuantity;
        _expiredCount = expired;
        _expiringIn3Days = expiring;
        _withoutDateCount = withoutDate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('error_loading', params: {'error': e.toString()}))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statistics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatCard(
                    l10n.translate('total_products'),
                    _totalProducts.toString(),
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    l10n.translate('total_lots'),
                    _totalLots.toString(),
                    Icons.layers,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    l10n.translate('total_quantity'),
                    '${_totalQuantity.toStringAsFixed(0)} ${l10n.translate('units_abbr')}',
                    Icons.shopping_basket,
                    Colors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.translate('expiration_status'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    l10n.expired,
                    _expiredCount.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    l10n.translate('expiring_soon_desc'),
                    _expiringIn3Days.toString(),
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    l10n.withoutDate,
                    _withoutDateCount.toString(),
                    Icons.help_outline,
                    Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  _buildProgressSection(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(AppLocalizations l10n) {
    final total = _totalLots;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('status_distribution'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildProgressBar(l10n.expired, _expiredCount, total, Colors.red),
            const SizedBox(height: 8),
            _buildProgressBar(l10n.translate('expiring_soon'), _expiringIn3Days, total, Colors.orange),
            const SizedBox(height: 8),
            _buildProgressBar(l10n.translate('good_condition'), total - _expiredCount - _expiringIn3Days - _withoutDateCount, total, Colors.green),
            const SizedBox(height: 8),
            _buildProgressBar(l10n.withoutDate, _withoutDateCount, total, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percent = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value (${(percent * 100).toStringAsFixed(1)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }
}
