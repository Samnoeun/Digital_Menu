import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'categories': 'Categories',
      'selected': '{count} Selected',
      'search_categories': 'Search categories...',
      'loading_categories': 'Loading categories...',
      'no_categories_found': 'No categories found',
      'no_matching_categories': 'No matching categories',
      'add_category_prompt': 'Tap the + button to add a new category',
      'try_different_search': 'Try a different search term',
      'select': 'Select',
      'confirm_delete': 'Confirm Delete',
      'delete_single': 'Delete category "{name}"? This will also delete all items in it.',
      'delete_multiple': 'Delete {count} selected {count, plural, one{category} other{categories}}? This will also delete all items in them.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'category_deleted': 'Category deleted successfully',
      'categories_deleted': 'Selected categories deleted successfully',
      'failed_delete_category': 'Failed to delete category: {error}',
      'failed_delete_categories': 'Failed to delete categories: {error}',
    },
    'Khmer': {
      'categories': 'ប្រភេទ',
      'selected': 'បានជ្រើសរើស {count}',
      'search_categories': 'ស្វែងរកប្រភេទ...',
      'loading_categories': 'កំពុងផ្ទុកប្រភេទ...',
      'no_categories_found': 'រកមិនឃើញប្រភេទទេ',
      'no_matching_categories': 'គ្មានប្រភេទដែលត្រូវនឹងការស្វែងរក',
      'add_category_prompt': 'ចុចប៊ូតុង + ដើម្បីបន្ថែមប្រភេទថ្មី',
      'try_different_search': 'សាកល្បងប្រើពាក្យស្វែងរកផ្សេង',
      'select': 'ជ្រើសរើស',
      'confirm_delete': 'បញ្ជាក់ការលុប',
      'delete_single': 'លុបប្រភេទ "{name}"? វានឹងលុបធាតុទាំងអស់នៅក្នុងនោះផងដែរ។',
      'delete_multiple': 'លុប {count} ប្រភេទដែលបានជ្រើសរើស? វានឹងលុបធាតុទាំងអស់នៅក្នុងនោះផងដែរ។',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'edit': 'កែសម្រួល',
      'category_deleted': 'បានលុបប្រភេទដោយជោគជ័យ',
      'categories_deleted': 'បានលុបប្រភេទដែលបានជ្រើសរើសដោយជោគជ័យ',
      'failed_delete_category': 'បរាជ័យក្នុងការលុបប្រភេទ: {error}',
      'failed_delete_categories': 'បរាជ័យក្នុងការលុបប្រភេទ: {error}',
    },
  };

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
    _loadSavedLanguage();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
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
    final lang = localization[selectedLanguage]!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              lang['confirm_delete']!,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
        content: Text(
          lang['delete_multiple']!.replaceFirst('{count}', '${_selectedCategoryIds.length}'),
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang['cancel']!,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
            child: Text(
              lang['delete']!,
              style: TextStyle(
                color: Colors.white,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        for (int categoryId in _selectedCategoryIds) {
          await ApiService.deleteCategory(categoryId);
        }
        _selectedCategoryIds.clear();
        _isSelectionMode = false;
        _fetchCategories();
        _showSuccessSnackbar(lang['categories_deleted']!);
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(lang['failed_delete_categories']!.replaceFirst('{error}', e.toString()));
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
            content: Text(
              localization[selectedLanguage]!['failed_delete_categories']!.replaceFirst('{error}', e.toString()),
              style: TextStyle(
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
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
    final lang = localization[selectedLanguage]!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              lang['confirm_delete']!,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ],
        ),
        content: Text(
          lang['delete_single']!.replaceFirst('{name}', name),
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang['cancel']!,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
            child: Text(
              lang['delete']!,
              style: TextStyle(
                color: Colors.white,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await ApiService.deleteCategory(id);
        _fetchCategories();
        _showSuccessSnackbar(lang['category_deleted']!);
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(lang['failed_delete_category']!.replaceFirst('{error}', e.toString()));
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
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
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
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
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
    final lang = localization[selectedLanguage]!;

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
                    ? lang['selected']!.replaceFirst('{count}', '${_selectedCategoryIds.length}')
                    : lang['categories']!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                tooltip: lang['delete']!,
              ),
          ] else ...[
            TextButton(
              onPressed: _toggleSelectionMode,
              child: Text(
                lang['select']!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                    hintText: lang['search_categories']!,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 14,
                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.deepPurple.shade600,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
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
                          lang['loading_categories']!,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.deepPurple.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                                    ? lang['no_categories_found']!
                                    : lang['no_matching_categories']!,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.deepPurple.shade700,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? lang['add_category_prompt']!
                                    : lang['try_different_search']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                                      final Category item = _filteredCategories.removeAt(oldIndex);
                                      _filteredCategories.insert(newIndex, item);
                                      if (_searchQuery.isEmpty) {
                                        final Category mainItem = _categories.removeAt(oldIndex);
                                        _categories.insert(newIndex, mainItem);
                                      }
                                    });
                                  },
                            itemBuilder: (context, index) {
                              final category = _filteredCategories[index];
                              final isSelected = _selectedCategoryIds.contains(category.id);
                              return AnimatedContainer(
                                key: ValueKey(category.id),
                                duration: Duration(milliseconds: 300 + (index * 50)),
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
                                        ? BorderSide(color: Colors.deepPurple.shade600, width: 2)
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
                                                _toggleCategorySelection(category.id);
                                              },
                                              activeColor: Colors.deepPurple.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
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
                                                borderRadius: BorderRadius.circular(8),
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
                                          color: isDarkMode ? Colors.white : Colors.deepPurple.shade800,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${category.items.length} items',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                        ),
                                      ),
                                      trailing: _isSelectionMode
                                          ? null
                                          : PopupMenuButton(
                                              icon: Icon(
                                                Icons.more_vert_rounded,
                                                color: isDarkMode ? Colors.grey[400] : Colors.deepPurple.shade600,
                                                size: 20,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_rounded,
                                                        color: Colors.deepPurple.shade600,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        lang['edit']!,
                                                        style: TextStyle(
                                                          color: isDarkMode ? Colors.white : Colors.black87,
                                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                                                        lang['delete']!,
                                                        style: TextStyle(
                                                          color: Colors.red.shade600,
                                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                                          AddCategoryScreen(category: category),
                                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                        return SlideTransition(
                                                          position: animation.drive(
                                                            Tween(
                                                              begin: const Offset(1.0, 0.0),
                                                              end: Offset.zero,
                                                            ).chain(CurveTween(curve: Curves.easeInOut)),
                                                          ),
                                                          child: child,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                  if (result == true) _fetchCategories();
                                                } else if (value == 'delete') {
                                                  _deleteCategory(category.id, category.name);
                                                }
                                              },
                                            ),
                                      onTap: _isSelectionMode
                                          ? () => _toggleCategorySelection(category.id)
                                          : () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                                      CategoryDetailScreen(category: category),
                                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return SlideTransition(
                                                      position: animation.drive(
                                                        Tween(
                                                          begin: const Offset(1.0, 0.0),
                                                          end: Offset.zero,
                                                        ).chain(CurveTween(curve: Curves.easeInOut)),
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
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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