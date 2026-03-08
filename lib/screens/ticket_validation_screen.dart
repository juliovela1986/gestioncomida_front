import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../models/ticket.dart';
import 'edit_ticket_line_screen.dart';
import 'expiration_date_manager_screen.dart';

class TicketValidationScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic>? initialTicketData;

  const TicketValidationScreen({
    super.key,
    required this.ticketId,
    this.initialTicketData,
  });

  @override
  State<TicketValidationScreen> createState() => _TicketValidationScreenState();
}

class _TicketValidationScreenState extends State<TicketValidationScreen> {
  final TicketService _ticketService = TicketService();
  TicketResponseDto? _ticket;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    try {
      print('[Validation] 🔵 Iniciando carga de ticket: ${widget.ticketId}');
      setState(() => _isLoading = true); // Mostramos el loader al recargar
      final ticket = await _ticketService.getTicketById(widget.ticketId);
      print('[Validation] ✅ Ticket cargado exitosamente');
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('[Validation] ❌ Error: $e\n$stackTrace');
      setState(() {
        _errorMessage = 'Error al cargar ticket: $e';
        _isLoading = false;
      });
    }
  }

  double _calculateLineTotal(TicketLineResponseDto line) {
    // Intentar usar lineTotal del backend
    double lineTotal = double.tryParse(line.lineTotal ?? '0') ?? 0.0;
    
    // Si lineTotal es 0 o parece incorrecto, calcular: cantidad × precio
    if (lineTotal == 0.0) {
      final quantity = double.tryParse(line.quantity ?? '1') ?? 1.0;
      final price = double.tryParse(line.price ?? '0') ?? 0.0;
      lineTotal = quantity * price;
    }
    
    return lineTotal;
  }

  double _calculateTotal() {
    if (_ticket == null || _ticket!.lines.isEmpty) return 0.0;
    double total = 0.0;
    for (var line in _ticket!.lines) {
      // Intentar usar lineTotal del backend
      double lineTotal = double.tryParse(line.lineTotal ?? '0') ?? 0.0;
      
      // Si lineTotal es 0 o parece incorrecto, calcular: cantidad × precio
      if (lineTotal == 0.0) {
        final quantity = double.tryParse(line.quantity ?? '1') ?? 1.0;
        final price = double.tryParse(line.price ?? '0') ?? 0.0;
        lineTotal = quantity * price;
      }
      
      total += lineTotal;
    }
    return total;
  }

  Future<void> _syncToInventory() async {
    try {
      print('[Validation] 🔵 Iniciando sincronización del ticket ${widget.ticketId}');
      await _ticketService.syncTicketInventory(widget.ticketId);
      print('[Validation] ✅ Sincronización completada, navegando a gestión de fechas...');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ticket sincronizado al inventario')),
        );
        
        // Navegar a gestión de fechas de caducidad
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExpirationDateManagerScreen(ticketId: widget.ticketId),
          ),
        );
      }
    } catch (e) {
      print('[Validation] ❌ Error al sincronizar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTicketLine(TicketLineResponseDto line) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text('¿Estás seguro de eliminar "${line.productName ?? line.parsedText ?? 'este producto'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ticketService.deleteTicketLine(widget.ticketId, line.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto eliminado')),
          );
          _loadTicket();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al eliminar: $e')),
          );
        }
      }
    }
  }

  Future<void> _addNewLine() async {
    final productNameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: '0.00');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(labelText: 'Nombre del producto'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Precio unitario (€)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final lineData = {
          'productName': productNameController.text,
          'quantity': quantityController.text,
          'price': priceController.text,
        };
        
        await _ticketService.addTicketLine(widget.ticketId, lineData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto añadido')),
          );
          _loadTicket();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al añadir: $e')),
          );
        }
      }
    }
  }

  void _navigateToEditLine(TicketLineResponseDto line) async {
    if (_ticket == null) return;

    // Navegamos a la pantalla de edición y esperamos un resultado.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTicketLineScreen(
          initialTicket: _ticket!,
          lineIdToEdit: line.id,
        ),
      ),
    );

    // Si la pantalla de edición nos devuelve `true`, significa que se guardó algo
    // y debemos recargar los datos del ticket para ver los cambios.
    if (result == true && mounted) {
      print('[Validation] 🔄 Recibido `true` desde edición, recargando ticket...');
      _loadTicket();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Validando Ticket')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validar Ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTicket,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supermercado: ${_ticket?.supermarketName ?? "N/A"}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Fecha: ${_ticket?.purchaseDatetime ?? "N/A"}'),
                Text('Productos: ${_ticket?.lines.length ?? 0}'),
                Text('Total: ${_calculateTotal().toStringAsFixed(2)}€',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _ticket?.lines.length ?? 0,
              itemBuilder: (context, index) {
                final line = _ticket!.lines[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (line.confidence ?? 0) > 0.7
                          ? Colors.green
                          : Colors.orange,
                      child: Text('${((line.confidence ?? 0) * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                    title: Text(line.productName ?? line.parsedText ?? 'Sin nombre'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cantidad: ${line.quantity ?? "?"} | Precio unit: ${line.price ?? "?"}€'),
                        Text(
                          'Total línea: ${_calculateLineTotal(line).toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _navigateToEditLine(line),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTicketLine(line),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _syncToInventory,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Confirmar y Sincronizar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
