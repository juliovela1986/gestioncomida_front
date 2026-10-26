class CatalogProduct {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final String? unit;
  final bool isWeighed;
  final bool isPerishable;
  final int? shelfLifeDays;
  final DateTime? createdInstant;

  CatalogProduct({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.unit,
    this.isWeighed = false,
    this.isPerishable = false,
    this.shelfLifeDays,
    this.createdInstant,
  });

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      unit: json['unit'],
      isWeighed: json['isWeighed'] ?? false,
      isPerishable: json['isPerishable'] ?? false,
      shelfLifeDays: json['shelfLifeDays'],
      createdInstant: json['createdInstant'] != null ? DateTime.parse(json['createdInstant']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'unit': unit,
      'isWeighed': isWeighed,
      'isPerishable': isPerishable,
      'shelfLifeDays': shelfLifeDays,
    };
  }
}

class CatalogProductResponseDto {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final String? unit;
  final bool? isWeighed;
  final bool? isPerishable;
  final int? shelfLifeDays;
  final DateTime? createdInstant;

  CatalogProductResponseDto({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    this.unit,
    this.isWeighed,
    this.isPerishable,
    this.shelfLifeDays,
    this.createdInstant,
  });

  factory CatalogProductResponseDto.fromJson(Map<String, dynamic> json) {
    return CatalogProductResponseDto(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      category: json['category'],
      unit: json['unit'],
      isWeighed: json['isWeighed'],
      isPerishable: json['isPerishable'],
      shelfLifeDays: json['shelfLifeDays'],
      createdInstant: json['createdInstant'] != null ? DateTime.parse(json['createdInstant']) : null,
    );
  }
}
