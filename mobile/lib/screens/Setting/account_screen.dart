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
  final String selectedLanguage;
  final Function(bool) onThemeToggle;
  const AccountScreen({super.key, required this.selectedLanguage, required this.onThemeToggle});

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

  final Map<String, Map<String, String>> localization = {
    'English': {
      'edit_restaurant': 'Edit Restaurant',
      'restaurant_name': 'Restaurant Name',
      'enter_restaurant_name': 'Enter restaurant name',
      'address': 'Address',
      'enter_address': 'Enter restaurant address',
      'save_changes': 'SAVE CHANGES',
      'failed_to_load': 'Failed to load restaurant data',
      'update_success': '✅ Restaurant updated successfully',
      'update_error': '❌ Error',
      'failed_to_pick_image': 'Failed to pick image',
    },
    'Khmer': {
      'edit_restaurant': 'កែសម្រួលភោជនីយដ្ឋាន',
      'restaurant_name': 'ឈ្មោះភោជនីយដ្ឋាន',
      'enter_restaurant_name': 'បញ្ចូលឈ្មោះភោជនីយដ្ឋាន',
      'address': 'អាសយដ្ឋាន',
      'enter_address': 'បញ្ចូលអាសយដ្ឋានភោជនីយដ្ឋាន',
      'save_changes': 'រក្សាទុកការផ្លាស់ប្តូរ',
      'failed_to_load': 'បរាជ័យក្នុងការផ្ទុកទិន្នន័យភោជនីយដ្ឋាន',
      'update_success': '✅ ភោជនីយដ្ឋានបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ',
      'update_error': '❌ កំហុស',
      'failed_to_pick_image': 'បរាជ័យក្នុងការជ្រើសរើសរូបភាព',
    },
  };

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
          SnackBar(content: Text(localization[widget.selectedLanguage]!['failed_to_load']!)),
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
          SnackBar(content: Text(localization[widget.selectedLanguage]!['failed_to_pick_image']!)),
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
          SnackBar(
            content: Text(localization[widget.selectedLanguage]!['update_success']!),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization[widget.selectedLanguage]!['update_error']!}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  TextStyle getTextStyle({bool isLabel = false, bool isHint = false}) {
    final theme = Theme.of(context);
    return TextStyle(
      fontFamily: widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: isLabel ? 16 : 14,
      color: isHint
          ? theme.textTheme.bodyMedium!.color!.withOpacity(0.7)
          : theme.textTheme.bodyLarge!.color,
      fontWeight: isLabel ? FontWeight.w600 : FontWeight.w400,
    );
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
    final lang = localization[widget.selectedLanguage]!;

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
                lang['edit_restaurant']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                        labelText: lang['restaurant_name'],
                        hintText: lang['enter_restaurant_name'],
                        prefixIcon: Icon(Icons.restaurant, color: iconColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: cardColor,
                        labelStyle: getTextStyle(isLabel: true),
                        hintStyle: getTextStyle(isHint: true),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return lang['enter_restaurant_name'];
                        }
                        return null;
                      },
                      style: getTextStyle(),
                    ),
                    const SizedBox(height: 28),

                    // Address field
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: lang['address'],
                        hintText: lang['enter_address'],
                        prefixIcon: Icon(Icons.location_on, color: iconColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: cardColor,
                        labelStyle: getTextStyle(isLabel: true),
                        hintStyle: getTextStyle(isHint: true),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return lang['enter_address'];
                        }
                        return null;
                      },
                      style: getTextStyle(),
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
                            : Text(
                                lang['save_changes']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                  fontFamily: widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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