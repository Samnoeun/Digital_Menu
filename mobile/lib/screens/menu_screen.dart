import 'package:flutter/material.dart';
import 'qr_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'order_screen.dart';
import 'menu_preview_screen.dart';
import 'category_list_screen.dart';
import 'item_list_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeScreen(), // index 0
    const OrderScreen(), // index 1
    const MenuPreviewScreen(), // index 2
    const ItemListScreen(), // index 3
    const CategoryListScreen(), // index 4 ← Category tab
    const QrScreen(), // index 5
    const SettingsScreen(), // index 6
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye),
            label: 'Preview',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final int id;
  final String name;
  final double price;
  final String description;
  final String category;
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
  });
}
