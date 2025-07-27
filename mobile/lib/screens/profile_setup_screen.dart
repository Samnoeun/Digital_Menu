import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickLogoImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedLogo = File(pickedImage.path);
      });
    }
  }

  void _onDone() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
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
              // Logo Avatar (optional)
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.deepPurple.shade100,
                backgroundImage:
                    _selectedLogo != null ? FileImage(_selectedLogo!) : null,
                child: _selectedLogo == null
                    ? const Icon(Icons.account_circle, size: 80, color: Colors.deepPurple)
                    : null,
              ),

              const SizedBox(height: 12),

              // Choose Logo Button (optional)
              ElevatedButton.icon(
                onPressed: _pickLogoImage,
                icon: const Icon(Icons.upload),
                label: const Text('Choose Logo '),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 166, 130, 228),
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Restaurant Name
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

              // Location
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

              // Done Button
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
