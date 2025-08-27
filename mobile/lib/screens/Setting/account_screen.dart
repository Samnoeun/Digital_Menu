import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_services.dart';
import '../../models/restaurant_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../services/image_picker_service.dart';

class AccountScreen extends StatefulWidget {
  final String selectedLanguage;
  final Function(bool)? onThemeToggle;  // Make it optional with ?
  
  const AccountScreen({
    super.key, 
    required this.selectedLanguage,
    this.onThemeToggle,  // Now it's optional
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Uint8List? _imageBytes; // For web
  dynamic _profileImage;  
  Restaurant? _restaurant;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;
  bool _showSuccess = false;

  final Map<String, Map<String, String>> localization = {
    'English': {
      'edit_restaurant': 'Edit Restaurant',
      'restaurant_name': 'Restaurant Name',
      'enter_restaurant_name': 'Enter restaurant name',
      'address': 'Address',
      'enter_address': 'Enter restaurant address',
      'save_changes': 'SAVE CHANGES',
      'failed_to_load': 'Failed to load restaurant data',
      'update_success': 'Restaurant updated successfully',
      'update_error': 'Error',
      'failed_to_pick_image': 'Failed to pick image',
      'name_required': 'Please enter restaurant name',
      'address_required': 'Please enter address',
    },
    'Khmer': {
      'edit_restaurant': 'កែសម្រួលភោជនីយដ្ឋាន',
      'restaurant_name': 'ឈ្មោះភោជនីយដ្ឋាន',
      'enter_restaurant_name': 'បញ្ចូលឈ្មោះភោជនីយដ្ឋាន',
      'address': 'អាសយដ្ឋាន',
      'enter_address': 'បញ្ចូលអាសយដ្ឋានភោជនីយដ្ឋាន',
      'save_changes': 'រក្សាទុកការផ្លាស់ប្តូរ',
      'failed_to_load': 'បរាជ័យក្នុងការផ្ទុកទិន្នន័យភោជនីយដ្ឋាន',
      'update_success': 'ភោជនីយដ្ឋានបានធ្វើបច្ចុប្បន្នភាពដោយជោគជ័យ',
      'update_error': 'កំហុស',
      'failed_to_pick_image': 'បរាជ័យក្នុងការជ្រើសរើសរូបភាព',
      'name_required': 'សូមបញ្ចូលឈ្មោះភោជនីយដ្ឋាន',
      'address_required': 'សូមបញ្ចូលអាសយដ្ឋាន',
    },
  };

  String _translate(String key) {
    return localization[widget.selectedLanguage]![key] ?? key;
  }

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
      _showStatusMessage(_translate('failed_to_load'));
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
          _profileImage = null;
        } else {
          _profileImage = result.mobileFile;
          _imageBytes = null;
        }
      });
    }
  } catch (e) {
    _showStatusMessage(_translate('failed_to_pick_image'));
  }
}

  void _showStatusMessage(String message) {
    setState(() {
      _statusMessage = message;
      _showSuccess = message.contains('successfully') || message.contains('ជោគជ័យ');
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = null;
          _showSuccess = false;
        });
      }
    });
  }

Future<void> _saveChanges() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isSaving = true;
    _statusMessage = null;
    _showSuccess = false;
  });

  try {
    if (kIsWeb) {
      // Web version - use webImageBytes and webImageName
      await ApiService.updateRestaurant(
        id: _restaurant?.id ?? 1,
        restaurantName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        webImageBytes: _imageBytes,
        webImageName: _imageBytes != null 
            ? 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg' 
            : null,
      );
    } else {
      // Mobile version - use profileImage
      await ApiService.updateRestaurant(
        id: _restaurant?.id ?? 1,
        restaurantName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        profileImage: _profileImage is File ? _profileImage : null,
      );
    }

    // Clear local image cache and reload data
    setState(() {
      _imageBytes = null;
      _profileImage = null;
    });

    await _loadRestaurantData();

    if (mounted) {
      _showStatusMessage(_translate('update_success'));
    }
  } catch (e) {
    debugPrint('Update error: $e');
    if (mounted) {
      _showStatusMessage('${_translate('update_error')}: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}

  TextStyle _getTextStyle(BuildContext context, {bool isLabel = false, bool isHint = false}) {
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
    final primaryColor = isDarkMode
        ? Colors.deepPurple[600]
        : Colors.deepPurple;
    final scaffoldBgColor = isDarkMode
        ? Colors.grey[900]
        : Colors.deepPurple[50];
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
                _translate('edit_restaurant'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: scaffoldBgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showSuccess)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _translate('update_success'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      80,
                                      55,
                                      127,
                                    ).withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
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
                                        : Colors.white,
                                    backgroundImage: _getProfileImage(),
                                    child: _showProfilePlaceholder(isDarkMode),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor!,
                                        width: 2,
                                      ),
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
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: _translate('restaurant_name'),
                              hintText: _translate('enter_restaurant_name'),
                              prefixIcon: Icon(
                                Icons.restaurant,
                                color: iconColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: cardColor,
                              labelStyle: _getTextStyle(context, isLabel: true),
                              hintStyle: _getTextStyle(context, isHint: true),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return _translate('name_required');
                              }
                              return null;
                            },
                            style: _getTextStyle(context),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: _translate('address'),
                              hintText: _translate('enter_address'),
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: iconColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              filled: true,
                              fillColor: cardColor,
                              labelStyle: _getTextStyle(context, isLabel: true),
                              hintStyle: _getTextStyle(context, isHint: true),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return _translate('address_required');
                              }
                              return null;
                            },
                            style: _getTextStyle(context),
                          ),
                          const SizedBox(height: 36),
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
                                      _translate('save_changes'),
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
                ),
              ],
            ),
    );
  }

ImageProvider? _getProfileImage() {
  if (_profileImage != null) return FileImage(_profileImage!);
  if (_imageBytes != null) return MemoryImage(_imageBytes!);
  if (_restaurant?.profile != null && _restaurant!.profile!.isNotEmpty) {
    final imageUrl = ApiService.getImageUrl(_restaurant!.profile!);
    return NetworkImage(imageUrl);
  }
  return null;
}

  Widget? _showProfilePlaceholder(bool isDarkMode) {
    if (_profileImage != null || _imageBytes != null) return null;
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