import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../models/category_model.dart';
import '../models/item_model.dart' as item_model;
import '../services/category_services.dart';

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
    try {
      final cats = await CategoryService.getCategories();
      setState(() {
        if (cats.isNotEmpty) {
          _categories = cats;
          _selectedCategory = widget.item != null
              ? cats.firstWhere(
                  (c) => c.id == widget.item!.categoryId,
                  orElse: () => cats.first, // ✅ always returns a Category
                )
              : cats.first;
        } else {
          _categories = [];
          _selectedCategory = null;
        }
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
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
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = widget.item == null
          ? Uri.parse('http://192.168.108.122:8000/api/items')
          : Uri.parse(
              'http://192.168.108.122:8000/api/items/${widget.item!.id}',
            );

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
              widget.item == null ? 'Item created' : 'Item updated',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Item' : 'Add Item')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter price'
                          : null,
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
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),

                    // Image Picker
                    Row(
                      children: [
                        if (_imageFile != null)
                          Image.file(
                            _imageFile!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        else if (_imagePath != null)
                          Image.network(
                            'http://192.168.108.122:8000$_imagePath',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Choose Image'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveItem,
                        icon: Icon(isEdit ? Icons.update : Icons.add),
                        label: Text(isEdit ? 'Update Item' : 'Create Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
