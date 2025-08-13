import 'package:flutter/material.dart';
import 'add_category_screen.dart';
import 'category_detail_screen.dart';
import '../../models/category_model.dart';
import '../../services/api_services.dart';


class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});
  
  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> 
    with TickerProviderStateMixin {
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedCategoryIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    _searchController.addListener(_onSearchChanged);
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Helper function to get restaurant/food related icons
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    // Food categories
    if (name.contains('pizza')) return Icons.local_pizza;
    if (name.contains('burger') || name.contains('sandwich'))
      return Icons.lunch_dining;
    if (name.contains('coffee') || name.contains('cafe'))
      return Icons.local_cafe;
    if (name.contains('drink') ||
        name.contains('beverage') ||
        name.contains('juice'))
      return Icons.local_drink;
    if (name.contains('dessert') ||
        name.contains('cake') ||
        name.contains('sweet'))
      return Icons.cake;
    if (name.contains('salad') ||
        name.contains('vegetable') ||
        name.contains('healthy'))
      return Icons.eco;
    if (name.contains('pasta') || name.contains('noodle'))
      return Icons.ramen_dining;
    if (name.contains('chicken') ||
        name.contains('meat') ||
        name.contains('grill'))
      return Icons.outdoor_grill;
    if (name.contains('seafood') ||
        name.contains('fish') ||
        name.contains('sushi'))
      return Icons.set_meal;
    if (name.contains('bread') || name.contains('bakery'))
      return Icons.bakery_dining;
    if (name.contains('ice cream') || name.contains('frozen'))
      return Icons.icecream;
    if (name.contains('wine') ||
        name.contains('alcohol') ||
        name.contains('bar'))
      return Icons.wine_bar;
    if (name.contains('breakfast') || name.contains('morning'))
      return Icons.free_breakfast;
    if (name.contains('soup')) return Icons.soup_kitchen;
    if (name.contains('snack') || name.contains('appetizer'))
      return Icons.tapas;
    if (name.contains('fast food') || name.contains('quick'))
      return Icons.fastfood;

    // Default restaurant icon
    return Icons.restaurant;
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedCategoryIds.clear();
      }
    });
  }

  void _toggleCategorySelection(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  Future<void> _deleteSelectedCategories() async {
    if (_selectedCategoryIds.isEmpty) return;

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              'Confirm Delete',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete ${_selectedCategoryIds.length} selected ${_selectedCategoryIds.length == 1 ? 'category' : 'categories'}? This will also delete all items in them.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
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
        setState(() => _isLoading = true);
        // Delete all selected categories
        for (int categoryId in _selectedCategoryIds) {
          await ApiService.deleteCategory(categoryId);
        }
        _selectedCategoryIds.clear();
        _isSelectionMode = false;
        _fetchCategories();
        _showSuccessSnackbar('Selected categories deleted successfully');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to delete categories: ${e.toString()}');
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _filteredCategories = categories;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              'Confirm Delete',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete category "$name"? This will also delete all items in it.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
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
        setState(() => _isLoading = true);
        await ApiService.deleteCategory(id);
        _fetchCategories();
        _showSuccessSnackbar('Category deleted successfully');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to delete category: ${e.toString()}');
      }
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.grey[900]
          : Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable default leading button
        title: Row(
          children: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _toggleSelectionMode,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            else
              const SizedBox(width: 0), // Tight spacing between icon and text
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                _isSelectionMode
                    ? '${_selectedCategoryIds.length} Selected'
                    : 'Categories',
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
            if (_selectedCategoryIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteSelectedCategories,
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
          // Search Bar in CategoryListScreen
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
                    hintText: 'Search categories...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
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
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
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
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8, // Reduced vertical padding
                    ),
                    isDense: true, // Makes the field more compact
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ), // Smaller text size
                ),
              ),
            ),
          ),
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
                          'Loading categories...',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : Colors.deepPurple.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredCategories.isEmpty
                ? Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.deepPurple.shade800
                                  : Colors.deepPurple.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: isDarkMode
                                  ? Colors.deepPurple.shade300
                                  : Colors.deepPurple.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No categories found'
                                : 'No matching categories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Tap the + button to add a new category'
                                : 'Try a different search term',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchCategories,
                    color: Colors.deepPurple.shade600,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCategories.length,
                        onReorder: _isSelectionMode
                            ? (int oldIndex, int newIndex) {}
                            : (int oldIndex, int newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final Category item = _filteredCategories
                                      .removeAt(oldIndex);
                                  _filteredCategories.insert(newIndex, item);
                                  // Also update the main categories list if no search is active
                                  if (_searchQuery.isEmpty) {
                                    final Category mainItem = _categories
                                        .removeAt(oldIndex);
                                    _categories.insert(newIndex, mainItem);
                                  }
                                });
                              },
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          final isSelected = _selectedCategoryIds.contains(
                            category.id,
                          );
                          return AnimatedContainer(
                            key: ValueKey(category.id),
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
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected
                                    ? BorderSide(
                                        color: Colors.deepPurple.shade600,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              color: isDarkMode ? Colors.grey[800] : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: isDarkMode
                                              ? [
                                                  Colors.deepPurple.shade800,
                                                  Colors.deepPurple.shade700,
                                                ]
                                              : [
                                                  Colors.deepPurple.shade100,
                                                  Colors.deepPurple.shade50,
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : isDarkMode
                                      ? null
                                      : LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.deepPurple.shade50,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  color: isDarkMode ? Colors.grey[800] : null,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: _isSelectionMode
                                      ? Checkbox(
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            _toggleCategorySelection(
                                              category.id,
                                            );
                                          },
                                          activeColor:
                                              Colors.deepPurple.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.deepPurple.shade600,
                                                Colors.deepPurple.shade400,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            _getCategoryIcon(category.name),
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                  title: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.deepPurple.shade800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${category.items.length} items',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.deepPurple.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: _isSelectionMode
                                      ? null
                                      : PopupMenuButton(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.deepPurple.shade600,
                                            size: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          itemBuilder: (context) => [
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
                                                  Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
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
                                                      ) => AddCategoryScreen(
                                                        category: category,
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
                                              if (result == true)
                                                _fetchCategories();
                                            } else if (value == 'delete') {
                                              _deleteCategory(
                                                category.id,
                                                category.name,
                                              );
                                            }
                                          },
                                        ),
                                  onTap: _isSelectionMode
                                      ? () => _toggleCategorySelection(
                                          category.id,
                                        )
                                      : () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => CategoryDetailScreen(
                                                    category: category,
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
                                                          begin: const Offset(
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
                                        },
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
                        const AddCategoryScreen(),
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
                if (result == true) _fetchCategories();
              },
              backgroundColor: Colors.deepPurple.shade600,
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }
}
