import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Digital Menu',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(decoration: const InputDecoration(labelText: 'Email')),
            TextField(obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
              },
              child: const Text('Continue'),
            ),
            const SizedBox(height: 12),
            const Text('----------- Or -----------'),
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata),
              onPressed: () {},
              label: const Text('Continue with Google'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.apple),
              onPressed: () {},
              label: const Text('Continue with Apple'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text('Create account'),
            )
          ],
        ),
      ),
    );
  }
}
