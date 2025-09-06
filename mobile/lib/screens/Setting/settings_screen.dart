import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'account_screen.dart';
import '../Login/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const SettingsScreen({super.key, required this.onThemeToggle});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'choose_language': 'Choose Language',
      'apply': 'Apply',
      'account': 'Account',
      'logout': 'Log Out',
      'logout_confirm_title': 'Confirm',
      'logout_confirm_message': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
    },
    'Khmer': {
      'settings': 'ការកំណត់',
      'dark_mode': 'របៀបងងឹត',
      'language': 'ភាសា',
      'choose_language': 'ជ្រើសរើសភាសា',
      'apply': 'អនុវត្ត',
      'account': 'គណនី',
      'logout': 'ចាកចេញ',
      'logout_confirm_title': 'ចាកចេញ',
      'logout_confirm_message': 'តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?',
      'cancel': 'បោះបង់',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage(); // Load saved language on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isDarkMode = Theme.of(context).brightness == Brightness.dark;
      });
    });
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  // Save the selected language to SharedPreferences
  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      isDarkMode = value;
      widget.onThemeToggle(value);
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      localization[tempSelected]!['choose_language']!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: tempSelected == 'Khmer'
                            ? 'NotoSansKhmer'
                            : null,
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedLanguage = tempSelected;
                        _saveLanguage(tempSelected); // Save the selected language
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      localization[tempSelected]!['apply']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: tempSelected == 'Khmer'
                            ? 'NotoSansKhmer'
                            : null,
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

 void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Material(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localization[selectedLanguage]!['logout_confirm_title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localization[selectedLanguage]!['logout_confirm_message']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      minimumSize: const Size(200, 50), // Updated width and height
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _logout(context);
                    },
                    child: Text(
                      localization[selectedLanguage]!['logout']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      localization[selectedLanguage]!['cancel']!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(onThemeToggle: widget.onThemeToggle),
      ),
      (route) => false,
    );
  }

  TextStyle getTextStyle({bool isSubtitle = false, bool isGray = false}) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: isSubtitle ? 14 : 16,
      color: isGray
          ? Theme.of(context).textTheme.bodyMedium!.color
          : isSubtitle
              ? Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)
              : Theme.of(context).textTheme.bodyLarge!.color,
      fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 0, right: 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              Text(
                lang['settings']!,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          SwitchListTile(
            title: Text(lang['dark_mode']!, style: getTextStyle(isGray: true)),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: Icon(
              Icons.dark_mode,
              color: isDark ? Colors.white : Colors.deepPurple.shade700,
            ),
            activeColor: Colors.deepPurple,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: Icon(
              Icons.language,
              size: 28,
              color: isDark ? Colors.white : Colors.deepPurple.shade700,
            ),
            title: Text(lang['language']!, style: getTextStyle(isGray: true)),
            subtitle: Text(
              selectedLanguage,
              style: getTextStyle(isSubtitle: true, isGray: true),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: _showLanguagePicker,
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: Icon(
              Icons.account_circle,
              size: 28,
              color: isDark ? Colors.white : Colors.deepPurple.shade700,
            ),
            title: Text(lang['account']!, style: getTextStyle(isGray: true)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountScreen(
                  selectedLanguage: selectedLanguage,
                  onThemeToggle: widget.onThemeToggle,
                ),
              ),
            ),
          ),
          const Divider(indent: 24, endIndent: 24, thickness: 1, height: 32),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: const Icon(Icons.logout, color: Colors.red, size: 28),
            title: Text(
              lang['logout']!,
              style: getTextStyle().copyWith(color: Colors.red),
            ),
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }
}