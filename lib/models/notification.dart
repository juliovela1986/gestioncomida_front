class NotificationResponseDto {
  final String id;
  final String? inventoryItemId;
  final String? channel;
  final DateTime? scheduledAt;
  final String? status;
  final String? reason;
  final String? alertType;
  final DateTime? createdInstant;

  NotificationResponseDto({
    required this.id,
    this.inventoryItemId,
    this.channel,
    this.scheduledAt,
    this.status,
    this.reason,
    this.alertType,
    this.createdInstant,
  });

  factory NotificationResponseDto.fromJson(Map<String, dynamic> json) {
    return NotificationResponseDto(
      id: json['id'],
      inventoryItemId: json['inventoryItemId'],
      channel: json['channel'],
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      status: json['status'],
      reason: json['reason'],
      alertType: json['alertType'],
      createdInstant: json['createdInstant'] != null ? DateTime.parse(json['createdInstant']) : null,
    );
  }
}
