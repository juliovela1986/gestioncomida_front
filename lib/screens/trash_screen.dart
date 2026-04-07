import 'package:flutter/material.dart';

import '../core/error_utils.dart';
import '../l10n/app_localizations.dart';
import '../models/pending_expiration_item.dart';
import '../services/inventory_service.dart';

typedef TrashItemsLoader = Future<List<ExpiredPendingItemDto>> Function();
typedef TrashActionExecutor = Future<ExpiredPendingBulkActionResponseDto> Function(
  InventoryTrashBulkRequestDto request,
);

enum _TrashActionType {
  restore,
  deleteForever,
}

class TrashScreen extends StatefulWidget {
  final TrashItemsLoader? loadTrashItems;
  final TrashActionExecutor? restoreItems;
  final TrashActionExecutor? deleteItems;

  const TrashScreen({
    super.key,
    this.loadTrashItems,
    this.restoreItems,
    this.deleteItems,
  });

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<ExpiredPendingItemDto> _trashItems = [];
  final Set<String> _selectedItemIds = <String>{};
  bool _isLoading = true;
  bool _isApplyingAction = false;
  String? _errorMessage;
  _TrashRetriableAction? _lastRetriableAction;

  @override
  void initState() {
    super.initState();
    _loadTrashItems();
  }

  bool get _isSelectionMode => _selectedItemIds.isNotEmpty;

  Future<void> _loadTrashItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await (widget.loadTrashItems?.call() ?? _inventoryService.getTrashItems());
      setState(() {
        _trashItems = items;
        _selectedItemIds.removeWhere((id) => !_trashItems.any((item) => item.id == id));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = userFriendlyError(e);
        _isLoading = false;
      });
    }
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

  Future<void> _runAction(
    _TrashActionType action,
    AppLocalizations l10n,
  ) async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('trash_select_items'))),
      );
      return;
    }

    if (_isApplyingAction) return;

    final request = InventoryTrashBulkRequestDto(itemIds: _selectedItemIds.toList());

    setState(() => _isApplyingAction = true);

    try {
      final response = await (action == _TrashActionType.restore
          ? (widget.restoreItems?.call(request) ?? _inventoryService.restoreTrashItems(request))
          : (widget.deleteItems?.call(request) ?? _inventoryService.deleteTrashItems(request)));

      if (!mounted) return;

      _lastRetriableAction = null;
      setState(() {
        _isApplyingAction = false;
        _selectedItemIds.clear();
      });

      final message = response.hasPartialErrors
          ? l10n.translate(
              'trash_bulk_partial',
              params: {
                'updated': response.updated.toString(),
                'requested': response.requested.toString(),
                'errors': response.errors.length.toString(),
              },
            )
          : l10n.translate(
              action == _TrashActionType.restore
                  ? 'trash_restore_success'
                  : 'trash_delete_success',
              params: {'count': response.updated.toString()},
            );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      await _loadTrashItems();
    } catch (e) {
      if (!mounted) return;

      _lastRetriableAction = _TrashRetriableAction(
        action: action,
        request: request,
      );
      setState(() => _isApplyingAction = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFriendlyError(e)),
          action: SnackBarAction(
            label: l10n.translate('retry'),
            onPressed: () {
              final lastAction = _lastRetriableAction;
              if (lastAction != null) {
                _selectedItemIds
                  ..clear()
                  ..addAll(lastAction.request.itemIds);
                _runAction(lastAction.action, l10n);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndDelete(AppLocalizations l10n) async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('trash_select_items'))),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('trash_delete_confirm_title')),
        content: Text(
          l10n.translate(
            'trash_delete_confirm_message',
            params: {'count': _selectedItemIds.length.toString()},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.translate('delete_forever')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _runAction(_TrashActionType.deleteForever, l10n);
    }
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
              Icon(Icons.delete_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                l10n.translate('no_trash_items'),
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
              onPressed: _loadTrashItems,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
            ),
          ],
        ),
      ),
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
                  'trash_selected_count',
                  params: {'count': _selectedItemIds.length.toString()},
                )
              : l10n.translate('trash'),
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
                  : const Icon(Icons.restore_from_trash_outlined),
              onPressed: _isApplyingAction ? null : () => _runAction(_TrashActionType.restore, l10n),
              tooltip: l10n.translate('restore'),
            ),
            PopupMenuButton<String>(
              enabled: !_isApplyingAction,
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmAndDelete(l10n);
                } else if (value == 'clear') {
                  _clearSelection();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(l10n.translate('delete_forever')),
                ),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Text(l10n.translate('clear_selection')),
                ),
              ],
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTrashItems,
              tooltip: l10n.refresh,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrashItems,
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
                : _trashItems.isEmpty
                    ? _buildEmptyState(l10n)
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: _trashItems.length,
                        itemBuilder: (context, index) {
                          final item = _trashItems[index];
                          final isSelected = _selectedItemIds.contains(item.id);
                          return Card(
                            color: Colors.grey.shade100,
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blueGrey.shade100,
                              leading: const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              title: Text(
                                item.productName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.locationName != null && item.locationName!.isNotEmpty)
                                    Text(item.locationName!),
                                  if (item.expirationDate.isNotEmpty)
                                    Text(
                                      '${l10n.date}: ${_formatExpirationDate(item.expirationDate)}',
                                    ),
                                  Text(item.status),
                                ],
                              ),
                              trailing: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: _isApplyingAction ? null : (_) => _toggleSelection(item.id),
                                    )
                                  : null,
                              onTap: _isSelectionMode
                                  ? (_isApplyingAction ? null : () => _toggleSelection(item.id))
                                  : null,
                              onLongPress: _isApplyingAction ? null : () => _toggleSelection(item.id),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _TrashRetriableAction {
  final _TrashActionType action;
  final InventoryTrashBulkRequestDto request;

  const _TrashRetriableAction({
    required this.action,
    required this.request,
  });
}

