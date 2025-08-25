import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import 'Login/login_screen.dart';
import 'taskbar_screen.dart';
import 'Login/restaurant_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const SplashScreen({super.key, required this.onThemeToggle});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String selectedLanguage = 'English'; // Default value

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
    _loadSavedLanguage().then((_) => _checkAuthStatus());
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      setState(() {
        selectedLanguage = savedLanguage;
      });
    } catch (e) {
      print('Error loading language: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final authData = await ApiService.getLoginData();
      if (authData != null) {
        try {
          final user = await ApiService.getUser();
          if (user != null) {
            try {
              await ApiService.getRestaurant();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(onThemeToggle: widget.onThemeToggle),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantScreen(onThemeToggle: widget.onThemeToggle),
                  ),
                );
              }
            }
          } else {
            throw Exception('User not found');
          }
        } catch (e) {
          await ApiService.clearLoginData();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LoginScreen(onThemeToggle: widget.onThemeToggle),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LoginScreen(onThemeToggle: widget.onThemeToggle),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(onThemeToggle: widget.onThemeToggle),
          ),
        );
      }
    }
  }

  TextStyle getTextStyle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge!.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = localization[selectedLanguage]!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo/app_logo.png',
              color: isDark ? Colors.white : null,
              height: 100,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              lang['loading']!,
              style: getTextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}