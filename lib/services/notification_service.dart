import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/notification.dart';

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationResponseDto>> getAllNotifications() async {
    final response = await _apiClient.dio.get('/api/notifications');
    return (response.data as List).map((e) => NotificationResponseDto.fromJson(e)).toList();
  }

  Future<NotificationResponseDto> getNotificationById(String id) async {
    final response = await _apiClient.dio.get('/api/notifications/$id');
    return NotificationResponseDto.fromJson(response.data);
  }

  Future<List<NotificationResponseDto>> getByStatus(String status) async {
    final response = await _apiClient.dio.get('/api/notifications/by-status/$status');
    return (response.data as List).map((e) => NotificationResponseDto.fromJson(e)).toList();
  }

  Future<List<NotificationResponseDto>> getByAlertType(String alertType) async {
    final response = await _apiClient.dio.get('/api/notifications/by-alert-type/$alertType');
    return (response.data as List).map((e) => NotificationResponseDto.fromJson(e)).toList();
  }

  Future<NotificationResponseDto> markAsRead(String id) async {
    final response = await _apiClient.dio.put('/api/notifications/$id/mark-read');
    return NotificationResponseDto.fromJson(response.data);
  }
}
