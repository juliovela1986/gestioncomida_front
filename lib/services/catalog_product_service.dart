import 'api_client.dart';
import '../models/catalog_product.dart';

class CatalogProductService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CatalogProductResponseDto>> getAllProducts() async {
    final response = await _apiClient.dio.get('/api/catalog-products');
    return (response.data as List).map((e) => CatalogProductResponseDto.fromJson(e)).toList();
  }

  Future<CatalogProductResponseDto> getProductById(String id) async {
    final response = await _apiClient.dio.get('/api/catalog-products/$id');
    return CatalogProductResponseDto.fromJson(response.data);
  }

  Future<List<CatalogProductResponseDto>> searchByName(String name) async {
    final response = await _apiClient.dio.get('/api/catalog-products/search/by-name', queryParameters: {'name': name});
    return (response.data as List).map((e) => CatalogProductResponseDto.fromJson(e)).toList();
  }

  Future<List<CatalogProductResponseDto>> searchByBrand(String brand) async {
    final response = await _apiClient.dio.get('/api/catalog-products/search/by-brand', queryParameters: {'brand': brand});
    return (response.data as List).map((e) => CatalogProductResponseDto.fromJson(e)).toList();
  }

  Future<bool> existsByNameAndBrand(String name, String brand) async {
    final response = await _apiClient.dio.get(
      '/api/catalog-products/exists',
      queryParameters: {'name': name, 'brand': brand},
    );
    return response.data as bool;
  }

  Future<CatalogProductResponseDto> findOrCreateProduct(Map<String, dynamic> searchData) async {
    final response = await _apiClient.dio.post('/api/catalog-products/search-or-create', data: searchData);
    return CatalogProductResponseDto.fromJson(response.data);
  }

  Future<CatalogProductResponseDto> createProduct(Map<String, dynamic> data) async {
    final response = await _apiClient.dio.post('/api/catalog-products', data: data);
    return CatalogProductResponseDto.fromJson(response.data);
  }

  Future<CatalogProductResponseDto> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/api/catalog-products/$id', data: data);
    return CatalogProductResponseDto.fromJson(response.data);
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.dio.delete('/api/catalog-products/$id');
  }
}
