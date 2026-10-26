import 'api_client.dart';
import '../models/price_insights.dart';

class PriceInsightsService {
  final ApiClient _apiClient = ApiClient();

  Future<SupermarketComparisonDto> compareSupermarkets({
    required String productId,
    int days = 90,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'productId': productId,
        'days': days,
      };
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (order != null) queryParams['order'] = order;

      final response = await _apiClient.dio.get(
        '/api/price-insights/supermarkets/compare',
        queryParameters: queryParams,
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
    String? startDate,
    String? endDate,
    int? minSamples,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{'days': days};
      if (supermarket != null) queryParams['supermarket'] = supermarket;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (minSamples != null) queryParams['minSamples'] = minSamples;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (order != null) queryParams['order'] = order;

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

  Future<TrackedProductsPageDto> getTrackedProducts({
    int limit = 50,
    int offset = 0,
    String? search,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (order != null) queryParams['order'] = order;

      final response = await _apiClient.dio.get(
        '/api/price-insights/products/tracked',
        queryParameters: queryParams,
      );
      return TrackedProductsPageDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error al obtener productos trackeados: $e');
      rethrow;
    }
  }

  Future<PriceOverviewDto> getOverview({
    int days = 30,
    int top = 5,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'days': days,
        'top': top,
      };
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (order != null) queryParams['order'] = order;

      final response = await _apiClient.dio.get(
        '/api/price-insights/overview',
        queryParameters: queryParams,
      );
      return PriceOverviewDto.fromJson(response.data);
    } catch (e) {
      print('Error al obtener resumen de precios: $e');
      rethrow;
    }
  }
}

