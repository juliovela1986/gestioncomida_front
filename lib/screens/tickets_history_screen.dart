import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import 'ticket_validation_screen.dart';

class TicketsHistoryScreen extends StatefulWidget {
  const TicketsHistoryScreen({super.key});

  @override
  State<TicketsHistoryScreen> createState() => _TicketsHistoryScreenState();
}

class _TicketsHistoryScreenState extends State<TicketsHistoryScreen> {
  final TicketService _ticketService = TicketService();
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final response = await _ticketService.getTickets(page: 0, size: 20);
      final data = response.data;
      
      // Extraer los tickets del response paginado
      final List<dynamic> content = data['content'] ?? [];
      
      setState(() {
        _tickets = content.map((ticket) => {
          'id': ticket['id'],
          'supermarketName': ticket['supermarketName'] ?? 'Sin nombre',
          'purchaseDatetime': ticket['purchaseDatetime'] ?? 'N/A',
          'lineCount': (ticket['lines'] as List?)?.length ?? 0,
          'total': _calculateTotal(ticket['lines']),
          'synced': ticket['inventorySynced'] ?? false,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar tickets: $e')),
        );
      }
    }
  }

  String _calculateTotal(List<dynamic>? lines) {
    if (lines == null || lines.isEmpty) return '0.00';
    double total = 0.0;
    for (var line in lines) {
      final lineTotal = line['lineTotal'];
      if (lineTotal != null) {
        total += double.tryParse(lineTotal.toString()) ?? 0.0;
      }
    }
    return total.toStringAsFixed(2);
  }

  Future<void> _deleteTicket(String ticketId, String supermarketName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar ticket?'),
        content: Text('¿Estás seguro de eliminar el ticket de $supermarketName?'),
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
        await _ticketService.deleteTicket(ticketId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Ticket eliminado')),
          );
          _loadTickets();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay tickets procesados',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    final synced = ticket['synced'] as bool;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: synced ? Colors.green : Colors.orange,
                          child: Icon(
                            synced ? Icons.check : Icons.sync,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          ticket['supermarketName'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha: ${ticket['purchaseDatetime']}'),
                            Text('Productos: ${ticket['lineCount']} | Total: ${ticket['total']}€'),
                            if (!synced)
                              const Text(
                                'Pendiente de sincronizar',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTicket(
                                ticket['id'],
                                ticket['supermarketName'] ?? 'Sin nombre',
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketValidationScreen(
                                ticketId: ticket['id'],
                              ),
                            ),
                          ).then((_) => _loadTickets());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
