import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/preferences_service.dart';
import '../services/notification_refresh_service.dart';
import 'home_tab.dart';
import 'inventory_tab.dart'; // Volvemos a usar la pestaña de menú para Inventario
import 'tickets_history_screen.dart';
import 'shopping_tab.dart';
import 'more_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final NotificationRefreshService _notificationRefreshService = NotificationRefreshService.instance;
  
  // Clave para forzar el refresco de los datos en tickets
  Key _ticketsKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationRefreshService.notifyRefreshRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prefs = Provider.of<PreferencesService>(context);

    return Scaffold(
      key: ValueKey(prefs.locale.languageCode), 
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeTab(),
          const InventoryTab(), // Aquí es donde están los botones de Inventario, Caducados y Ubicaciones
          TicketsHistoryScreen(key: _ticketsKey),
          const ShoppingTab(),
          const MoreTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index == 2) {
              _ticketsKey = UniqueKey();
            }
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory),
            label: l10n.inventory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt),
            label: l10n.tickets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: l10n.shopping,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            label: l10n.more,
          ),
        ],
      ),
    );
  }
}
