import 'package:flutter/material.dart';
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('ReportOrder'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(onThemeToggle: onThemeToggle),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(onThemeToggle: onThemeToggle),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}