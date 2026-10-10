enum CompareItemStatus {
  ready,
  pending,
  unavailable,
  unknown;

  static CompareItemStatus fromApi(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'ready':
        return CompareItemStatus.ready;
      case 'pending':
        return CompareItemStatus.pending;
      case 'unavailable':
        return CompareItemStatus.unavailable;
      default:
        return CompareItemStatus.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case CompareItemStatus.ready:
        return 'ready';
      case CompareItemStatus.pending:
        return 'pending';
      case CompareItemStatus.unavailable:
        return 'unavailable';
      case CompareItemStatus.unknown:
        return 'unknown';
    }
  }
}

class CompareBatchRequestDto {
  final List<String> itemIds;
  final int freshnessDays;
  final bool forceRefresh;

  const CompareBatchRequestDto({
    required this.itemIds,
    this.freshnessDays = 14,
    this.forceRefresh = false,
  });

  Map<String, dynamic> toJson() => {
        'itemIds': itemIds,
        'freshnessDays': freshnessDays,
        'forceRefresh': forceRefresh,
      };
}

class ShoppingListPriceDto {
  final String supermarket;
  final double avgUnitPrice;
  final double? lastUnitPrice;
  final int samples;
  final double deltaVsCheapestPct;
  final double deltaVsCheapestAmount;
  final String? priceSource;

  const ShoppingListPriceDto({
    required this.supermarket,
    required this.avgUnitPrice,
    this.lastUnitPrice,
    required this.samples,
    required this.deltaVsCheapestPct,
    required this.deltaVsCheapestAmount,
    this.priceSource,
  });

  double get displayUnitPrice => lastUnitPrice ?? avgUnitPrice;

  factory ShoppingListPriceDto.fromJson(Map<String, dynamic> json) {
    return ShoppingListPriceDto(
      supermarket: (json['supermarket'] ?? '').toString(),
      avgUnitPrice: (json['avgUnitPrice'] as num?)?.toDouble() ?? 0,
      lastUnitPrice: (json['lastUnitPrice'] as num?)?.toDouble(),
      samples: (json['samples'] as num?)?.toInt() ?? 0,
      deltaVsCheapestPct: (json['deltaVsCheapestPct'] as num?)?.toDouble() ?? 0,
      deltaVsCheapestAmount:
          (json['deltaVsCheapestAmount'] as num?)?.toDouble() ?? 0,
      priceSource: json['priceSource']?.toString(),
    );
  }
}

class ShoppingListItemComparisonDetailDto {
  final String? itemId;
  final String? masterProductId;
  final String productName;
  final CompareItemStatus status;
  final String? message;
  final bool stale;
  final List<ShoppingListPriceDto> prices;

  const ShoppingListItemComparisonDetailDto({
    this.itemId,
    this.masterProductId,
    required this.productName,
    required this.status,
    this.message,
    this.stale = false,
    this.prices = const [],
  });

  factory ShoppingListItemComparisonDetailDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ShoppingListItemComparisonDetailDto(
      itemId: json['itemId']?.toString(),
      masterProductId: json['masterProductId']?.toString(),
      productName: (json['productName'] ?? '').toString(),
      status: CompareItemStatus.fromApi(json['status']?.toString()),
      message: json['message']?.toString(),
      stale: json['stale'] as bool? ?? false,
      prices: (json['prices'] as List<dynamic>?)
              ?.map((e) => ShoppingListPriceDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  bool get isCarrefourUnavailable {
    final haystack = '${message ?? ''} $productName'.toLowerCase();
    return status == CompareItemStatus.unavailable &&
        haystack.contains('carrefour');
  }
}

class SupermarketRankingDto {
  final String supermarket;
  final double totalPrice;
  final int itemsFound;
  final int itemsMissing;
  final int resolved;
  final int total;

  const SupermarketRankingDto({
    required this.supermarket,
    required this.totalPrice,
    required this.itemsFound,
    required this.itemsMissing,
    required this.resolved,
    required this.total,
  });

  factory SupermarketRankingDto.fromJson(Map<String, dynamic> json) {
    final resolved = (json['resolved'] as num?)?.toInt() ??
        (json['itemsFound'] as num?)?.toInt() ??
        0;
    final total = (json['total'] as num?)?.toInt() ??
        (resolved + ((json['itemsMissing'] as num?)?.toInt() ?? 0));
    return SupermarketRankingDto(
      supermarket: (json['supermarket'] ?? '').toString(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      itemsFound: (json['itemsFound'] as num?)?.toInt() ?? resolved,
      itemsMissing: (json['itemsMissing'] as num?)?.toInt() ?? 0,
      resolved: resolved,
      total: total,
    );
  }

  SupermarketRankingDto merge(SupermarketRankingDto other) {
    return SupermarketRankingDto(
      supermarket: supermarket,
      totalPrice: totalPrice + other.totalPrice,
      itemsFound: itemsFound + other.itemsFound,
      itemsMissing: itemsMissing + other.itemsMissing,
      resolved: resolved + other.resolved,
      total: total + other.total,
    );
  }
}

class ShoppingListComparisonResponseDto {
  final int itemsCompared;
  final int staleItems;
  final int processedCount;
  final int skippedCount;
  final int readyCount;
  final int pendingCount;
  final int unavailableCount;
  final int jobsEnqueued;
  final bool? rankingConclusive;
  final String? rankingPartialReason;
  final String? cheapestSupermarket;
  final List<SupermarketRankingDto> ranking;
  final List<ShoppingListItemComparisonDetailDto> detail;

  const ShoppingListComparisonResponseDto({
    required this.itemsCompared,
    required this.staleItems,
    required this.processedCount,
    required this.skippedCount,
    required this.readyCount,
    required this.pendingCount,
    required this.unavailableCount,
    required this.jobsEnqueued,
    this.rankingConclusive,
    this.rankingPartialReason,
    this.cheapestSupermarket,
    this.ranking = const [],
    this.detail = const [],
  });

  factory ShoppingListComparisonResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ShoppingListComparisonResponseDto(
      itemsCompared: (json['itemsCompared'] as num?)?.toInt() ?? 0,
      staleItems: (json['staleItems'] as num?)?.toInt() ?? 0,
      processedCount: (json['processedCount'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
      readyCount: (json['readyCount'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      unavailableCount: (json['unavailableCount'] as num?)?.toInt() ?? 0,
      jobsEnqueued: (json['jobsEnqueued'] as num?)?.toInt() ?? 0,
      rankingConclusive: json['rankingConclusive'] as bool?,
      rankingPartialReason: json['rankingPartialReason']?.toString(),
      cheapestSupermarket: json['cheapestSupermarket']?.toString(),
      ranking: (json['ranking'] as List<dynamic>?)
              ?.map((e) => SupermarketRankingDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      detail: (json['detail'] as List<dynamic>?)
              ?.map(
                (e) => ShoppingListItemComparisonDetailDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  bool get hasPending => pendingCount > 0 ||
      detail.any((d) => d.status == CompareItemStatus.pending);
}

/// Acumula rankings de varios lotes/páginas sin doble-contar el mismo lote.
class AccumulatedRanking {
  final Map<String, List<SupermarketRankingDto>> _byBatchKey = {};

  void upsertBatch(String batchKey, List<SupermarketRankingDto> ranking) {
    _byBatchKey[batchKey] = List<SupermarketRankingDto>.from(ranking);
  }

  void clear() => _byBatchKey.clear();

  List<SupermarketRankingDto> build() {
    final merged = <String, SupermarketRankingDto>{};
    for (final ranking in _byBatchKey.values) {
      for (final entry in ranking) {
        final key = entry.supermarket.toLowerCase();
        final existing = merged[key];
        merged[key] = existing == null ? entry : existing.merge(entry);
      }
    }
    final list = merged.values.toList()
      ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    return list;
  }
}
