class InventoryItemResponseDto {
  final String id;
  final String? catalogProductId;
  final String? locationId;
  final String? productName;
  final String? productBrand;
  final String? userId;
  final String? status;
  final String? expirationDate;
  final String? alertDate;
  final String? openedAt;
  final String? consumedAt;
  final String? notes;
  final String? quantity;
  final String? initialQuantity;
  final int? openShelfLifeDays;
  final int? consumedQuantity;
  final DateTime? createdInstant;

  InventoryItemResponseDto({
    required this.id,
    this.catalogProductId,
    this.locationId,
    this.productName,
    this.productBrand,
    this.userId,
    this.status,
    this.expirationDate,
    this.alertDate,
    this.openedAt,
    this.consumedAt,
    this.notes,
    this.quantity,
    this.initialQuantity,
    this.openShelfLifeDays,
    this.consumedQuantity,
    this.createdInstant,
  });

  factory InventoryItemResponseDto.fromJson(Map<String, dynamic> json) {
    return InventoryItemResponseDto(
      id: json['id'],
      catalogProductId: json['catalogProductId'],
      locationId: json['locationId'],
      productName: json['productName'],
      productBrand: json['productBrand'],
      userId: json['userId'],
      status: json['status'],
      expirationDate: json['expirationDate'],
      alertDate: json['alertDate'],
      openedAt: json['openedAt'],
      consumedAt: json['consumedAt'],
      notes: json['notes'],
      quantity: json['quantity'],
      initialQuantity: json['initialQuantity'],
      openShelfLifeDays: json['openShelfLifeDays'],
      consumedQuantity: json['consumedQuantity'],
      createdInstant: json['createdInstant'] != null ? DateTime.parse(json['createdInstant']) : null,
    );
  }
}
