import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show PlatformDispatcher;
import 'auth_service.dart';
import '../app_config.dart';
import '../core/app_exception.dart';
import '../core/app_globals.dart';

class ApiClient {
  ApiClient._internal() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final locale = await _resolveAcceptLanguage();
        options.headers['Accept-Language'] = locale;

        final token = await _authService.getValidAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('[ApiClient] 🔑 Token añadido: ${token.substring(0, 20)}...');
        } else {
          print('[ApiClient] ⚠️ No hay token disponible');
        }
        print('[ApiClient] 📤 ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        print('[ApiClient] ❌ Error: ${e.message}');
        print('[ApiClient] ❌ URL: ${e.requestOptions.uri}');
        print('[ApiClient] ❌ Status: ${e.response?.statusCode}');
        print('[ApiClient] ❌ Response: ${e.response?.data}');
        
        final alreadyRetried = e.requestOptions.extra['auth_retry'] == true;
        final skipAuthFailureHandling =
            e.requestOptions.extra['skip_auth_failure_handling'] == true;

        if (e.response?.statusCode == 401 && !alreadyRetried && !skipAuthFailureHandling) {
          print('[ApiClient] ⚠️ Token expirado (401), intentando refresh...');

          try {
            final newToken = await _authService.refreshToken();

            if (newToken != null) {
              if (_isMultipartRequest(e.requestOptions)) {
                await _handleSessionExpired(
                  const SessionExpiredException(
                    'Tu sesión ha caducado durante la subida del archivo. Vuelve a iniciar sesión e inténtalo de nuevo.',
                  ),
                );
                return handler.reject(
                  DioException(
                    requestOptions: e.requestOptions,
                    error: const SessionExpiredException(
                      'Tu sesión ha caducado durante la subida del archivo. Vuelve a iniciar sesión e inténtalo de nuevo.',
                    ),
                    response: e.response,
                    type: DioExceptionType.badResponse,
                  ),
                );
              }

              try {
                final retryResponse = await _retryRequest(e.requestOptions, newToken);
                print('[ApiClient] ✅ Petición reintentada tras refresh correcto.');
                return handler.resolve(retryResponse);
              } on DioException catch (retryError) {
                print('[ApiClient] ❌ Falló el reintento tras refresh: ${retryError.message}');
              }
            }
          } on SessionExpiredException catch (sessionError) {
            await _handleSessionExpired(sessionError);
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: sessionError,
                response: e.response,
                type: DioExceptionType.badResponse,
              ),
            );
          }

          await _handleSessionExpired(const SessionExpiredException());
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: const SessionExpiredException(),
              response: e.response,
              type: DioExceptionType.badResponse,
            ),
          );
        }
        return handler.next(e);
      },
    ));
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.backendUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 120),
  ));

  final AuthService _authService = AuthService();
  DateTime? _lastSessionExpiredNotificationAt;

  Future<String> _resolveAcceptLanguage() async {
    const supportedLanguages = <String>{'en', 'ca', 'es'};

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = (prefs.getString('locale') ?? '').trim();
      if (savedLocale.isNotEmpty) {
        return supportedLanguages.contains(savedLocale) ? savedLocale : 'es';
      }
    } catch (_) {
      // Fallback al locale del dispositivo si no podemos leer preferencias.
    }

    final deviceLocale = PlatformDispatcher.instance.locale.languageCode.trim();
    if (deviceLocale.isNotEmpty && supportedLanguages.contains(deviceLocale)) {
      return deviceLocale;
    }

    return 'es';
  }

  bool _isMultipartRequest(RequestOptions requestOptions) {
    return requestOptions.data is FormData;
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions, String token) async {
    requestOptions.headers['Authorization'] = 'Bearer $token';
    requestOptions.extra['auth_retry'] = true;
    return _dio.fetch<dynamic>(requestOptions);
  }

  Future<void> _handleSessionExpired(SessionExpiredException exception) async {
    await _authService.logout();

    final now = DateTime.now();
    final shouldNotify = _lastSessionExpiredNotificationAt == null ||
        now.difference(_lastSessionExpiredNotificationAt!) > const Duration(seconds: 5);

    if (shouldNotify) {
      _lastSessionExpiredNotificationAt = now;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(exception.message),
          backgroundColor: const Color(0xFFD32F2F),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Dio get dio => _dio;
}
