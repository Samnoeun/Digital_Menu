import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/category_model.dart' as category;
import '../models/item_model.dart' as item;
import '../services/api_services.dart';
import 'cart_screen.dart';

class MenuPreviewScreen extends StatefulWidget {
  const MenuPreviewScreen({super.key});

  @override
  State<MenuPreviewScreen> createState() => _MenuPreviewScreenState();
}

class _MenuPreviewScreenState extends State<MenuPreviewScreen> {
  List<category.Category> _categories = [];
  List<item.Item> _allItems = [];
  List<item.Item> _filteredItems = [];
  List<item.Item> _cart = [];
  int? _selectedCategoryId;
  String _searchText = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await ApiService.getCategories();
      final items = await ApiService.getItems();
      setState(() {
        _categories = categories;
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
      _filterItems();
    });
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterItems();
    });
  }

  void _filterItems() {
    _filteredItems = _allItems.where((item.Item item) {
      final matchesCategory =
          _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
      final matchesSearch = item.name.toLowerCase().contains(
        _searchText.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _addToCart(item.Item itemToAdd) {
    setState(() {
      _cart.add(itemToAdd);
    });
  }

  void _goToCartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: _cart,
          onDelete: _removeFromCart,
          onClearCart: () {
            setState(() => _cart.clear());
          },
        ),
      ),
    );
  }

  void _removeFromCart(item.Item itemToRemove) {
    setState(() {
      _cart.remove(itemToRemove);
    });
  }

  void _generateQR() {
    // This will be your actual website URL when you deploy to web
    // Replace this with your deployed website URL
    const String webMenuUrl = 'https://yourrestaurant-menu.web.app';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.qr_code_2,
                  size: 48,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Menu QR Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Customers can scan this QR code to view the menu on their phones',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: QrImageView(
                    data: webMenuUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('QR Code ready! Print and place on tables.'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          // Generate QR Button
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            onPressed: _generateQR,
            tooltip: 'Generate QR Code',
          ),
          // Shopping Cart with Badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _goToCartPage,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cart.length.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search items...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) => _onCategorySelected(null),
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map(
                          (category.Category cat) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(cat.name),
                              selected: _selectedCategoryId == cat.id,
                              onSelected: (_) => _onCategorySelected(cat.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: _categories.map((category.Category cat) {
                      final itemsInCategory = _filteredItems
                          .where((item.Item item) => item.categoryId == cat.id)
                          .toList();
                      if (itemsInCategory.isEmpty) return const SizedBox();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...itemsInCategory.map((item.Item item) {
                            return Card(
                              child: ListTile(
                                leading: item.imagePath != null
                                    ? Image.network(
                                        ApiService.getImageUrl(item.imagePath),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      )
                                    : const Icon(Icons.image_not_supported),
                                title: Text(item.name),
                                subtitle: Text(
                                  '${item.price.toStringAsFixed(2)} \$',
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                  ),
                                  onPressed: () => _addToCart(item),
                                  child: const Text("Add"),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 20),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
