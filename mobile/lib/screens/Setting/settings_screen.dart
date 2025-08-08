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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        String tempSelected = selectedLanguage;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      localization[selectedLanguage]!['choose_language']!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily:
                            selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RadioListTile<String>(
                    title: Text(localization['English']!['language']!),
                    value: 'English',
                    groupValue: tempSelected,
                    onChanged: (value) {
                      setModalState(() => tempSelected = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(localization['Khmer']!['language']!),
                    value: 'Khmer',
                    groupValue: tempSelected,
                    onChanged: (value) {
                      setModalState(() => tempSelected = value!);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedLanguage = tempSelected;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      localization[selectedLanguage]!['apply']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily:
                            selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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

  TextStyle getTextStyle({bool isSubtitle = false, bool isGray = false}) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: isSubtitle ? 14 : 16,
      color: isGray
          ? Colors.grey.shade700
          : isSubtitle
              ? Colors.deepPurple.shade600.withOpacity(0.7)
              : Colors.deepPurple.shade900,
      fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: 0,
          ), // ⬅️ Your desired spacing
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(
                width: 0,
              ), 
              const Text('Settings'),
            ],
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          SwitchListTile(
            title: Text(
              lang['dark_mode']!,
              style: getTextStyle(isGray: true),
            ),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: Icon(Icons.dark_mode, color: Colors.deepPurple.shade700),
            activeColor: Colors.deepPurple,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(Icons.language, color: Colors.deepPurple.shade700, size: 28),
            title: Text(lang['language']!, style: getTextStyle(isGray: true)),
            subtitle: Text(selectedLanguage, style: getTextStyle(isSubtitle: true, isGray: true)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: _showLanguagePicker,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(Icons.account_circle, color: Colors.deepPurple.shade700, size: 28),
            title: Text(lang['account']!, style: getTextStyle(isGray: true)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
          const Divider(
            indent: 24,
            endIndent: 24,
            thickness: 1,
            height: 32,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: const Icon(Icons.logout, color: Colors.red, size: 28),
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
