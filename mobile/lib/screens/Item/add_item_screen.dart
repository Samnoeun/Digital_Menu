import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../models/category_model.dart';
import '../../models/item_model.dart' as item_model;
import '../../services/api_services.dart';

class AddItemScreen extends StatefulWidget {
  final item_model.Item? item;
  const AddItemScreen({Key? key, this.item}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  List<Category> _categories = [];
  Category? _selectedCategory;
  File? _imageFile;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descController.text = widget.item!.description ?? '';
      _priceController.text = widget.item!.price.toString();
      _imagePath = widget.item!.imagePath;
    }
    await _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        if (cats.isNotEmpty) {
          _categories = cats;
          _selectedCategory = widget.item != null
              ? cats.firstWhere(
                  (c) => c.id == widget.item!.categoryId,
                  orElse: () => cats.first,
                )
              : cats.first;
        } else {
          _categories = [];
          _selectedCategory = null;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load categories: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _imagePath = null; // Reset path for update
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = widget.item == null
          ? Uri.parse('${ApiService.baseUrl}/api/items')
          : Uri.parse('${ApiService.baseUrl}/api/items/${widget.item!.id}');

      final request = http.MultipartRequest('POST', uri)
        ..fields['name'] = _nameController.text.trim()
        ..fields['description'] = _descController.text.trim()
        ..fields['price'] = _priceController.text.trim()
        ..fields['category_id'] = _selectedCategory!.id.toString();

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _imageFile!.path),
        );
      } else if (_imagePath != null && widget.item != null) {
        request.fields['image_path'] = _imagePath!;
      }

      if (widget.item != null) {
        request.fields['_method'] = 'PUT';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item == null
                  ? '${_nameController.text.trim()} created successfully'
                  : '${_nameController.text.trim()} updated successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Item' : 'Add Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Item'),
                    content: Text(
                      'Are you sure you want to delete "${widget.item!.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final uri = Uri.parse(
                      '${ApiService.baseUrl}/api/items/${widget.item!.id}',
                    );
                    final request = http.MultipartRequest('POST', uri)
                      ..fields['_method'] = 'DELETE';
                    final streamedResponse = await request.send();
                    final response = await http.Response.fromStream(
                      streamedResponse,
                    );

                    if (response.statusCode == 200 ||
                        response.statusCode == 204) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.item!.name} deleted successfully',
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context, true);
                    } else {
                      throw Exception(
                        'Failed to delete item: ${response.body}',
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting item: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Delete Item',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit item details' : 'Create a new item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'e.g., Apple, Laptop',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        prefixIcon: const Icon(Icons.inventory),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an item name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters long';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'e.g., Fresh red apples',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        hintText: 'e.g., 9.99',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value.trim()) == null ||
                            double.parse(value.trim()) <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    // Category Dropdown
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem<Category>(
                              value: cat,
                              child: Text(cat.name),
                            ),
                          )
                          .toList(),
                      onChanged: _categories.isNotEmpty
                          ? (value) => setState(() => _selectedCategory = value)
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        hintText: _categories.isEmpty
                            ? 'No categories available'
                            : 'Select a category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        prefixIcon: const Icon(Icons.category),
                      ),
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    // Image Picker
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : _imagePath != null
                              ? Image.network(
                                  ApiService.getImageUrl(_imagePath),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(
                            _imageFile != null || _imagePath != null
                                ? 'Change Image'
                                : 'Choose Image',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_imageFile != null || _imagePath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () => setState(() {
                              _imageFile = null;
                              _imagePath = null;
                            }),
                            tooltip: 'Remove Image',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEdit ? Icons.update : Icons.add,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit ? 'Update Item' : 'Create Item',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
