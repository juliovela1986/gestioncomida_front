import 'api_client.dart';
import '../models/inventory_item.dart';
import '../models/pending_expiration_item.dart';
import '../models/grouped_inventory.dart';
import 'location_service.dart';

class InventoryService {
  final ApiClient _apiClient = ApiClient();
  final LocationService _locationService = LocationService();

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

  Future<List<ExpiredPendingItemDto>> getExpiredPendingItems({
    bool includeSnoozed = false,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/inventory/expired-pending',
      queryParameters: {'includeSnoozed': includeSnoozed},
    );

    return (response.data as List)
        .map((e) => ExpiredPendingItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpiredPendingBulkActionResponseDto> applyExpiredPendingBulkAction(
    ExpiredPendingBulkActionRequestDto request,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/inventory/expired-pending/actions',
      data: request.toJson(),
    );

    return ExpiredPendingBulkActionResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<ExpiredPendingItemDto>> getTrashItems() async {
    final response = await _apiClient.dio.get('/api/inventory/trash');

    return (response.data as List)
        .map((e) => ExpiredPendingItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpiredPendingBulkActionResponseDto> restoreTrashItems(
    InventoryTrashBulkRequestDto request,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/inventory/trash/restore',
      data: request.toJson(),
    );

    return ExpiredPendingBulkActionResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ExpiredPendingBulkActionResponseDto> deleteTrashItems(
    InventoryTrashBulkRequestDto request,
  ) async {
    final response = await _apiClient.dio.delete(
      '/api/inventory/trash/items',
      data: request.toJson(),
    );

    return ExpiredPendingBulkActionResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ExpiredPendingSummaryResponseDto> getExpiredPendingSummary() async {
    final response = await _apiClient.dio.get('/api/inventory/expired-pending/summary');

    return ExpiredPendingSummaryResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<GroupedInventoryResponse>> getGroupedInventory() async {
    print('[InventoryService] 🔵 Llamando a GET /api/inventory/grouped');
    try {
      final response = await _apiClient.dio.get('/api/inventory/grouped');
      print('[InventoryService] ✅ Respuesta recibida: ${response.statusCode}');
      print('[InventoryService] 📦 Data type: ${response.data.runtimeType}');
      print('[InventoryService] 📦 Data length: ${(response.data as List).length}');
      print('[InventoryService] 📦 First item: ${(response.data as List).isNotEmpty ? (response.data as List).first : "empty"}');
      
      final grouped = (response.data as List)
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

      final result = await _enrichLotsWithLocationName(grouped);
      
      print('[InventoryService] ✅ Parseado exitoso: ${result.length} productos');
      return result;
    } catch (e, stackTrace) {
      print('[InventoryService] ❌ Error en getGroupedInventory: $e');
      print('[InventoryService] 📍 StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<List<GroupedInventoryResponse>> _enrichLotsWithLocationName(
    List<GroupedInventoryResponse> grouped,
  ) async {
    // Si backend ya envía nombres en los lotes, no hacemos llamadas extra.
    final hasAllLocationNames = grouped.every(
      (product) => product.lots.every(
        (lot) => lot.locationName != null && lot.locationName!.isNotEmpty,
      ),
    );
    if (hasAllLocationNames) return grouped;

    try {
      final inventoryItems = await getUserInventory();
      final locations = await _locationService.getUserLocations();

      final locationNameById = {
        for (final loc in locations) if (loc.id.isNotEmpty) loc.id: loc.name,
      };
      final itemById = {
        for (final item in inventoryItems) if (item.id.isNotEmpty) item.id: item,
      };

      return grouped
          .map(
            (product) => GroupedInventoryResponse(
              catalogProductId: product.catalogProductId,
              productName: product.productName,
              productBrand: product.productBrand,
              totalQuantity: product.totalQuantity,
              lotCount: product.lotCount,
              nextExpirationDate: product.nextExpirationDate,
              lots: product.lots.map((lot) {
                final item = itemById[lot.inventoryItemId];
                final resolvedLocationId = lot.locationId ?? item?.locationId;
                final resolvedLocationName =
                    lot.locationName ??
                    (resolvedLocationId != null
                        ? locationNameById[resolvedLocationId]
                        : null);

                return lot.copyWith(
                  locationId: resolvedLocationId,
                  locationName: resolvedLocationName,
                );
              }).toList(),
            ),
          )
          .toList();
    } catch (e) {
      print('[InventoryService] ⚠️ No se pudo enriquecer ubicación: $e');
      return grouped;
    }
  }
}
