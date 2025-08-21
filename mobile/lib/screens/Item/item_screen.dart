import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'item_list_screen.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({Key? key}) : super(key: key);

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  String selectedLanguage = 'English';
  
  final Map<String, Map<String, String>> localization = {
    'English': {
      'loading': 'Loading...',
    },
    'Khmer': {
      'loading': 'កំពុងផ្ទុក...',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ItemListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurple.shade600,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              lang['loading']!,
              style: TextStyle(
                color: Colors.deepPurple.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}