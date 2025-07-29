import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
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

                                // leading: Image.network(
                                //   item.imagePath ?? '',
                                //   width: 50,
                                //   height: 50,
                                //   fit: BoxFit.cover,
                                //   errorBuilder: (context, error, stackTrace) =>
                                //       const Icon(Icons.broken_image),
                                // ),
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

