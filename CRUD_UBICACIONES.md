# CRUD de Ubicaciones - Guía Rápida

## Endpoints disponibles

### 1. Crear ubicación
```
POST /api/locations
```

**Request Body:**
```json
{
  "name": "Nevera",
  "type": "Cocina"
}
```

**Response:** `LocationResponseDto` (201 Created)

---

### 2. Listar mis ubicaciones
```
GET /api/locations
```

**Response:** Array de `LocationResponseDto`

---

### 3. Obtener ubicación por ID
```
GET /api/locations/{id}
```

**Response:** `LocationResponseDto`

---

### 4. Actualizar ubicación
```
PUT /api/locations/{id}
```

**Request Body:**
```json
{
  "name": "Congelador",
  "type": "Cocina"
}
```

**Response:** `LocationResponseDto`

---

### 5. Eliminar ubicación
```
DELETE /api/locations/{id}
```

**Response:** 204 No Content

---

### 6. Buscar por nombre
```
GET /api/locations/by-name?name=Nevera
```

**Response:** `LocationResponseDto`

---

### 7. Verificar existencia
```
GET /api/locations/exists?name=Nevera
```

**Response:** `boolean`

---

## Modelo LocationResponseDto

```json
{
  "id": "uuid",
  "userId": "uuid",
  "name": "Nevera",
  "type": "Cocina",
  "createdBy": "user-id",
  "createdInstant": "2024-01-15T10:30:00Z",
  "modifiedBy": "user-id",
  "modifiedInstant": "2024-01-15T10:30:00Z",
  "version": 1
}
```

## Implementación Flutter mínima

### Servicio
```dart
// lib/services/location_service.dart

class LocationService {
  final Dio dio;

  LocationService(this.dio);

  Future<List<Location>> getLocations() async {
    final response = await dio.get('/api/locations');
    return (response.data as List)
        .map((json) => Location.fromJson(json))
        .toList();
  }

  Future<Location> createLocation(String name, String type) async {
    final response = await dio.post('/api/locations', data: {
      'name': name,
      'type': type,
    });
    return Location.fromJson(response.data);
  }

  Future<Location> updateLocation(String id, String name, String type) async {
    final response = await dio.put('/api/locations/$id', data: {
      'name': name,
      'type': type,
    });
    return Location.fromJson(response.data);
  }

  Future<void> deleteLocation(String id) async {
    await dio.delete('/api/locations/$id');
  }
}
```

### Modelo
```dart
// lib/models/location.dart

class Location {
  final String id;
  final String name;
  final String type;

  Location({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}
```

### Pantalla CRUD
```dart
// lib/screens/locations_screen.dart

class LocationsScreen extends StatefulWidget {
  @override
  _LocationsScreenState createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<Location> locations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final service = LocationService(dio);
    final data = await service.getLocations();
    setState(() {
      locations = data;
      isLoading = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final typeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nueva Ubicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: 'Tipo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = LocationService(dio);
              await service.createLocation(
                nameController.text,
                typeController.text,
              );
              Navigator.pop(context);
              _loadLocations();
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(String id) async {
    final service = LocationService(dio);
    await service.deleteLocation(id);
    _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Ubicaciones')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ubicaciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          return ListTile(
            title: Text(location.name),
            subtitle: Text(location.type),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteLocation(location.id),
            ),
          );
        },
      ),
    );
  }
}
```

## Casos de uso

1. **Al procesar ticket**: Seleccionar ubicación destino
2. **Al añadir item manual**: Seleccionar ubicación
3. **Gestión de ubicaciones**: CRUD completo
4. **Filtrar inventario**: Por ubicación

## Ubicaciones típicas

- **Cocina**: Nevera, Congelador, Despensa, Armario
- **Garaje**: Congelador grande, Estantería
- **Habitación**: Mini nevera
