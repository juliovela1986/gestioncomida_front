import 'package:flutter/material.dart';
import '../screens/price_insights_screen.dart';
import '../screens/product_price_comparison_screen.dart';
import '../screens/ticket_validation_enhanced_screen.dart';

/// Guía de integración de nuevas funcionalidades
///
/// Este archivo documenta cómo integrar las nuevas pantallas
/// en la navegación existente del proyecto.

// PASO 1: Importar en main_navigation_screen.dart o donde sea necesario
// import '../screens/price_insights_screen.dart';
// import '../screens/product_price_comparison_screen.dart';
// import '../screens/ticket_validation_enhanced_screen.dart';

// PASO 2: Agregar en el menú principal (more_tab.dart)
// Ejemplo:
/*
ListTile(
  leading: const Icon(Icons.trending_up),
  title: const Text('💰 Insights de Precios'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PriceInsightsScreen()),
    );
  },
),
*/

// PASO 3: Reemplazar ticket_validation_screen.dart
// En cualquier lugar donde se use ticket_validation_screen.dart:
/*
// Antes:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => TicketValidationScreen(ticketId: ticketId),
//   ),
// );

// Después:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TicketValidationEnhancedScreen(
      ticketId: ticketId,
      onValidated: () {
        // Refrescar lista de tickets o hacer algo después
      },
    ),
  ),
);
*/

// PASO 4: Para comparar precios de un producto
// Usar ProductPriceComparisonScreen:
/*
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ProductPriceComparisonScreen(
      productId: product.id,
      productName: product.name,
    ),
  ),
);
*/

/// Ejemplo completo de integración en more_tab.dart
class IntegrationExampleMoreTab extends StatelessWidget {
  const IntegrationExampleMoreTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.trending_up),
          title: const Text('💰 Insights de Precios'),
          subtitle: const Text('Comparativas y tendencias'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PriceInsightsScreen(),
              ),
            );
          },
        ),
        const Divider(),
        // Otros items existentes...
      ],
    );
  }
}

/// Ejemplo de uso en ticket_history_screen.dart para tickets
class IntegrationExampleTicketHistory extends StatelessWidget {
  final String ticketId = 'example-uuid';

  const IntegrationExampleTicketHistory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Validar ticket'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketValidationEnhancedScreen(
              ticketId: ticketId,
              onValidated: () {
                print('Ticket validado y sincronizado');
                // Refrescar datos si es necesario
                Navigator.pop(context, true);
              },
            ),
          ),
        );
      },
    );
  }
}

/// Ejemplo de uso en producto para ver comparativa de precios
class IntegrationExampleProductComparison extends StatelessWidget {
  final String productId = 'example-product-uuid';
  final String productName = 'Arroz redondo 1kg';

  const IntegrationExampleProductComparison({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'price-comparison',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductPriceComparisonScreen(
              productId: productId,
              productName: productName,
            ),
          ),
        );
      },
      tooltip: 'Ver precios',
      child: const Icon(Icons.price_check),
    );
  }
}

/// Archivo de referencia para nuevos servicios disponibles
///
/// PriceInsightsService:
/// - compareSupermarkets(productId, days)
/// - getProductTrend(productId, days, supermarket?)
/// - getTrackedProducts(limit)
/// - getOverview(days, top)
///
/// TicketService (mejorado):
/// - validateTicket(ticketId)
/// - syncTicketInventory(ticketId, locationId?)
/// - updateTicketLine(ticketId, lineId, data)
///
/// NotificationService (mejorado):
/// - getByStatus(status)
/// - getByStatusAndType(status, alertType)
/// - getByAlertType(alertType)
/// - markAsSent(notificationId)
/// - markAsFailed(notificationId, reason)
///
/// CatalogProductService (mejorado):
/// - existsByNameAndBrand(name, brand)
/// - findOrCreateProduct(searchData)
/// - createProduct(data)
/// - updateProduct(id, data)
/// - deleteProduct(id)
///
/// LocationService (mejorado):
/// - existsByName(name)

