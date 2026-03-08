# Implementación: Gestión de Fechas de Caducidad

## Flujo completo

### 1. Backend (Ya implementado)
- **Endpoint**: `GET /api/inventory/pending-expiration`
- **Respuesta**: Lista de items sin fecha de caducidad
```json
[
  {
    "inventoryItemId": "uuid",
    "productName": "Leche Entera",
    "quantity": 2.0,
    "alreadyInInventory": true,
    "existingItemId": "uuid-existente"
  }
]
```

### 2. Frontend - Pantalla de Gestión de Fechas

#### Componentes necesarios:

**1. Servicio API** (`lib/services/inventory_service.dart`)
```dart
Future<List<PendingExpirationItem>> getPendingExpirationItems() async {
  final response = await dio.get('/api/inventory/pending-expiration');
  return (response.data as List)
      .map((item) => PendingExpirationItem.fromJson(item))
      .toList();
}

Future<void> updateExpirationDate(String itemId, DateTime expirationDate) async {
  await dio.put('/api/inventory/$itemId', data: {
    'expirationDate': expirationDate.toIso8601String(),
  });
}
```

**2. Modelo** (`lib/models/pending_expiration_item.dart`)
```dart
class PendingExpirationItem {
  final String inventoryItemId;
  final String productName;
  final double quantity;
  final bool alreadyInInventory;
  final String? existingItemId;

  PendingExpirationItem({
    required this.inventoryItemId,
    required this.productName,
    required this.quantity,
    required this.alreadyInInventory,
    this.existingItemId,
  });

  factory PendingExpirationItem.fromJson(Map<String, dynamic> json) {
    return PendingExpirationItem(
      inventoryItemId: json['inventoryItemId'],
      productName: json['productName'],
      quantity: json['quantity'],
      alreadyInInventory: json['alreadyInInventory'],
      existingItemId: json['existingItemId'],
    );
  }
}
```

**3. Pantalla Principal** (`lib/screens/expiration_date_manager_screen.dart`)
```dart
class ExpirationDateManagerScreen extends StatefulWidget {
  @override
  _ExpirationDateManagerScreenState createState() => _ExpirationDateManagerScreenState();
}

class _ExpirationDateManagerScreenState extends State<ExpirationDateManagerScreen> {
  List<PendingExpirationItem> items = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final service = InventoryService();
    final data = await service.getPendingExpirationItems();
    setState(() {
      items = data;
      isLoading = false;
    });
  }

  void _nextItem() {
    if (currentIndex < items.length - 1) {
      setState(() => currentIndex++);
    } else {
      Navigator.pop(context); // Finalizar
    }
  }

  Future<void> _selectDateManually() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      await _saveDate(date);
    }
  }

  Future<void> _selectDateFromPhoto() async {
    // Implementar captura de foto y OCR
    // Por ahora, mostrar diálogo de fecha manual
    await _selectDateManually();
  }

  Future<void> _saveDate(DateTime date) async {
    final service = InventoryService();
    final item = items[currentIndex];
    
    await service.updateExpirationDate(item.inventoryItemId, date);
    _nextItem();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Fechas de Caducidad')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Fechas de Caducidad')),
        body: Center(child: Text('No hay items pendientes')),
      );
    }

    final item = items[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Fechas de Caducidad (${currentIndex + 1}/${items.length})'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.alreadyInInventory)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este producto ya existe en tu inventario',
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 24),
            Text(
              item.productName,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Cantidad: ${item.quantity}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _selectDateManually,
              icon: Icon(Icons.calendar_today),
              label: Text('Seleccionar fecha manualmente'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectDateFromPhoto,
              icon: Icon(Icons.camera_alt),
              label: Text('Escanear fecha del producto'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: _nextItem,
              child: Text('Saltar (sin caducidad)'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Integración en el flujo de tickets

**IMPORTANTE**: Ver guía completa en `NAVEGACION_TICKET_PROCESADO.md`

Después de sincronizar un ticket al inventario, navegar a esta pantalla:

```dart
// En tu pantalla de detalle de ticket, después de sincronizar:
await ticketService.syncTicketToInventory(ticketId);

// Navegar a gestión de fechas
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ExpirationDateManagerScreen(),
  ),
);
```

**Flujo completo**:
1. Upload PDF → `POST /api/tickets/upload` (retorna ticketId)
2. Navegar a `TicketDetailScreen(ticketId)`
3. Usuario revisa y presiona "Añadir al inventario"
4. Sincronizar → `POST /api/tickets/{ticketId}/sync-inventory`
5. Navegar a `ExpirationDateManagerScreen`

## Casuísticas manejadas

### 1. Artículo ya en inventario
- Se muestra aviso visual (banner naranja)
- El usuario puede:
  - Editar la fecha del existente
  - Mantener el existente y añadir nuevo con fecha diferente
  - Saltar si no tiene caducidad

### 2. Artículo nuevo
- Se añade directamente con la fecha seleccionada

### 3. Sin fecha de caducidad
- Botón "Saltar" permite continuar sin asignar fecha
- El item permanece en inventario sin fecha

## Próximos pasos

1. Implementar captura de foto con `image_picker`
2. Integrar OCR para extraer fecha de la foto (Google ML Kit)
3. Añadir validación de fechas
4. Implementar edición de items existentes con conflicto
