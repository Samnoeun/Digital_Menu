import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/category_model.dart';
import '../../models/item_model.dart' as item_model;
import '../../services/api_services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../services/image_picker_service.dart';

class AddItemScreen extends StatefulWidget {
  final item_model.Item? item;
  const AddItemScreen({Key? key, this.item}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  bool _isSelectionMode = false;
  Set<int> _selectedItemIds = {};
  List<Category> _categories = [];
  Category? _selectedCategory;
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imagePath;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItemIds.clear();
      }
    });
  }

  Future<void> _initializeForm() async {
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descController.text = widget.item!.description ?? '';
      _priceController.text = widget.item!.price.toString();
      _imagePath = widget.item!.imagePath;
    }
    await _fetchCategories();
    _animationController.forward();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        if (widget.item != null && cats.isNotEmpty) {
          _selectedCategory = cats.firstWhere(
            (c) => c.id == widget.item!.categoryId,
            orElse: () => cats.first,
          );
        } else if (cats.isNotEmpty) {
          _selectedCategory = cats.first;
        }
      });
    } catch (e) {
      _showErrorSnackbar('Failed to load categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await ImagePickerService.pickImage();
      if (result != null) {
        setState(() {
          if (kIsWeb) {
            _imageBytes = result.webBytes;
            _imageFile = null;
          } else {
            _imageFile = result.mobileFile;
            _imageBytes = null;
          }
          _imagePath = null;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      _showErrorSnackbar('Please fill all required fields');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final description = _descController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final categoryId = _selectedCategory!.id;

      if (widget.item == null) {
        await ApiService.createItem(
          name: name,
          description: description,
          price: price,
          categoryId: categoryId,
          imageFile: _imageFile,
          imageBytes: _imageBytes,
        );
        _showSuccessSnackbar('Item created successfully');
      } else {
        await ApiService.updateItem(
          widget.item!.id,
          name: name,
          description: description,
          price: price,
          categoryId: categoryId,
          imageFile: _imageFile,
          imageBytes: _imageBytes,
        );
        _showSuccessSnackbar('Item updated successfully');
      }
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text('Delete ${widget.item!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteItem(widget.item!.id);
      _showSuccessSnackbar('Item deleted successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackbar('Failed to delete item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? 'Edit Item' : 'Add Item',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade700,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _toggleSelectionMode,
            child: const Text(
              'Select',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.deepPurple.shade600,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Colors.deepPurple.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Image Picker with Animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade100,
                                  Colors.deepPurple.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.deepPurple.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _imageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : _imagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: Image.network(
                                              ApiService.getImageUrl(_imagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.broken_image_rounded,
                                                size: 50,
                                                color: Colors.deepPurple.shade400,
                                              ),
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate_rounded,
                                                size: 50,
                                                color: Colors.deepPurple.shade600,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Add Image',
                                                style: TextStyle(
                                                  color: Colors.deepPurple.shade600,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Name Field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            labelStyle: TextStyle(color: Colors.deepPurple.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              Icons.restaurant_menu,
                              color: Colors.deepPurple.shade600,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter item name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description Field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        child: TextFormField(
                          controller: _descController,
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            labelStyle: TextStyle(color: Colors.deepPurple.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              Icons.description_rounded,
                              color: Colors.deepPurple.shade600,
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price Field
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Price',
                            labelStyle: TextStyle(color: Colors.deepPurple.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              Icons.attach_money_rounded,
                              color: Colors.deepPurple.shade600,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category Dropdown
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        child: DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          items: _categories.map((category) {
                            return DropdownMenuItem<Category>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: Colors.deepPurple.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              color: Colors.deepPurple.shade600,
                            ),
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select category';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Submit Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: Colors.deepPurple.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isEdit ? 'Update Item' : 'Create Item',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}