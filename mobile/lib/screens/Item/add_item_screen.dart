import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/category_model.dart' as my_models;
import '../../models/item_model.dart' as item_model;
import '../../services/api_services.dart';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../../services/image_picker_service.dart'; // For ImagePickerService

class AddItemScreen extends StatefulWidget {
  final item_model.Item? item;
  final Function(bool)? onThemeToggle;
  const AddItemScreen({Key? key, this.item, this.onThemeToggle}) : super(key: key);

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> with TickerProviderStateMixin {
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
  String selectedLanguage = 'English';

  final Map<String, Map<String, String>> localization = {
    'English': {
      'edit_item': 'Edit Item',
      'add_item': 'Add Item',
      'add_image': 'Add Image',
      'change_image': 'Change Image',
      'item_name': 'Item Name',
      'description_optional': 'Description (Optional)',
      'price': 'Price',
      'category': 'Category',
      'update_item': 'Update Item',
      'create_item': 'Create Item',
      'select_category': 'Select Category',
      'name_required': 'Please enter item name',
      'price_required': 'Please enter price',
      'price_valid': 'Please enter valid price',
      'category_required': 'Please select category',
      'image_required': 'Image is required',
      'loading': 'Loading...',
      'success': 'Success',
      'error': 'Error',
      'item_created': 'Item created successfully',
      'item_updated': 'Item updated successfully',
      'item_deleted': 'Item deleted successfully',
      'create_failed': 'Failed to create item',
      'update_failed': 'Failed to update item',
      'delete_failed': 'Failed to delete item',
      'categories_failed': 'Failed to load categories',
      'image_failed': 'Failed to pick image',
      'fill_required': 'Please fill all required fields',
      'confirm_delete': 'Confirm Delete',
      'delete_confirm': 'Delete this item?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'choose_image': 'Choose Image',
    },
    'Khmer': {
      'edit_item': 'កែសម្រួលធាតុ',
      'add_item': 'បន្ថែមធាតុ',
      'add_image': 'បន្ថែមរូបភាព',
      'change_image': 'ផ្លាស់ប្តូររូបភាព',
      'item_name': 'ឈ្មោះធាតុ',
      'description_optional': 'ការពិពណ៌នា (ជាជម្រើស)',
      'price': 'តម្លៃ',
      'category': 'ប្រភេទ',
      'update_item': 'ធ្វើបច្ចុប្បន្នភាពធាតុ',
      'create_item': 'បង្កើតធាតុ',
      'select_category': 'ជ្រើសរើសប្រភេទ',
      'name_required': 'សូមបញ្ចូលឈ្មោះធាតុ',
      'price_required': 'សូមបញ្ចូលតម្លៃ',
      'price_valid': 'សូមបញ្ចូលតម្លៃដែលត្រឹមត្រូវ',
      'category_required': 'សូមជ្រើសរើសប្រភេទ',
      'image_required': 'រូបភាពត្រូវបានទាមទារ',
      'loading': 'កំពុងផ្ទុក...',
      'success': 'ជោគជ័យ',
      'error': 'កំហុស',
      'item_created': 'ធាតុត្រូវបានបង្កើតដោយជោគជ័យ',
      'item_updated': 'ធាតុត្រូវបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ',
      'item_deleted': 'ធាតុត្រូវបានលុបដោយជោគជ័យ',
      'create_failed': 'បរាជ័យក្នុងការបង្កើតធាតុ',
      'update_failed': 'បរាជ័យក្នុងការធ្វើបច្ចុប្បន្នភាពធាតុ',
      'delete_failed': 'បរាជ័យក្នុងការលុបធាតុ',
      'categories_failed': 'បរាជ័យក្នុងការផ្ទុកប្រភេទ',
      'image_failed': 'បរាជ័យក្នុងការជ្រើសរើសរូបភាព',
      'fill_required': 'សូមបំពេញគ្រប់ផ្នែកដែលត្រូវការ',
      'confirm_delete': 'បញ្ជាក់ការលុប',
      'delete_confirm': 'លុបធាតុនេះ?',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'camera': 'កាមេរ៉ា',
      'gallery': 'វិចិត្រសាល',
      'choose_image': 'ជ្រើសរើសរូបភាព',
    },
  };

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
    _loadSavedLanguage();
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

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  TextStyle getTextStyle({bool isBold = false, double? fontSize, Color? color}) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: fontSize ?? 16,
      color: color ?? Theme.of(context).textTheme.bodyLarge!.color,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );
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
            (my_models.Category c) => c.id == widget.item!.categoryId,
            orElse: () => cats.first,
          );
        } else if (cats.isNotEmpty) {
          _selectedCategory = cats.first;
        }
      });
    } catch (e) {
      final lang = localization[selectedLanguage]!;
      _showErrorSnackbar('${lang['categories_failed']!}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final lang = localization[selectedLanguage]!;
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
        final source = await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(lang['camera']!),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(lang['gallery']!),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );

        if (source != null) {
          final picked = await ImagePicker().pickImage(source: source);
          if (picked != null) {
            setState(() {
              _imageFile = File(picked.path);
              _webImageBytes = null;
              _webImageName = null;
              _imagePath = null;
            });
          }
        }
      }
    } catch (e) {
      _showErrorSnackbar('${lang['image_failed']!}: $e');
    }
  }

  Future<void> _saveItem() async {
    final lang = localization[selectedLanguage]!;
    
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      _showErrorSnackbar(lang['fill_required']!);
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
        _showSuccessSnackbar(lang['item_created']!);
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
        _showSuccessSnackbar(lang['item_updated']!);
      }
      Navigator.pop(context, true);
    } catch (e) {
      final errorMsg = widget.item != null ? lang['update_failed']! : lang['create_failed']!;
      _showErrorSnackbar('$errorMsg: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    final lang = localization[selectedLanguage]!;
    
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
              lang['confirm_delete']!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
        content: Text(
          '${lang['delete_confirm']!} "${widget.item!.name}"?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang['cancel']!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
            child: Text(
              lang['delete']!,
              style: TextStyle(
                color: Colors.white,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.deleteItem(widget.item!.id);
      _showSuccessSnackbar(lang['item_deleted']!);
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorSnackbar('${lang['delete_failed']!}: $e');
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
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade700,
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
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
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
    final lang = localization[selectedLanguage]!;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? lang['edit_item']! : lang['add_item']!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
              tooltip: lang['delete']!,
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
                    lang['loading']!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                                    ? [Colors.grey.shade700, Colors.grey.shade800]
                                    : [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
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
                                              ApiService.getImageUrl(_imagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.broken_image_rounded,
                                                size: 50,
                                                color: isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.deepPurple.shade400,
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
                                                lang['add_image']!,
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? Colors.grey[400]
                                                      : Colors.deepPurple.shade600,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                            labelText: lang['item_name']!,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            prefixIcon: Icon(
                              Icons.restaurant_menu,
                              color: isDarkMode ? Colors.white : Colors.deepPurple.shade600,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang['name_required']!;
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
                            labelText: lang['description_optional']!,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            prefixIcon: Icon(
                              Icons.description_rounded,
                              color: isDarkMode ? Colors.white : Colors.deepPurple.shade600,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                            labelText: lang['price']!,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            prefixIcon: Icon(
                              Icons.attach_money_rounded,
                              color: isDarkMode ? Colors.white : Colors.deepPurple.shade600,
                            ),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang['price_required']!;
                            }
                            if (double.tryParse(value) == null) {
                              return lang['price_valid']!;
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
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                            labelText: lang['category']!,
                            labelStyle: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.deepPurple.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.deepPurple.shade600,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              color: isDarkMode ? Colors.white : Colors.deepPurple.shade600,
                            ),
                          ),
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          validator: (value) {
                            if (value == null) {
                              return lang['category_required']!;
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
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isEdit ? lang['update_item']! : lang['create_item']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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