import 'package:flutter/material.dart';
import '../../models/category_model.dart' as category;
import '../../models/item_model.dart' as item;
import '../../services/api_services.dart';
import '../screens/cart_screen.dart';
import '../screens/Preview/item_detail_screen.dart';

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
  Map<item.Item, int> _itemQuantities = {};
  bool _showAddButton = false;
  item.Item? _selectedItem;

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

  void _incrementQuantity(item.Item item) {
    setState(() {
      _itemQuantities.update(item, (value) => value + 1, ifAbsent: () => 1);
      _selectedItem = item;
      _showAddButton = true;
    });
  }

  void _decrementQuantity(item.Item item) {
    setState(() {
      final currentQuantity = _itemQuantities[item] ?? 0;
      if (currentQuantity > 1) {
        _itemQuantities[item] = currentQuantity - 1;
      } else {
        _itemQuantities.remove(item);
        _showAddButton = false;
      }
      _selectedItem = item;
    });
  }

  void _addItemsToCart(item.Item item) {
    final quantity = _itemQuantities[item] ?? 1;
    setState(() {
      _cart.addAll(List.filled(quantity, item));
      _itemQuantities.remove(item);
      _showAddButton = false;
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

  void _showItemDetail(item.Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ItemDetailBottomSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF3E5F5),
        iconTheme: const IconThemeData(color: Color(0xFF6A1B9A)),
        title: Padding(
          padding: const EdgeInsets.only(left: 0, right: 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF6A1B9A)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              const Text(
                'Preview',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
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
                                    onTap: () => _showItemDetail(item),
                                    leading: item.imagePath != null
                                        ? Image.network(
                                            ApiService.getImageUrl(item.imagePath),
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                          )
                                        : const Icon(Icons.image_not_supported),
                                    title: Text(item.name),
                                    subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                                    trailing: _itemQuantities.containsKey(item)
                                        ? Container(
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, size: 18),
                                                  onPressed: () => _decrementQuantity(item),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                Text('${_itemQuantities[item]}'),
                                                IconButton(
                                                  icon: const Icon(Icons.add, size: 18),
                                                  onPressed: () => _incrementQuantity(item),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () => _incrementQuantity(item),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.deepPurple,
                                              foregroundColor: Colors.white,
                                            ),
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
      floatingActionButton: _showAddButton && _selectedItem != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addItemsToCart(_selectedItem!),
                child: Text(
                  'Add ${_itemQuantities[_selectedItem]} items • \$${((_selectedItem!.price) * (_itemQuantities[_selectedItem] ?? 1)).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}