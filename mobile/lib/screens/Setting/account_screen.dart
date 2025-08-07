import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
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
      );

      // Refresh data after update
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        titleSpacing: 0, // Remove default title spacing
        title: Padding(
          padding: const EdgeInsets.only(
            left: 5,
            right: 0,
          ), // Optional padding
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              const Text(
                'Edit Restaurant',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.deepPurple.shade100,
                            backgroundImage: _getProfileImage(),
                            child: _showProfilePlaceholder(),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.deepPurple),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Restaurant Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant Name',
                        prefixIcon: Icon(Icons.restaurant),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter restaurant name'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter address'
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('SAVE CHANGES'),
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
    if (_restaurant?.profile != null && _restaurant!.profile!.isNotEmpty) {
      return NetworkImage(ApiService.getImageUrl(_restaurant!.profile!));
    }
    return null;
  }

  Widget? _showProfilePlaceholder() {
    if (_profileImage != null) return null;
    if (_restaurant?.profile == null || _restaurant!.profile!.isEmpty) {
      return const Icon(Icons.restaurant, size: 50, color: Colors.deepPurple);
    }
    return null;
  }
}
