import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'Order/order_screen.dart';
import 'item/item_list_screen.dart' as item_screen;
import 'category/category_list_screen.dart' as category_screen;
import 'QR/qr_screen.dart';
import 'Setting/settings_screen.dart';
import 'Preview/menu_preview_screen.dart';
import 'more_screen.dart';
import 'Preview/item_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  const MenuScreen({super.key, required this.onThemeToggle});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'home': 'Home',
      'orders': 'Orders',
      'menu': 'Menu',
      'category': 'Category',
      'more': 'More',
      'menu_preview': 'Menu Preview',
      'qr_code': 'QR Code',
      'settings': 'Settings',
      'close': 'Close',
      'error': 'Error',
    },
    'Khmer': {
      'home': 'ទំព័រដើម',
      'orders': 'ការបញ្ជាទិញ',
      'menu': 'មឺនុយ',
      'category': 'ប្រភេទ',
      'more': 'បន្ថែម',
      'menu_preview': 'មើលមឺនុយជាមុន',
      'qr_code': 'កូដ QR',
      'settings': 'ការកំណត់',
      'close': 'បិទ',
      'error': 'កំហុស',
    },
  };

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const OrderScreen(),
      const item_screen.ItemListScreen(),
      const category_screen.CategoryListScreen(),
    ];
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
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
        final lang = localization[selectedLanguage]!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: Text(
                  lang['menu_preview']!,
                  style: TextStyle(
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
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
                title: Text(
                  lang['qr_code']!,
                  style: TextStyle(
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(
                  lang['settings']!,
                  style: TextStyle(
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
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
    final lang = localization[selectedLanguage]!;
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: lang['home']!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: lang['orders']!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book),
            label: lang['menu']!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: lang['category']!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu),
            label: lang['more']!,
          ),
        ],
      ),
    );
  }
}