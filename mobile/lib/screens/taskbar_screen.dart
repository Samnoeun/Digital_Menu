import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'Order/order_screen.dart';
import 'item/item_list_screen.dart' as item_screen;
// import 'category/category_list_screen.dart' as category_screen;
import 'QR/qr_screen.dart';
import 'Setting/settings_screen.dart';
import 'Preview/menu_preview_screen.dart';
import 'more_screen.dart';
import 'Preview/item_detail_screen.dart';
import '../screens/report_order_screen.dart';
// Option 1: With alias
import 'category/category_list_screen.dart' as category_screen;


class MenuScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const MenuScreen({super.key, required this.onThemeToggle});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  @override
void initState() {
  super.initState();
  _pages = [
    const HomeScreen(),
    const OrderScreen(),
    const item_screen.ItemListScreen(),
    const category_screen.CategoryListScreen(),
  ];
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text('Menu Preview'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MenuPreviewScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('QR Code'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('ReportOrder'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportOrderScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(onThemeToggle: widget.onThemeToggle),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
        onTap: (index) {
          if (index == 4) {
            _openMoreMenu(context);
          } else {
            _onItemTapped(index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
        ],
      ),
    );
  }
}