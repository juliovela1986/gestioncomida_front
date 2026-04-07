import 'api_client.dart';
import '../models/price_insights.dart';

class PriceInsightsService {
  final ApiClient _apiClient = ApiClient();

  Future<SupermarketComparisonDto> compareSupermarkets({
    required String productId,
    int days = 90,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/price-insights/supermarkets/compare',
        queryParameters: {
          'productId': productId,
          'days': days,
        },
      );
      return SupermarketComparisonDto.fromJson(response.data);
    } catch (e) {
      print('Error al comparar supermercados: $e');
      rethrow;
    }
  }

  Future<ProductPriceTrendDto> getProductTrend({
    required String productId,
    int days = 90,
    String? supermarket,
  }) async {
    try {
      final queryParams = {
        'productId': productId,
        'days': days,
      };
      if (supermarket != null) {
        queryParams['supermarket'] = supermarket;
      }

      final response = await _apiClient.dio.get(
        '/api/price-insights/products/$productId/trend',
        queryParameters: queryParams,
      );
      return ProductPriceTrendDto.fromJson(response.data);
    } catch (e) {
      print('Error al obtener tendencia de precio: $e');
      rethrow;
    }
  }

  Future<List<TrackedProductDto>> getTrackedProducts({int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/price-insights/products/tracked',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((e) => TrackedProductDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener productos trackeados: $e');
      rethrow;
    }
  }

  Future<PriceOverviewDto> getOverview({
    int days = 30,
    int top = 5,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/price-insights/overview',
        queryParameters: {
          'days': days,
          'top': top,
        },
      );
      return PriceOverviewDto.fromJson(response.data);
    } catch (e) {
      print('Error al obtener resumen de precios: $e');
      rethrow;
    }
  }
}

