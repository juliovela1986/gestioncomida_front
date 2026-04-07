import 'api_client.dart';
import '../models/pending_expiration_item.dart';

class CleanupPreferencesService {
  final ApiClient _apiClient = ApiClient();

  Future<CleanupPreferencesResponseDto> getCleanupPreferences() async {
    final response = await _apiClient.dio.get('/api/users/cleanup-preferences');
    return CleanupPreferencesResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CleanupPreferencesResponseDto> updateCleanupPreferences(
    CleanupPreferencesUpdateRequestDto request,
  ) async {
    final response = await _apiClient.dio.put(
      '/api/users/cleanup-preferences',
      data: request.toJson(),
    );
    return CleanupPreferencesResponseDto.fromJson(response.data as Map<String, dynamic>);
  }
}

