import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/category_model.dart' as my_models;
import '../../models/item_model.dart' as item_model;
import '../../services/api_services.dart';
import '../../services/image_picker_service.dart'; // For ImagePickerService

class AddItemScreen extends StatefulWidget {
  final item_model.Item? item;
  final Function(bool)? onThemeToggle;
  const AddItemScreen({Key? key, this.item, this.onThemeToggle})
    : super(key: key);

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
  List<my_models.Category> _categories = [];
  my_models.Category? _selectedCategory;
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imagePath;
  String? _webImageName;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDuplicateName = false;

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

  Future<void> _checkDuplicateName(String name) async {
    if (name.isEmpty) return;

    try {
      final items = await ApiService.getItems();
      final exists = items.any(
        (item) =>
            item.name.toLowerCase() == name.toLowerCase() &&
            (widget.item == null || item.id != widget.item!.id),
      );

      if (mounted) {
        setState(() {
          _isDuplicateName = exists;
        });
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await ApiService.getCategories();
      setState(() {
        _categories = cats;
        if (widget.item != null && cats.isNotEmpty) {
          _selectedCategory = cats.firstWhere(
            (my_models.Category c) => c.id == widget.item!.categoryId,
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
      if (kIsWeb) {
        final result = await ImagePickerService.pickImage();
        if (result != null && result.webBytes != null) {
          setState(() {
            _webImageBytes = result.webBytes;
            _webImageName = result.fileName;
            _imageFile = null;
            _imagePath = null;
          });
        }
      } else {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          setState(() {
            _imageFile = File(picked.path);
            _webImageBytes = null;
            _webImageName = null;
            _imagePath = null;
          });
        }
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
          webImageBytes: _webImageBytes,
          webImageName: _webImageName,
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
          webImageBytes: _webImageBytes,
          webImageName: _webImageName,
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
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              'Confirm Delete',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ${widget.item!.name}?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
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
        backgroundColor: Colors.red,
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
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                ), // Explicit white text
              ),
            ),
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.grey[900]
          : Colors.deepPurple.shade50,
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
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteItem,
              tooltip: 'Delete Item',
            ),
          if (widget.onThemeToggle != null)
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () {
                widget.onThemeToggle!(isDarkMode);
              },
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
                    color: Colors.deepPurple.shade700,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',

                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey[400]
                          : Colors.deepPurple.shade600,
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
                                colors: isDarkMode
                                    ? [
                                        Colors.grey.shade700,
                                        Colors.grey.shade800,
                                      ]
                                    : [
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
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _webImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.memory(
                                      _webImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _imagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      ApiService.getImageUrl(widget.item!.imagePath),
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.broken_image_rounded,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.deepPurple.shade600,
                                            size: 32,
                                          ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 50,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.deepPurple.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Image',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.deepPurple.shade600,
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

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.deepPurple.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.white,
                            prefixIcon: Icon(
                              Icons.restaurant_menu,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.deepPurple.shade600,
                            ),
                            errorText: _isDuplicateName
                                ? '"${_nameController.text}" already exists'
                                : null,
                            errorStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.red[400]
                                  : Colors.red, // Red color for errors
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.red[400]!
                                    : Colors.red, // Red border for errors
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),

                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.red[400]!
                                    : Colors
                                          .red, // Red border when focused with error
                                width: 2,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter item name';
                            }
                            if (_isDuplicateName) {
                              return '"$value" already exists. Please use a different name.';
                            }
                            return null;
                          },
                          onChanged: (value) async {
                            if (_isDuplicateName) {
                              setState(() {
                                _isDuplicateName = false;
                              });
                              _formKey.currentState?.validate();
                            }
                            await _checkDuplicateName(value);
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
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.deepPurple.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.white,
                            prefixIcon: Icon(
                              Icons.description_rounded,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.deepPurple.shade600,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
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
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.deepPurple.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.white,
                            prefixIcon: Icon(
                              Icons.attach_money_rounded,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.deepPurple.shade600,
                            ),
                            errorStyle: TextStyle(
                              color: isDarkMode ? Colors.red[400] : Colors.red,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.red[400]!
                                    : Colors.red,
                                width: 1.5,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: isDarkMode
                                    ? Colors.red[400]!
                                    : Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                        child: DropdownButtonFormField<my_models.Category>(
                          value: _selectedCategory,
                          items: _categories.map((my_models.Category category) {
                            return DropdownMenuItem<my_models.Category>(
                              value: category,
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (my_models.Category? category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.deepPurple.shade600,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey[800]
                                : Colors.white,
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.deepPurple.shade600,
                            ),
                          ),
                          dropdownColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.white,
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
                            backgroundColor: Colors.deepPurple.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: Colors.deepPurple.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
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
