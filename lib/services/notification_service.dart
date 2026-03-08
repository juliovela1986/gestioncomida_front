import 'package:dio/dio.dart';
import '../models/notification.dart';

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<List<NotificationModel>> getUserNotifications() async {
    final response = await _dio.get('/api/notifications/user');
    return (response.data as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
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
}
