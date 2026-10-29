import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/error_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/catalog_product.dart';
import '../models/shopping_list_comparison.dart';
import '../models/shopping_list_item.dart';
import '../services/catalog_product_service.dart';
import '../services/shopping_list_service.dart';

typedef ShoppingListPageLoader = Future<ShoppingListPageDto> Function({
  required int page,
  required int size,
});
typedef ShoppingListItemCreator = Future<ShoppingListItemDto> Function(
  ShoppingListItemRequestDto request,
);
typedef ShoppingListItemDeleter = Future<void> Function(String itemId);
typedef ShoppingListCompareBatchExecutor = Future<ShoppingListComparisonResponseDto>
    Function(CompareBatchRequestDto request);
typedef CatalogProductNameSearcher = Future<List<CatalogProductResponseDto>> Function(
  String query,
);

class ShoppingListScreen extends StatefulWidget {
  final ShoppingListPageLoader? loadPage;
  final ShoppingListItemCreator? createItem;
  final ShoppingListItemDeleter? deleteItem;
  final ShoppingListCompareBatchExecutor? compareBatch;
  /// Override búsqueda catálogo (tests / inyección). Por defecto API `search/by-name`.
  final CatalogProductNameSearcher? searchCatalogByName;
  final Duration pollInterval;
  final Duration pollTimeout;
  final int pageSize;
  /// Deep link desde FCM COMPARE_READY / bandeja: refresca comparativa al abrir.
  final bool openCompareResults;

  const ShoppingListScreen({
    super.key,
    this.loadPage,
    this.createItem,
    this.deleteItem,
    this.compareBatch,
    this.searchCatalogByName,
    this.pollInterval = const Duration(seconds: 3),
    this.pollTimeout = const Duration(seconds: 90),
    this.pageSize = ShoppingListService.defaultPageSize,
    this.openCompareResults = false,
  });

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  ShoppingListService? _service;
  final Set<String> _checkedIds = <String>{};
  final Set<String> _expandedItemIds = <String>{};
  final Map<String, ShoppingListItemComparisonDetailDto> _detailByItemId = {};
  final AccumulatedRanking _accumulatedRanking = AccumulatedRanking();

  List<ShoppingListItemDto> _items = [];
  int _page = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  bool _isLoading = true;
  bool _isComparing = false;
  bool _rankingConclusive = true;
  String? _rankingPartialReason;
  /// Ranking expandido: por defecto sí si concluyente, no si cobertura parcial.
  bool _rankingExpanded = false;
  bool _rankingExpandInitialized = false;
  String? _errorMessage;
  String? _compareStatusMessage;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  List<String> _activeCompareIds = const [];
  bool _autoCompareRequested = false;

  ShoppingListService get _resolvedService =>
      _service ??= ShoppingListService();

