import 'package:flutter/material.dart';
import 'add_menu_screen.dart';
import 'category_screen.dart';
import 'qr_screen.dart';
import 'settings_screen.dart';
import 'menu_detail_screen.dart';
import 'qr_menu_view_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const MenuPage(),
    const CategoryScreen(),
    const QrScreen(),
    const SettingsScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _isSelectionMode = false;
  Set<int> _selectedItems = {};
  
  List<MenuItem> menuItems = [
    MenuItem(
      id: 1,
      name: 'Beef Burger',
      price: 12.99,
      description: 'Juicy beef patty with fresh vegetables',
      category: 'Main Dishes',
      imageUrl: '/placeholder.svg?height=100&width=100',
    ),
    MenuItem(
      id: 2,
      name: 'Coca Cola',
      price: 2.50,
      description: 'Refreshing cold drink',
      category: 'Beverages',
      imageUrl: '/placeholder.svg?height=100&width=100',
    ),
    MenuItem(
      id: 3,
      name: 'Chocolate Cake',
      price: 6.99,
      description: 'Rich chocolate cake with cream',
      category: 'Desserts',
      imageUrl: '/placeholder.svg?height=100&width=100',
    ),
  ];

  void _addMenuItem(MenuItem item) {
    setState(() {
      menuItems.add(item);
    });
  }

  void _editMenuItem(int index, MenuItem updatedItem) {
    setState(() {
      menuItems[index] = updatedItem;
    });
  }

  void _deleteMenuItem(int index) {
    setState(() {
      menuItems.removeAt(index);
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedItems.contains(index)) {
        _selectedItems.remove(index);
      } else {
        _selectedItems.add(index);
      }
      
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _startSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add(index);
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _deleteSelectedItems() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Items'),
          content: Text('Are you sure you want to delete ${_selectedItems.length} item(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  // Sort indices in descending order to avoid index shifting issues
                  final sortedIndices = _selectedItems.toList()..sort((a, b) => b.compareTo(a));
                  for (int index in sortedIndices) {
                    menuItems.removeAt(index);
                  }
                  _selectedItems.clear();
                  _isSelectionMode = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Items deleted successfully')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _generateQRForSelected() {
    final selectedMenuItems = _selectedItems.map((index) => menuItems[index]).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRMenuViewScreen(menuItems: selectedMenuItems),
      ),
    );
  }

  void _showMenuOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuDetailScreen(menuItem: menuItems[index]),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editMenuDialog(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editMenuDialog(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMenuScreen(menuItem: menuItems[index]),
      ),
    );
    if (result != null) {
      _editMenuItem(index, result);
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Menu Item'),
          content: Text('Are you sure you want to delete "${menuItems[index].name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _deleteMenuItem(index);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Menu item deleted successfully')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedItems.length} selected' : 'Your Menu'),
        // Remove the automaticallyImplyLeading to hide back button
        automaticallyImplyLeading: false,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: _selectedItems.isNotEmpty ? _generateQRForSelected : null,
                  tooltip: 'Generate QR Code',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedItems.isNotEmpty ? _deleteSelectedItems : null,
                  tooltip: 'Delete Selected',
                ),
              ]
            : null,
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMenuScreen()),
                );
                if (result != null) {
                  _addMenuItem(result);
                }
              },
              child: const Icon(Icons.add),
            ),
      body: menuItems.isEmpty
          ? const Center(
              child: Text(
                'No menu items yet.\nTap + to add a menu item.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = _selectedItems.contains(index);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(index),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.fastfood),
                                );
                              },
                            ),
                          ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.category, style: TextStyle(color: Colors.grey[600])),
                        Text('\$${item.price.toStringAsFixed(2)}', 
                             style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    trailing: _isSelectionMode
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showMenuOptions(context, index),
                          ),
                    onTap: _isSelectionMode
                        ? () => _toggleSelection(index)
                        : null,
                    onLongPress: _isSelectionMode
                        ? null
                        : () => _startSelectionMode(index),
                    selected: isSelected,
                  ),
                );
              },
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
