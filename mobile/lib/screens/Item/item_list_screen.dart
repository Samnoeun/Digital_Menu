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

class _ItemListScreenState extends State<ItemListScreen>
    with TickerProviderStateMixin {
  List<Category> _categories = [];
  List<item.Item> _allItems = [];
  List<item.Item> _filteredItems = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedItemIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItemIds.clear();
      }
    });
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItemIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Delete ${_selectedItemIds.length} selected ${_selectedItemIds.length == 1 ? 'item' : 'items'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (int itemId in _selectedItemIds) {
          await ApiService.deleteItem(itemId);
        }
        _selectedItemIds.clear();
        _isSelectionMode = false;
        _showSuccessSnackbar('Selected items deleted successfully');
        _loadData();
      } catch (e) {
        _showErrorSnackbar('Failed to delete items: ${e.toString()}');
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) {
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
      _animationController.forward();
    } catch (e) {
      if (e.toString().contains('Unauthenticated')) {
        await ApiService.clearAuthToken();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showErrorSnackbar('Error: ${e.toString()}');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Delete Item'),
          ],
        ),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteItem(id);
      _showSuccessSnackbar('$itemName deleted successfully');
      _loadData();
    } catch (e) {
      _showErrorSnackbar('Error deleting item: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _toggleSelectionMode,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            SizedBox(width: _isSelectionMode ? 8 : 0),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                _isSelectionMode
                    ? '${_selectedItemIds.length} Selected'
                    : 'Items',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade700,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedItemIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteSelectedItems,
                tooltip: 'Delete Selected',
              ),
          ] else ...[
            TextButton(
              onPressed: _toggleSelectionMode,
              child: const Text(
                'Select',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                height: 45, // Set fixed height for shorter search bar
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.deepPurple.shade600,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade600,
                              size: 18,
                            ),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8, // Reduced vertical padding
                    ),
                    isDense: true, // Makes the field more compact
                  ),
                  style: const TextStyle(fontSize: 14), // Smaller text size
                ),
              ),
            ),
          ),

          // Category Filter Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategoryId == null,
                    onSelected: (_) => _onCategorySelected(null),
                    selectedColor: Colors.deepPurple.shade200,
                    checkmarkColor: Colors.deepPurple.shade700,
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map(
                    (Category cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: _selectedCategoryId == cat.id,
                        onSelected: (_) => _onCategorySelected(cat.id),
                        selectedColor: Colors.deepPurple.shade200,
                        checkmarkColor: Colors.deepPurple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Items List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.deepPurple.shade600,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading items...',
                          style: TextStyle(
                            color: Colors.deepPurple.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredItems.isEmpty
                ? Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.deepPurple.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No items found'
                                : 'No matching items',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Tap the + button to add a new item'
                                : 'Try a different search term',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: Colors.deepPurple.shade600,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = _selectedItemIds.contains(item.id);

                          return AnimatedContainer(
                            duration: Duration(
                              milliseconds: 300 + (index * 50),
                            ),
                            curve: Curves.easeOutBack,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: isSelected ? 6 : 3,
                              shadowColor: isSelected
                                  ? Colors.deepPurple.withOpacity(0.3)
                                  : Colors.deepPurple.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: isSelected
                                    ? BorderSide(
                                        color: Colors.deepPurple.shade600,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [
                                            Colors.deepPurple.shade100,
                                            Colors.deepPurple.shade50,
                                          ]
                                        : [
                                            Colors.white,
                                            Colors.deepPurple.shade50,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: _isSelectionMode
                                      ? Checkbox(
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            _toggleItemSelection(item.id);
                                          },
                                          activeColor:
                                              Colors.deepPurple.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.deepPurple.shade200,
                                                  Colors.deepPurple.shade100,
                                                ],
                                              ),
                                            ),
                                            child: item.imagePath != null
                                                ? Image.network(
                                                    ApiService.getImageUrl(
                                                      item.imagePath!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          color: Colors
                                                              .deepPurple
                                                              .shade600,
                                                          size: 30,
                                                        ),
                                                  )
                                                : Icon(
                                                    Icons
                                                        .image_not_supported_rounded,
                                                    color: Colors
                                                        .deepPurple
                                                        .shade600,
                                                    size: 30,
                                                  ),
                                          ),
                                        ),
                                  title: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.deepPurple.shade800,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (item.description?.isNotEmpty == true)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            item.description!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.deepPurple.shade600,
                                                Colors.deepPurple.shade400,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: _isSelectionMode
                                      ? null
                                      : PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: Colors.deepPurple.shade600,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              final result = await Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) => AddItemScreen(
                                                        item: item,
                                                      ),
                                                  transitionsBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                        child,
                                                      ) {
                                                        return SlideTransition(
                                                          position: animation.drive(
                                                            Tween(
                                                              begin:
                                                                  const Offset(
                                                                    1.0,
                                                                    0.0,
                                                                  ),
                                                              end: Offset.zero,
                                                            ).chain(
                                                              CurveTween(
                                                                curve: Curves
                                                                    .easeInOut,
                                                              ),
                                                            ),
                                                          ),
                                                          child: child,
                                                        );
                                                      },
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
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_rounded,
                                                    color: Colors
                                                        .deepPurple
                                                        .shade600,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_rounded,
                                                    color: Colors.red.shade600,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                  onTap: _isSelectionMode
                                      ? () => _toggleItemSelection(item.id)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AddItemScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween(
                                begin: const Offset(0.0, 1.0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeInOut)),
                            ),
                            child: child,
                          );
                        },
                  ),
                );
                if (result == true) _loadData();
              },
              backgroundColor: Colors.deepPurple.shade600,
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }
}
