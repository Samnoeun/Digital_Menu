import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/category_model.dart' as category_model;
import '../../models/item_model.dart' as item_model;
import '../../services/api_services.dart';
import '../Item/add_item_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final category_model.Category category;
  const CategoryDetailScreen({Key? key, required this.category})
      : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin {
  late List<item_model.Item> _items;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'loading_items': 'Loading items...',
      'no_items': 'No items in this category',
      'add_items_prompt': 'Add items to "{name}" via the Items screen',
      'delete_item': 'Delete Item',
      'confirm_delete': 'Are you sure you want to delete "{name}"?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'refresh_items': 'Refresh items',
      'item_deleted': '{name} deleted successfully',
      'failed_delete_item': 'Error deleting item: {error}',
      'failed_reload_items': 'Failed to reload items: {error}',
    },
    'Khmer': {
      'loading_items': 'កំពុងផ្ទុកធាតុ...',
      'no_items': 'គ្មានធាតុនៅក្នុងប្រភេទនេះទេ',
      'add_items_prompt': 'បន្ថែមធាតុទៅ "{name}" តាមរយៈអេក្រង់ធាតុ',
      'delete_item': 'លុបធាតុ',
      'confirm_delete': 'តើអ្នកប្រាកដថាចង់លុប "{name}" មែនទេ?',
      'cancel': 'បោះបង់',
      'delete': 'លុប',
      'edit': 'កែសម្រួល',
      'refresh_items': 'ធ្វើឱ្យធាតុស្រស់',
      'item_deleted': 'បានលុប {name} ដោយជោគជ័យ',
      'failed_delete_item': 'កំហុសក្នុងការលុបធាតុ: {error}',
      'failed_reload_items': 'បរាជ័យក្នុងការផ្ទុកធាតុឡើងវិញ: {error}',
    },
  };

  String getTranslatedString(String key) {
    final translations = localization[selectedLanguage] ?? localization['English']!;
    return translations[key] ?? 'Translation missing: $key';
  }

  @override
  void initState() {
    super.initState();
    _items = [];
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedLanguage();
      _reloadItems();
    });
  }

  @override
  void dispose() {
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

  Future<void> _reloadItems() async {
    setState(() => _isLoading = true);
    try {
      final allItems = await ApiService.getItems();
      setState(() {
        _items = allItems
            .where((item) => item.categoryId == widget.category.id)
            .toList();
      });
      _animationController.forward();
    } catch (e) {
      _showErrorSnackbar(getTranslatedString('failed_reload_items').replaceFirst('{error}', e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(int itemId, String itemName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _buildDeleteConfirmationDialog(itemName),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteItem(itemId);
      _showSuccessSnackbar(getTranslatedString('item_deleted').replaceFirst('{name}', itemName));
      setState(() {
        _items.removeWhere((item) => item.id == itemId);
      });
    } catch (e) {
      _showErrorSnackbar(getTranslatedString('failed_delete_item').replaceFirst('{error}', e.toString()));
    }
  }

  Widget _buildDeleteConfirmationDialog(String itemName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Text(
            getTranslatedString('delete_item'),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
        ],
      ),
      content: Text(
        getTranslatedString('confirm_delete').replaceFirst('{name}', itemName),
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[800],
          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
        ),
      ),
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            getTranslatedString('cancel'),
            style: TextStyle(
              color: Colors.grey.shade600,
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
            getTranslatedString('delete'),
            style: TextStyle(
              color: Colors.white,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editItem(item_model.Item item) async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddItemScreen(item: item),
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
    if (result == true) await _reloadItems();
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
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.deepPurple[300] : Colors.deepPurple;
    final scaffoldBgColor = isDark
        ? Colors.grey[900]
        : Colors.deepPurple.shade50;

    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final emptyStateColor = isDark
        ? Colors.deepPurple[200]!
        : Colors.deepPurple[400]!;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[800]! : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor!,
                isDark
                    ? Colors.deepPurple.shade500
                    : Colors.deepPurple.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          constraints: const BoxConstraints(),
        ),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reloadItems,
            tooltip: getTranslatedString('refresh_items'),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator(isDark)
          : _items.isEmpty
              ? _buildEmptyState(
                  isDark,
                  emptyStateColor,
                  textColor,
                  secondaryTextColor,
                )
              : _buildItemList(isDark, cardColor, textColor, secondaryTextColor),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? Colors.deepPurple[300] : Colors.deepPurple.shade600,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            getTranslatedString('loading_items'),
            style: TextStyle(
              color: isDark
                  ? Colors.deepPurple[300]
                  : Colors.deepPurple.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool isDark,
    Color? emptyStateColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.deepPurple.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: emptyStateColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              getTranslatedString('no_items'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                getTranslatedString('add_items_prompt').replaceFirst('{name}', widget.category.name),
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return RefreshIndicator(
      onRefresh: _reloadItems,
      color: isDark ? Colors.deepPurple[300] : Colors.deepPurple.shade600,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final hasImage =
                item.imagePath != null && item.imagePath!.isNotEmpty;

            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutBack,
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 6,
                shadowColor: Colors.deepPurple.withOpacity(isDark ? 0.1 : 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        cardColor,
                        isDark ? Colors.grey[800]! : Colors.deepPurple.shade50,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _buildItemTile(
                    item,
                    hasImage,
                    isDark,
                    textColor,
                    secondaryTextColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemTile(
    item_model.Item item,
    bool hasImage,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.all(20),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: hasImage
                ? null
                : LinearGradient(
                    colors: [
                      isDark
                          ? Colors.deepPurple[400]!
                          : Colors.deepPurple.shade200,
                      isDark
                          ? Colors.deepPurple[300]!
                          : Colors.deepPurple.shade100,
                    ],
                  ),
          ),
          child: hasImage
              ? Image.network(
                  ApiService.getImageUrl(item.imagePath!),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildErrorImage(isDark),
                )
              : Icon(
                  Icons.image_not_supported_rounded,
                  color: isDark
                      ? Colors.deepPurple[100]
                      : Colors.deepPurple.shade600,
                  size: 32,
                ),
        ),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                item.description!,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? Colors.deepPurple[400]!
                        : Colors.deepPurple.shade600,
                    isDark
                        ? Colors.deepPurple[300]!
                        : Colors.deepPurple.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
          ),
        ],
      ),
      trailing: _buildPopupMenuButton(item, isDark),
    );
  }

  Widget _buildErrorImage(bool isDark) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? Colors.deepPurple[400]! : Colors.deepPurple.shade200,
            isDark ? Colors.deepPurple[300]! : Colors.deepPurple.shade100,
          ],
        ),
      ),
      child: Icon(
        Icons.broken_image_rounded,
        color: isDark ? Colors.deepPurple[100] : Colors.deepPurple.shade600,
        size: 32,
      ),
    );
  }

  PopupMenuButton<String> _buildPopupMenuButton(
    item_model.Item item,
    bool isDark,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? Colors.deepPurple[100] : Colors.deepPurple.shade600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') {
          _editItem(item);
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
                color: isDark
                    ? Colors.deepPurple[300]
                    : Colors.deepPurple.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                getTranslatedString('edit'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.deepPurple.shade700,
                  fontWeight: FontWeight.w500,
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
              Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                getTranslatedString('delete'),
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}