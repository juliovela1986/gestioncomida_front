class NotificationModel {
  final String id;
  final String inventoryItemId;
  final String channel;
  final DateTime scheduledAt;
  final String status;
  final String? reason;
  final String alertType;
  final DateTime createdInstant;

  NotificationModel({
    required this.id,
    required this.inventoryItemId,
    required this.channel,
    required this.scheduledAt,
    required this.status,
    this.reason,
    required this.alertType,
    required this.createdInstant,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      inventoryItemId: json['inventoryItemId'],
      channel: json['channel'],
      scheduledAt: DateTime.parse(json['scheduledAt']),
      status: json['status'],
      reason: json['reason'],
      alertType: json['alertType'],
      createdInstant: DateTime.parse(json['createdInstant']),
    );
  }
}
