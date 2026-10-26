import 'package:flutter/material.dart';
import '../core/error_utils.dart';
import '../l10n/app_localizations.dart';
import '../services/price_insights_service.dart';
import '../models/price_insights.dart';
import 'product_price_comparison_screen.dart';

class PriceInsightsScreen extends StatefulWidget {
  const PriceInsightsScreen({super.key});

  @override
  State<PriceInsightsScreen> createState() => _PriceInsightsScreenState();
}

class _PriceInsightsScreenState extends State<PriceInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PriceInsightsService _priceInsightsService = PriceInsightsService();
  final TextEditingController _trackedSearchController = TextEditingController();

  int _selectedOverviewDays = 30;
  String _overviewSortBy = 'price_change';
  String _overviewOrder = 'desc';
  String _trackedSortBy = 'last_updated';
  String _trackedOrder = 'desc';
  String _trackedSearch = '';

  late Future<PriceOverviewDto> _overviewFuture;
  late Future<TrackedProductsPageDto> _trackedProductsFuture;

  void _reloadData() {
    setState(() {
      _overviewFuture = _priceInsightsService.getOverview(
        days: _selectedOverviewDays,
        sortBy: _overviewSortBy,
        order: _overviewOrder,
      );
      _trackedProductsFuture = _priceInsightsService.getTrackedProducts(
        search: _trackedSearch,
        sortBy: _trackedSortBy,
        order: _trackedOrder,
      );
    });
  }

  List<DropdownMenuItem<String>> _buildOverviewSortItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(
        value: 'price_change',
        child: Text(l10n.translate('price_insights_sort_price_change')),
      ),
      DropdownMenuItem(
        value: 'samples',
        child: Text(l10n.translate('price_insights_sort_samples')),
      ),
      DropdownMenuItem(
        value: 'supermarket',
        child: Text(l10n.translate('price_insights_sort_supermarket')),
      ),
      DropdownMenuItem(
        value: 'avg_price',
        child: Text(l10n.translate('price_insights_sort_avg_price')),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _buildTrackedSortItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(
        value: 'name',
        child: Text(l10n.translate('price_insights_sort_name')),
      ),
      DropdownMenuItem(
        value: 'last_updated',
        child: Text(l10n.translate('price_insights_sort_last_updated')),
      ),
      DropdownMenuItem(
        value: 'supermarket_count',
        child: Text(l10n.translate('price_insights_sort_supermarket_count')),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _buildOrderItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(
        value: 'asc',
        child: Text(l10n.translate('price_insights_order_asc')),
      ),
      DropdownMenuItem(
        value: 'desc',
        child: Text(l10n.translate('price_insights_order_desc')),
      ),
    ];
  }

  Widget _buildErrorState(Object error) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userFriendlyError(error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _reloadData,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.translate('price_insights_retry')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProductDetail(String productId, String productName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductPriceComparisonScreen(
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reloadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackedSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('price_insights_title')),
        actions: [
          IconButton(
            onPressed: _reloadData,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.translate('price_insights_tab_summary')),
            Tab(text: l10n.translate('price_insights_tab_products')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrackedProductsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<PriceOverviewDto>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        if (!snapshot.hasData) {
          return Center(child: Text(l10n.translate('price_insights_no_data')));
        }

        final overview = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${l10n.translate('price_insights_period')}: '),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selectedOverviewDays,
                          items: [7, 30, 90, 180, 365]
                              .map(
                                (days) => DropdownMenuItem(
                                  value: days,
                                  child: Text(
                                    l10n.translate('price_insights_period_days', params: {'days': days.toString()}),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            _selectedOverviewDays = value;
                            _reloadData();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${l10n.translate('price_insights_sort_by')}: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _overviewSortBy,
                          items: _buildOverviewSortItems(l10n),
                          onChanged: (value) {
                            if (value == null) return;
                            _overviewSortBy = value;
                            _reloadData();
                          },
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _overviewOrder,
                      items: _buildOrderItems(l10n),
                      onChanged: (value) {
                        if (value == null) return;
                        _overviewOrder = value;
                        _reloadData();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMetricsCard(overview),
            const SizedBox(height: 20),
            _buildTopIncreasesSection(overview),
            const SizedBox(height: 20),
            _buildTopDropsSection(overview),
          ],
        );
      },
    );
  }

  Widget _buildMetricsCard(PriceOverviewDto overview) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('price_insights_metrics_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              l10n.translate('price_insights_metrics_period'),
              l10n.translate('price_insights_period_days', params: {'days': overview.days.toString()}),
            ),
            _buildMetricRow(l10n.translate('price_insights_metrics_observations'), '${overview.observations}'),
            _buildMetricRow(l10n.translate('price_insights_metrics_products'), '${overview.productsTracked}'),
            _buildMetricRow(l10n.translate('price_insights_metrics_supermarkets'), '${overview.supermarketsTracked}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIncreasesSection(PriceOverviewDto overview) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('price_insights_top_increases'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            ...overview.topIncreases.map((variation) => _buildVariationRow(variation)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDropsSection(PriceOverviewDto overview) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('price_insights_top_drops'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            ...overview.topDrops.map((variation) => _buildVariationRow(variation)),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationRow(PriceVariationDto variation) {
    return InkWell(
      onTap: () => _openProductDetail(variation.productId, variation.productName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variation.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${variation.previousAvg.toStringAsFixed(2)}€ → ${variation.currentAvg.toStringAsFixed(2)}€',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${variation.variationPct > 0 ? '+' : ''}${variation.variationPct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: variation.variationPct > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackedProductsTab() {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<TrackedProductsPageDto>(
      future: _trackedProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.translate('price_insights_tracked_empty'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final page = snapshot.data!;
        final products = page.items;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _trackedSearchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.translate('price_insights_search_hint'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _trackedSearch.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _trackedSearchController.clear();
                                  _trackedSearch = '';
                                  _reloadData();
                                },
                              ),
                      ),
                      onSubmitted: (value) {
                        _trackedSearch = value.trim();
                        _reloadData();
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${l10n.translate('price_insights_sort_by')}: '),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _trackedSortBy,
                              items: _buildTrackedSortItems(l10n),
                              onChanged: (value) {
                                if (value == null) return;
                                _trackedSortBy = value;
                                _reloadData();
                              },
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: _trackedOrder,
                          items: _buildOrderItems(l10n),
                          onChanged: (value) {
                            if (value == null) return;
                            _trackedOrder = value;
                            _reloadData();
                          },
                        ),
                        Text(
                          '${page.totalCount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...products.map((product) {
              return Card(
                child: ListTile(
                  title: Text(product.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.translate('price_insights_observations_count', params: {'count': product.observations.toString()}),
                      ),
                      Text(
                        l10n.translate('price_insights_supermarkets_count', params: {'count': product.supermarketCount.toString()}),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Text(
                    l10n.translate('price_insights_last_seen', params: {'value': product.lastSeenAt.toString().split('.')[0]}),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.end,
                  ),
                  onTap: () => _openProductDetail(product.productId, product.productName),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

