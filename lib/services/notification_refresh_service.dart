import 'dart:async';

/// Bus global ligero para forzar refresco de notificaciones desde cualquier flujo.
class NotificationRefreshService {
  NotificationRefreshService._();

  static final NotificationRefreshService instance = NotificationRefreshService._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notifyRefreshRequested() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}

