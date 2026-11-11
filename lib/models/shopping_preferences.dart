class ShoppingPreferencesCompletenessDto {
  final bool hasPreferredSupermarkets;
  final bool hasPostalCode;
  final bool readyForMercadona;
  final String? deploymentPostalCode;
  final bool zoneMismatch;
  final String? zoneMismatchNote;
  final String? carrefourNote;

  const ShoppingPreferencesCompletenessDto({
    required this.hasPreferredSupermarkets,
    required this.hasPostalCode,
    required this.readyForMercadona,
    this.deploymentPostalCode,
    required this.zoneMismatch,
    this.zoneMismatchNote,
    this.carrefourNote,
  });

  factory ShoppingPreferencesCompletenessDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ShoppingPreferencesCompletenessDto(
        hasPreferredSupermarkets: false,
        hasPostalCode: false,
        readyForMercadona: false,
        zoneMismatch: false,
      );
    }
    return ShoppingPreferencesCompletenessDto(
      hasPreferredSupermarkets: json['hasPreferredSupermarkets'] as bool? ?? false,
      hasPostalCode: json['hasPostalCode'] as bool? ?? false,
      readyForMercadona: json['readyForMercadona'] as bool? ?? false,
      deploymentPostalCode: json['deploymentPostalCode'] as String?,
      zoneMismatch: json['zoneMismatch'] as bool? ?? false,
      zoneMismatchNote: json['zoneMismatchNote'] as String?,
      carrefourNote: json['carrefourNote'] as String?,
    );
  }
}

class ShoppingPreferencesResponseDto {
  final List<String> preferredSupermarkets;
  final String? postalCode;
  final Map<String, String> storeIds;
  final String? zoneLabel;
  final String? source;
  final ShoppingPreferencesCompletenessDto? completeness;
  final DateTime? updatedAt;

  const ShoppingPreferencesResponseDto({
    required this.preferredSupermarkets,
    this.postalCode,
    required this.storeIds,
    this.zoneLabel,
    this.source,
    this.completeness,
    this.updatedAt,
  });

  factory ShoppingPreferencesResponseDto.fromJson(Map<String, dynamic> json) {
    final preferredRaw = json['preferredSupermarkets'];
    final preferred = preferredRaw is List
        ? preferredRaw.map((e) => e.toString()).toList()
        : <String>[];
    final storeIdsRaw = json['storeIds'];
    final storeIds = <String, String>{};
    if (storeIdsRaw is Map) {
      storeIdsRaw.forEach((k, v) {
        if (v != null) storeIds[k.toString()] = v.toString();
      });
    }
    return ShoppingPreferencesResponseDto(
      preferredSupermarkets: preferred,
      postalCode: json['postalCode'] as String?,
      storeIds: storeIds,
      zoneLabel: json['zoneLabel'] as String?,
      source: json['source'] as String?,
      completeness: ShoppingPreferencesCompletenessDto.fromJson(
        json['completeness'] as Map<String, dynamic>?,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  ShoppingPreferencesResponseDto copyWith({
    List<String>? preferredSupermarkets,
    String? postalCode,
    bool clearPostalCode = false,
    Map<String, String>? storeIds,
    String? zoneLabel,
    ShoppingPreferencesCompletenessDto? completeness,
  }) {
    return ShoppingPreferencesResponseDto(
      preferredSupermarkets: preferredSupermarkets ?? this.preferredSupermarkets,
      postalCode: clearPostalCode ? null : (postalCode ?? this.postalCode),
      storeIds: storeIds ?? this.storeIds,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      source: source,
      completeness: completeness ?? this.completeness,
      updatedAt: updatedAt,
    );
  }
}

class ShoppingPreferencesUpdateRequestDto {
  final List<String> preferredSupermarkets;
  final String? postalCode;
  final String? zoneLabel;
  final String source;

  const ShoppingPreferencesUpdateRequestDto({
    required this.preferredSupermarkets,
    this.postalCode,
    this.zoneLabel,
    this.source = 'EXPLICIT',
  });

  Map<String, dynamic> toJson() {
    return {
      'preferredSupermarkets': preferredSupermarkets,
      'postalCode': postalCode,
      'zoneLabel': zoneLabel,
      'source': source,
    };
  }
}

/// Keys aceptadas por el backend (SCRUM-113 / PricingConstants.KNOWN_SUPERMARKET_KEYS).
const List<String> kKnownSupermarketKeys = [
  'mercadona',
  'carrefour',
  'lidl',
  'aldi',
  'dia',
  'consum',
  'eroski',
  'ahorramas',
  'hipercor',
  'alcampo',
];

String supermarketDisplayName(String key) {
  switch (key) {
    case 'mercadona':
      return 'Mercadona';
    case 'carrefour':
      return 'Carrefour';
    case 'lidl':
      return 'Lidl';
    case 'aldi':
      return 'Aldi';
    case 'dia':
      return 'Dia';
    case 'consum':
      return 'Consum';
    case 'eroski':
      return 'Eroski';
    case 'ahorramas':
      return 'Ahorramás';
    case 'hipercor':
      return 'Hipercor';
    case 'alcampo':
      return 'Alcampo';
    default:
      return key;
  }
}
