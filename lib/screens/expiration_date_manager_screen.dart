import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expiration_management_response.dart';
import '../models/location.dart';
import '../services/inventory_service.dart';
import '../services/ticket_service.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/expiry_date_voice_widget.dart';

class ExpirationDateManagerScreen extends StatefulWidget {
  final String ticketId;

  /// Datos pre-asignados desde el editor de líneas: lineId → {locationId, expirationDate, alertDate}
  final Map<String, Map<String, dynamic>> preAssignedExtras;

  const ExpirationDateManagerScreen({
    super.key,
    required this.ticketId,
    this.preAssignedExtras = const {},
  });

  @override
  State<ExpirationDateManagerScreen> createState() => _ExpirationDateManagerScreenState();
}

class _ExpirationDateManagerScreenState extends State<ExpirationDateManagerScreen> {
  final InventoryService _inventoryService = InventoryService();
  final TicketService _ticketService = TicketService();
  final LocationService _locationService = LocationService();
  
  List<ProductToManage> _products = [];
  final Map<String, DateTime?> _selectedDates = {}; // ticketLineId -> fecha caducidad
  final Map<String, DateTime?> _selectedAlertDates = {}; // ticketLineId -> fecha alerta
  final Map<String, String?> _selectedLocations = {}; // ticketLineId -> locationId
  
  List<LocationResponseDto> _locations = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final response = await _ticketService.getExpirationManagement(widget.ticketId);
      final locs = await _locationService.getUserLocations();
      
      final productsNeedingDate = response.products
          .where((p) => p.newInventoryItemId.isNotEmpty)
          .toList();
      
      setState(() {
        _products = productsNeedingDate;
        _locations = locs;
        
        // Pre-seleccionar "Despensa" por defecto para cada producto
        final defaultLoc = locs.firstWhere(
          (l) => l.name.toLowerCase().contains('despensa'),
          orElse: () => locs.isNotEmpty ? locs.first : LocationResponseDto(id: '', name: '', type: '', createdInstant: DateTime.now(), userId: ''),
        );

        for (var p in productsNeedingDate) {
          if (defaultLoc.id.isNotEmpty) {
            _selectedLocations[p.ticketLineId] = defaultLoc.id;
          }
        }

        // Pre-rellenar con datos asignados desde el editor de líneas (si los hay)
        for (var p in productsNeedingDate) {
          final extras = widget.preAssignedExtras[p.ticketLineId];
          if (extras == null) continue;

          final locId = extras['locationId'] as String?;
          final expDate = extras['expirationDate'] as DateTime?;
          final alertDate = extras['alertDate'] as DateTime?;

          if (locId != null && locId.isNotEmpty) {
            _selectedLocations[p.ticketLineId] = locId;
          }
          if (expDate != null) {
            _selectedDates[p.ticketLineId] = expDate;
            // Pre-rellenar alerta si existe o sugerir 3 días antes
            _selectedAlertDates[p.ticketLineId] =
                alertDate ?? expDate.subtract(const Duration(days: 3));
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1000)),
    );

    if (date != null) {
      setState(() {
        final lineId = _products[_currentIndex].ticketLineId;
        _selectedDates[lineId] = date;
        // Sugerir alerta 3 días antes si no hay una
        if (_selectedAlertDates[lineId] == null) {
          _selectedAlertDates[lineId] = date.subtract(const Duration(days: 3));
        }
      });
    }
  }

