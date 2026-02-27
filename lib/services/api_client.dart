import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.143:8081',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  final AuthService _authService = AuthService();

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
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
}
