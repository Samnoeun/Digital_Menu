import 'package:flutter/material.dart';
import 'account_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Remove back arrow for main page
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: false,
            onChanged: (val) {},
          ),
          ListTile(
            title: const Text('Translate to Khmer'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Account'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          ListTile(
            title: const Text('Log Out'),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
