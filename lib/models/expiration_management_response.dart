class ExpirationManagementResponse {
  final String ticketId;
  final List<ProductToManage> products;

  ExpirationManagementResponse({
    required this.ticketId,
    required this.products,
  });

  factory ExpirationManagementResponse.fromJson(Map<String, dynamic> json) {
    return ExpirationManagementResponse(
      ticketId: json['ticketId'] as String? ?? '',
      products: (json['products'] as List? ?? [])
          .map((p) => ProductToManage.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductToManage {
  final String ticketLineId;
  final String productName;
  final double newQuantity;
  final String newInventoryItemId;
  final List<ExistingLot> existingLots;

  ProductToManage({
    required this.ticketLineId,
    required this.productName,
    required this.newQuantity,
    required this.newInventoryItemId,
    required this.existingLots,
  });

  factory ProductToManage.fromJson(Map<String, dynamic> json) {
    return ProductToManage(
      ticketLineId: json['ticketLineId'] as String? ?? '',
      productName: json['productName'] as String? ?? 'Sin nombre',
      newQuantity: (json['newQuantity'] as num?)?.toDouble() ?? 0.0,
      newInventoryItemId: json['newInventoryItemId'] as String? ?? '',
      existingLots: (json['existingLots'] as List? ?? [])
          .map((l) => ExistingLot.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExistingLot {
  final String inventoryItemId;
  final String expirationDate;
  final double quantity;

  ExistingLot({
    required this.inventoryItemId,
    required this.expirationDate,
    required this.quantity,
  });

  factory ExistingLot.fromJson(Map<String, dynamic> json) {
    return ExistingLot(
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      expirationDate: json['expirationDate'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
