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

                      localization[selectedLanguage]!['choose_language']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                      child: Text(
                        localization[selectedLanguage]!['apply']!,
                        style: TextStyle(
                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
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

    TextStyle getTextStyle() {
      return TextStyle(
        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple.shade600,  // Purple background
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.deepPurple.shade50),  // Light icon color
            const SizedBox(width: 8),
            Text(
              lang['settings']!,
              style: getTextStyle().copyWith(color: Colors.deepPurple.shade50), // Light text color
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          SwitchListTile(
            title: Text(
              lang['dark_mode']!,
              style: getTextStyle(),
            ),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              lang['language']!,
              style: getTextStyle(),
            ),
            subtitle: Text(selectedLanguage),
            onTap: _showLanguagePicker,
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(
              lang['account']!,
              style: getTextStyle(),
            ),
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
              style: getTextStyle().copyWith(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
