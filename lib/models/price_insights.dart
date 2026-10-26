class SupermarketComparisonDto {
  final String productId;
  final String productName;
  final int days;
  final List<SupermarketPriceDto> supermarkets;

  SupermarketComparisonDto({
    required this.productId,
    required this.productName,
    required this.days,
    required this.supermarkets,
  });

  factory SupermarketComparisonDto.fromJson(Map<String, dynamic> json) {
    return SupermarketComparisonDto(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      days: json['days'] ?? 0,
      supermarkets: (json['supermarkets'] as List<dynamic>?)
          ?.map((e) => SupermarketPriceDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'days': days,
      'supermarkets': supermarkets.map((e) => e.toJson()).toList(),
    };
  }
}

class SupermarketPriceDto {
  final String supermarket;
  final double avgUnitPrice;
  final double? lastUnitPrice;
  final DateTime? lastPurchaseDate;
  final int samples;
  final double deltaVsCheapestPct;
  final double deltaVsCheapestAmount;

  SupermarketPriceDto({
    required this.supermarket,
    required this.avgUnitPrice,
    this.lastUnitPrice,
    this.lastPurchaseDate,
    required this.samples,
    required this.deltaVsCheapestPct,
    required this.deltaVsCheapestAmount,
  });

  double get displayUnitPrice => lastUnitPrice ?? avgUnitPrice;

  factory SupermarketPriceDto.fromJson(Map<String, dynamic> json) {
    return SupermarketPriceDto(
      supermarket: json['supermarket'] ?? '',
      avgUnitPrice: (json['avgUnitPrice'] ?? 0).toDouble(),
      lastUnitPrice: json['lastUnitPrice'] != null
          ? (json['lastUnitPrice'] as num).toDouble()
          : null,
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.tryParse(json['lastPurchaseDate'].toString())
          : null,
      samples: json['samples'] ?? 0,
      deltaVsCheapestPct: (json['deltaVsCheapestPct'] ?? 0).toDouble(),
      deltaVsCheapestAmount: (json['deltaVsCheapestAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supermarket': supermarket,
      'avgUnitPrice': avgUnitPrice,
      'lastUnitPrice': lastUnitPrice,
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
      'samples': samples,
      'deltaVsCheapestPct': deltaVsCheapestPct,
      'deltaVsCheapestAmount': deltaVsCheapestAmount,
    };
  }
}

class ProductPriceTrendDto {
  final String productId;
  final String productName;
  final int days;
  final String? supermarket;
  final List<PriceTrendPointDto> points;

  ProductPriceTrendDto({
    required this.productId,
    required this.productName,
    required this.days,
    this.supermarket,
    required this.points,
  });

  factory ProductPriceTrendDto.fromJson(Map<String, dynamic> json) {
    return ProductPriceTrendDto(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      days: json['days'] ?? 0,
      supermarket: json['supermarket'],
      points: (json['points'] as List<dynamic>?)
          ?.map((e) => PriceTrendPointDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'days': days,
      'supermarket': supermarket,
      'points': points.map((e) => e.toJson()).toList(),
    };
  }
}

class PriceTrendPointDto {
  final String day;
  final double avgUnitPrice;
  final int samples;

  PriceTrendPointDto({
    required this.day,
    required this.avgUnitPrice,
    required this.samples,
  });

  factory PriceTrendPointDto.fromJson(Map<String, dynamic> json) {
    return PriceTrendPointDto(
      day: json['day'] ?? '',
      avgUnitPrice: (json['avgUnitPrice'] ?? 0).toDouble(),
      samples: json['samples'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'avgUnitPrice': avgUnitPrice,
      'samples': samples,
    };
  }
}

class PriceOverviewDto {
  final int days;
  final int observations;
  final int productsTracked;
  final int supermarketsTracked;
  final List<PriceVariationDto> topIncreases;
  final List<PriceVariationDto> topDrops;

  PriceOverviewDto({
    required this.days,
    required this.observations,
    required this.productsTracked,
    required this.supermarketsTracked,
    required this.topIncreases,
    required this.topDrops,
  });

  factory PriceOverviewDto.fromJson(Map<String, dynamic> json) {
    return PriceOverviewDto(
      days: json['days'] ?? 0,
      observations: json['observations'] ?? 0,
      productsTracked: json['productsTracked'] ?? 0,
      supermarketsTracked: json['supermarketsTracked'] ?? 0,
      topIncreases: (json['topIncreases'] as List<dynamic>?)
          ?.map((e) => PriceVariationDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      topDrops: (json['topDrops'] as List<dynamic>?)
          ?.map((e) => PriceVariationDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'observations': observations,
      'productsTracked': productsTracked,
      'supermarketsTracked': supermarketsTracked,
      'topIncreases': topIncreases.map((e) => e.toJson()).toList(),
      'topDrops': topDrops.map((e) => e.toJson()).toList(),
    };
  }
}

class PriceVariationDto {
  final String productId;
  final String productName;
  final double currentAvg;
  final double previousAvg;
  final double variationPct;
  final int currentSamples;
  final int previousSamples;

  PriceVariationDto({
    required this.productId,
    required this.productName,
    required this.currentAvg,
    required this.previousAvg,
    required this.variationPct,
    required this.currentSamples,
    required this.previousSamples,
  });

  factory PriceVariationDto.fromJson(Map<String, dynamic> json) {
    return PriceVariationDto(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      currentAvg: (json['currentAvg'] ?? 0).toDouble(),
      previousAvg: (json['previousAvg'] ?? 0).toDouble(),
      variationPct: (json['variationPct'] ?? 0).toDouble(),
      currentSamples: json['currentSamples'] ?? 0,
      previousSamples: json['previousSamples'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'currentAvg': currentAvg,
      'previousAvg': previousAvg,
      'variationPct': variationPct,
      'currentSamples': currentSamples,
      'previousSamples': previousSamples,
    };
  }
}

class TrackedProductDto {
  final String productId;
  final String productName;
  final int observations;
  final int supermarketCount;
  final DateTime lastSeenAt;

  TrackedProductDto({
    required this.productId,
    required this.productName,
    required this.observations,
    required this.supermarketCount,
    required this.lastSeenAt,
  });

  factory TrackedProductDto.fromJson(Map<String, dynamic> json) {
    return TrackedProductDto(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      observations: json['observations'] ?? 0,
      supermarketCount: json['supermarketCount'] ?? 0,
      lastSeenAt: DateTime.parse(json['lastSeenAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'observations': observations,
      'supermarketCount': supermarketCount,
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }
}

class TrackedProductsPageDto {
  final List<TrackedProductDto> items;
  final int totalCount;
  final int limit;
  final int offset;

  TrackedProductsPageDto({
    required this.items,
    required this.totalCount,
    required this.limit,
    required this.offset,
  });

  factory TrackedProductsPageDto.fromJson(Map<String, dynamic> json) {
    return TrackedProductsPageDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TrackedProductDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
    );
  }
}

