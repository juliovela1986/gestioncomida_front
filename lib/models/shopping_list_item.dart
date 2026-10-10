class ShoppingListItemDto {
  final String id;
  final String name;
  final double quantity;
  final String? unit;
  final String? status;
  final String? masterProductId;
  final String? catalogProductId;

  const ShoppingListItemDto({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit,
    this.status,
    this.masterProductId,
    this.catalogProductId,
  });

  factory ShoppingListItemDto.fromJson(Map<String, dynamic> json) {
    return ShoppingListItemDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit']?.toString(),
      status: json['status']?.toString(),
      masterProductId: json['masterProductId']?.toString(),
      catalogProductId: json['catalogProductId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (status != null) 'status': status,
        if (masterProductId != null) 'masterProductId': masterProductId,
        if (catalogProductId != null) 'catalogProductId': catalogProductId,
      };

  ShoppingListItemDto copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    String? status,
    String? masterProductId,
    String? catalogProductId,
  }) {
    return ShoppingListItemDto(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      masterProductId: masterProductId ?? this.masterProductId,
      catalogProductId: catalogProductId ?? this.catalogProductId,
    );
  }
}

class ShoppingListPageDto {
  final List<ShoppingListItemDto> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;
  final bool first;
  final bool last;
  final bool empty;

  const ShoppingListPageDto({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory ShoppingListPageDto.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] as List<dynamic>? ?? const [];
    return ShoppingListPageDto(
      content: contentJson
          .map((e) => ShoppingListItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? contentJson.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? contentJson.length,
      first: json['first'] as bool? ?? true,
      last: json['last'] as bool? ?? true,
      empty: json['empty'] as bool? ?? contentJson.isEmpty,
    );
  }
}

class ShoppingListItemRequestDto {
  final String name;
  final double quantity;
  final String? unit;
  final String? masterProductId;
  final String? catalogProductId;

  const ShoppingListItemRequestDto({
    required this.name,
    this.quantity = 1,
    this.unit,
    this.masterProductId,
    this.catalogProductId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (masterProductId != null) 'masterProductId': masterProductId,
        if (catalogProductId != null) 'catalogProductId': catalogProductId,
      };
}
