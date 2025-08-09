import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'Login/login_screen.dart';
import 'taskbar_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      final authData = await ApiService.getLoginData();
      
      if (authData != null) {
        // Verify token is still valid
        try {
          await ApiService.getUser(); // This will throw if token is invalid
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MenuScreen()),
            );
          }
        } catch (e) {
          // Token is invalid, clear it and go to login
          await ApiService.clearLoginData();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } else {
        // No saved credentials, go to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/logo/app_logo.png'), // Use your app logo
      ),
    );
  }
}