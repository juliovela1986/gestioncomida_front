import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final LocationService _locationService = LocationService();
  List<LocationResponseDto> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locations = await _locationService.getUserLocations();
      if (mounted) {
        setState(() {
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.translate('error_loading', params: {'error': e.toString()})}')),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final typeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('new_location')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.translate('location_name_label')),
            ),
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: l10n.translate('location_type_label')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || typeController.text.isEmpty) {
                return;
              }
              try {
                await _locationService.createLocation({
                  'name': nameController.text,
                  'type': typeController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadLocations();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l10n.translate('create')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(LocationResponseDto location) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: location.name);
    final typeController = TextEditingController(text: location.type);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('edit_location')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.translate('location_name_label')),
            ),
            TextField(
              controller: typeController,
              decoration: InputDecoration(labelText: l10n.translate('location_type_label')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _locationService.updateLocation(location.id, {
                  'name': nameController.text,
                  'type': typeController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadLocations();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_title')),
        content: Text(l10n.translate('confirm_delete_location')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _locationService.deleteLocation(id);
        _loadLocations();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.manageLocations)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageLocations)),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _locations.isEmpty
          ? Center(child: Text(l10n.translate('no_locations')))
          : ListView.builder(
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final location = _locations[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.location_on)),
                  title: Text(location.name),
                  subtitle: Text(location.type ?? l10n.translate('no_type')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditDialog(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLocation(location.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
