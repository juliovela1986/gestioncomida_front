import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/error_utils.dart';
import '../core/date_picker_utils.dart';
import '../core/idempotency_utils.dart';
import '../l10n/app_localizations.dart';
import '../services/inventory_service.dart';
import '../models/pending_expiration_item.dart';
import 'trash_screen.dart';

typedef ExpiredPendingItemsLoader = Future<List<ExpiredPendingItemDto>> Function();
typedef ExpiredPendingBulkActionExecutor = Future<ExpiredPendingBulkActionResponseDto> Function(
  ExpiredPendingBulkActionRequestDto request,
);
typedef ExpiredPendingSnoozeDatePicker = Future<DateTime?> Function(BuildContext context);

class ExpiredProductsScreen extends StatefulWidget {
  final ExpiredPendingItemsLoader? loadExpiredPendingItems;
  final ExpiredPendingBulkActionExecutor? executeBulkAction;
  final ExpiredPendingSnoozeDatePicker? pickSnoozeDate;

  const ExpiredProductsScreen({
    super.key,
    this.loadExpiredPendingItems,
    this.executeBulkAction,
    this.pickSnoozeDate,
  });

  @override
  State<ExpiredProductsScreen> createState() => _ExpiredProductsScreenState();
}

class _ExpiredProductsScreenState extends State<ExpiredProductsScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<ExpiredPendingItemDto> _expiredItems = [];
  bool _isLoading = true;
  bool _isApplyingAction = false;
  String? _errorMessage;
  final Set<String> _selectedItemIds = <String>{};
  ExpiredPendingBulkActionRequestDto? _lastRetriableBulkAction;

  @override
  void initState() {
    super.initState();
    _loadExpiredItems();
  }

  Future<void> _loadExpiredItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await (widget.loadExpiredPendingItems?.call() ??
          _inventoryService.getExpiredPendingItems());

      setState(() {
        _expiredItems = items;
        _selectedItemIds.removeWhere(
          (id) => !_expiredItems.any((item) => item.id == id),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = userFriendlyError(e);
        _isLoading = false;
      });
    }
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ?? l10n.noProductsFound,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadExpiredItems,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green.shade300),
              const SizedBox(height: 16),
              Text(
                l10n.noExpiredPendingProducts,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.pullToRefresh,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _isSelectionMode => _selectedItemIds.isNotEmpty;

  Future<DateTime?> _pickSnoozeDate(BuildContext context) async {
    final now = DateTime.now();
    final pickerConfig = buildSafeDatePickerConfig(
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    return showDatePicker(
      context: context,
      helpText: AppLocalizations.of(context).translate('expired_pending_snooze_title'),
      initialDate: pickerConfig.initialDate,
      firstDate: pickerConfig.firstDate,
      lastDate: pickerConfig.lastDate,
    );
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedItemIds.clear());
  }

  Future<void> _runBulkAction(
    ExpiredPendingBulkActionRequestDto request,
    AppLocalizations l10n,
  ) async {
    if (_isApplyingAction) return;

    setState(() => _isApplyingAction = true);

    try {
      final response = await (widget.executeBulkAction?.call(request) ??
          _inventoryService.applyExpiredPendingBulkAction(request));

      if (!mounted) return;

      _lastRetriableBulkAction = null;

      final message = response.hasPartialErrors
          ? l10n.translate(
              'expired_pending_bulk_partial',
              params: {
                'updated': response.updated.toString(),
                'requested': response.requested.toString(),
                'errors': response.errors.length.toString(),
              },
            )
          : l10n.translate(
              response.idempotentReplay
                  ? 'expired_pending_bulk_success_replay'
                  : 'expired_pending_bulk_success',
              params: {'count': response.updated.toString()},
            );

      setState(() {
        _selectedItemIds.clear();
        _isApplyingAction = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await _loadExpiredItems();
    } catch (e) {
      if (!mounted) return;

      _lastRetriableBulkAction = request;
      setState(() => _isApplyingAction = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyError(e)),
          action: SnackBarAction(
            label: l10n.translate('retry'),
            onPressed: () {
              final lastRequest = _lastRetriableBulkAction;
              if (lastRequest != null) {
                _runBulkAction(lastRequest, l10n);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _applyBulkAction(
    ExpiredPendingBulkActionType action,
    AppLocalizations l10n, {
    DateTime? snoozeUntil,
  }) async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('expired_pending_select_items'))),
      );
      return;
    }

    final request = ExpiredPendingBulkActionRequestDto(
      itemIds: _selectedItemIds.toList(),
      action: action,
      clientRequestId: generateClientRequestId(),
      reason: 'manual_cleanup',
      snoozeUntil: snoozeUntil != null ? DateFormat('yyyy-MM-dd').format(snoozeUntil) : null,
    );

    await _runBulkAction(request, l10n);
  }

  Future<void> _handleArchive(AppLocalizations l10n) async {
    await _applyBulkAction(ExpiredPendingBulkActionType.archive, l10n);
  }

  Future<void> _handleMoveToTrash(AppLocalizations l10n) async {
    await _applyBulkAction(ExpiredPendingBulkActionType.moveToTrash, l10n);
  }

  Future<void> _handleMoveSingleToTrash(String itemId, AppLocalizations l10n) async {
    final request = ExpiredPendingBulkActionRequestDto(
      itemIds: [itemId],
      action: ExpiredPendingBulkActionType.moveToTrash,
      clientRequestId: generateClientRequestId(),
      reason: 'manual_cleanup',
    );
    await _runBulkAction(request, l10n);
  }

  Future<void> _handleSnooze(AppLocalizations l10n) async {
    final selectedDate = await (widget.pickSnoozeDate?.call(context) ?? _pickSnoozeDate(context));
    if (selectedDate == null) return;

    await _applyBulkAction(
      ExpiredPendingBulkActionType.snooze,
      l10n,
      snoozeUntil: selectedDate,
    );
  }

  String _formatExpirationDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isApplyingAction ? null : _clearSelection,
                tooltip: l10n.cancel,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? l10n.translate(
                  'expired_pending_selected_count',
                  params: {'count': _selectedItemIds.length.toString()},
                )
              : l10n.expiredProducts,
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: _isApplyingAction
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.archive_outlined),
              onPressed: _isApplyingAction ? null : () => _handleArchive(l10n),
              tooltip: l10n.translate('archive'),
            ),
            PopupMenuButton<String>(
              enabled: !_isApplyingAction,
              onSelected: (value) {
                if (value == 'trash') {
                  _handleMoveToTrash(l10n);
                } else if (value == 'snooze') {
                  _handleSnooze(l10n);
                } else if (value == 'clear') {
                  _clearSelection();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'trash',
                  child: Text(l10n.translate('move_to_trash')),
                ),
                PopupMenuItem<String>(
                  value: 'snooze',
                  child: Text(l10n.translate('snooze')),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Text(l10n.translate('clear_selection')),
                ),
              ],
            ),
          ] else
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
            },
            tooltip: l10n.translate('trash'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpiredItems,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpiredItems,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildErrorState(l10n),
                      ),
                    ],
                  )
                : _expiredItems.isEmpty
                    ? _buildEmptyState(l10n)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: _expiredItems.length,
                        itemBuilder: (context, index) {
                          final item = _expiredItems[index];
                          final isSelected = _selectedItemIds.contains(item.id);
                          return Card(
                            color: Colors.red.shade50,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.orange.shade100,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.red,
                                child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                              ),
                              title: Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (item.locationName != null && item.locationName!.isNotEmpty)
                                    Text(item.locationName!),
                                  Text(
                                    l10n.expiredDaysAgo(item.daysExpired),
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('${l10n.date}: ${_formatExpirationDate(item.expirationDate)}'),
                                ],
                              ),
                              trailing: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: _isApplyingAction
                                          ? null
                                          : (_) => _toggleSelection(item.id),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: l10n.translate('move_to_trash'),
                                      onPressed: _isApplyingAction
                                          ? null
                                          : () => _handleMoveSingleToTrash(item.id, l10n),
                                    ),
                              onTap: _isApplyingAction ? null : () => _toggleSelection(item.id),
                              onLongPress: _isApplyingAction
                                  ? null
                                  : () => _toggleSelection(item.id),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
