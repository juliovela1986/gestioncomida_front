import 'api_client.dart';

class MasterProductDto {
  final String id;
  final String canonicalName;
  final String? brand;
  final String? category;
  final String? unitType;

  MasterProductDto({
    required this.id,
    required this.canonicalName,
    this.brand,
    this.category,
    this.unitType,
  });

  factory MasterProductDto.fromJson(Map<String, dynamic> json) {
    return MasterProductDto(
      id: json['id'].toString(),
      canonicalName: json['canonicalName']?.toString() ?? '',
      brand: json['brand']?.toString(),
      category: json['category']?.toString(),
      unitType: json['unitType']?.toString(),
    );
  }
}

class MasterProductService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MasterProductDto>> search(String query, {int limit = 20}) async {
    final response = await _apiClient.dio.get(
      '/api/master-products/search',
      queryParameters: {'q': query, 'limit': limit},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MasterProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MasterProductDto> findOrCreate({
    required String canonicalName,
    String? brand,
    String? category,
    String? unitType,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/master-products/find-or-create',
      data: {
        'canonicalName': canonicalName,
        if (brand != null) 'brand': brand,
        if (category != null) 'category': category,
        if (unitType != null) 'unitType': unitType,
      },
    );
    return MasterProductDto.fromJson(response.data as Map<String, dynamic>);
  }
}
