import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Add this import
import './screens/taskbar_screen.dart';
import './screens/Preview/menu_preview_screen.dart'; // Add this import for MenuPreviewScreen
import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Add this for clean URL strategy (optional)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy()); // Add this for clean URLs without # (optional but recommended)
  runApp(const DigitalMenuApp());
}

class DigitalMenuApp extends StatelessWidget {
  const DigitalMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Menu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple.shade100),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3E5F5),
          foregroundColor: Colors.deepPurple,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const SplashScreen(), // Changed from LoginScreen to SplashScreen
      routes: {
        '/menu': (context) => const MenuScreen(),
        '/preview': (context) => const MenuPreviewScreen(), // Add this named route
      },
    );
  }
}