import 'dart:async';

import 'package:flutter/material.dart';
import '../models/catalog_product.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/catalog_master_link_service.dart';
import '../services/master_product_service.dart';

class EditCatalogProductScreen extends StatefulWidget {
  final CatalogProduct product;

  const EditCatalogProductScreen({super.key, required this.product});

  @override
  State<EditCatalogProductScreen> createState() => _EditCatalogProductScreenState();
}

class _EditCatalogProductScreenState extends State<EditCatalogProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  final MasterProductService _masterService = MasterProductService();
  final CatalogMasterLinkService _linkService = CatalogMasterLinkService();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _categoryController;
  late TextEditingController _shelfLifeController;
  late TextEditingController _masterSearchController;
  late bool _isPerishable;
  bool _isLoading = false;
  bool _isAdmin = false;

  String? _linkedMasterId;
  String? _linkedMasterName;
  List<MasterProductDto> _masterSuggestions = [];
  bool _searchingMasters = false;
  Timer? _masterDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _categoryController = TextEditingController(text: widget.product.category ?? '');
    _shelfLifeController = TextEditingController(
      text: widget.product.shelfLifeDays?.toString() ?? '',
    );
    _masterSearchController = TextEditingController();
    _isPerishable = widget.product.isPerishable;
    _linkedMasterId = widget.product.masterProductId;
    _linkedMasterName = widget.product.masterCanonicalName;
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final admin = await AuthService().isAdmin();
    if (mounted) setState(() => _isAdmin = admin);
  }

  @override
  void dispose() {
    _masterDebounce?.cancel();
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _shelfLifeController.dispose();
    _masterSearchController.dispose();
    super.dispose();
  }

  void _onMasterSearchChanged(String value) {
    _masterDebounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _masterSuggestions = [];
        _searchingMasters = false;
      });
      return;
    }
    setState(() => _searchingMasters = true);
    _masterDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _masterService.search(q);
        if (!mounted || _masterSearchController.text.trim() != q) return;
        setState(() {
          _masterSuggestions = results;
          _searchingMasters = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _masterSuggestions = [];
          _searchingMasters = false;
        });
      }
    });
  }

  Future<void> _linkExisting(MasterProductDto master) async {
    setState(() => _isLoading = true);
    try {
      final updated = await _linkService.linkMaster(
        catalogProductId: widget.product.id,
        masterProductId: master.id,
      );
      if (!mounted) return;
      setState(() {
        _linkedMasterId = updated['masterProductId']?.toString() ?? master.id;
        _linkedMasterName =
            updated['masterCanonicalName']?.toString() ?? master.canonicalName;
        _masterSuggestions = [];
        _masterSearchController.clear();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vinculado a ${master.canonicalName}')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al vincular: $e')),
        );
      }
    }
  }

  Future<void> _createAndLink() async {
    final name = _masterSearchController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final updated = await _linkService.linkMaster(
        catalogProductId: widget.product.id,
        masterCanonicalName: name,
        createIfMissing: true,
      );
      if (!mounted) return;
      setState(() {
        _linkedMasterId = updated['masterProductId']?.toString();
        _linkedMasterName = updated['masterCanonicalName']?.toString() ?? name;
        _masterSuggestions = [];
        _masterSearchController.clear();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maestro «$name» vinculado')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _unlinkMaster() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.dio.put(
        '/api/catalog-products/${widget.product.id}',
        data: {
          'name': _nameController.text.trim(),
          'brand': _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          'category': _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          'isPerishable': _isPerishable,
          'shelfLifeDays': _isPerishable && _shelfLifeController.text.isNotEmpty
              ? int.parse(_shelfLifeController.text)
              : null,
          'masterProductId': null,
        },
      );
      if (!mounted) return;
      setState(() {
        _linkedMasterId = null;
        _linkedMasterName = null;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maestro desvinculado')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desvincular: $e')),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.dio.put(
        '/api/catalog-products/${widget.product.id}',
        data: {
          'name': _nameController.text.trim(),
          'brand': _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          'category':
              _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          'isPerishable': _isPerishable,
          'shelfLifeDays': _isPerishable && _shelfLifeController.text.isNotEmpty
              ? int.parse(_shelfLifeController.text)
              : null,
          if (_linkedMasterId != null) 'masterProductId': _linkedMasterId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este producto del catálogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.dio.delete('/api/catalog-products/${widget.product.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildMasterSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text('Producto maestro (comparativa)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Ej.: «PIÑA S/AZ AÑADIDO» → buscar o crear «ZUMO DE PIÑA».',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_linkedMasterName != null && _linkedMasterName!.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: Text(_linkedMasterName!),
              subtitle: Text(_linkedMasterId ?? ''),
              trailing: IconButton(
                tooltip: 'Desvincular',
                icon: const Icon(Icons.link_off),
                onPressed: _isLoading ? null : _unlinkMaster,
              ),
            ),
          )
        else
          Text(
            'Sin maestro vinculado — no entrará bien en la comparativa de lista.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _masterSearchController,
          decoration: InputDecoration(
            labelText: 'Buscar / crear maestro',
            hintText: widget.product.name,
            border: const OutlineInputBorder(),
            suffixIcon: _searchingMasters
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Usar nombre del producto',
                    icon: const Icon(Icons.content_paste_go),
                    onPressed: () {
                      _masterSearchController.text = widget.product.name;
                      _onMasterSearchChanged(widget.product.name);
                    },
                  ),
          ),
          onChanged: _onMasterSearchChanged,
        ),
        if (_masterSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._masterSuggestions.map(
            (m) => ListTile(
              dense: true,
              title: Text(m.canonicalName),
              subtitle: m.brand != null ? Text(m.brand!) : null,
              trailing: const Icon(Icons.link),
              onTap: _isLoading ? null : () => _linkExisting(m),
            ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isLoading || _masterSearchController.text.trim().isEmpty
              ? null
              : _createAndLink,
          icon: const Icon(Icons.add_link),
          label: const Text('Crear maestro con este nombre y vincular'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!_isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Solo lectura: guardar / vincular maestro requiere rol ADMIN.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _nameController,
                    enabled: _isAdmin,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _brandController,
                    enabled: _isAdmin,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    enabled: _isAdmin,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Producto Perecedero'),
                    value: _isPerishable,
                    onChanged: _isAdmin
                        ? (value) {
                            setState(() => _isPerishable = value);
                          }
                        : null,
                  ),
                  if (_isPerishable) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shelfLifeController,
                      enabled: _isAdmin,
                      decoration: const InputDecoration(
                        labelText: 'Vida útil (días)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_isPerishable && (value == null || value.isEmpty)) {
                          return 'Ingresa la vida útil';
                        }
                        if (value != null && value.isNotEmpty) {
                          final days = int.tryParse(value);
                          if (days == null || days <= 0) {
                            return 'Debe ser un número positivo';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_isAdmin) _buildMasterSection(theme),
                  if (_isAdmin) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
