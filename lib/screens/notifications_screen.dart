import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../core/error_utils.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/notification_refresh_service.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  final NotificationRefreshService _notificationRefreshService = NotificationRefreshService.instance;
  StreamSubscription<void>? _refreshSubscription;
  List<NotificationModel> _notifications = [];
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(ApiClient().dio);
    _loadNotifications();
    _refreshSubscription = _notificationRefreshService.stream.listen((_) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getUserNotifications();
      setState(() {
        _notifications = notifications;
        _selectedIds.removeWhere((id) => !_notifications.any((n) => n.id == id));
        if (_selectedIds.isEmpty) {
          _selectionMode = false;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudieron cargar las notificaciones.'))),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      } else {
        _selectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..addAll(_notifications.map((n) => n.id));
    });
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _notificationService.markAsRead(notification.id);
      await _loadNotifications();
      _notificationRefreshService.notifyRefreshRequested();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudo marcar como leída.'))),
        );
      }
    }
  }

  Future<void> _markSelectedAsRead() async {
    if (_selectedIds.isEmpty || _isBusy) return;
    setState(() => _isBusy = true);
    try {
      await _notificationService.markAsReadBatch(_selectedIds.toList());
      _selectedIds.clear();
      _selectionMode = false;
      await _loadNotifications();
      _notificationRefreshService.notifyRefreshRequested();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificaciones marcadas como vistas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudieron marcar como vistas.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta notificación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _notificationService.deleteNotification(notification.id);
        await _loadNotifications();
        _notificationRefreshService.notifyRefreshRequested();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificación eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudo eliminar la notificación.'))),
          );
        }
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty || _isBusy) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar seleccionadas'),
        content: Text('¿Eliminar $count notificación${count == 1 ? '' : 'es'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isBusy = true);
    try {
      await _notificationService.deleteBatch(_selectedIds.toList());
      _selectedIds.clear();
      _selectionMode = false;
      await _loadNotifications();
      _notificationRefreshService.notifyRefreshRequested();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count eliminada${count == 1 ? '' : 's'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudieron eliminar.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Color _getAlertColor(String alertType) {
    switch (alertType) {
      case 'EXPIRATION_WARNING':
        return Colors.orange;
      case 'EXPIRED':
        return Colors.red;
      case 'LOW_STOCK':
        return Colors.amber;
      case 'COMPARE_READY':
        return Colors.teal;
      case 'PRICE_DROP':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType) {
      case 'EXPIRATION_WARNING':
        return Icons.warning_amber;
      case 'EXPIRED':
        return Icons.error;
      case 'LOW_STOCK':
        return Icons.inventory_2;
      case 'COMPARE_READY':
        return Icons.compare_arrows;
      case 'PRICE_DROP':
        return Icons.trending_down;
      default:
        return Icons.notifications;
    }
  }

  String _getAlertTitle(String alertType) {
    switch (alertType) {
      case 'EXPIRATION_WARNING':
        return 'Próximo a caducar';
      case 'EXPIRED':
        return 'Producto caducado';
      case 'LOW_STOCK':
        return 'Stock bajo';
      case 'COMPARE_READY':
        return 'Comparativa lista';
      case 'PRICE_DROP':
        return 'Bajada de precio';
      case 'REMINDER':
        return 'Recordatorio';
      default:
        return 'Notificación';
    }
  }

  Future<void> _openNotificationDetail(NotificationModel notification) async {
    if (_selectionMode) {
      _toggleSelected(notification.id);
      return;
    }

    if (notification.status != 'READ') {
      await _markAsRead(notification);
    }
    if (!mounted) return;

    if (notification.alertType == 'COMPARE_READY') {
      Navigator.pushNamed(
        context,
        '/shopping-list',
        arguments: const {'openCompareResults': true},
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getAlertTitle(notification.alertType)),
        content: Text(notification.reason?.trim().isNotEmpty == true ? notification.reason! : 'Sin mensaje'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIds.length} seleccionadas' : 'Notificaciones'),
        backgroundColor: Colors.green,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
                tooltip: 'Cancelar selección',
              )
            : null,
        actions: [
          if (!_selectionMode && _notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Seleccionar',
              onPressed: _toggleSelectionMode,
            ),
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Seleccionar todas',
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar como vistas',
              onPressed: hasSelection && !_isBusy ? _markSelectedAsRead : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: hasSelection && !_isBusy ? _deleteSelected : null,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay notificaciones', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isUnread = notification.status != 'READ';
                      final color = _getAlertColor(notification.alertType);
                      final selected = _selectedIds.contains(notification.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: selected
                            ? Colors.green.withValues(alpha: 0.15)
                            : (isUnread ? color.withValues(alpha: 0.1) : null),
                        child: ListTile(
                          onTap: () => _openNotificationDetail(notification),
                          onLongPress: () {
                            setState(() {
                              _selectionMode = true;
                              _selectedIds.add(notification.id);
                            });
                          },
                          leading: _selectionMode
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) => _toggleSelected(notification.id),
                                )
                              : Icon(_getAlertIcon(notification.alertType), color: color, size: 32),
                          title: Text(
                            _getAlertTitle(notification.alertType),
                            style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notification.reason != null) Text(notification.reason!),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(notification.scheduledAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: _selectionMode
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isUnread)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline),
                                        onPressed: () => _markAsRead(notification),
                                        tooltip: 'Marcar como leída',
                                      )
                                    else
                                      const Icon(Icons.check_circle, color: Colors.grey),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteNotification(notification),
                                      tooltip: 'Eliminar',
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
