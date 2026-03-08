import 'ticket.dart';

class TicketProcessingResultDto {
  final TicketMetadataDto metadata;
  final List<TicketLineResponseDto> lines;
  final String processedBy;
  final bool manualReviewRequired;
  final String? message;

  TicketProcessingResultDto({
    required this.metadata,
    required this.lines,
    required this.processedBy,
    required this.manualReviewRequired,
    this.message,
  });

  factory TicketProcessingResultDto.fromJson(Map<String, dynamic> json) {
    return TicketProcessingResultDto(
      metadata: TicketMetadataDto.fromJson(json['metadata']),
      lines: (json['lines'] as List).map((e) => TicketLineResponseDto.fromJson(e)).toList(),
      processedBy: json['processedBy'],
      manualReviewRequired: json['manualReviewRequired'],
      message: json['message'],
    );
  }
}

class TicketMetadataDto {
  final String id;
  final String? locationId;
  final String? supermarketName;
  final DateTime? purchaseInstant;

  TicketMetadataDto({
    required this.id,
    this.locationId,
    this.supermarketName,
    this.purchaseInstant,
  });

  factory TicketMetadataDto.fromJson(Map<String, dynamic> json) {
    return TicketMetadataDto(
      id: json['id'],
      locationId: json['locationId'],
      supermarketName: json['supermarketName'],
      purchaseInstant: json['purchaseInstant'] != null ? DateTime.parse(json['purchaseInstant']) : null,
    );
  }
}
