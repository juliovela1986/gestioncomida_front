import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/app_globals.dart';
import 'api_client.dart';
import 'notification_navigation.dart';
import 'notification_refresh_service.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationRefreshService _notificationRefreshService = NotificationRefreshService.instance;

  FCMService(this.navigatorKey);

  /// Inicializar FCM y solicitar permisos
  Future<void> initialize() async {
    try {
      // Solicitar permisos (iOS principalmente)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('[FCM] ✅ Permisos concedidos');
        
        // Obtener token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          print('[FCM] 📱 Token obtenido: ${token.substring(0, 20)}...');
          await _sendTokenToBackend(token);
        }

        // Escuchar cambios de token
        _firebaseMessaging.onTokenRefresh.listen(_sendTokenToBackend);

        // Configurar handlers
        _setupMessageHandlers();
      } else {
        print('[FCM] ⚠️ Permisos denegados');
      }
    } catch (e) {
      print('[FCM] ❌ Error al inicializar: $e');
    }
  }

  /// Enviar token al backend
  Future<void> _sendTokenToBackend(String token) async {
    final payload = {
      'token': token,
      'deviceType': 'ANDROID',
    };

    final options = Options(
      extra: {'skip_auth_failure_handling': true},
    );

    try {
      await _apiClient.dio.post('/api/users/fcm-tokens', data: payload, options: options);
      print('[FCM] ✅ Token enviado al backend (/api/users/fcm-tokens)');
      return;
    } on DioException catch (e) {
      // Fallback por compatibilidad con backends que exponen la ruta singular.
      if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
        print('[FCM] ❌ Error al enviar token en endpoint plural: $e');
        return;
      }
    } catch (e) {
      print('[FCM] ❌ Error inesperado al enviar token en endpoint plural: $e');
      return;
    }

    try {
      await _apiClient.dio.post('/api/users/fcm-token', data: payload, options: options);
      print('[FCM] ✅ Token enviado al backend (/api/users/fcm-token)');
    } catch (e) {
      print('[FCM] ❌ Error al enviar token: $e');
    }
  }

  /// Configurar handlers de mensajes
  void _setupMessageHandlers() {
    // Mensaje recibido cuando app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] 📩 Mensaje recibido (foreground)');
      print('[FCM] Título: ${message.notification?.title}');
      print('[FCM] Cuerpo: ${message.notification?.body}');
      print('[FCM] Data: ${message.data}');
      
      // Refrescamos la campanita/listado aunque el usuario no navegue.
      _notificationRefreshService.notifyRefreshRequested();

      final type = message.data['type']?.toString();
      if (type == 'COMPARE_READY') {
        _showCompareReadyForegroundSnack();
      }
    });

    // Mensaje tocado cuando app está en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM] 📩 Notificación tocada (background)');
      _notificationRefreshService.notifyRefreshRequested();
      _handleMessage(message);
    });

    // Verificar si la app se abrió desde una notificación
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('[FCM] 📩 App abierta desde notificación');
        _notificationRefreshService.notifyRefreshRequested();
        _handleMessage(message);
      }
    });
  }

  /// Manejar mensaje recibido (SCRUM-174: deep link al producto si hay inventoryItemId)
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    if (type == null || type.isEmpty) {
      _navigateToNotifications();
      return;
    }

    print('[FCM] 🔔 Deep link type=$type item=${data['inventoryItemId']} screen=${data['screen']}');
    NotificationNavigation.open(
      context: navigatorKey.currentContext,
      alertType: type,
      inventoryItemId: data['inventoryItemId']?.toString(),
      pushNamed: (route, {arguments}) => _pushNamedWithRetry(route, arguments: arguments),
    ).then((_) {
      Future.delayed(
        const Duration(milliseconds: 250),
        _notificationRefreshService.notifyRefreshRequested,
      );
    });
  }

  void _showCompareReadyForegroundSnack() {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('Comparativa lista'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: _navigateToShoppingListCompare,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _navigateToShoppingListCompare() {
    _pushNamedWithRetry(
      '/shopping-list',
      arguments: const {'openCompareResults': true},
    );
    Future.delayed(
      const Duration(milliseconds: 250),
      _notificationRefreshService.notifyRefreshRequested,
    );
  }

  void _pushNamedWithRetry(String routeName, {Object? arguments}) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
    });
  }

  void _navigateToExpiredProducts() {
    _pushNamedWithRetry('/expired-products');
    Future.delayed(const Duration(milliseconds: 250), _notificationRefreshService.notifyRefreshRequested);
  }

  void _navigateToInventory() {
    _pushNamedWithRetry('/inventory');
    Future.delayed(const Duration(milliseconds: 250), _notificationRefreshService.notifyRefreshRequested);
  }

  void _navigateToNotifications() {
    _pushNamedWithRetry('/notifications');
    Future.delayed(const Duration(milliseconds: 250), _notificationRefreshService.notifyRefreshRequested);
  }

  /// Obtener token actual
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Eliminar todos los tokens del usuario (logout)
  Future<void> deleteToken() async {
    try {
      // Eliminar todos los tokens del backend
      await _apiClient.dio.delete('/api/users/fcm-tokens');
      print('[FCM] ✅ Todos los tokens eliminados del backend');
      
      // Eliminar token local
      await _firebaseMessaging.deleteToken();
      print('[FCM] 🗑️ Token eliminado localmente');
    } catch (e) {
      print('[FCM] ❌ Error al eliminar token: $e');
    }
  }
}

/// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] 📩 Mensaje recibido en background');
  print('[FCM] Título: ${message.notification?.title}');
  print('[FCM] Cuerpo: ${message.notification?.body}');
}
