import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import 'ticket_validation_screen.dart';
import '../l10n/app_localizations.dart';

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
    print('[TicketsHistoryScreen] 🟢 initState ejecutado');
    
    // Asegurar carga al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  Future<void> _loadTickets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await _ticketService.getTickets(page: 0, size: 50);
      final data = response.data;
      final List<dynamic> content = data['content'] ?? [];
      
      if (!mounted) return;
      setState(() {
        _tickets = content.map((ticket) => {
          'id': ticket['id'],
          'supermarketName': ticket['supermarketName'] ?? 'Sin nombre',
          'purchaseDatetime': ticket['purchaseDatetime'] ?? 'N/A',
          'lineCount': (ticket['lines'] as List?)?.length ?? 0,
          'total': _resolveTicketTotal(ticket),
          'synced': ticket['inventorySynced'] ?? false,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('error_loading', params: {'error': e.toString()}))),
      );
    }
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;

    var normalized = value.toString().trim();
    if (normalized.isEmpty) return 0.0;

    normalized = normalized.replaceAll(RegExp(r'[^0-9,.-]'), '');

    final hasComma = normalized.contains(',');
    final hasDot = normalized.contains('.');
    if (hasComma && hasDot) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0.0;
  }

  String _resolveTicketTotal(Map<String, dynamic> ticket) {
    final backendTotal = _parseAmount(ticket['ticketTotal']);
    if (backendTotal > 0) {
      return backendTotal.toStringAsFixed(2);
    }
    return _calculateTotal(ticket['lines']);
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

  Future<void> _editSupermarketName(String ticketId, String currentName) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editSupermarket),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.supermarketName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await _ticketService.updateTicket(ticketId, {'supermarketName': newName});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.updateSuccess)),
          );
          _loadTickets();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteTicket(String ticketId, String supermarketName) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTicketTitle),
        content: Text(l10n.translate('delete_ticket_confirm', params: {'name': supermarketName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _ticketService.deleteTicket(ticketId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteSuccess)),
          );
          _loadTickets();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.translate('error_delete', params: {'error': e.toString()}))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ticketsHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _tickets.isEmpty
                  ? Center(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          const Center(child: Icon(Icons.receipt_long, size: 80, color: Colors.grey)),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(l10n.noTickets,
                                style: const TextStyle(fontSize: 18, color: Colors.grey)),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(l10n.pullToRefresh,
                                style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ),
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
                                Text('${l10n.date}: ${ticket['purchaseDatetime']}'),
                                Text('${l10n.products}: ${ticket['lineCount']} | ${l10n.total}: ${ticket['total']}€'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: synced ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    synced ? '✅ ${l10n.synced}' : '⏳ ${l10n.pendingSync}',
                                    style: TextStyle(
                                      color: synced ? Colors.green.shade900 : Colors.orange.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editSupermarketName(
                                    ticket['id'],
                                    ticket['supermarketName'] ?? '',
                                  ),
                                ),
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
            ),
    );
  }
}
