import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurpleAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Restaurant Name'),
              controller: TextEditingController(text: 'My Restaurant'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: TextEditingController(text: 'restaurant@example.com'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone'),
              controller: TextEditingController(text: '+855 12 345 678'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Location'),
              controller: TextEditingController(text: 'Phnom Penh, Cambodia'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
