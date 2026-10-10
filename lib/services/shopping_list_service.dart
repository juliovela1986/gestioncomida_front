import '../models/shopping_list_comparison.dart';
import '../models/shopping_list_item.dart';
import 'api_client.dart';

class ShoppingListService {
  final ApiClient _apiClient = ApiClient();

  static const int defaultPageSize = 5;
  static const int defaultFreshnessDays = 14;
  static const int maxBatchSize = 10;

  Future<ShoppingListPageDto> getShoppingList({
    int page = 0,
    int size = defaultPageSize,
    String sort = 'createdInstant,desc',
  }) async {
    final response = await _apiClient.dio.get(
      '/api/v1/shopping-list',
      queryParameters: {
        'page': page,
        'size': size,
        'sort': sort,
      },
    );

    final data = response.data;
    if (data is List) {
      // Compat legacy: array sin paginar.
      final items = data
          .map((e) => ShoppingListItemDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return ShoppingListPageDto(
        content: items,
        totalElements: items.length,
        totalPages: 1,
        number: 0,
        size: items.length,
        first: true,
        last: true,
        empty: items.isEmpty,
      );
    }

    return ShoppingListPageDto.fromJson(data as Map<String, dynamic>);
  }

  Future<ShoppingListItemDto> addItem(ShoppingListItemRequestDto request) async {
    final response = await _apiClient.dio.post(
      '/api/v1/shopping-list',
      data: request.toJson(),
    );
    return ShoppingListItemDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ShoppingListItemDto> updateItem(
    String itemId,
    ShoppingListItemRequestDto request,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/shopping-list/$itemId',
      data: request.toJson(),
    );
    return ShoppingListItemDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteItem(String itemId) async {
    await _apiClient.dio.delete('/api/v1/shopping-list/$itemId');
  }

  Future<ShoppingListComparisonResponseDto> compareBatch(
    CompareBatchRequestDto request,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/shopping-list/compare-batch',
      data: request.toJson(),
    );
    final parsed = ShoppingListComparisonResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
    print(
      '[ShoppingListService] 📥 ${response.statusCode} compare-batch '
      'pending=${parsed.pendingCount} ready=${parsed.readyCount} '
      'unavailable=${parsed.unavailableCount} jobsEnqueued=${parsed.jobsEnqueued}',
    );
    return parsed;
  }
}
