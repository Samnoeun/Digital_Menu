import 'package:flutter/material.dart';
import '../services/api_services.dart';

class SplashScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const SplashScreen({super.key, required this.onThemeToggle});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay auth check until the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Maintain delay for UI

    try {
      final authData = await ApiService.getLoginData();
      if (authData != null) {
        try {
          final user = await ApiService.getUser();
          if (user != null) {
            try {
              await ApiService.getRestaurant();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/menu', arguments: widget.onThemeToggle);
              }
            } catch (e) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/restaurant', arguments: widget.onThemeToggle);
              }
            }
          } else {
            throw Exception('User not found');
          }
        } catch (e) {
          await ApiService.clearLoginData();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login', arguments: widget.onThemeToggle);
          }
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login', arguments: widget.onThemeToggle);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login', arguments: widget.onThemeToggle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}