import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/error_utils.dart';
import '../core/ticket_discount_utils.dart';
import '../services/ticket_service.dart';
import '../services/location_service.dart';
import '../models/ticket.dart';
import '../models/location.dart';
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
  final LocationService _locationService = LocationService();

  TicketResponseDto? _ticket;
  List<LocationResponseDto> _locations = [];
  String? _selectedLocationId;

  /// Pre-asignaciones por línea: lineId → {locationId, expirationDate, alertDate}
  final Map<String, Map<String, dynamic>> _lineExtras = {};

  bool _isLoading = true;
  bool _isSyncing = false;
  String? _errorMessage;
  String? _manualReviewHint;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTicketData;
    if (initial != null) {
      final manualRequired = initial['manualReviewRequired'] == true;
      final message = initial['message']?.toString();
      if (manualRequired || (message != null && message.isNotEmpty)) {
        _manualReviewHint = message?.isNotEmpty == true
            ? message
            : 'No se pudo procesar el ticket automáticamente. Añade los productos a mano.';
      }
    }
    _loadTicket();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await _locationService.getUserLocations();
      if (!mounted) return;
      setState(() {
        _locations = locs;
        // Pre-seleccionar "Despensa" por defecto si existe
        final despensa = locs.where(
          (l) => l.name.toLowerCase().contains('despensa'),
        );
        if (despensa.isNotEmpty) {
          _selectedLocationId = despensa.first.id;
        }
      });
    } catch (_) {
      // Las ubicaciones son opcionales; si fallan, el usuario puede continuar sin ellas
    }
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
        _errorMessage = userFriendlyError(e, fallback: 'No se pudo cargar el ticket. Inténtalo de nuevo.');
        _isLoading = false;
      });
    }
  }

  double _parseAmount(String? value) => parseTicketAmount(value);

  double _calculateGlobalDiscount() {
    if (_ticket == null) return 0.0;
    return calculateGlobalDiscount(
      rawText: _ticket!.rawText,
      subtotal: _calculateSubtotalFromLines(),
      backendTicketTotal: _ticket!.ticketTotal,
      supermarketName: _ticket!.supermarketName,
    );
  }

  double _calculateTotal() {
    if (_ticket == null) return 0.0;
    return calculateTicketDisplayTotal(
      subtotal: _calculateSubtotalFromLines(),
      rawText: _ticket!.rawText,
      backendTicketTotal: _ticket!.ticketTotal,
      supermarketName: _ticket!.supermarketName,
    );
  }

  bool _totalsAreConsistent(double a, double b, {double tolerance = 0.05}) {
    return totalsAreConsistent(a, b, tolerance: tolerance);
  }

  double _calculateSubtotalFromLines() {
    if (_ticket == null || _ticket!.lines.isEmpty) return 0.0;

    double subtotal = 0.0;
    for (final line in _ticket!.lines) {
      double lineTotal = _parseAmount(line.lineTotal);
      if (lineTotal == 0.0) {
        final quantity = _parseAmount(line.quantity).clamp(0.0, double.infinity);
        final price = _parseAmount(line.price);
        lineTotal = quantity * price;
      }
      subtotal += lineTotal;
    }

    return subtotal;
  }

  double _calculateLineTotal(TicketLineResponseDto line) {
    // Intentar usar lineTotal del backend
    double lineTotal = _parseAmount(line.lineTotal);

    // Si lineTotal es 0 o parece incorrecto, calcular: cantidad × precio
    if (lineTotal == 0.0) {
      final quantity = _parseAmount(line.quantity).clamp(0.0, double.infinity);
      final price = _parseAmount(line.price);
      lineTotal = quantity * price;
    }
    
    return lineTotal;
  }

  Future<void> _syncToInventory() async {
    if (_ticket == null || _ticket!.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Añade al menos un producto antes de sincronizar. El OCR no detectó líneas.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    try {
      // Intentar validar el ticket — no es fatal si ya estaba validado
      try {
        print('[Validation] 🔵 Validando ticket ${widget.ticketId}...');
        await _ticketService.validateTicket(widget.ticketId);
        print('[Validation] ✅ Ticket validado.');
      } catch (e) {
        print('[Validation] ⚠️ validateTicket falló (puede que ya estuviera validado): $e');
      }

      // Sincronizar al inventario con ubicación global seleccionada
      print('[Validation] 🔵 Sincronizando inventario...');
      await _ticketService.syncTicketInventory(
        widget.ticketId,
        locationId: _selectedLocationId,
      );
      print('[Validation] ✅ Sincronización completada, navegando a gestión de fechas...');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ticket sincronizado al inventario')),
        );
        // Siempre navegar a ExpirationDateManagerScreen.
        // Si el usuario pre-asignó datos en el editor, se pasan para pre-rellenar.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExpirationDateManagerScreen(
              ticketId: widget.ticketId,
              preAssignedExtras: _lineExtras,
            ),
          ),
        );
      }
    } catch (e) {
      print('[Validation] ❌ Error al sincronizar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudo sincronizar el ticket con el inventario.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
            SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudo eliminar el producto.'))),
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
            SnackBar(content: Text(userFriendlyError(e, fallback: 'No se pudo añadir el producto.'))),
          );
        }
      }
    }
  }

  void _navigateToEditLine(TicketLineResponseDto line) async {
    if (_ticket == null) return;

    final extras = _lineExtras[line.id] ?? {};

    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTicketLineScreen(
          initialTicket: _ticket!,
          lineIdToEdit: line.id,
          locations: _locations,
          initialLocationId: extras['locationId'] as String?,
          initialExpirationDate: extras['expirationDate'] as DateTime?,
          initialAlertDate: extras['alertDate'] as DateTime?,
        ),
      ),
    );

    if (result != null && result['saved'] == true && mounted) {
      print('[Validation] 🔄 Recibido resultado desde edición, recargando ticket...');
      // Guardar las pre-asignaciones devueltas por el editor
      _lineExtras[line.id] = {
        'locationId': result['locationId'],
        'expirationDate': result['expirationDate'],
        'alertDate': result['alertDate'],
      };
      _loadTicket();
    }
  }

  String _displaySupermarketName() {
    final name = _ticket?.supermarketName;
    if (name != null && name.trim().isNotEmpty) return name;
    final raw = (_ticket?.rawText ?? '').toUpperCase();
    if (raw.contains('CARREFOUR')) return 'CARREFOUR';
    if (raw.contains('MERCADONA')) return 'MERCADONA';
    if (RegExp(r'\bDIA\b').hasMatch(raw) || raw.startsWith('DIA')) return 'DIA';
    if (raw.contains('ALCAMPO')) return 'ALCAMPO';
    if (raw.contains('CONSUM')) return 'CONSUM';
    return 'N/A';
  }

  bool get _needsManualLines =>
      _ticket != null && _ticket!.lines.isEmpty;

  Widget _buildManualReviewBanner() {
    if (!_needsManualLines && _manualReviewHint == null) {
      return const SizedBox.shrink();
    }

    final hint = _manualReviewHint ??
        'El OCR no extrajo productos (confianza baja). Usa «Añadir Producto» o revisa el texto OCR.';

    return Material(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if ((_ticket?.rawText ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _showRawText = !_showRawText),
                icon: Icon(_showRawText ? Icons.expand_less : Icons.expand_more),
                label: Text(_showRawText ? 'Ocultar texto OCR' : 'Ver texto OCR'),
              ),
              if (_showRawText)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _ticket!.rawText!,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotalFromLines();
    final globalDiscount = _calculateGlobalDiscount();
    final total = _calculateTotal();

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
                Text('Supermercado: ${_displaySupermarketName()}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Fecha: ${_ticket?.purchaseDatetime ?? "N/A"}'),
                Text('Productos: ${_ticket?.lines.length ?? 0}'),
                if (globalDiscount > 0 || !_totalsAreConsistent(total, subtotal))
                  Text(
                    'Subtotal líneas: ${subtotal.toStringAsFixed(2)}€',
                    style: const TextStyle(color: Colors.black87),
                  ),
                if (globalDiscount > 0)
                  Text(
                    'Descuento ticket: -${globalDiscount.toStringAsFixed(2)}€',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                Text('Total: ${total.toStringAsFixed(2)}€',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          _buildManualReviewBanner(),
          Expanded(
            child: _needsManualLines
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Sin productos detectados',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'El total es 0,00 € porque el ticket llegó sin líneas.\nPulsa «Añadir Producto» para cargarlas a mano.',
                            style: TextStyle(color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addNewLine,
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir Producto'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
              itemCount: _ticket?.lines.length ?? 0,
              itemBuilder: (context, index) {
                final line = _ticket!.lines[index];
                final extras = _lineExtras[line.id] ?? {};
                final hasExpDate = extras['expirationDate'] != null;
                final hasLocation = extras['locationId'] != null;
                final fmt = DateFormat('dd/MM/yy');

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
                        // ── Badges de pre-asignación ────────────────────
                        if (hasExpDate || hasLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              children: [
                                if (hasExpDate)
                                  Chip(
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                    label: Text(
                                      '📅 ${fmt.format(extras['expirationDate'] as DateTime)}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.blue.shade50,
                                  ),
                                if (hasLocation)
                                  Chip(
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                    label: Text(
                                      '📍 ${_locations.firstWhere((l) => l.id == extras['locationId'], orElse: () => LocationResponseDto(id: '', name: '?')).name}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.green.shade50,
                                  ),
                              ],
                            ),
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
                // ── Selector de ubicación por defecto ──────────────────────
                if (_locations.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación de destino',
                      prefixIcon: Icon(Icons.location_on, color: Colors.green),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin ubicación específica'),
                      ),
                      ..._locations.map(
                        (loc) => DropdownMenuItem<String?>(
                          value: loc.id,
                          child: Text(loc.name),
                        ),
                      ),
                    ],
                    onChanged: _isSyncing
                        ? null
                        : (v) => setState(() => _selectedLocationId = v),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSyncing ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isSyncing || _needsManualLines) ? null : _syncToInventory,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: _isSyncing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmar y Sincronizar'),
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
