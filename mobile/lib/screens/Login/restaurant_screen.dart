import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create restaurant: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Setup Restaurant',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Colors.deepPurple.shade700, 
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
                  labelText: 'Restaurant Name',
                  prefixIcon: Icon(
                    Icons.restaurant,
                    color: isDark ? Colors.white : Colors.deepPurple,
                  ),
                  border: const OutlineInputBorder(),
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter restaurant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',

                  prefixIcon: Icon(
                    Icons.location_on,
                    color: isDark ? Colors.white : Colors.deepPurple,
                  ),
                  border: const OutlineInputBorder(),
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: _submit,
                style: Theme.of(context).elevatedButtonTheme.style,
                child: const Text('Save Restaurant'),
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
