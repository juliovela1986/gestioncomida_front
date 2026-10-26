class ExpiredPendingItemDto {
  final String id;
  final String productName;
  final String expirationDate;
  final int daysExpired;
  final String status;
  final String? locationId;
  final String? locationName;

  ExpiredPendingItemDto({
    required this.id,
    required this.productName,
    required this.expirationDate,
    required this.daysExpired,
    required this.status,
    this.locationId,
    this.locationName,
  });

  factory ExpiredPendingItemDto.fromJson(Map<String, dynamic> json) {
    return ExpiredPendingItemDto(
      id: json['id'] as String,
      productName: json['productName'] as String? ?? '',
      expirationDate: json['expirationDate'] as String? ?? '',
      daysExpired: (json['daysExpired'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'EXPIRED_PENDING',
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
    );
  }
}

enum ExpiredPendingBulkActionType {
  archive,
  moveToTrash,
  snooze,
}

extension ExpiredPendingBulkActionTypeApiValue on ExpiredPendingBulkActionType {
  String get apiValue {
    switch (this) {
      case ExpiredPendingBulkActionType.archive:
        return 'ARCHIVE';
      case ExpiredPendingBulkActionType.moveToTrash:
        return 'MOVE_TO_TRASH';
      case ExpiredPendingBulkActionType.snooze:
        return 'SNOOZE';
    }
  }
}

class ExpiredPendingBulkActionRequestDto {
  final List<String> itemIds;
  final ExpiredPendingBulkActionType action;
  final String clientRequestId;
  final String? reason;
  final String? snoozeUntil;
  final int? snoozeDays;

  const ExpiredPendingBulkActionRequestDto({
    required this.itemIds,
    required this.action,
    required this.clientRequestId,
    this.reason,
    this.snoozeUntil,
    this.snoozeDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemIds': itemIds,
      'action': action.apiValue,
      'clientRequestId': clientRequestId,
      if (reason != null) 'reason': reason,
      if (snoozeUntil != null) 'snoozeUntil': snoozeUntil,
      if (snoozeDays != null) 'snoozeDays': snoozeDays,
    };
  }
}

class ExpiredPendingBulkActionResponseDto {
  final int requested;
  final int processed;
  final int updated;
  final int skipped;
  final List<String> errors;
  final bool idempotentReplay;

  const ExpiredPendingBulkActionResponseDto({
    required this.requested,
    required this.processed,
    required this.updated,
    required this.skipped,
    required this.errors,
    required this.idempotentReplay,
  });

  bool get hasPartialErrors => errors.isNotEmpty;

  factory ExpiredPendingBulkActionResponseDto.fromJson(Map<String, dynamic> json) {
    return ExpiredPendingBulkActionResponseDto(
      requested: (json['requested'] as num?)?.toInt() ?? 0,
      processed: (json['processed'] as num?)?.toInt() ?? 0,
      updated: (json['updated'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      errors: (json['errors'] as List? ?? []).map((e) => e.toString()).toList(),
      idempotentReplay: json['idempotentReplay'] as bool? ?? false,
    );
  }
}

class InventoryTrashBulkRequestDto {
  final List<String> itemIds;

  const InventoryTrashBulkRequestDto({required this.itemIds});

  Map<String, dynamic> toJson() {
    return {
      'itemIds': itemIds,
    };
  }
}

enum CleanupReminderFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  disabled,
}

extension CleanupReminderFrequencyApiValue on CleanupReminderFrequency {
  String get apiValue {
    switch (this) {
      case CleanupReminderFrequency.daily:
        return 'DAILY';
      case CleanupReminderFrequency.weekly:
        return 'WEEKLY';
      case CleanupReminderFrequency.biweekly:
        return 'BIWEEKLY';
      case CleanupReminderFrequency.monthly:
        return 'MONTHLY';
      case CleanupReminderFrequency.disabled:
        return 'DISABLED';
    }
  }

  static CleanupReminderFrequency fromApiValue(String? value) {
    switch (value) {
      case 'DAILY':
        return CleanupReminderFrequency.daily;
      case 'WEEKLY':
        return CleanupReminderFrequency.weekly;
      case 'BIWEEKLY':
        return CleanupReminderFrequency.biweekly;
      case 'MONTHLY':
        return CleanupReminderFrequency.monthly;
      case 'DISABLED':
        return CleanupReminderFrequency.disabled;
      default:
        return CleanupReminderFrequency.weekly;
    }
  }
}

class CleanupPreferencesResponseDto {
  final CleanupReminderFrequency reminderFrequency;
  final int? reminderWeekday;
  final String? reminderTime;
  final int trashRetentionDays;

  const CleanupPreferencesResponseDto({
    required this.reminderFrequency,
    required this.reminderWeekday,
    required this.reminderTime,
    required this.trashRetentionDays,
  });

  factory CleanupPreferencesResponseDto.fromJson(Map<String, dynamic> json) {
    return CleanupPreferencesResponseDto(
      reminderFrequency: CleanupReminderFrequencyApiValue.fromApiValue(
        json['reminderFrequency'] as String?,
      ),
      reminderWeekday: (json['reminderWeekday'] as num?)?.toInt(),
      reminderTime: json['reminderTime'] as String?,
      trashRetentionDays: (json['trashRetentionDays'] as num?)?.toInt() ?? 7,
    );
  }
}

class CleanupPreferencesUpdateRequestDto {
  final CleanupReminderFrequency reminderFrequency;
  final int? reminderWeekday;
  final String? reminderTime;
  final int trashRetentionDays;

  const CleanupPreferencesUpdateRequestDto({
    required this.reminderFrequency,
    required this.reminderWeekday,
    required this.reminderTime,
    required this.trashRetentionDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderFrequency': reminderFrequency.apiValue,
      'reminderWeekday': reminderWeekday,
      'reminderTime': reminderTime,
      'trashRetentionDays': trashRetentionDays,
    };
  }
}

class ExpiredPendingSummaryResponseDto {
  final int expiredPendingCount;
  final int trashedCount;
  final DateTime? nextReminderAt;

  const ExpiredPendingSummaryResponseDto({
    required this.expiredPendingCount,
    required this.trashedCount,
    required this.nextReminderAt,
  });

  factory ExpiredPendingSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return ExpiredPendingSummaryResponseDto(
      expiredPendingCount: (json['expiredPendingCount'] as num?)?.toInt() ?? 0,
      trashedCount: (json['trashedCount'] as num?)?.toInt() ?? 0,
      nextReminderAt: json['nextReminderAt'] != null
          ? DateTime.tryParse(json['nextReminderAt'] as String)
          : null,
    );
  }
}

