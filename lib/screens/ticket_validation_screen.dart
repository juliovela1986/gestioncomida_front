import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../models/ticket.dart';
import 'edit_ticket_line_screen.dart';

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

  double _calculateTotal() {
    if (_ticket == null || _ticket!.lines.isEmpty) return 0.0;
    double total = 0.0;
    for (var line in _ticket!.lines) {
      final lineTotal = double.tryParse(line.lineTotal ?? '0') ?? 0.0;
      total += lineTotal;
    }
    return total;
  }

  Future<void> _syncToInventory() async {
    try {
      await _ticketService.syncTicketInventory(widget.ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ticket sincronizado al inventario')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
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
                    subtitle: Text(
                        'Cantidad: ${line.quantity ?? "?"} | Precio: ${line.price ?? "?"}'),
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
            child: Row(
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
          ),
        ],
      ),
    );
  }
}
