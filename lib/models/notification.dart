class NotificationModel {
  final String id;
  final String? inventoryItemId;
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
      inventoryItemId: json['inventoryItemId'] as String?,
      channel: json['channel'] as String? ?? 'PUSH',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? '') ??
          DateTime.tryParse(json['createdInstant']?.toString() ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'PENDING',
      reason: json['reason'],
      alertType: json['alertType'] as String? ?? 'REMINDER',
      createdInstant: DateTime.tryParse(json['createdInstant']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
