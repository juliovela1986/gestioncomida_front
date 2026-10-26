import 'package:dio/dio.dart';
import '../models/notification.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<NotificationModel>> getUserNotifications() async {
    final response = await _dio.get('/api/notifications/user');
    final raw = response.data;
    if (raw is! List) return <NotificationModel>[];

    final notifications = raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    notifications.sort((a, b) => b.createdInstant.compareTo(a.createdInstant));
    return notifications;
  }

  Future<int> getUnreadCount() async {
    final notifications = await getUserNotifications();
    return notifications.where((n) => n.status != 'READ').length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.put('/api/notifications/$notificationId/mark-read');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _dio.delete('/api/notifications/$notificationId');
  }

  Future<List<NotificationModel>> getByStatus(String status) async {
    final response = await _dio.get('/api/notifications/by-status/$status');
    final raw = response.data;
    if (raw is! List) return <NotificationModel>[];

    final notifications = raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    notifications.sort((a, b) => b.createdInstant.compareTo(a.createdInstant));
    return notifications;
  }

  Future<List<NotificationModel>> getByStatusAndType(String status, String alertType) async {
    final response = await _dio.get('/api/notifications/by-status-and-type/$status/$alertType');
    final raw = response.data;
    if (raw is! List) return <NotificationModel>[];

    final notifications = raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    notifications.sort((a, b) => b.createdInstant.compareTo(a.createdInstant));
    return notifications;
  }

  Future<List<NotificationModel>> getByAlertType(String alertType) async {
    final response = await _dio.get('/api/notifications/by-alert-type/$alertType');
    final raw = response.data;
    if (raw is! List) return <NotificationModel>[];

    final notifications = raw
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    notifications.sort((a, b) => b.createdInstant.compareTo(a.createdInstant));
    return notifications;
  }

  Future<void> markAsSent(String notificationId) async {
    await _dio.put('/api/notifications/$notificationId/mark-sent');
  }

  Future<void> markAsFailed(String notificationId, String reason) async {
    await _dio.put(
      '/api/notifications/$notificationId/mark-failed',
      queryParameters: {'reason': reason},
    );
  }
}
