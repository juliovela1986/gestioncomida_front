import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/date_picker_utils.dart';
import '../models/grouped_inventory.dart';
import '../models/location.dart';
import '../services/inventory_service.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';

class ProductLotsScreen extends StatefulWidget {
  final GroupedInventoryResponse product;

  const ProductLotsScreen({super.key, required this.product});

  @override
  State<ProductLotsScreen> createState() => _ProductLotsScreenState();
}

class _ProductLotsScreenState extends State<ProductLotsScreen> {
  final InventoryService _inventoryService = InventoryService();
  final LocationService _locationService = LocationService();
  late GroupedInventoryResponse _currentProduct;
  List<LocationResponseDto> _locations = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await _locationService.getUserLocations();
      if (mounted) {
        setState(() => _locations = locs);
      }
    } catch (e) {
      debugPrint('Error al cargar ubicaciones: $e');
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final updatedInventory = await _inventoryService.getGroupedInventory();
      final updatedProduct = updatedInventory.firstWhere(
        (p) => p.productName == _currentProduct.productName && p.productBrand == _currentProduct.productBrand,
        orElse: () => _currentProduct,
      );
      if (mounted) {
        setState(() {
          _currentProduct = updatedProduct;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Color _getLotColor(LotDetail lot) {
    if (lot.expirationDate == null) return Colors.grey;
    if (lot.daysUntilExpiration == null) return Colors.grey;
    if (lot.daysUntilExpiration! < 0) return Colors.red;
    if (lot.daysUntilExpiration! <= 3) return Colors.orange;
    return Colors.green;
  }

  IconData _getLotIcon(LotDetail lot) {
    if (lot.expirationDate == null) return Icons.help_outline;
    if (lot.daysUntilExpiration == null) return Icons.help_outline;
    if (lot.daysUntilExpiration! < 0) return Icons.error;
    if (lot.daysUntilExpiration! <= 3) return Icons.warning;
    return Icons.check_circle;
  }

  Future<void> _editExpirationDate(LotDetail lot) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final pickerConfig = buildSafeDatePickerConfig(
      initialDate: lot.expirationDate != null
          ? DateTime.tryParse(lot.expirationDate!)
          : now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1000)),
    );

    final newDate = await showDatePicker(
      context: context,
      helpText: l10n.expirationDate,
      initialDate: pickerConfig.initialDate,
      firstDate: pickerConfig.firstDate,
      lastDate: pickerConfig.lastDate,
    );

    if (newDate != null) {
      try {
        final formattedDate = DateFormat('yyyy-MM-dd').format(newDate);
        // Si no tiene fecha de alerta, sugerimos una (3 días antes)
        String? newAlertDate;
        if (lot.alertDate == null) {
          newAlertDate = DateFormat('yyyy-MM-dd').format(newDate.subtract(const Duration(days: 3)));
        }

        await _inventoryService.updateItem(lot.inventoryItemId, {
          'expirationDate': formattedDate,
          if (newAlertDate != null) 'alertDate': newAlertDate,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.updateSuccess)),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  Future<void> _editAlertDate(LotDetail lot) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final expirationDate = lot.expirationDate != null
        ? DateTime.tryParse(lot.expirationDate!)
        : null;
    final pickerConfig = buildSafeDatePickerConfig(
      initialDate: lot.alertDate != null
          ? DateTime.tryParse(lot.alertDate!)
          : expirationDate?.subtract(const Duration(days: 3)) ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: expirationDate ?? now.add(const Duration(days: 1000)),
    );

    final newDate = await showDatePicker(
      context: context,
      helpText: l10n.alertDate,
      initialDate: pickerConfig.initialDate,
      firstDate: pickerConfig.firstDate,
      lastDate: pickerConfig.lastDate,
    );

    if (newDate != null) {
      try {
        await _inventoryService.updateItem(lot.inventoryItemId, {
          'alertDate': DateFormat('yyyy-MM-dd').format(newDate),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.updateSuccess)),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  Future<void> _changeLocation(LotDetail lot) async {
    final l10n = AppLocalizations.of(context);
    String? selectedLocId;

    final newLocId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('manage_locations')),
        content: DropdownButtonFormField<String>(
          items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
          onChanged: (v) => selectedLocId = v,
          decoration: InputDecoration(labelText: l10n.translate('select_location')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, selectedLocId), child: Text(l10n.save)),
        ],
      ),
    );

    if (newLocId != null) {
      try {
        await _inventoryService.updateItem(lot.inventoryItemId, {'locationId': newLocId});
        _refreshData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteLot(LotDetail lot) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLot),
        content: Text(l10n.translate('delete_confirm_lot_msg')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _inventoryService.deleteItem(lot.inventoryItemId);
        _refreshData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentProduct.productName),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Column(
        children: [
          // Resumen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentProduct.productName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (_currentProduct.productBrand != null)
                  Text(_currentProduct.productBrand!, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  '${l10n.total}: ${_currentProduct.totalQuantity} ${l10n.unitsAbbr}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${_currentProduct.lotCount} ${l10n.translate('lots_count')}'),
              ],
            ),
          ),
          // Lista de lotes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _currentProduct.lots.length,
              itemBuilder: (context, index) {
                final lot = _currentProduct.lots[index];
                return Card(
                  color: _getLotColor(lot).withValues(alpha: 0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getLotColor(lot),
                      child: Icon(_getLotIcon(lot), color: Colors.white),
                    ),
                    title: Text(
                      '${lot.quantity} ${l10n.unitsAbbr}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lot.locationName != null && lot.locationName!.isNotEmpty)
                          Text(
                            '📍 ${lot.locationName}',
                            style: const TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        if (lot.expirationDate != null) ...[
                          Text('${l10n.expirationLabel}: ${lot.expirationDate}'),
                          if (lot.daysUntilExpiration != null)
                            Text(
                              lot.daysUntilExpiration! < 0
                                  ? l10n.expiredDaysAgo(-lot.daysUntilExpiration!)
                                  : l10n.inDaysCount(lot.daysUntilExpiration!),
                              style: TextStyle(
                                color: _getLotColor(lot),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ] else
                          Text(l10n.noExpirationDate, style: const TextStyle(color: Colors.orange)),
                        
                        if (lot.alertDate != null)
                          Text(
                            '${l10n.alertLabel}: ${lot.alertDate}',
                            style: const TextStyle(color: Colors.blue),
                          )
                        else
                          Text(l10n.noAlertDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit_exp',
                          child: Row(
                            children: [
                              const Icon(Icons.event, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.editExpirationDate),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit_alert',
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(l10n.editAlertDate, style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'loc',
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(l10n.translate('manage_locations'), style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.deleteLot, style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit_exp') {
                          _editExpirationDate(lot);
                        } else if (value == 'edit_alert') {
                          _editAlertDate(lot);
                        } else if (value == 'loc') {
                          _changeLocation(lot);
                        } else if (value == 'delete') {
                          _deleteLot(lot);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
