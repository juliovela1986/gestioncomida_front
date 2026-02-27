class TicketResponseDto {
  final String id;
  final String? imageHash;
  final String? purchaseDatetime;
  final String? rawText;
  final String? keyInvoice;
  final String? supermarketName;
  final bool? inventorySynced;
  final List<TicketLineResponseDto> lines;
  final String? createdBy;
  final DateTime? createdInstant;

  TicketResponseDto({
    required this.id,
    this.imageHash,
    this.purchaseDatetime,
    this.rawText,
    this.keyInvoice,
    this.supermarketName,
    this.inventorySynced,
    required this.lines,
    this.createdBy,
    this.createdInstant,
  });

  factory TicketResponseDto.fromJson(Map<String, dynamic> json) {
    return TicketResponseDto(
      id: json['id'],
      imageHash: json['imageHash'],
      purchaseDatetime: json['purchaseDatetime'],
      rawText: json['rawText'],
      keyInvoice: json['keyInvoice'],
      supermarketName: json['supermarketName'],
      inventorySynced: json['inventorySynced'],
      lines: (json['lines'] as List?)?.map((e) => TicketLineResponseDto.fromJson(e)).toList() ?? [],
      createdBy: json['createdBy'],
      createdInstant: json['createdInstant'] != null ? DateTime.parse(json['createdInstant']) : null,
    );
  }
}

class TicketLineResponseDto {
  final String id;
  final String? productId;
  final String? productName;
  final String? parsedText;
  final double? confidence;
  final String? quantity;
  final String? price;
  final String? lineTotal;

  TicketLineResponseDto({
    required this.id,
    this.productId,
    this.productName,
    this.parsedText,
    this.confidence,
    this.quantity,
    this.price,
    this.lineTotal,
  });

  factory TicketLineResponseDto.fromJson(Map<String, dynamic> json) {
    return TicketLineResponseDto(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      parsedText: json['parsedText'],
      confidence: json['confidence']?.toDouble(),
      quantity: json['quantity'],
      price: json['price'],
      lineTotal: json['lineTotal'],
    );
  }
}
