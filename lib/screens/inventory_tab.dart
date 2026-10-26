import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'expired_products_screen.dart';
import 'trash_screen.dart';
import 'locations_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/inventory_service.dart';
import '../models/pending_expiration_item.dart';

typedef ExpiredPendingSummaryLoader = Future<ExpiredPendingSummaryResponseDto> Function();

class InventoryTab extends StatefulWidget {
  final ExpiredPendingSummaryLoader? loadSummary;

  const InventoryTab({
    super.key,
    this.loadSummary,
  });

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  final InventoryService _inventoryService = InventoryService();
  ExpiredPendingSummaryResponseDto? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await (widget.loadSummary?.call() ?? _inventoryService.getExpiredPendingSummary());
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {
      // Si falla el summary no bloqueamos navegación; mostramos subtítulo base.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expiredSubtitle = _summary == null
        ? l10n.translate('expired_products_subtitle')
        : l10n.translate(
            'expired_products_subtitle_with_count',
            params: {'count': _summary!.expiredPendingCount.toString()},
          );
    final trashSubtitle = _summary == null
        ? l10n.translate('trash_subtitle')
        : l10n.translate(
            'trash_subtitle_with_count',
            params: {'count': _summary!.trashedCount.toString()},
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOptionCard(
              context,
              icon: Icons.inventory_2,
              title: l10n.viewInventory,
              subtitle: l10n.translate('view_inventory_subtitle'),
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              icon: Icons.warning_amber,
              title: l10n.expiredProducts,
              subtitle: expiredSubtitle,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpiredProductsScreen()),
                ).then((_) => _loadSummary());
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              icon: Icons.delete_outline,
              title: l10n.translate('trash'),
              subtitle: trashSubtitle,
              color: Colors.blueGrey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                ).then((_) => _loadSummary());
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              icon: Icons.location_on,
              title: l10n.manageLocations,
              subtitle: l10n.translate('manage_locations_subtitle'),
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
