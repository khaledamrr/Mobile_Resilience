import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:async';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = 't_shirts';
  List<File?> _imageFiles = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  final List<String> _categories = [
    't_shirts',
    'jeans',
    'shorts',
    'hoodies',
    'jackets',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .order('created_at', ascending: false);
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
      });
      // Debug: Print the loaded products to check image_url
      for (var product in _products) {
        print('Product: ${product['name']}, image_url: ${product['image_url']}');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading products')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    setState(() {
      _imageFiles.addAll(pickedFiles.map((file) => File(file.path)));
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = List.from(_existingImageUrls);
      for (var image in _imageFiles) {
        if (image != null) {
          final imagePath = 'products/${DateTime.now().millisecondsSinceEpoch}_${_imageFiles.indexOf(image)}.jpg';
          await _supabase.storage.from('products').upload(
            imagePath,
            image,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          final imageUrl = _supabase.storage.from('products').getPublicUrl(imagePath);
          imageUrls.add(imageUrl);
          print('Uploaded image URL: $imageUrl');
        }
      }

      if (imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one image')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory,
        'image_url': imageUrls,
      };

      if (_selectedProduct == null) {
        // Create new product
        await _supabase.from('products').insert(productData);
      } else {
        // Update existing product
        await _supabase
            .from('products')
            .update(productData)
            .eq('id', _selectedProduct!['id']);
      }

      _formKey.currentState!.reset();
      setState(() {
        _imageFiles = [];
        _existingImageUrls = [];
        _selectedProduct = null;
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _stockController.clear();
      });
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: ${error.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
      await _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting product')),
        );
      }
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    setState(() {
      _selectedProduct = product;
      _nameController.text = product['name'];
      _descriptionController.text = product['description'];
      _priceController.text = product['price'].toString();
      _stockController.text = product['stock'].toString();
      _selectedCategory = product['category'];
      _existingImageUrls = product['image_url'] != null && product['image_url'] is List
          ? List<String>.from(product['image_url'])
          : [];
      _imageFiles = [];
      print('Editing product: ${product['name']}, existing image URLs: $_existingImageUrls');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Manage Product',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Please enter price';
                          if (double.tryParse(value!) == null) return 'Please enter a valid price';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockController,
                        decoration: InputDecoration(
                          labelText: 'Stock',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Please enter stock';
                          if (int.tryParse(value!) == null) return 'Please enter a valid quantity';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category.replaceAll('_', ' ').toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value!),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Images'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Display existing images (from URLs)
                      if (_existingImageUrls.isNotEmpty) ...[
                        const Text(
                          'Existing Images:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      _existingImageUrls[index],
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const CircularProgressIndicator();
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Failed to load existing image: ${_existingImageUrls[index]}, error: $error');
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 100,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _existingImageUrls.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      // Display newly picked images
                      if (_imageFiles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'New Images:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Image.file(
                                      _imageFiles[index]!,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _imageFiles.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                            : Text(_selectedProduct == null ? 'Add Product' : 'Update Product'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final imageUrl = product['image_url'] != null &&
                    product['image_url'] is List &&
                    product['image_url'].isNotEmpty &&
                    product['image_url'][0] is String
                    ? product['image_url'][0] as String
                    : null;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Failed to load image for ${product['name']}: $imageUrl, error: $error');
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        );
                      },
                    )
                        : const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                    title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '\$${product['price'].toStringAsFixed(2)} - Stock: ${product['stock']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editProduct(product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}