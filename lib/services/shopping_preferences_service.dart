import 'api_client.dart';
import '../models/shopping_preferences.dart';

class ShoppingPreferencesService {
  final ApiClient _apiClient = ApiClient();

  Future<ShoppingPreferencesResponseDto> getShoppingPreferences() async {
    final response = await _apiClient.dio.get('/api/users/shopping-preferences');
    return ShoppingPreferencesResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ShoppingPreferencesResponseDto> updateShoppingPreferences(
    ShoppingPreferencesUpdateRequestDto request,
  ) async {
    final response = await _apiClient.dio.put(
      '/api/users/shopping-preferences',
      data: request.toJson(),
    );
    return ShoppingPreferencesResponseDto.fromJson(response.data as Map<String, dynamic>);
  }
}
