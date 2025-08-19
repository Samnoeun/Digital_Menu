import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'QR/qr_screen.dart';
import 'Setting/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  final Function(bool) onThemeToggle;
  const MoreScreen({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('QR Preview'),
            onTap: () {
              // Navigate to /qr with a restaurantId (hardcoded for now, replace with dynamic value if available)
              context.push('/qr', extra: {'restaurantId': 1}); // Replace 1 with dynamic ID
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to /account with theme toggle and selectedLanguage
              context.push('/account', extra: {
                'onThemeToggle': onThemeToggle,
                'selectedLanguage': 'English', // Adjust dynamically if needed
              });
            },
          ),
        ],
      ),
    );
  }
}