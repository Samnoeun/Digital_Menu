import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/item_model.dart';
import '../services/api_services.dart';

class MenuPreviewScreen extends StatefulWidget {
  const MenuPreviewScreen({super.key});

  @override
  State<MenuPreviewScreen> createState() => _MenuPreviewScreenState();
}

class _MenuPreviewScreenState extends State<MenuPreviewScreen> {
  List<CategoryModel> _categories = [];
  List<ItemModel> _items = [];
  List<ItemModel> _filteredItems = [];
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
      final categories = await ApiService.fetchCategories();
      final items = await ApiService.fetchAllItems(); // ✅

      setState(() {
        _categories = categories;
        _items = items;
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

  void _onSearch(String value) {
    setState(() {
      _searchText = value;
      _filterItems();
    });
  }

  void _onFilterByCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterItems();
    });
  }

  void _filterItems() {
    _filteredItems = _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchText.toLowerCase());
      final matchesCategory = _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : Column(
                  children: [
                    // 🔍 Search
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search items...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // 🧃 Filter buttons
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          TextButton(
                            onPressed: () => _onFilterByCategory(null),
                            child: const Text("All"),
                          ),
                          ..._categories.map(
                            (cat) => TextButton(
                              onPressed: () => _onFilterByCategory(cat.id),
                              child: Text(cat.name),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 🍽️ Items grouped by category
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: _categories.map((category) {
                          final itemsInCategory = _filteredItems
                              .where((item) => item.categoryId == category.id)
                              .toList();

                          if (itemsInCategory.isEmpty) return const SizedBox();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...itemsInCategory.map((item) => Card(
                                    child: ListTile(
                                      leading: item.imagePath != null
                                          ? Image.network(item.imagePath!, width: 50, height: 50, fit: BoxFit.cover)
                                          : const Icon(Icons.fastfood),
                                      title: Text(item.name),
                                      subtitle: Text('${item.price} \$'),
                                      trailing: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                        ),
                                        child: const Text("Add to Cart"),
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 24),
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
