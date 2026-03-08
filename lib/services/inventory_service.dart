import 'api_client.dart';
import '../models/inventory_item.dart';
import '../models/pending_expiration_item.dart';
import '../models/grouped_inventory.dart';

class InventoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<InventoryItemResponseDto>> getUserInventory() async {
    final response = await _apiClient.dio.get('/api/inventory');
    return (response.data as List).map((e) => InventoryItemResponseDto.fromJson(e)).toList();
  }

  Future<List<InventoryItemResponseDto>> getItemsWithExpiration() async {
    final response = await _apiClient.dio.get('/api/inventory/with-expiration');
    return (response.data as List).map((e) => InventoryItemResponseDto.fromJson(e)).toList();
  }

  Future<InventoryItemResponseDto> getItem(String id) async {
    final response = await _apiClient.dio.get('/api/inventory/$id');
    return InventoryItemResponseDto.fromJson(response.data);
  }

  Future<InventoryItemResponseDto> createItem(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/api/inventory', data: data);
    return InventoryItemResponseDto.fromJson(response.data);
  }

  Future<InventoryItemResponseDto> updateItem(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/api/inventory/$id', data: data);
    return InventoryItemResponseDto.fromJson(response.data);
  }

  Future<void> deleteItem(String id) async {
    await _apiClient.dio.delete('/api/inventory/$id');
  }

  Future<List<PendingExpirationItemDto>> getPendingExpirationItems() async {
    final response = await _apiClient.dio.get('/api/inventory/pending-expiration');
    return (response.data as List).map((e) => PendingExpirationItemDto.fromJson(e)).toList();
  }

  Future<List<GroupedInventoryResponse>> getGroupedInventory() async {
    print('[InventoryService] 🔵 Llamando a GET /api/inventory/grouped');
    try {
      final response = await _apiClient.dio.get('/api/inventory/grouped');
      print('[InventoryService] ✅ Respuesta recibida: ${response.statusCode}');
      print('[InventoryService] 📦 Data type: ${response.data.runtimeType}');
      print('[InventoryService] 📦 Data length: ${(response.data as List).length}');
      print('[InventoryService] 📦 First item: ${(response.data as List).isNotEmpty ? (response.data as List).first : "empty"}');
      
      final result = (response.data as List)
          .map((e) {
            try {
              return GroupedInventoryResponse.fromJson(e as Map<String, dynamic>);
            } catch (parseError) {
              print('[InventoryService] ❌ Error parseando item: $e');
              print('[InventoryService] ❌ Parse error: $parseError');
              rethrow;
            }
          })
          .toList();
      
      print('[InventoryService] ✅ Parseado exitoso: ${result.length} productos');
      return result;
    } catch (e, stackTrace) {
      print('[InventoryService] ❌ Error en getGroupedInventory: $e');
      print('[InventoryService] 📍 StackTrace: $stackTrace');
      rethrow;
    }
  }
}
