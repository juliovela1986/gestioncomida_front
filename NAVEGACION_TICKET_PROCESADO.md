# Solución: Navegación después de procesar ticket

## Problema
Cuando procesamos un PDF con `/api/tickets/upload`, no navegamos automáticamente a la pantalla del ticket procesado.

## Solución

### 1. Respuesta del endpoint `/api/tickets/upload`

El endpoint ya retorna `TicketProcessingResultDto` que incluye:
```json
{
  "metadata": {
    "id": "uuid-del-ticket",
    "locationId": "uuid",
    "fecha": "2024-01-15",
    "supermarketName": "Mercadona",
    ...
  },
  "lines": [...],
  "processedBy": "user-id",
  "manualReviewRequired": false,
  "message": "Ticket procesado correctamente"
}
```

### 2. Implementación en Flutter

**Modificar el método de upload en el servicio:**

```dart
// lib/services/ticket_service.dart

Future<TicketProcessingResult> uploadTicket(File file, {String? locationId}) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path),
    if (locationId != null) 'locationId': locationId,
  });

  final response = await dio.post('/api/tickets/upload', data: formData);
  return TicketProcessingResult.fromJson(response.data);
}
```

**Navegar después del upload:**

```dart
// En tu pantalla de upload (ej: ticket_upload_screen.dart)

Future<void> _uploadTicket(File file) async {
  try {
    setState(() => isLoading = true);
    
    final result = await ticketService.uploadTicket(file);
    
    // Extraer el ID del ticket de la respuesta
    final ticketId = result.metadata.id;
    
    // Navegar a la pantalla de detalle del ticket
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDetailScreen(ticketId: ticketId),
        ),
      );
    }
  } catch (e) {
    // Mostrar error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error procesando ticket: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}
```

### 3. Pantalla de detalle del ticket

**Crear o modificar `ticket_detail_screen.dart`:**

```dart
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({required this.ticketId});

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketResponse? ticket;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    final service = TicketService();
    final data = await service.getTicketById(widget.ticketId);
    setState(() {
      ticket = data;
      isLoading = false;
    });
  }

  Future<void> _syncToInventory() async {
    final service = TicketService();
    await service.syncTicketToInventory(widget.ticketId);
    
    // Navegar a gestión de fechas de caducidad
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpirationDateManagerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Ticket')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket!.supermarketName ?? 'Ticket'),
        actions: [
          if (!ticket!.inventorySynced)
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _syncToInventory,
              tooltip: 'Sincronizar a inventario',
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Información del ticket
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fecha: ${ticket!.purchaseDatetime}'),
                  if (ticket!.keyInvoice != null)
                    Text('Nº Ticket: ${ticket!.keyInvoice}'),
                  SizedBox(height: 8),
                  if (ticket!.inventorySynced)
                    Chip(
                      label: Text('Sincronizado'),
                      backgroundColor: Colors.green.shade100,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Líneas del ticket
          Text('Productos', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 8),
          ...ticket!.lines.map((line) => Card(
            child: ListTile(
              title: Text(line.productName),
              subtitle: Text('Cantidad: ${line.quantity}'),
              trailing: Text('${line.price}€'),
            ),
          )),
          
          SizedBox(height: 24),
          
          // Botón de sincronización
          if (!ticket!.inventorySynced)
            ElevatedButton.icon(
              onPressed: _syncToInventory,
              icon: Icon(Icons.inventory),
              label: Text('Añadir al inventario'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
              ),
            ),
        ],
      ),
    );
  }
}
```

### 4. Modelos necesarios

**Añadir modelo `TicketProcessingResult`:**

```dart
// lib/models/ticket_processing_result.dart

class TicketProcessingResult {
  final TicketMetadata metadata;
  final List<TicketLine> lines;
  final String processedBy;
  final bool manualReviewRequired;
  final String? message;

  TicketProcessingResult({
    required this.metadata,
    required this.lines,
    required this.processedBy,
    required this.manualReviewRequired,
    this.message,
  });

  factory TicketProcessingResult.fromJson(Map<String, dynamic> json) {
    return TicketProcessingResult(
      metadata: TicketMetadata.fromJson(json['metadata']),
      lines: (json['lines'] as List)
          .map((line) => TicketLine.fromJson(line))
          .toList(),
      processedBy: json['processedBy'],
      manualReviewRequired: json['manualReviewRequired'],
      message: json['message'],
    );
  }
}

class TicketMetadata {
  final String id;
  final String? locationId;
  final String? supermarketName;
  final DateTime? purchaseInstant;

  TicketMetadata({
    required this.id,
    this.locationId,
    this.supermarketName,
    this.purchaseInstant,
  });

  factory TicketMetadata.fromJson(Map<String, dynamic> json) {
    return TicketMetadata(
      id: json['id'],
      locationId: json['locationId'],
      supermarketName: json['supermarketName'],
      purchaseInstant: json['purchaseInstant'] != null
          ? DateTime.parse(json['purchaseInstant'])
          : null,
    );
  }
}
```

## Flujo completo

1. Usuario sube PDF → `/api/tickets/upload`
2. Backend procesa y retorna `TicketProcessingResultDto` con el `id` del ticket
3. Frontend extrae el `id` y navega a `TicketDetailScreen(ticketId: id)`
4. Usuario revisa el ticket y presiona "Añadir al inventario"
5. Se llama a `/api/tickets/{ticketId}/sync-inventory`
6. Se navega a `ExpirationDateManagerScreen` para gestionar fechas de caducidad

## Resumen de endpoints usados

1. `POST /api/tickets/upload` → Procesar PDF
2. `GET /api/tickets/{ticketId}` → Ver detalle
3. `POST /api/tickets/{ticketId}/sync-inventory` → Sincronizar a inventario
4. `GET /api/inventory/pending-expiration` → Obtener items sin fecha
5. `PUT /api/inventory/{id}` → Actualizar fecha de caducidad
