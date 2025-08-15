import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'screens/splash_screen.dart';
import 'screens/taskbar_screen.dart';
import 'screens/Preview/menu_preview_screen.dart';
import 'screens/Login/restaurant_screen.dart';
import 'screens/Login/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy()); // Clean URLs without #
  runApp(const DigitalMenuApp());
}

class DigitalMenuApp extends StatefulWidget {
  const DigitalMenuApp({super.key});

  @override
  _DigitalMenuAppState createState() => _DigitalMenuAppState();
}

class _DigitalMenuAppState extends State<DigitalMenuApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Menu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple.shade100,
          brightness: Brightness.light,
        ),
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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple.shade100,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple.shade800,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
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
      themeMode: _themeMode,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(onThemeToggle: toggleTheme),
        '/menu': (context) => MenuScreen(onThemeToggle: toggleTheme),
        '/preview': (context) => const MenuPreviewScreen(),
        '/restaurant': (context) => RestaurantScreen(onThemeToggle: toggleTheme),
        '/login': (context) => LoginScreen(onThemeToggle: toggleTheme),
      },
    );
  }
}