import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_services.dart';
import '../taskbar_screen.dart';

class RestaurantScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const RestaurantScreen({super.key, required this.onThemeToggle});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _profileImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'setup_restaurant': 'Setup Restaurant',
      'pick_image': 'Pick Image',
      'restaurant_name': 'Restaurant Name',
      'enter_restaurant_name': 'Please enter restaurant name',
      'address': 'Address',
      'enter_address': 'Please enter address',
      'save_restaurant': 'Save Restaurant',
      'failed_pick_image': 'Failed to pick image: ',
      'failed_create_restaurant': 'Failed to create restaurant: ',
    },
    'Khmer': {
      'setup_restaurant': 'កំណត់ភោជនីយដ្ឋាន',
      'pick_image': 'ជ្រើសរើសរូបភាព',
      'restaurant_name': 'ឈ្មោះភោជនីយដ្ឋាន',
      'enter_restaurant_name': 'សូមបញ្ចូលឈ្មោះភោជនីយដ្ឋាន',
      'address': 'អាសយដ្ឋាន',
      'enter_address': 'សូមបញ្ចូលអាសយដ្ឋាន',
      'save_restaurant': 'រក្សាទុកភោជនីយដ្ឋាន',
      'failed_pick_image': 'បរាជ័យក្នុងការជ្រើសរូបភាព៖ ',
      'failed_create_restaurant': 'បរាជ័យក្នុងការបង្កើតភោជនីយដ្ឋាន៖ ',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage(); // Load saved language on initialization
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
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
      if (context.mounted) {
        final lang = localization[selectedLanguage]!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${lang['failed_pick_image']!}$e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ApiService.createRestaurant(
          restaurantName: _nameController.text.trim(),
          address: _addressController.text.trim(),
          profileImage: _profileImage,
          webImageBytes: _webImageBytes,
          webImageName: _webImageName,
        );

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MenuScreen(onThemeToggle: widget.onThemeToggle),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final lang = localization[selectedLanguage]!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${lang['failed_create_restaurant']!}$e')),
          );
        }
      }
    }
  }

  TextStyle getTextStyle({bool isSubtitle = false, bool isGray = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: isSubtitle ? 14 : 16,
      color: isGray
          ? isDark ? Colors.grey[400] : Colors.grey[600]
          : isSubtitle
              ? isDark ? Colors.grey[300] : Colors.grey[700]
              : isDark ? Colors.white : Colors.black,
      fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          lang['setup_restaurant']!,
          style: TextStyle(
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            color: isDark ? Colors.white : Colors.white,
          ),
        ),
        backgroundColor: isDark ? Colors.deepPurple[800] : Colors.deepPurple[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: isDark
                        ? Colors.deepPurple.shade800
                        : Colors.deepPurple.shade100,
                    backgroundImage: _getProfileImage(),
                    child: _profileImage == null && _webImageBytes == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: isDark ? Colors.white70 : Colors.deepPurple,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang['restaurant_name']!,
                  prefixIcon: Icon(
                    Icons.restaurant,
                    color: isDark ? Colors.white70 : Colors.deepPurple,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.deepPurple[400]! : Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  labelStyle: getTextStyle(),
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                  filled: true,
                ),
                style: getTextStyle(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang['enter_restaurant_name']!;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: lang['address']!,
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: isDark ? Colors.white70 : Colors.deepPurple,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDark ? Colors.deepPurple[400]! : Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  labelStyle: getTextStyle(),
                  fillColor: isDark ? Colors.grey[800] : Colors.white,
                  filled: true,
                ),
                style: getTextStyle(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang['enter_address']!;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.deepPurple[700] : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  lang['save_restaurant']!,
                  style: TextStyle(
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
    return null;
  }
}