  void _showExpiryVoiceInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpiryDateVoiceWidget(
        onDateDetected: (date) {
          setState(() {
            final lineId = _products[_currentIndex].ticketLineId;
            _selectedDates[lineId] = date;
            if (_selectedAlertDates[lineId] == null) {
              _selectedAlertDates[lineId] = date.subtract(const Duration(days: 3));
            }
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fecha reconocida: ${DateFormat('dd/MM/yyyy').format(date)}')),
          );
        },
        onFallback: () {
          Navigator.pop(context);
          _pickExpirationDate();
        },
      ),
    );
  }

  Future<void> _pickAlertDate() async {
    final expDate = _selectedDates[_products[_currentIndex].ticketLineId] ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedAlertDates[_products[_currentIndex].ticketLineId] ?? expDate.subtract(const Duration(days: 3)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: expDate,
    );

    if (date != null) {
      setState(() {
        _selectedAlertDates[_products[_currentIndex].ticketLineId] = date;
      });
    }
  }

  Future<void> _updateInventoryItemWithRetry(String itemId, Map<String, dynamic> payload) async {
    const delays = <Duration>[
      Duration(milliseconds: 0),
      Duration(milliseconds: 350),
      Duration(milliseconds: 700),
    ];

    Object? lastError;
    for (final delay in delays) {
      if (delay.inMilliseconds > 0) {
        await Future.delayed(delay);
      }
      try {
        await _inventoryService.updateItem(itemId, payload);
        return;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<void> _confirmSave() async {
    final currentProduct = _products[_currentIndex];
    final selectedDate = _selectedDates[currentProduct.ticketLineId];
    final selectedAlertDate = _selectedAlertDates[currentProduct.ticketLineId];
    final selectedLocId = _selectedLocations[currentProduct.ticketLineId];
    
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha primero')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final expirationDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      // El endpoint del ticket garantiza la asignación de caducidad por línea.
      await _ticketService.assignExpirationDates(widget.ticketId, [
        {
          'ticketLineId': currentProduct.ticketLineId,
          'expirationDate': expirationDate,
        }
      ]);

      // Refuerzo: persistimos alerta/ubicación directamente sobre el lote creado.
      if (currentProduct.newInventoryItemId.isNotEmpty) {
        await _updateInventoryItemWithRetry(
          currentProduct.newInventoryItemId,
          {
            'expirationDate': expirationDate,
            if (selectedAlertDate != null)
              'alertDate': DateFormat('yyyy-MM-dd').format(selectedAlertDate),
            if (selectedLocId != null && selectedLocId.isNotEmpty)
              'locationId': selectedLocId,
          },
        );
      }
      
      if (_currentIndex < _products.length - 1) {
        setState(() {
          _currentIndex++;
          _isSaving = false;
        });
      } else {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _skipProduct() {
    if (_currentIndex < _products.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_products.isEmpty) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Todo al día')));

    final product = _products[_currentIndex];
    final expDate = _selectedDates[product.ticketLineId];
    final alertDate = _selectedAlertDates[product.ticketLineId];

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.translate('product')} ${_currentIndex + 1}/${_products.length}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(product.productName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            
            // Selector de Ubicación (Despensa por defecto)
            DropdownButtonFormField<String>(
              initialValue: _selectedLocations[product.ticketLineId],
              items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (v) => setState(() => _selectedLocations[product.ticketLineId] = v),
              decoration: InputDecoration(
                labelText: l10n.translate('select_location'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),

            // Botón Fecha Caducidad
            ListTile(
              tileColor: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.event, color: Colors.blue),
              title: Text(l10n.expirationDate),
              subtitle: Text(expDate == null ? l10n.translate('tap_to_select') : DateFormat('dd/MM/yyyy').format(expDate)),
              trailing: IconButton(
                icon: const Icon(Icons.mic, color: Colors.blue),
                onPressed: _showExpiryVoiceInput,
              ),
              onTap: _pickExpirationDate,
            ),
            const SizedBox(height: 12),

            // Botón Fecha Alerta
            ListTile(
              tileColor: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: Text(l10n.alertDate),
              subtitle: Text(alertDate == null ? l10n.translate('tap_to_select') : DateFormat('dd/MM/yyyy').format(alertDate)),
              onTap: _pickAlertDate,
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _skipProduct,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: Text(l10n.skip.toUpperCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: expDate != null && !_isSaving ? _confirmSave : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.green,
                    ),
                    child: Text(l10n.save.toUpperCase()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
