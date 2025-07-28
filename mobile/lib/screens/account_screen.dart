// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class AccountScreen extends StatefulWidget {
//   const AccountScreen({super.key});

//   @override
//   State<AccountScreen> createState() => _AccountScreenState();
// }

// class _AccountScreenState extends State<AccountScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController restaurantNameController =
//       TextEditingController(text: 'My Restaurant');
//   final TextEditingController emailController =
//       TextEditingController(text: 'owner@example.com');

//   File? _profileImage;
//   DateTime lastUpdated = DateTime.now();

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         _profileImage = File(picked.path);
//       });
//     }
//   }

//   void _saveChanges() {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         lastUpdated = DateTime.now();
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('✅ Changes saved successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: const [
//             Icon(Icons.account_circle),
//             SizedBox(width: 8),
//             Text('Account'),
//           ],
//         ),
//         backgroundColor: const Color.fromARGB(255, 201, 191, 218),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             GestureDetector(
//               onTap: _pickImage,
//               child: Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 60,
//                     backgroundColor: const Color.fromARGB(255, 191, 168, 232),
//                     backgroundImage:
//                         _profileImage != null ? FileImage(_profileImage!) : null,
//                     child: _profileImage == null
//                         ? const Icon(Icons.storefront, size: 60, color: Colors.white)
//                         : null,
//                   ),
//                   Container(
//                     padding: const EdgeInsets.all(6),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.white,
//                       border: Border.all(color: const Color.fromARGB(255, 166, 140, 212)),
//                     ),
//                     child: const Icon(Icons.edit,
//                         size: 18, color: Color.fromARGB(255, 167, 135, 222)),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             const Text(
//               'Restaurant Info',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 10),

//             Text(
//               'Last updated: ${lastUpdated.toLocal().toString().split('.')[0]}',
//               style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//             ),

//             const Divider(height: 30, thickness: 1),

//             Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   // Editable Restaurant Name
//                   TextFormField(
//                     controller: restaurantNameController,
//                     decoration: InputDecoration(
//                       labelText: 'Restaurant Name',
//                       prefixIcon: const Icon(Icons.store),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     validator: (value) =>
//                         value == null || value.isEmpty ? 'Name is required' : null,
//                   ),
//                   const SizedBox(height: 20),

//                   // Editable Email
//                   TextFormField(
//                     controller: emailController,
//                     decoration: InputDecoration(
//                       labelText: 'Email Address',
//                       prefixIcon: const Icon(Icons.email),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     keyboardType: TextInputType.emailAddress,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Email is required';
//                       }
//                       final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
//                       if (!emailRegex.hasMatch(value)) {
//                         return 'Enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.save),
//                 label: const Text('Save Changes'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.deepPurple.shade400,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   textStyle: const TextStyle(fontSize: 18),
//                 ),
//                 onPressed: _saveChanges,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_services.dart'; // Make sure this exists
import '../models/setting_model.dart';  // Make sure this exists

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController restaurantNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  File? _profileImage;
  String? logoUrl; // For displaying from server
  DateTime lastUpdated = DateTime.now();

  SettingModel? currentSetting;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final setting = await ApiService.getSetting(1); // replace 1 with dynamic ID if needed
      if (setting != null) {
        setState(() {
          currentSetting = SettingModel.fromJson(setting);
          restaurantNameController.text = currentSetting!.restaurantName;
          emailController.text = 'owner@example.com'; // Replace if email comes from API
          logoUrl = '${ApiService.baseUrl.replaceAll("/api", "")}/storage/${currentSetting!.logo}';
        });
      }
    } catch (e) {
      debugPrint('Failed to load setting: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
        logoUrl = null; // Remove logo URL so we show local image
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ApiService.updateSetting(
          id: currentSetting?.id ?? 1,
          restaurantName: restaurantNameController.text,
          address: currentSetting?.address ?? "Unknown",
          logoFile: _profileImage,
          currency: currentSetting?.currency,
          language: currentSetting?.language,
          darkMode: currentSetting?.darkMode ?? false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadProfileData(); // refresh view
      } catch (e) {
        debugPrint('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.account_circle),
            SizedBox(width: 8),
            Text('Account'),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 201, 191, 218),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color.fromARGB(255, 191, 168, 232),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (logoUrl != null ? NetworkImage(logoUrl!) : null) as ImageProvider?,
                    child: (_profileImage == null && logoUrl == null)
                        ? const Icon(Icons.storefront, size: 60, color: Colors.white)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color.fromARGB(255, 166, 140, 212)),
                    ),
                    child: const Icon(Icons.edit, size: 18, color: Color.fromARGB(255, 167, 135, 222)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Restaurant Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'Last updated: ${lastUpdated.toLocal().toString().split('.')[0]}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const Divider(height: 30, thickness: 1),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: restaurantNameController,
                    decoration: InputDecoration(
                      labelText: 'Restaurant Name',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _saveChanges,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
