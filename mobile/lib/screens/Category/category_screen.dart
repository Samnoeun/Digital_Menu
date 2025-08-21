import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_list_screen.dart';

// Centralized Language Service
class LanguageService {
  static final Map<String, Map<String, String>> _localization = {
    'English': {
      'loading_categories': 'Loading Categories...',
    },
    'Khmer': {
      'loading_categories': 'កំពុងដំណើរការប្រភេទ...',
    },
  };

  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLanguage') ?? 'English';
  }

  static String getText(String key, String language) {
    return _localization[language]?[key] ?? key;
  }
}

// Updated CategoryScreen with translation support
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String selectedLanguage = 'English';
  String loadingText = 'Loading Categories...';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await LanguageService.getCurrentLanguage();
    setState(() {
      selectedLanguage = language;
      loadingText = LanguageService.getText('loading_categories', language);
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const CategoryListScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                color: Colors.deepPurple.shade600,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loadingText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade700,
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