  @override
  void initState() {
    super.initState();
    _autoCompareRequested = widget.openCompareResults;
    _loadPage(0);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<ShoppingListPageDto> _fetchPage(int page) {
    if (widget.loadPage != null) {
      return widget.loadPage!(page: page, size: widget.pageSize);
    }
    return _resolvedService.getShoppingList(page: page, size: widget.pageSize);
  }

  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _fetchPage(page);
      if (!mounted) return;
      setState(() {
        _items = result.content;
        _page = result.number;
        _totalPages = result.totalPages < 1 ? 1 : result.totalPages;
        _totalElements = result.totalElements;
        _checkedIds.removeWhere((id) => !_items.any((item) => item.id == id));
        _isLoading = false;
      });
      if (_autoCompareRequested && _items.isNotEmpty) {
        _autoCompareRequested = false;
        // forceRefresh=false: solo pintar precios ya listos tras scrape (SCRUM-118).
        unawaited(_compareCurrentPage(forceRefresh: false));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = userFriendlyError(e);
        _isLoading = false;
      });
    }
  }

  Future<List<CatalogProductResponseDto>> _searchCatalog(String query) {
    if (widget.searchCatalogByName != null) {
      return widget.searchCatalogByName!(query);
    }
    return CatalogProductService().searchByName(query);
  }

  Future<void> _addCustomItem() async {
    final result = await showDialog<_AddShoppingListItemResult>(
      context: context,
      builder: (context) => _AddShoppingListItemDialog(
        searchCatalog: _searchCatalog,
      ),
    );

    if (result == null || result.name.isEmpty) return;

    final request = ShoppingListItemRequestDto(
      name: result.name,
      quantity: result.quantity,
      unit: result.unit,
      catalogProductId: result.catalogProductId,
    );

    try {
      if (widget.createItem != null) {
        await widget.createItem!(request);
      } else {
        await _resolvedService.addItem(request);
      }
      if (!mounted) return;
      await _loadPage(_page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyError(e))),
      );
    }
  }

  Future<void> _deleteItem(ShoppingListItemDto item) async {
    try {
      if (widget.deleteItem != null) {
        await widget.deleteItem!(item.id);
      } else {
        await _resolvedService.deleteItem(item.id);
      }
      _detailByItemId.remove(item.id);
      if (!mounted) return;
      await _loadPage(_page);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyError(e))),
      );
    }
  }

  void _shareList() {
    final l10n = AppLocalizations.of(context);
    final unchecked = _items.where((item) => !_checkedIds.contains(item.id)).toList();
    if (unchecked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('no_items_in_list'))),
      );
      return;
    }

    final text = unchecked.map((item) {
      final unit = item.unit != null ? ' ${item.unit}' : '';
      return '• ${item.name} - ${item.quantity}$unit';
    }).join('\n');

    Clipboard.setData(
      ClipboardData(text: '${l10n.translate('shopping_list_share_title')}:\n\n$text'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.translate('list_copied'))),
    );
  }

  String _batchKey(List<String> itemIds) {
    final sorted = List<String>.from(itemIds)..sort();
    return sorted.join('|');
  }

  Future<void> _compareCurrentPage({bool forceRefresh = false}) async {
    final l10n = AppLocalizations.of(context);
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('compare_no_items'))),
      );
      return;
    }

    final itemIds = _items.map((e) => e.id).take(ShoppingListService.maxBatchSize).toList();
    _pollTimer?.cancel();
    setState(() {
      _isComparing = true;
      _activeCompareIds = itemIds;
      _pollStartedAt = DateTime.now();
      _compareStatusMessage = l10n.translate('compare_starting');
      // Nueva comparativa: reaplicar default expand (parcial → plegado).
      _rankingExpandInitialized = false;
    });

    await _runComparePoll(forceRefresh: forceRefresh);
  }

  Future<void> _runComparePoll({required bool forceRefresh}) async {
    final l10n = AppLocalizations.of(context);
    final itemIds = _activeCompareIds;
    if (itemIds.isEmpty) return;

    try {
      final request = CompareBatchRequestDto(
        itemIds: itemIds,
        freshnessDays: ShoppingListService.defaultFreshnessDays,
        forceRefresh: forceRefresh,
      );
      final response = widget.compareBatch != null
          ? await widget.compareBatch!(request)
          : await _resolvedService.compareBatch(request);

      if (!mounted) return;

      for (final detail in response.detail) {
        final id = detail.itemId;
        if (id != null && id.isNotEmpty) {
          _detailByItemId[id] = detail;
        }
      }
      _accumulatedRanking.upsertBatch(_batchKey(itemIds), response.ranking);

      final pending = response.pendingCount;
      final ready = response.readyCount;
      final unavailable = response.unavailableCount;
      final processed = response.processedCount == 0
          ? response.detail.length
          : response.processedCount;

      setState(() {
        _rankingConclusive = response.rankingConclusive ?? true;
        _rankingPartialReason = response.rankingPartialReason;
        if (!_rankingExpandInitialized && response.ranking.isNotEmpty) {
          // Híbrido: cobertura parcial → ranking plegado (productos visibles).
          _rankingExpanded = _rankingConclusive;
          _rankingExpandInitialized = true;
        }
        if (pending > 0 && ready > 0) {
          _compareStatusMessage = l10n.translate('compare_partial_updating');
        } else {
          _compareStatusMessage = l10n.translate(
            'compare_progress',
            params: {
              'ready': ready.toString(),
              'pending': pending.toString(),
              'unavailable': unavailable.toString(),
              'total': processed.toString(),
            },
          );
        }
      });

      final timedOut = _pollStartedAt != null &&
          DateTime.now().difference(_pollStartedAt!) >= widget.pollTimeout;

      if (response.hasPending && !timedOut) {
        _pollTimer?.cancel();
        _pollTimer = Timer(widget.pollInterval, () {
          if (!mounted) return;
          // Poll sin forceRefresh para no re-encolar scrapes.
          _runComparePoll(forceRefresh: false);
        });
        return;
      }

      _pollTimer?.cancel();
      setState(() {
        _isComparing = false;
        if (timedOut && response.hasPending) {
          _compareStatusMessage = l10n.translate('compare_timeout');
        } else if (unavailable > 0) {
          _compareStatusMessage = l10n.translate(
            'compare_done_with_unavailable',
            params: {'count': unavailable.toString()},
          );
        } else {
          _compareStatusMessage = l10n.translate('compare_done');
        }
      });
    } catch (e) {
      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _isComparing = false;
        _compareStatusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyError(e))),
      );
    }
  }

  String _statusLabel(
    AppLocalizations l10n,
    ShoppingListItemComparisonDetailDto? detail,
  ) {
    if (detail == null) return '';
    switch (detail.status) {
      case CompareItemStatus.ready:
        final msg = (detail.message ?? '').toLowerCase();
        if (msg.contains('parcial')) {
          return l10n.translate('compare_status_ready_partial');
        }
        return l10n.translate('compare_status_ready');
      case CompareItemStatus.pending:
        if (detail.prices.isNotEmpty) {
          return l10n.translate('compare_status_pending_with_prices');
        }
        return l10n.translate('compare_status_pending');
      case CompareItemStatus.unavailable:
        if (detail.isCarrefourUnavailable) {
          return l10n.translate('compare_carrefour_unavailable');
        }
        return detail.message?.isNotEmpty == true
            ? detail.message!
            : l10n.translate('compare_status_unavailable');
      case CompareItemStatus.unknown:
        return detail.message ?? '';
    }
  }

  Color _statusColor(CompareItemStatus? status) {
    switch (status) {
      case CompareItemStatus.ready:
        return Colors.green.shade700;
      case CompareItemStatus.pending:
        return Colors.orange.shade800;
      case CompareItemStatus.unavailable:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// Ordena ranking: concluyente → precio; parcial → cobertura (evita crownear 1/5).
  List<SupermarketRankingDto> _sortedRanking(List<SupermarketRankingDto> ranking) {
    final list = List<SupermarketRankingDto>.from(ranking);
    if (_rankingConclusive) {
      list.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    } else {
      list.sort((a, b) {
        final ca = a.total == 0 ? 0.0 : a.resolved / a.total;
        final cb = b.total == 0 ? 0.0 : b.resolved / b.total;
        final byCoverage = cb.compareTo(ca);
        if (byCoverage != 0) return byCoverage;
        return a.totalPrice.compareTo(b.totalPrice);
      });
    }
    return list;
  }

  List<String> _knownSupermarkets() {
    final names = <String>{};
    for (final row in _accumulatedRanking.build()) {
      if (row.supermarket.isNotEmpty) names.add(row.supermarket);
    }
    for (final detail in _detailByItemId.values) {
      for (final price in detail.prices) {
        if (price.supermarket.isNotEmpty) names.add(price.supermarket);
      }
    }
    final list = names.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<ShoppingListPriceDto> _sortedPrices(List<ShoppingListPriceDto> prices) {
    return List<ShoppingListPriceDto>.from(prices)
      ..sort((a, b) => a.displayUnitPrice.compareTo(b.displayUnitPrice));
  }

  Widget _rankingRow(
    AppLocalizations l10n, {
    required int index,
    required SupermarketRankingDto row,
    required bool conclusive,
  }) {
    final isWinner = conclusive && index == 0;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: isWinner ? Colors.green.shade100 : Colors.grey.shade200,
        child: Text(
          conclusive ? '${index + 1}' : '·',
          style: TextStyle(
            color: isWinner ? Colors.green.shade800 : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(row.supermarket),
      subtitle: Text(
        l10n.translate(
          'compare_ranking_coverage',
          params: {
            'resolved': row.resolved.toString(),
            'total': row.total.toString(),
          },
        ),
      ),
      trailing: Text(
        '${row.totalPrice.toStringAsFixed(2)} €',
        style: TextStyle(
          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
          color: isWinner ? Colors.green.shade700 : null,
        ),
      ),
    );
  }

  Widget _buildRanking(AppLocalizations l10n) {
    final ranking = _sortedRanking(_accumulatedRanking.build());
    if (ranking.isEmpty) return const SizedBox.shrink();

    final conclusive = _rankingConclusive;
    final title = conclusive
        ? l10n.translate('compare_ranking_title')
        : l10n.translate('compare_ranking_inconclusive_title');
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.4;
    final previewCount = ranking.length < 2 ? ranking.length : 2;
    final preview = ranking.take(previewCount).toList();

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => setState(() => _rankingExpanded = !_rankingExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (!conclusive) ...[
                            const SizedBox(height: 4),
                            Text(
                              _rankingPartialReason?.isNotEmpty == true
                                  ? _rankingPartialReason!
                                  : l10n.translate('compare_ranking_partial'),
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (!_rankingExpanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.translate(
                                'compare_ranking_summary',
                                params: {'count': ranking.length.toString()},
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _rankingExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
            ),
            if (!_rankingExpanded) ...[
              const SizedBox(height: 4),
              ...preview.asMap().entries.map(
                    (e) => _rankingRow(
                      l10n,
                      index: e.key,
                      row: e.value,
                      conclusive: conclusive,
                    ),
                  ),
              if (ranking.length > previewCount)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _rankingExpanded = true),
                    child: Text(l10n.translate('compare_ranking_expand')),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: ranking.length,
                  itemBuilder: (context, index) {
                    return _rankingRow(
                      l10n,
                      index: index,
                      row: ranking[index],
                      conclusive: conclusive,
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _rankingExpanded = false),
                  child: Text(l10n.translate('compare_ranking_collapse')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemPriceRows(
    AppLocalizations l10n,
    ShoppingListItemComparisonDetailDto detail,
  ) {
    final bySuper = <String, ShoppingListPriceDto>{
      for (final p in detail.prices) p.supermarket: p,
    };
    final orderedFound = _sortedPrices(detail.prices);
    final missing = _knownSupermarkets()
        .where((name) => !bySuper.containsKey(name))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            l10n.translate('compare_item_prices_hint'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ...orderedFound.asMap().entries.map((entry) {
          final i = entry.key;
          final price = entry.value;
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(price.supermarket),
            trailing: Text(
              '${price.displayUnitPrice.toStringAsFixed(2)} €',
              style: TextStyle(
                fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                color: i == 0 ? Colors.green.shade700 : null,
              ),
            ),
          );
        }),
        ...missing.map(
          (name) => ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: Text(name, style: TextStyle(color: Colors.grey.shade600)),
            trailing: Text(
              l10n.translate('compare_no_price'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.translate(
              'shopping_page_info',
              params: {
                'page': (_page + 1).toString(),
                'totalPages': _totalPages.toString(),
                'total': _totalElements.toString(),
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: !_isLoading && _page > 0 ? () => _loadPage(_page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: !_isLoading && _page + 1 < _totalPages
                    ? () => _loadPage(_page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uncheckedCount =
        _items.where((item) => !_checkedIds.contains(item.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingList),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _items.isEmpty ? null : _shareList,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _loadPage(_page),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _loadPage(_page),
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.refresh),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (_items.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${l10n.translate('pending_products')}: $uncheckedCount',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_checkedIds.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _checkedIds.clear());
                                    },
                                    child: Text(l10n.translate('clear_checked')),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isComparing
                                        ? null
                                        : () => _compareCurrentPage(),
                                    icon: const Icon(Icons.compare_arrows),
                                    label: Text(l10n.translate('compare_this_page')),
                                  ),
                                ),
                                if (_detailByItemId.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: _isComparing
                                        ? null
                                        : () => _compareCurrentPage(forceRefresh: true),
                                    child: Text(l10n.translate('compare_force_refresh')),
                                  ),
                                ],
                              ],
                            ),
                            if (_isComparing || _compareStatusMessage != null) ...[
                              const SizedBox(height: 8),
                              // Chip no modal (SCRUM-118): no Dialog ni loader a pantalla completa.
                              Chip(
                                avatar: _isComparing
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.green.shade700,
                                      ),
                                label: Text(
                                  _compareStatusMessage ??
                                      l10n.translate('compare_in_progress'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    _buildPagination(l10n),
                    _buildRanking(l10n),
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.translate('no_items_in_list'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _addCustomItem,
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.translate('add_product')),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => _loadPage(_page),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  final checked = _checkedIds.contains(item.id);
                                  final detail = _detailByItemId[item.id];
                                  final statusText = _statusLabel(l10n, detail);
                                  final sortedPrices = detail == null
                                      ? const <ShoppingListPriceDto>[]
                                      : _sortedPrices(detail.prices);
                                  final cheapest =
                                      sortedPrices.isNotEmpty ? sortedPrices.first : null;
                                  final canExpand = detail != null &&
                                      (detail.prices.isNotEmpty ||
                                          _knownSupermarkets().isNotEmpty);
                                  final expanded = _expandedItemIds.contains(item.id);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Checkbox(
                                            value: checked,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _checkedIds.add(item.id);
                                                } else {
                                                  _checkedIds.remove(item.id);
                                                }
                                              });
                                            },
                                          ),
                                          title: Text(
                                            item.name,
                                            style: TextStyle(
                                              decoration: checked
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${l10n.translate('quantity')}: ${item.quantity}'
                                                '${item.unit != null ? ' ${item.unit}' : ''}',
                                              ),
                                              if (statusText.isNotEmpty)
                                                Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    color: _statusColor(detail?.status),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              if (cheapest != null)
                                                Text(
                                                  l10n.translate(
                                                    'compare_cheapest_price',
                                                    params: {
                                                      'supermarket':
                                                          cheapest.supermarket,
                                                      'price': cheapest
                                                          .displayUnitPrice
                                                          .toStringAsFixed(2),
                                                    },
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              if (detail?.status ==
                                                      CompareItemStatus.unavailable &&
                                                  detail?.message != null &&
                                                  !detail!.isCarrefourUnavailable)
                                                Text(
                                                  detail.message!,
                                                  style: TextStyle(
                                                    color: Colors.blueGrey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (canExpand)
                                                IconButton(
                                                  tooltip: l10n.translate(
                                                    'compare_item_prices_hint',
                                                  ),
                                                  icon: Icon(
                                                    expanded
                                                        ? Icons.expand_less
                                                        : Icons.expand_more,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (expanded) {
                                                        _expandedItemIds
                                                            .remove(item.id);
                                                      } else {
                                                        _expandedItemIds.add(item.id);
                                                      }
                                                    });
                                                  },
                                                ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () => _deleteItem(item),
                                              ),
                                            ],
                                          ),
                                          onTap: canExpand
                                              ? () {
                                                  setState(() {
                                                    if (expanded) {
                                                      _expandedItemIds.remove(item.id);
                                                    } else {
                                                      _expandedItemIds.add(item.id);
                                                    }
                                                  });
                                                }
                                              : null,
                                        ),
                                        if (expanded && detail != null)
                                          _buildItemPriceRows(l10n, detail),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddShoppingListItemResult {
  final String name;
  final double quantity;
  final String? unit;
  final String? catalogProductId;

  const _AddShoppingListItemResult({
    required this.name,
    required this.quantity,
    this.unit,
    this.catalogProductId,
  });
}

/// Diálogo alta lista con autocomplete de catálogo (SCRUM-128).
class _AddShoppingListItemDialog extends StatefulWidget {
  final CatalogProductNameSearcher searchCatalog;

  const _AddShoppingListItemDialog({required this.searchCatalog});

  @override
  State<_AddShoppingListItemDialog> createState() =>
      _AddShoppingListItemDialogState();
}

class _AddShoppingListItemDialogState extends State<_AddShoppingListItemDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _focusNode = FocusNode();

  Timer? _debounce;
  List<CatalogProductResponseDto> _suggestions = [];
  bool _searching = false;
  CatalogProductResponseDto? _selected;
  String? _searchError;

  static const _minChars = 2;
  static const _debounceMs = 280;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _selected = null;
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < _minChars) {
      setState(() {
        _suggestions = [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () async {
      try {
        final results = await widget.searchCatalog(q);
        if (!mounted || _nameController.text.trim() != q) return;
        setState(() {
          _suggestions = results.take(12).toList();
          _searching = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _searching = false;
          _searchError = userFriendlyError(e);
        });
      }
    });
  }

  void _pick(CatalogProductResponseDto product) {
    setState(() {
      _selected = product;
      _nameController.text = product.name;
      _nameController.selection = TextSelection.collapsed(offset: product.name.length);
      _suggestions = [];
      _searching = false;
    });
    _focusNode.unfocus();
  }

  void _submit() {
    final name = (_selected?.name ?? _nameController.text).trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      _AddShoppingListItemResult(
        name: name,
        quantity: double.tryParse(_quantityController.text.trim()) ?? 1,
        unit: _selected?.unit,
        catalogProductId: _selected?.id,
      ),
    );
  }

  String _suggestionLabel(CatalogProductResponseDto p) {
    final brand = p.brand?.trim();
    if (brand != null && brand.isNotEmpty) return '${p.name} · $brand';
    return p.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.translate('add_product')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.translate('product_name'),
                hintText: l10n.translate('catalog_search_hint'),
                border: const OutlineInputBorder(),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_selected != null
                        ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                        : const Icon(Icons.search)),
              ),
              onChanged: _onNameChanged,
              onSubmitted: (_) => _submit(),
            ),
            if (_searchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _searchError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final p = _suggestions[index];
                      return ListTile(
                        dense: true,
                        title: Text(_suggestionLabel(p)),
                        onTap: () => _pick(p),
                      );
                    },
                  ),
                ),
              ),
            ] else if (!_searching &&
                _nameController.text.trim().length >= _minChars &&
                _selected == null &&
                _searchError == null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.translate('no_products_found'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: l10n.translate('quantity'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.translate('add')),
        ),
      ],
    );
  }
}
