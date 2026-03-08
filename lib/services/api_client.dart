import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../app_config.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.backendUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 120),
  ));

  final AuthService _authService = AuthService();
  bool _isRefreshing = false;

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('[ApiClient] 🔑 Token añadido: ${token.substring(0, 20)}...');
        } else {
          print('[ApiClient] ⚠️ No hay token disponible');
        }
        print('[ApiClient] 📤 ${options.method} ${options.path}');
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          print('[ApiClient] ⚠️ Token expirado (401), intentando refresh...');
          
          try {
            final newToken = await _authService.refreshToken();
            
            if (newToken != null) {
              print('[ApiClient] ✅ Token refrescado, la petición debe ser reintentada manualmente.');
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  error: 'token-refreshed-retry-manually',
                  response: e.response,
                  type: DioExceptionType.unknown,
                ),
              );
            }
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
