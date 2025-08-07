import 'package:flutter/material.dart';
import 'add_item_screen.dart';
import '../../models/category_model.dart';
import '../../models/item_model.dart' as item;
import '../../services/api_services.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({Key? key}) : super(key: key);

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Category> _categories = [];
  List<item.Item> _allItems = [];
  List<item.Item> _filteredItems = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
        // Redirect to login if not authenticated
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final categories = await ApiService.getCategories();
      final items = await ApiService.getItems();

      setState(() {
        _categories = categories;
        _allItems = items;
        _filterItems();
      });
    } catch (e) {
      if (e.toString().contains('Unauthenticated')) {
        // Handle expired token
        await ApiService.clearAuthToken();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
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
    setState(() {
      _filteredItems = _allItems.where((item.Item item) {
        final matchesCategory =
            _selectedCategoryId == null ||
            item.categoryId == _selectedCategoryId;
        final matchesSearch =
            item.name.toLowerCase().contains(_searchQuery) ||
            item.price.toStringAsFixed(2).contains(_searchQuery) ||
            (item.description?.toLowerCase().contains(_searchQuery) ?? false);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteItem(int id, String itemName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteItem(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable default back button
        elevation: 0,
        backgroundColor: const Color(0xFFF3E5F5),
        titleSpacing: 0, // Ensures custom padding starts from edge
        title: Padding(
          padding: const EdgeInsets.only(
            left: 5, // Adjusted for tighter layout
            right: 0,
          ), // <<< This is what you want
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Color(0xFF6A1B9A),
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 2), // reduced from 4 to get tighter spacing
              const Text(
                'Items',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6A1B9A)),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search here...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
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
                    (Category cat) => Padding(
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No items found.'
                          : 'No matching items found.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imagePath != null
                                  ? Image.network(
                                      ApiService.getImageUrl(item.imagePath),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.description?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.description!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddItemScreen(item: item),
                                    ),
                                  );
                                  if (result == true) _loadData();
                                } else if (value == 'delete') {
                                  _deleteItem(item.id, item.name);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (result == true) _loadData();
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
