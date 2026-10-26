import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/catalog_product.dart';

class EditCatalogProductScreen extends StatefulWidget {
  final CatalogProduct product;

  const EditCatalogProductScreen({super.key, required this.product});

  @override
  State<EditCatalogProductScreen> createState() => _EditCatalogProductScreenState();
}

class _EditCatalogProductScreenState extends State<EditCatalogProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _categoryController;
  late TextEditingController _shelfLifeController;
  late bool _isPerishable;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _categoryController = TextEditingController(text: widget.product.category ?? '');
    _shelfLifeController = TextEditingController(
      text: widget.product.shelfLifeDays?.toString() ?? '',
    );
    _isPerishable = widget.product.isPerishable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _shelfLifeController.dispose();
    super.dispose();
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
          'category': _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          'isPerishable': _isPerishable,
          'shelfLifeDays': _isPerishable && _shelfLifeController.text.isNotEmpty
              ? int.parse(_shelfLifeController.text)
              : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
        actions: [
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
                  TextFormField(
                    controller: _nameController,
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
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Producto Perecedero'),
                    value: _isPerishable,
                    onChanged: (value) {
                      setState(() => _isPerishable = value);
                    },
                  ),
                  if (_isPerishable) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shelfLifeController,
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
