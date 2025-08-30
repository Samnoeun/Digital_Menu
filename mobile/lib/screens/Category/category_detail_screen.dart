import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  List<item_model.Item> _items = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedLanguage = 'English';

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
      'invalid_data': 'Invalid item data',
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
      'invalid_data': 'ទិន្នន័យធាតុមិនត្រឹមត្រូវ',
    },
  };

  String getTranslatedString(String key) {
    final translations = localization[selectedLanguage] ?? localization['English']!;
    return translations[key] ?? 'Translation missing: $key';
  }

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
      print('Loaded items for category ${widget.category.id}: $allItems');
      setState(() {
        _items = allItems
            .where((item) =>
                item != null &&
                item.name != null &&
                item.name!.isNotEmpty &&
                item.price != null &&
                item.categoryId == widget.category.id)
            .toList();
      });
      _animationController.forward();
    } catch (e) {
      _showErrorSnackbar(
          getTranslatedString('failed_reload_items').replaceFirst('{error}', e.toString()));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(int itemId, String? itemName) async {
    itemName ??= getTranslatedString('item');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _buildDeleteConfirmationDialog(itemName!),
    );
    if (confirm != true) return;

    try {
      await ApiService.deleteItem(itemId);
      _showSuccessSnackbar(
          getTranslatedString('item_deleted').replaceFirst('{name}', itemName));
      setState(() {
        _items.removeWhere((item) => item.id == itemId);
      });
    } catch (e) {
      _showErrorSnackbar(
          getTranslatedString('failed_delete_item').replaceFirst('{error}', e.toString()));
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
    final scaffoldBgColor = isDark ? Colors.grey[900] : Colors.deepPurple.shade50;
    final secondaryTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final emptyStateColor = isDark ? Colors.deepPurple[200]! : Colors.deepPurple[400]!;
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
                isDark ? Colors.deepPurple.shade500 : Colors.deepPurple.shade400,
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
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingIndicator(isDark)
            : _items.isEmpty
                ? _buildEmptyState(isDark, emptyStateColor, textColor, secondaryTextColor)
                : _buildItemList(isDark, cardColor, textColor, secondaryTextColor),
      ),
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
              color: isDark ? Colors.deepPurple[300] : Colors.deepPurple.shade600,
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
    Color emptyStateColor,
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
                getTranslatedString('add_items_prompt')
                    .replaceFirst('{name}', widget.category.name),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          if (item == null || item.name == null || item.name!.isEmpty || item.price == null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    getTranslatedString('invalid_data'),
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                  ),
                ),
              ),
            );
          }
          final hasImage = item.imagePath != null && item.imagePath!.isNotEmpty;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 6,
              shadowColor: Colors.deepPurple.withOpacity(isDark ? 0.1 : 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      cardColor,
                      isDark ? Colors.grey[800]! : Colors.deepPurple.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ItemTile(
                  item: item,
                  hasImage: hasImage,
                  isDark: isDark,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  selectedLanguage: selectedLanguage,
                  onEdit: () => _editItem(item),
                  onDelete: () => _deleteItem(item.id, item.name),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ItemTile extends StatefulWidget {
  final item_model.Item item;
  final bool hasImage;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;
  final String selectedLanguage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemTile({
    Key? key,
    required this.item,
    required this.hasImage,
    required this.isDark,
    required this.textColor,
    required this.secondaryTextColor,
    required this.selectedLanguage,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ItemTileState createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  String getTranslatedString(String key) {
    final localization = {
      'English': {
        'edit': 'Edit',
        'delete': 'Delete',
      },
      'Khmer': {
        'edit': 'កែសម្រួល',
        'delete': 'លុប',
      },
    };
    final translations = localization[widget.selectedLanguage] ?? localization['English']!;
    return translations[key] ?? 'Translation missing: $key';
  }

  Widget _buildErrorImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.isDark ? Colors.deepPurple[400]! : Colors.deepPurple.shade200,
            widget.isDark ? Colors.deepPurple[300]! : Colors.deepPurple.shade100,
          ],
        ),
      ),
      child: Icon(
        Icons.image_not_supported_rounded,
        color: widget.isDark ? Colors.deepPurple[100] : Colors.deepPurple.shade600,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 80,
        maxHeight: 100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Section
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTapDown: (_) => _scaleController.forward(),
              onTapUp: (_) => _scaleController.reverse(),
              onTapCancel: () => _scaleController.reverse(),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.isDark ? Colors.grey[700]! : Colors.deepPurple.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(widget.isDark ? 0.2 : 0.1),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: widget.hasImage
                        ? CachedNetworkImage(
                            imageUrl: ApiService.getImageUrl(widget.item.imagePath!),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                color: widget.isDark
                                    ? Colors.deepPurple[300]
                                    : Colors.deepPurple.shade600,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildErrorImage(),
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 300),
                          )
                        : _buildErrorImage(),
                  ),
                ),
              ),
            ),
          ),
          // Item Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.name ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                      fontFamily: widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.isDark
                                ? Colors.deepPurple[400]!
                                : Colors.deepPurple.shade600,
                            widget.isDark
                                ? Colors.deepPurple[300]!
                                : Colors.deepPurple.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '\$${widget.item.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily:
                              widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                    ),
                  ),
                  if (widget.item.description != null && widget.item.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.secondaryTextColor,
                          fontFamily:
                              widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Popup Menu
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: widget.isDark ? Colors.deepPurple[100] : Colors.deepPurple.shade600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  widget.onEdit();
                } else if (value == 'delete') {
                  widget.onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: widget.isDark
                            ? Colors.deepPurple[300]
                            : Colors.deepPurple.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getTranslatedString('edit'),
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : Colors.deepPurple.shade700,
                          fontWeight: FontWeight.w500,
                          fontFamily:
                              widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                          fontFamily:
                              widget.selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
    );
  }
}
