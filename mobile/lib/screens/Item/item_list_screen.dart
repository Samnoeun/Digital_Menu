import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_item_screen.dart';
import '../../models/category_model.dart';
import '../../models/item_model.dart' as item;
import '../../services/api_services.dart';

class ItemListScreen extends StatefulWidget {
  final Function(bool)? onThemeToggle;
  const ItemListScreen({Key? key, this.onThemeToggle}) : super(key: key);

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
  String selectedLanguage = 'English';

  final Map<String, Map<String, String>> localization = {
    'English': {
      'items': 'Items',
      'selected': 'Selected',
      'search_items': 'Search items...',
      'all': 'All',
      'loading_items': 'Loading items...',
      'no_items_found': 'No items found',
      'no_matching_items': 'No matching items',
      'add_new_item': 'Tap the + button to add a new item',
      'try_different_search': 'Try a different search term',
      'confirm_delete': 'Confirm Delete',
      'delete_item': 'Delete Item',
      'delete_selected': 'Delete selected items?',
      'delete_single': 'Delete this item?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'select': 'Select',
      'items_deleted': 'Selected items deleted successfully',
      'item_deleted': 'Item deleted successfully',
      'delete_failed': 'Failed to delete items',
      'error': 'Error',
      'unauthorized': 'Unauthorized access',
      'invalid_data': 'Invalid item data',
    },
    'Khmer': {
      'items': 'ធាតុ',
      'selected': 'បានជ្រើសរើស',
      'search_items': 'ស្វែងរកធាតុ...',
      'all': 'ទាំងអស់',
      'loading_items': 'កំពុងផ្ទុកធាតុ...',
      'no_items_found': 'មិនមានធាតុណាមួយត្រូវបានរកឃើញ',
      'no_matching_items': 'មិនមានធាតុដែលត្រូវគ្នា',
      'add_new_item': 'ចុចប៊ូតុង + ដើម្បីបន្ថែមធាតុថ្មី',
      'try_different_search': 'សាកល្បងពាក្យស្វែងរកផ្សេងទៀត',
      'confirm_delete': 'បញ្ជាក់ការលុប',
      'delete_item': 'លុបធាតុ',
      'delete_selected': 'លុបធាតុដែលបានជ្រើសរើស?',
      'delete_single': 'លុបធាតុនេះ?',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'edit': 'កែសម្រួល',
      'select': 'ជ្រើសរើស',
      'items_deleted': 'ធាតុដែលបានជ្រើសរើសត្រូវបានលុបដោយជោគជ័យ',
      'item_deleted': 'ធាតុត្រូវបានលុបដោយជោគជ័យ',
      'delete_failed': 'បរាជ័យក្នុងការលុបធាតុ',
      'error': 'កំហុស',
      'unauthorized': 'ការចូលប្រើប្រាស់មិនត្រឹមត្រូវ',
      'invalid_data': 'ទិន្នន័យធាតុមិនត្រឹមត្រូវ',
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
    _loadSavedLanguage();
    _loadData();
    _searchController.addListener(_onSearchChanged);
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

  TextStyle getTextStyle({
    bool isBold = false,
    bool isSecondary = false,
    double? fontSize,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: fontSize ?? (isSecondary ? 16 : 18),
      color:
          color ??
          (isSecondary
              ? Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)
              : Theme.of(context).textTheme.bodyLarge!.color),
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );
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
    final lang = localization[selectedLanguage]!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              lang['confirm_delete']!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200]
                    : Colors.black87,
                fontFamily: selectedLanguage == 'Khmer'
                    ? 'NotoSansKhmer'
                    : null,
              ),
            ),
          ],
        ),
        content: Text(
          '${_selectedItemIds.length} ${lang['delete_selected']!}',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang['cancel']!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontFamily: selectedLanguage == 'Khmer'
                    ? 'NotoSansKhmer'
                    : null,
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
                fontFamily: selectedLanguage == 'Khmer'
                    ? 'NotoSansKhmer'
                    : null,
              ),
            ),
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
        _showSuccessSnackbar(lang['items_deleted']!);
        _loadData();
      } catch (e) {
        _showErrorSnackbar('${lang['delete_failed']!}: ${e.toString()}');
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
        _categories = categories ?? [];
        _allItems = items ?? [];
        _filterItems();
      });
      _animationController.forward();
    } catch (e) {
      final lang = localization[selectedLanguage]!;
      if (e.toString().contains('Unauthenticated')) {
        await ApiService.clearAuthToken();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        _showErrorSnackbar('${lang['error']!}: ${e.toString()}');
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
      _filteredItems = _allItems.where((item) {
        // Skip null items or items with null required fields
        if (item == null || item.name == null || item.price == null) {
          return false;
        }
        final matchesCategory =
            _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
        final matchesSearch = item.name!.toLowerCase().contains(_searchQuery) ||
            item.price!.toStringAsFixed(2).contains(_searchQuery) ||
            (item.description?.toLowerCase().contains(_searchQuery) ?? false);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Future<void> _deleteItem(int id, String? itemName) async {
    final lang = localization[selectedLanguage]!;
    itemName ??= lang['item']!; // Fallback name if null

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text(
              lang['delete_item']!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200]
                    : Colors.black87,
                fontFamily: selectedLanguage == 'Khmer'
                    ? 'NotoSansKhmer'
                    : null,
              ),
            ),
          ],
        ),
        content: Text(
          '${lang['delete_single']!} "$itemName"?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              lang['cancel']!,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontFamily: selectedLanguage == 'Khmer'
                    ? 'NotoSansKhmer'
                    : null,
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
                fontFamily: selectedLanguage == 'Khmer'
                    ? 'NotoSansKhmer'
                    : null,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteItem(id);
      _showSuccessSnackbar('$itemName ${lang['item_deleted']!}');
      _loadData();
    } catch (e) {
      _showErrorSnackbar('${lang['error']!} ${lang['delete_item']!}: $e');
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
                  fontFamily: selectedLanguage == 'Khmer'
                      ? 'NotoSansKhmer'
                      : null,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.red[700]
            : Colors.deepPurple.shade700,
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
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: selectedLanguage == 'Khmer'
                      ? 'NotoSansKhmer'
                      : null,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.green[700]
            : Colors.green.shade600,
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
          ? const Color.fromARGB(255, 33, 33, 33)
          : Colors.deepPurple.shade50,
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
                    ? '${_selectedItemIds.length} ${lang['selected']!}'
                    : lang['items']!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Colors.white,
                  fontFamily: selectedLanguage == 'Khmer'
                      ? 'NotoSansKhmer'
                      : null,
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
                  fontFamily: selectedLanguage == 'Khmer'
                      ? 'NotoSansKhmer'
                      : null,
                ),
              ),
            ),
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
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: lang['search_items']!,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 14,
                        fontFamily: selectedLanguage == 'Khmer'
                            ? 'NotoSansKhmer'
                            : null,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDarkMode
                            ? Colors.grey[300]
                            : Colors.deepPurple.shade600,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: isDarkMode
                                    ? Colors.grey[500]
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
                      fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[200] : Colors.black87,
                      fontFamily: selectedLanguage == 'Khmer'
                          ? 'NotoSansKhmer'
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            // Category Filter Chips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(
                        lang['all']!,
                        style: TextStyle(
                          color: _selectedCategoryId == null
                              ? Colors.white
                              : isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.deepPurple.shade700,
                          fontFamily: selectedLanguage == 'Khmer'
                              ? 'NotoSansKhmer'
                              : null,
                        ),
                      ),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => _onCategorySelected(null),
                      selectedColor: isDarkMode
                          ? Colors.deepPurple[400]
                          : Colors.deepPurple.shade600,
                      backgroundColor: isDarkMode
                          ? Colors.grey[800]
                          : Colors.deepPurple.shade100,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isDarkMode
                            ? BorderSide(color: Colors.grey[700]!, width: 1)
                            : BorderSide.none,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._categories.map(
                      (Category cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(
                            cat.name,
                            style: TextStyle(
                              color: _selectedCategoryId == cat.id
                                  ? Colors.white
                                  : isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.deepPurple.shade700,
                              fontFamily: selectedLanguage == 'Khmer'
                                  ? 'NotoSansKhmer'
                                  : null,
                            ),
                          ),
                          selected: _selectedCategoryId == cat.id,
                          onSelected: (_) => _onCategorySelected(cat.id),
                          selectedColor: isDarkMode
                              ? Colors.deepPurple[400]
                              : Colors.deepPurple.shade600,
                          backgroundColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.deepPurple.shade100,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isDarkMode
                                ? BorderSide(color: Colors.grey[700]!, width: 1)
                                : BorderSide.none,
                          ),
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
                            color: isDarkMode
                                ? Colors.deepPurple[400]
                                : Colors.deepPurple.shade700,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang['loading_items']!,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.deepPurple.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: selectedLanguage == 'Khmer'
                                  ? 'NotoSansKhmer'
                                  : null,
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
                                    color: isDarkMode
                                        ? Colors.grey[850]
                                        : Colors.deepPurple.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.deepPurple.shade400,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _searchQuery.isEmpty
                                      ? lang['no_items_found']!
                                      : lang['no_matching_items']!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.grey[200]
                                        : Colors.deepPurple.shade700,
                                    fontFamily: selectedLanguage == 'Khmer'
                                        ? 'NotoSansKhmer'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? lang['add_new_item']!
                                      : lang['try_different_search']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontFamily: selectedLanguage == 'Khmer'
                                        ? 'NotoSansKhmer'
                                        : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: isDarkMode
                              ? Colors.deepPurple[400]
                              : Colors.deepPurple.shade700,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              if (item == null ||
                                  item.name == null ||
                                  item.price == null) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    color: isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        lang['invalid_data']!,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontFamily: selectedLanguage == 'Khmer'
                                              ? 'NotoSansKhmer'
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final isSelected = _selectedItemIds.contains(item.id);

                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                curve: Curves.easeOutBack,
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: const BoxConstraints(minHeight: 80),
                                child: Card(
                                  elevation: isSelected ? 8 : 4,
                                  shadowColor: isSelected
                                      ? Colors.deepPurple
                                          .withOpacity(isDarkMode ? 0.3 : 0.4)
                                      : Colors.deepPurple
                                          .withOpacity(isDarkMode ? 0.15 : 0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: isSelected
                                        ? BorderSide(
                                            color: isDarkMode
                                                ? Colors.deepPurple[400]!
                                                : Colors.deepPurple.shade600,
                                            width: 3,
                                          )
                                        : BorderSide(
                                            color: isDarkMode
                                                ? Colors.grey[800]!
                                                : Colors.transparent,
                                            width: isDarkMode ? 0.5 : 0,
                                          ),
                                  ),
                                  color: isSelected && isDarkMode
                                      ? Colors.grey[800]
                                      : isDarkMode
                                          ? const Color.fromARGB(255, 40, 40, 40)
                                          : Colors.white,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 80,
                                        height: 80, // Constrain image height
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isDarkMode
                                                    ? [
                                                        Colors.grey[700]!,
                                                        Colors.grey[850]!
                                                            .withOpacity(0.9),
                                                      ]
                                                    : [
                                                        Colors.deepPurple.shade200,
                                                        Colors.deepPurple.shade100,
                                                      ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: item.imageUrl != null
                                                ? Image.network(
                                                    ApiService.getImageUrl(
                                                        item.imageUrl!),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    loadingBuilder: (context, child,
                                                        loadingProgress) {
                                                      if (loadingProgress == null)
                                                        return child;
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (_, __, ___) =>
                                                        Icon(
                                                      Icons.broken_image_rounded,
                                                      color: isDarkMode
                                                          ? Colors.grey[400]
                                                          : Colors
                                                              .deepPurple.shade600,
                                                      size: 32,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons
                                                        .image_not_supported_rounded,
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.deepPurple
                                                            .shade600,
                                                    size: 32,
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.name ?? 'Unknown',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16, // Reduced from 18
                                                    color: isDarkMode
                                                        ? Colors.grey[100]
                                                        : Colors.deepPurple.shade900,
                                                    fontFamily:
                                                        selectedLanguage == 'Khmer'
                                                            ? 'NotoSansKhmer'
                                                            : null,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (item.description?.isNotEmpty ==
                                                    true)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                        top: 4),
                                                    child: Text(
                                                      item.description!,
                                                      style: TextStyle(
                                                        fontSize: 13, // Reduced from 14
                                                        color: isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[700],
                                                        fontFamily: selectedLanguage ==
                                                                'Khmer'
                                                            ? 'NotoSansKhmer'
                                                            : null,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 4),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: isDarkMode
                                                          ? LinearGradient(
                                                              colors: [
                                                                Colors.grey[700]!,
                                                                Colors.grey[800]!,
                                                              ],
                                                              begin:
                                                                  Alignment.topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            )
                                                          : LinearGradient(
                                                              colors: [
                                                                Colors.deepPurple
                                                                    .shade100,
                                                                Colors.deepPurple
                                                                    .shade200,
                                                              ],
                                                              begin:
                                                                  Alignment.topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: isDarkMode
                                                              ? Colors.black12
                                                              : Colors.deepPurple
                                                                  .shade100,
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      '\$${item.price!.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: isDarkMode
                                                            ? Colors.grey[200]
                                                            : Colors.deepPurple
                                                                .shade800,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                        fontFamily:
                                                            selectedLanguage ==
                                                                    'Khmer'
                                                                ? 'NotoSansKhmer'
                                                                : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (!_isSelectionMode)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.deepPurple.shade600,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: isDarkMode
                                                    ? Colors.grey[700]!
                                                    : Colors.deepPurple.shade300,
                                                width: 1.0,
                                              ),
                                            ),
                                            color: isDarkMode
                                                ? Colors.grey[850]
                                                : Colors.grey[200],
                                            elevation: 4,
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                final result = await Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                    ) =>
                                                        AddItemScreen(
                                                      item: item,
                                                    ),
                                                    transitionsBuilder: (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child,
                                                    ) {
                                                      return SlideTransition(
                                                        position: animation.drive(
                                                          Tween(
                                                            begin: const Offset(
                                                                1.0, 0.0),
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
                                                      color: isDarkMode
                                                          ? Colors.blue[300]
                                                          : Colors
                                                              .deepPurple.shade600,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      lang['edit']!,
                                                      style: TextStyle(
                                                        color: isDarkMode
                                                            ? Colors.blue[300]
                                                            : Colors.black87,
                                                        fontFamily:
                                                            selectedLanguage ==
                                                                    'Khmer'
                                                                ? 'NotoSansKhmer'
                                                                : null,
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
                                                        fontFamily:
                                                            selectedLanguage ==
                                                                    'Khmer'
                                                                ? 'NotoSansKhmer'
                                                                : null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
              backgroundColor: isDarkMode
                  ? Colors.deepPurple[400]
                  : Colors.deepPurple.shade700,
              elevation: 6,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }
}