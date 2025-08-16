import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../../services/api_services.dart';
import '../../models/restaurant_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _profileImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  Restaurant? _restaurant;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    setState(() => _isLoading = true);
    try {
      final restaurant = await ApiService.getRestaurant();
      if (restaurant != null) {
        setState(() {
          _restaurant = restaurant;
          _nameController.text = _restaurant!.restaurantName;
          _addressController.text = _restaurant!.address ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading restaurant data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurant data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        final completer = Completer<void>();
        
        uploadInput.onChange.listen((e) {
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            final reader = html.FileReader();
            
            reader.onLoadEnd.listen((e) {
              setState(() {
                _webImageBytes = reader.result as Uint8List?;
                _webImageName = file.name;
                _profileImage = null;
              });
              completer.complete();
            });
            
            reader.readAsArrayBuffer(file);
          } else {
            completer.complete();
          }
        });

        await completer.future;
      } else {
        final picker = ImagePicker();
        final pickedImage = await picker.pickImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          setState(() {
            _profileImage = File(pickedImage.path);
            _webImageBytes = null;
            _webImageName = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ApiService.updateRestaurant(
        id: _restaurant?.id ?? 1,
        restaurantName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        profileImage: _profileImage,
        webImageBytes: _webImageBytes,
        webImageName: _webImageName,
      );

      await _loadRestaurantData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Restaurant updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple;
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final iconColor = isDarkMode ? Colors.white : Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
                splashRadius: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Edit Restaurant',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: scaffoldBgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile image with shadow and border
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: isDarkMode 
                                  ? Colors.grey[700] 
                                  : Colors.deepPurple.shade50,
                              backgroundImage: _getProfileImage(),
                              child: _showProfilePlaceholder(isDarkMode),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[800] : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primaryColor!, 
                                  width: 2),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Restaurant Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Restaurant Name',
                        hintText: 'Enter restaurant name',
                        prefixIcon: Icon(Icons.restaurant, color: iconColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: cardColor,
                        labelStyle: TextStyle(color: textColor),
                        hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter restaurant name';
                        }
                        return null;
                      },
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 28),

                    // Address field
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter restaurant address',
                        prefixIcon: Icon(Icons.location_on, color: iconColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: cardColor,
                        labelStyle: TextStyle(color: textColor),
                        hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 36),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'SAVE CHANGES',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_webImageBytes != null) return MemoryImage(_webImageBytes!);
    if (_restaurant?.profile != null && _restaurant!.profile!.isNotEmpty) {
      return NetworkImage(ApiService.getImageUrl(_restaurant!.profile!));
    }
    return null;
  }

  Widget? _showProfilePlaceholder(bool isDarkMode) {
    if (_profileImage != null || _webImageBytes != null) return null;
    if (_restaurant?.profile == null || _restaurant!.profile!.isEmpty) {
      return Icon(
        Icons.restaurant, 
        size: 60, 
        color: isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple,
      );
    }
    return null;
  }
}