import 'package:flutter/material.dart';
import '../../models/category_model.dart' as category;
import '../../models/item_model.dart' as item;
import '../../services/api_services.dart';
import '../../screens/cart_screen.dart';
import './item_detail_screen.dart';
import '../../screens/home_screen.dart'; // Adjust the path as needed

class MenuPreviewScreen extends StatefulWidget {
  final Function(bool)? onThemeToggle;
  const MenuPreviewScreen({Key? key, this.onThemeToggle}) : super(key: key);

  @override
  State<MenuPreviewScreen> createState() => _MenuPreviewScreenState();
}

class _MenuPreviewScreenState extends State<MenuPreviewScreen> {
  List<category.Category> _categories = [];
  List<item.Item> _allItems = [];
  List<item.Item> _filteredItems = [];
  List<item.Item> _cart = [];
  Map<item.Item, int> _selectedItems = {};

  int? _selectedCategoryId;
  String _searchText = '';
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
        _filterItems();
      });
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.deepPurple.shade700,
        ),
      );
    }
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
      _selectedItems.update(item, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _decrementQuantity(item.Item item) {
    setState(() {
      if (_selectedItems.containsKey(item)) {
        if (_selectedItems[item]! > 1) {
          _selectedItems[item] = _selectedItems[item]! - 1;
        } else {
          _selectedItems.remove(item);
        }
      }
    });
  }

  void _addToCart() {
    setState(() {
      _selectedItems.forEach((item, quantity) {
        _cart.addAll(List.filled(quantity, item));
      });
      _selectedItems.clear();
    });
    _goToCartPage();
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ItemDetailBottomSheet(item: item),
        );
      },
    );
  }

  int get _totalSelectedItems {
    return _selectedItems.values.fold(0, (sum, quantity) => sum + quantity);
  }

  double get _totalSelectedPrice {
    return _selectedItems.entries.fold(
      0,
      (sum, entry) => sum + (entry.key.price * entry.value),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items...',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors
                          .white // White in dark mode
                    : Colors.deepPurple.shade600, // Purple in light mode
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.grey[900]
          : Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple.shade700,
        iconTheme: const IconThemeData(color: Color(0xFF6A1B9A)),
        title: Padding(
          padding: const EdgeInsets.only(left: 0, right: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              const Text(
                'Preview',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.onThemeToggle != null)
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              onPressed: () {
                widget.onThemeToggle!(isDarkMode);
              },
            ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text(
                      'All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _selectedCategoryId == null,
                    selectedColor: Colors.deepPurple.shade600,
                    backgroundColor: isDarkMode
                        ? Colors.grey[700]
                        : Colors.deepPurple.shade100,
                    labelStyle: TextStyle(
                      color: _selectedCategoryId == null
                          ? Colors.white
                          : isDarkMode
                          ? Colors.grey[400]
                          : Colors.deepPurple.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    onSelected: (_) => _onCategorySelected(null),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ..._categories.map(
                    (category.Category cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _selectedCategoryId == cat.id,
                        selectedColor: Colors.deepPurple.shade600,
                        backgroundColor: isDarkMode
                            ? Colors.grey[700]
                            : Colors.deepPurple.shade100,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == cat.id
                              ? Colors.white
                              : isDarkMode
                              ? Colors.grey[400]
                              : Colors.deepPurple.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        onSelected: (_) => _onCategorySelected(cat.id),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple.shade700,
                    ),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      'Error: $_error',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: _categories.map((category.Category cat) {
                      final itemsInCategory = _filteredItems
                          .where((item) => item.categoryId == cat.id)
                          .toList();

                      if (itemsInCategory.isEmpty) return const SizedBox();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                        .white // White text in dark mode
                                  : Colors
                                        .deepPurple
                                        .shade700, // Deep purple in light mode
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...itemsInCategory.map((item.Item item) {
                            final quantity = _selectedItems[item] ?? 0;
                            return Card(
                              color: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () => _showItemDetail(item),
                                leading: item.imagePath != null
                                    ? Image.network(
                                        ApiService.getImageUrl(item.imagePath),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.broken_image,
                                                  color: isDarkMode
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                ),
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                trailing: quantity > 0
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade700
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.remove,
                                                size: 18,
                                                color:
                                                    Colors.deepPurple.shade700,
                                              ),
                                              onPressed: () =>
                                                  _decrementQuantity(item),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            Text(
                                              '$quantity',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.add,
                                                size: 18,
                                                color:
                                                    Colors.deepPurple.shade700,
                                              ),
                                              onPressed: () =>
                                                  _incrementQuantity(item),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _incrementQuantity(item),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.deepPurple.shade700,
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
      bottomNavigationBar: _selectedItems.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Container(
                height: 55,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _addToCart,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Basket • ${_totalSelectedItems} Item${_totalSelectedItems > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_totalSelectedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
