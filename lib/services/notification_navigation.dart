import 'package:flutter/material.dart';
import '../models/grouped_inventory.dart';
import '../models/notification.dart';
import '../screens/product_lots_screen.dart';
import 'inventory_service.dart';

/// Deep link unificado para lista in-app y FCM (SCRUM-171 / SCRUM-174).
class NotificationNavigation {
  NotificationNavigation._();

  static Future<void> openFromModel(
    BuildContext context,
    NotificationModel notification, {
    required void Function(String route, {Object? arguments}) pushNamed,
  }) {
    return open(
      context: context,
      alertType: notification.alertType,
      inventoryItemId: notification.inventoryItemId,
      pushNamed: pushNamed,
    );
  }

  static Future<void> open({
    BuildContext? context,
    required String alertType,
    String? inventoryItemId,
    required void Function(String route, {Object? arguments}) pushNamed,
    Future<List<GroupedInventoryResponse>> Function()? loadGroupedInventory,
  }) async {
    if (alertType == 'COMPARE_READY') {
      pushNamed('/shopping-list', arguments: const {'openCompareResults': true});
      return;
    }

    final itemId = inventoryItemId?.trim();
    if (itemId != null && itemId.isNotEmpty && context != null && context.mounted) {
      final opened = await _openProductLots(
        context,
        itemId,
        loadGroupedInventory: loadGroupedInventory,
      );
      if (opened) return;
    }

    switch (alertType) {
      case 'EXPIRED':
      case 'EXPIRATION_WARNING':
      case 'EXPIRING_TOMORROW':
      case 'WASTE_RISK_WEEK':
        pushNamed(itemId != null && itemId.isNotEmpty ? '/inventory' : '/expired-products');
        break;
      case 'PRICE_DROP':
      case 'LOW_STOCK':
      case 'OUT_OF_STOCK':
      case 'REMINDER':
        pushNamed('/inventory');
        break;
      default:
        pushNamed('/notifications');
    }
  }

  static Future<bool> _openProductLots(
    BuildContext context,
    String inventoryItemId, {
    Future<List<GroupedInventoryResponse>> Function()? loadGroupedInventory,
  }) async {
    try {
      final loader = loadGroupedInventory ?? () => InventoryService().getGroupedInventory();
      final products = await loader();
      GroupedInventoryResponse? match;
      for (final product in products) {
        if (product.lots.any((lot) => lot.inventoryItemId == inventoryItemId)) {
          match = product;
          break;
        }
      }
      if (match == null || !context.mounted) return false;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductLotsScreen(product: match!)),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
