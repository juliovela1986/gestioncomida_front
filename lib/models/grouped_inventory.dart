class GroupedInventoryResponse {
  final String? catalogProductId;
  final String productName;
  final String? productBrand;
  final double totalQuantity;
  final int lotCount;
  final String? nextExpirationDate;
  final List<LotDetail> lots;

  GroupedInventoryResponse({
    this.catalogProductId,
    required this.productName,
    this.productBrand,
    required this.totalQuantity,
    required this.lotCount,
    this.nextExpirationDate,
    required this.lots,
  });

  factory GroupedInventoryResponse.fromJson(Map<String, dynamic> json) {
    return GroupedInventoryResponse(
      catalogProductId: json['catalogProductId'] as String?,
      productName: json['productName'] as String? ?? 'Sin nombre',
      productBrand: json['productBrand'] as String?,
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      lotCount: json['lotCount'] as int? ?? 0,
      nextExpirationDate: json['nextExpirationDate'] as String?,
      lots: (json['lots'] as List? ?? [])
          .map((l) => LotDetail.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LotDetail {
  final String inventoryItemId;
  final double quantity;
  final String? expirationDate;
  final String? alertDate;
  final int? daysUntilExpiration;
  final String status;

  LotDetail({
    required this.inventoryItemId,
    required this.quantity,
    this.expirationDate,
    this.alertDate,
    this.daysUntilExpiration,
    required this.status,
  });

  factory LotDetail.fromJson(Map<String, dynamic> json) {
    return LotDetail(
      inventoryItemId: json['inventoryItemId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      expirationDate: json['expirationDate'] as String?,
      alertDate: json['alertDate'] as String?,
      daysUntilExpiration: json['daysUntilExpiration'] as int?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}
