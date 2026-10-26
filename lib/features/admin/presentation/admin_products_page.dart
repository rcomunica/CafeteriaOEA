import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../menu/data/product_repository.dart';
import '../../menu/domain/menu_item.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({required this.repository, super.key});

  final ProductRepository repository;

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  late Future<List<MenuItem>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.repository.readAll();
  }

  Future<void> _openCreateProduct() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(repository: widget.repository),
      ),
    );
    if (created == true && mounted) {
      _reloadProducts();
    }
  }

  Future<void> _reloadProducts() async {
    final future = widget.repository.readAll();
    if (!mounted) return;
    setState(() {
      _productsFuture = future;
    });
    await future;
  }

  Future<void> _editProduct(MenuItem product) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductFormPage(repository: widget.repository, product: product),
      ),
    );
    if (updated == true && mounted) {
      await _reloadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis productos'),
        actions: [
          IconButton(
            onPressed: _openCreateProduct,
            tooltip: 'Crear producto',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProduct,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'No se pudieron cargar los productos: ${snapshot.error}',
              ),
            );
          }
          final products = snapshot.data ?? const <MenuItem>[];
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos registrados.'));
          }
          return RefreshIndicator(
            onRefresh: _reloadProducts,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _ProductTile(
                item: products[index],
                onEdit: () => _editProduct(products[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.item, required this.onEdit});

  final MenuItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.all(10),
        leading: SizedBox(
          width: 64,
          height: 64,
          child: item.imageUrl == null
              ? const Icon(Icons.fastfood_outlined, size: 36)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fastfood_outlined, size: 36),
                  ),
                ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${item.category}\n\$${item.price}'),
        isThreeLine: true,
        trailing: IconButton(
          onPressed: onEdit,
          tooltip: 'Editar producto',
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({required this.repository, this.product, super.key});

  final ProductRepository repository;
  final MenuItem? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  String? _imagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _categoryController.text = product.category;
      _priceController.text = '${product.price}';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image != null && mounted) setState(() => _imagePath = image.path);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final message = error.code == 'channel-error'
          ? 'El selector de imágenes no está disponible. Reinicia la aplicación completamente.'
          : 'No se pudo seleccionar la imagen: ${error.message ?? error.code}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir foto'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null && mounted) await _pickImage(source);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final product = widget.product;
      final name = _nameController.text.trim();
      final category = _categoryController.text.trim();
      final price = int.parse(_priceController.text.trim());
      if (product == null) {
        await widget.repository.createProduct(
          name: name,
          category: category,
          price: price,
          imagePath: _imagePath,
        );
      } else {
        await widget.repository.updateProduct(
          id: product.id,
          name: name,
          category: category,
          price: price,
          imagePath: _imagePath,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'No se pudo crear el producto: $error'
                : 'No se pudo actualizar el producto: $error',
          ),
        ),
      );
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo requerido' : null;

  String? _positiveInteger(String? value) {
    if (_required(value) != null) return _required(value);
    final parsed = int.tryParse(value!.trim());
    return parsed == null || parsed < 0 ? 'Ingresa un número válido' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Crear producto' : 'Editar producto',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Categoría'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio'),
              validator: _positiveInteger,
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _chooseImageSource,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _imagePath == null
                    ? (widget.product?.imageUrl == null
                          ? 'Elegir foto o tomar foto'
                          : 'Cambiar foto')
                    : 'Foto seleccionada',
              ),
            ),
            if (_isSaving) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: Text(
                widget.product == null ? 'Crear producto' : 'Guardar cambios',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
