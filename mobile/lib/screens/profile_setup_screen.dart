import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'menu_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _selectedLogo;
  String? _networkLogoUrl;

  @override
  void initState() {
    super.initState();
    _fetchSetting();
  }

  Future<void> _fetchSetting() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.108.122:8000/api/settings/1'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        final data = jsonData['data'] ?? jsonData;

        setState(() {
          _nameController.text = data['restaurant_name'] ?? '';
          _locationController.text = data['address'] ?? '';
          if (data['logo'] != null && data['logo'].toString().isNotEmpty) {
            _networkLogoUrl = 'http://192.168.108.122:8000/storage/${data['logo']}';
          }
        });
      } else {
        print('Failed to load setting: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching setting: $e');
    }
  }

  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedLogo = File(pickedImage.path);
        _networkLogoUrl = null; // Clear network logo if user picked local file
      });
    }
  }

  Future<bool> updateSetting({
    required String restaurantName,
    required String address,
    File? logoFile,
  }) async {
    var uri = Uri.parse('http://192.168.108.122:8000/api/settings/1');
    
    var request = http.MultipartRequest('POST', uri);
    request.fields['_method'] = 'PUT'; // Laravel method spoofing
    request.fields['restaurant_name'] = restaurantName;
    request.fields['address'] = address;
    
    if (logoFile != null) {
      var multipartFile = await http.MultipartFile.fromPath('logo', logoFile.path);
      request.files.add(multipartFile);
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      print('Update successful: ${response.body}');
      return true;
    } else {
      print('Failed to update: ${response.statusCode} - ${response.body}');
      return false;
    }
  }

  void _onDone() async {
    if (_formKey.currentState!.validate()) {
      bool success = await updateSetting(
        restaurantName: _nameController.text.trim(),
        address: _locationController.text.trim(),
        logoFile: _selectedLogo,
      );

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile logo
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.deepPurple.shade100,
              backgroundImage: _selectedLogo != null
                  ? FileImage(_selectedLogo!)
                  : (_networkLogoUrl != null
                      ? NetworkImage(_networkLogoUrl!)
                      : null) as ImageProvider<Object>?,
              child: (_selectedLogo == null && _networkLogoUrl == null)
                  ? const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Colors.deepPurple,
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _pickLogoImage,
              icon: const Icon(Icons.upload),
              label: const Text('Choose Logo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 166, 130, 228),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Restaurant Name',
                prefixIcon: const Icon(Icons.restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _onDone,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    ),
  );
}

}
