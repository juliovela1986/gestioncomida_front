import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/inventory_item.dart';

class InventoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<InventoryItemResponseDto>> getUserInventory() async {
    final response = await _apiClient.dio.get('/api/inventory');
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
}
