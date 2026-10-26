import 'package:flutter/material.dart';
import '../core/error_utils.dart';
import '../l10n/app_localizations.dart';
import '../services/price_insights_service.dart';
import '../models/price_insights.dart';

class ProductPriceComparisonScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductPriceComparisonScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductPriceComparisonScreen> createState() =>
      _ProductPriceComparisonScreenState();
}

class _ProductPriceComparisonScreenState
    extends State<ProductPriceComparisonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PriceInsightsService _priceInsightsService = PriceInsightsService();

  int _selectedDays = 90;
  String _comparisonSortBy = 'price';
  String _comparisonOrder = 'asc';
  String _trendSortBy = 'date';
  String _trendOrder = 'desc';
  String? _selectedSupermarket;
  List<String> _availableSupermarkets = const [];
  late Future<SupermarketComparisonDto> _comparisonFuture;
  late Future<ProductPriceTrendDto> _trendFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _comparisonFuture = _priceInsightsService.compareSupermarkets(
      productId: widget.productId,
      days: _selectedDays,
      sortBy: _comparisonSortBy,
      order: _comparisonOrder,
    );
    _comparisonFuture.then((comparison) {
      if (!mounted) return;
      setState(() {
        _availableSupermarkets = comparison.supermarkets
            .map((supermarket) => supermarket.supermarket)
            .toList();
      });
    });

    _trendFuture = _priceInsightsService.getProductTrend(
      productId: widget.productId,
      days: _selectedDays,
      supermarket: _selectedSupermarket,
      sortBy: _trendSortBy,
      order: _trendOrder,
    );
  }

  List<DropdownMenuItem<String>> _buildComparisonSortItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(
        value: 'price',
        child: Text(l10n.translate('price_insights_sort_price')),
      ),
      DropdownMenuItem(
        value: 'avg_price',
        child: Text(l10n.translate('price_insights_sort_avg_price')),
      ),
      DropdownMenuItem(
        value: 'samples',
        child: Text(l10n.translate('price_insights_sort_samples')),
      ),
      DropdownMenuItem(
        value: 'supermarket',
        child: Text(l10n.translate('price_insights_sort_supermarket')),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _buildTrendSortItems(AppLocalizations l10n) {
    return [
      DropdownMenuItem(
        value: 'date',
        child: Text(l10n.translate('price_insights_sort_date')),
      ),
      DropdownMenuItem(
        value: 'price',
        child: Text(l10n.translate('price_insights_sort_price')),
      ),
      DropdownMenuItem(
        value: 'avg_price',
        child: Text(l10n.translate('price_insights_sort_avg_price')),
      ),
      DropdownMenuItem(
        value: 'samples',
        child: Text(l10n.translate('price_insights_sort_samples')),
      ),
      DropdownMenuItem(
        value: 'supermarket',
        child: Text(l10n.translate('price_insights_sort_supermarket')),
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

  void _retryLoad() {
    setState(_loadData);
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
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.translate('price_insights_retry')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.translate('price_insights_comparison_tab')),
            Tab(text: l10n.translate('price_insights_trend_tab')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector de período
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('${l10n.translate('price_insights_period')}: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedDays,
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
                    if (value != null) {
                      setState(() {
                        _selectedDays = value;
                        _loadData();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComparisonTab(),
                _buildTrendTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<SupermarketComparisonDto>(
      future: _comparisonFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        if (!snapshot.hasData || snapshot.data!.supermarkets.isEmpty) {
          return Center(child: Text(l10n.translate('price_insights_comparison_empty')));
        }

        final comparison = snapshot.data!;

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
                        Text('${l10n.translate('price_insights_sort_by')}: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _comparisonSortBy,
                          items: _buildComparisonSortItems(l10n),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _comparisonSortBy = value;
                              _loadData();
                            });
                          },
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _comparisonOrder,
                      items: _buildOrderItems(l10n),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _comparisonOrder = value;
                          _loadData();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('price_insights_price_by_supermarket'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...comparison.supermarkets.mapIndexed((index, supermarket) {
              final isCheapest = supermarket.deltaVsCheapestPct == 0;
              return Card(
                color: isCheapest ? Colors.green.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            supermarket.supermarket,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCheapest)
                            Chip(
                              label: Text(l10n.translate('price_insights_cheapest')),
                              backgroundColor: Colors.green,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${supermarket.displayUnitPrice.toStringAsFixed(2)}€',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (supermarket.lastUnitPrice != null &&
                                  (supermarket.lastUnitPrice! - supermarket.avgUnitPrice).abs() > 0.001)
                                Text(
                                  l10n.translate(
                                    'price_insights_period_avg',
                                    params: {'value': supermarket.avgUnitPrice.toStringAsFixed(2)},
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              Text(
                                l10n.translate('price_insights_samples', params: {'count': supermarket.samples.toString()}),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (!isCheapest)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${supermarket.deltaVsCheapestAmount.toStringAsFixed(2)}€',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '+${supermarket.deltaVsCheapestPct.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildTrendTab() {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<ProductPriceTrendDto>(
      future: _trendFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }

        if (!snapshot.hasData || snapshot.data!.points.isEmpty) {
          return Center(child: Text(l10n.translate('price_insights_trend_empty')));
        }

        final trend = snapshot.data!;
        final chartPoints = [...trend.points]
          ..sort((a, b) => a.day.compareTo(b.day));

        // Calcular min y max para el gráfico
        final prices = chartPoints.map((p) => p.avgUnitPrice).toList();
        final minPrice = prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.reduce((a, b) => a > b ? a : b);

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
                        Text('${l10n.translate('price_insights_filter_supermarket')}: '),
                        const SizedBox(width: 8),
                        DropdownButton<String?>(
                          value: _selectedSupermarket,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.translate('price_insights_filter_all')),
                            ),
                            ..._availableSupermarkets.map(
                              (supermarket) => DropdownMenuItem<String?>(
                                value: supermarket,
                                child: Text(supermarket),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSupermarket = value;
                              _loadData();
                            });
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
                          value: _trendSortBy,
                          items: _buildTrendSortItems(l10n),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _trendSortBy = value;
                              _loadData();
                            });
                          },
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _trendOrder,
                      items: _buildOrderItems(l10n),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _trendOrder = value;
                          _loadData();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('price_insights_price_evolution'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Gráfico simple de línea
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TrendChartPainter(
                        points: chartPoints,
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.translate('price_insights_price_detail'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...trend.points.map((point) {
              return ListTile(
                title: Text(point.day),
                subtitle: Text(
                  l10n.translate('price_insights_samples', params: {'count': point.samples.toString()}),
                ),
                trailing: Text(
                  '${point.avgUnitPrice.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// Extensión para mapIndexed
extension MapIndexed<T> on List<T> {
  Iterable<E> mapIndexed<E>(E Function(int, T) f) {
    return asMap().entries.map((e) => f(e.key, e.value));
  }
}

class TrendChartPainter extends CustomPainter {
  final List<PriceTrendPointDto> points;
  final double minPrice;
  final double maxPrice;

  TrendChartPainter({
    required this.points,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final priceRange = (maxPrice - minPrice).abs() < 0.000001 ? 1.0 : maxPrice - minPrice;
    final spacing = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    Path path = Path();

    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * spacing;
      final y = size.height -
          ((points[i].avgUnitPrice - minPrice) / priceRange) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Dibuja puntos
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : i * spacing;
      final y = size.height -
          ((points[i].avgUnitPrice - minPrice) / priceRange) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(TrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

