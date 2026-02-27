import 'package:dio/dio.dart';
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
}
