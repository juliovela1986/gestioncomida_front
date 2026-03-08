class PendingExpirationItemDto {
  final String inventoryItemId;
  final String productName;
  final double quantity;
  final bool alreadyInInventory;
  final String? existingItemId;

  PendingExpirationItemDto({
    required this.inventoryItemId,
    required this.productName,
    required this.quantity,
    required this.alreadyInInventory,
    this.existingItemId,
  });

  factory PendingExpirationItemDto.fromJson(Map<String, dynamic> json) {
    return PendingExpirationItemDto(
      inventoryItemId: json['inventoryItemId'],
      productName: json['productName'],
      quantity: (json['quantity'] as num).toDouble(),
      alreadyInInventory: json['alreadyInInventory'],
      existingItemId: json['existingItemId'],
    );
  }
}
