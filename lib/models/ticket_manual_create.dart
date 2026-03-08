class TicketManualCreateRequest {
  final String supermarketName;
  final String purchaseDatetime;
  final String? locationId;
  final List<TicketLineCreate> lines;

  TicketManualCreateRequest({
    required this.supermarketName,
    required this.purchaseDatetime,
    this.locationId,
    required this.lines,
  });

  Map<String, dynamic> toJson() {
    return {
      'supermarketName': supermarketName,
      'purchaseDatetime': purchaseDatetime,
      if (locationId != null) 'locationId': locationId,
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }
}

class TicketLineCreate {
  final String productName;
  final double quantity;
  final double? price;
  final double? lineTotal;

  TicketLineCreate({
    required this.productName,
    required this.quantity,
    this.price,
    this.lineTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'quantity': quantity,
      if (price != null) 'price': price,
      if (lineTotal != null) 'lineTotal': lineTotal,
    };
  }
}
