import 'package:digital_menu/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/item_model.dart' as item;
import 'screens/splash_screen.dart';
import 'screens/taskbar_screen.dart';
import 'screens/Preview/menu_preview_screen.dart';
import 'screens/Login/login_screen.dart';
import 'screens/Login/restaurant_screen.dart';
import 'screens/Setting/settings_screen.dart'; // Added for account route

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  late final GoRouter _router;

  _DigitalMenuAppState() {
    _router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashScreen(onThemeToggle: toggleTheme),
        ),
        GoRoute(
          path: '/taskbar',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final restaurantId = extra['restaurantId'] as int?;
            return TaskbarScreen(
              onThemeToggle: toggleTheme,
              restaurantId: restaurantId,
            );
          },
        ),
        GoRoute(
          path: '/menu',
          builder: (context, state) {
            debugPrint(
              'Navigating to /menu with params: ${state.uri.queryParameters}',
            );
            final restaurantIdStr = state.uri.queryParameters['restaurantId'];
            if (restaurantIdStr == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid restaurant ID')),
              );
            }
            final restaurantId = int.tryParse(restaurantIdStr);
            if (restaurantId == null) {
              return const Scaffold(
                body: Center(child: Text('Invalid restaurant ID format')),
              );
            }
            return MenuPreviewScreen(
              restaurantId: restaurantId,
              onThemeToggle: toggleTheme,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(onThemeToggle: toggleTheme),
        ),
        GoRoute(
          path: '/restaurant',
          builder: (context, state) =>
              RestaurantScreen(onThemeToggle: toggleTheme),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CartScreen(
              cart: extra['cart'] as List<item.Item> ?? [],
              onDelete: extra['onDelete'] as Function(item.Item)? ?? (_) {},
              onClearCart: extra['onClearCart'] as Function()? ?? () {},
              restaurantId: extra['restaurantId'] as int? ?? 0,
            );
          },
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return SettingsScreen(
              selectedLanguage: extra['selectedLanguage'] ?? 'English',
              onThemeToggle:
                  extra['onThemeToggle'] as Function(bool)? ?? (_) {},
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
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
    );
  }
}