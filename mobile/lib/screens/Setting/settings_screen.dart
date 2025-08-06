import 'package:flutter/material.dart';
import 'account_screen.dart';
import '../Login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String selectedLanguage = 'English';

  // Localization Map
  final Map<String, Map<String, String>> localization = {
    'English': {
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'choose_language': 'Choose Language',
      'apply': 'Apply',
      'account': 'Account',
      'logout': 'Log Out',
    },
    'Khmer': {
      'settings': 'ការកំណត់',
      'dark_mode': 'របៀបងងឹត',
      'language': 'ភាសា',
      'choose_language': 'ជ្រើសរើសភាសា',
      'apply': 'អនុវត្ត',
      'account': 'គណនី',
      'logout': 'ចាកចេញ',
    },
  };

  void _toggleDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
    });
    
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String tempSelected = selectedLanguage;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      // Always display current selectedLanguage until Apply is clicked
                      localization[selectedLanguage]!['choose_language']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'English',
                        groupValue: tempSelected,
                        onChanged: (value) {
                          setModalState(() => tempSelected = value!);
                        },
                      ),
                      Text(localization['English']!['language']!),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: 'Khmer',
                        groupValue: tempSelected,
                        onChanged: (value) {
                          setModalState(() => tempSelected = value!);
                        },
                      ),
                      Text(localization['Khmer']!['language']!),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLanguage = tempSelected;
                        });
                        Navigator.pop(context);

                      },
                      // Always display Apply button text in current selectedLanguage
                      child: Text(localization[selectedLanguage]!['apply']!),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.settings),
            const SizedBox(width: 8),
            Text(lang['settings']!),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          SwitchListTile(
            title: Text(lang['dark_mode']!),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(lang['language']!),
            subtitle: Text(selectedLanguage),
            onTap: _showLanguagePicker,
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(lang['account']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              lang['logout']!,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
