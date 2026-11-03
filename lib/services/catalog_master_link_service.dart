import 'api_client.dart';

class CatalogMasterLinkService {
  final ApiClient _apiClient = ApiClient();

  /// Vincula catalog → master. Con [createIfMissing] crea el maestro si no existe.
  Future<Map<String, dynamic>> linkMaster({
    required String catalogProductId,
    String? masterProductId,
    String? masterCanonicalName,
    bool createIfMissing = false,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/catalog-products/$catalogProductId/link-master',
      data: {
        if (masterProductId != null) 'masterProductId': masterProductId,
        if (masterCanonicalName != null) 'masterCanonicalName': masterCanonicalName,
        'createIfMissing': createIfMissing,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
