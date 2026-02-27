
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../screens/login_webview_screen.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Cache en memoria para el token de acceso
  String? _inMemoryToken;

  final String _clientId = 'gestioncomida-mobile';
  final List<String> _scopes = ['openid', 'profile', 'email'];
  final String _redirectUrl = 'com.gestioncomida.app://callback';
  final String _issuer = 'http://192.168.1.143:8180/realms/gestioncomida';
  final String _discoveryUrl = 'http://192.168.1.143:8180/realms/gestioncomida/.well-known/openid-configuration';

  String _generateRandomString(int len) {
    final random = Random.secure();
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(len, (index) => charset[random.nextInt(charset.length)]).join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    var bytes = utf8.encode(codeVerifier);
    var digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<String?> login(BuildContext context) async {
    try {
      print('[Auth] 🔑 Iniciando proceso de login');
      await _storage.deleteAll();
      _inMemoryToken = null;
      print('[Auth] ✅ Storage y cache en memoria limpiados');

      final dio = Dio();
      final discoveryResponse = await dio.get(_discoveryUrl);
      final authEndpoint = discoveryResponse.data['authorization_endpoint'];
      final tokenEndpoint = discoveryResponse.data['token_endpoint'];

      final state = _generateRandomString(16);
      final codeVerifier = _generateRandomString(128);
      await _storage.write(key: 'code_verifier', value: codeVerifier);
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final authUrl = '$authEndpoint?'
          'client_id=$_clientId&'
          'redirect_uri=$_redirectUrl&'
          'response_type=code&'
          'scope=${_scopes.join(' ')}&'
          'state=$state&'
          'code_challenge=$codeChallenge&'
          'code_challenge_method=S256&'
          'prompt=login';
      
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => LoginWebViewScreen(
            initialUrl: authUrl,
            onRedirect: (redirectUrl) async {
                final uri = Uri.parse(redirectUrl);
                final returnedCode = uri.queryParameters['code'];
                final returnedState = uri.queryParameters['state'];

                if (returnedState == state && returnedCode != null) {
                    try {
                        final storedCodeVerifier = await _storage.read(key: 'code_verifier');
                        final response = await dio.post(
                            tokenEndpoint,
                            data: {
                                'grant_type': 'authorization_code',
                                'client_id': _clientId,
                                'code': returnedCode,
                                'redirect_uri': _redirectUrl,
                                'code_verifier': storedCodeVerifier,
                            },
                            options: Options(contentType: Headers.formUrlEncodedContentType),
                        );

                        if (response.statusCode == 200 && response.data['access_token'] != null) {
                            final token = response.data['access_token'];
                            final refreshToken = response.data['refresh_token'];
                            
                            await _saveTokens(token, refreshToken);
                            
                            print('[Auth] ✅ Token obtenido y guardado exitosamente');
                            return token; // Devolvemos el token
                        }
                    } catch (e) {
                        print('[Auth] ❌ Error al canjear código: $e');
                    }
                }
                return null; // Devolvemos null si falla
            },
          ),
        ),
      );
      
      return result;

    } catch (e) {
      print('[Auth] ❌ Error general: $e');
      return null;
    }
  }

  Future<void> _saveTokens(String? accessToken, String? refreshToken) async {
    _inMemoryToken = accessToken; // Guardamos en memoria
    if (accessToken != null) {
      await _storage.write(key: 'access_token', value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<String?> getToken() async {
    // Primero intentamos obtener el token de la memoria
    if (_inMemoryToken != null) {
      return _inMemoryToken;
    }
    // Si no está en memoria, lo leemos del storage
    _inMemoryToken = await _storage.read(key: 'access_token');
    return _inMemoryToken;
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  Future<String?> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      print('[Auth] 🔄 Refrescando token...');
      final dio = Dio();
      final discoveryResponse = await dio.get(_discoveryUrl);
      final tokenEndpoint = discoveryResponse.data['token_endpoint'];

      final response = await dio.post(
        tokenEndpoint,
        data: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'refresh_token': refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        final newToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        
        await _saveTokens(newToken, newRefreshToken); // Guardamos los nuevos tokens
        
        print('[Auth] ✅ Token refrescado exitosamente');
        return newToken;
      }
    } catch (e) {
      print('[Auth] ❌ Error al refrescar token: $e');
    }
    return null;
  }
}
