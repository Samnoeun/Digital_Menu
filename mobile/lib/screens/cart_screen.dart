import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart' as item;
import '../services/api_services.dart';
import 'table_number_screen.dart';

class CartScreen extends StatefulWidget {
  final List<item.Item> cart;
  final Function(item.Item) onDelete;
  final Function() onClearCart;

  const CartScreen({
    Key? key,
    required this.cart,
    required this.onDelete,
    required this.onClearCart,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<item.Item, int> _itemQuantities;
  final Map<item.Item, String> _specialNotes = {};
  bool _isSubmitting = false;
  String selectedLanguage = 'English'; // Default value

  final Map<String, Map<String, String>> localization = {
    'English': {
      'your_cart': 'Your Cart',
      'summary': 'Summary',
      'cart_empty': 'Cart is empty',
      'special_note': 'Special note (e.g. No chilli...)',
      'total': 'Total:',
      'submit_order': 'SUBMIT ORDER',
      'order_error': 'Error: ',
    },
    'Khmer': {
      'your_cart': 'តារាងទិញឥវ៉ាន់របស់អ្នក',
      'summary': 'សង្ខេប',
      'cart_empty': 'តារាងទិញឥវ៉ាន់គឺទទេ',
      'special_note': 'កំណត់ចំណាំ (ឧ. គ្មានម្ទេស...)',
      'total': 'សរុប៖',
      'submit_order': 'បញ្ជូនការកម្មង់',
      'order_error': 'កំហុស៖ ',
    },
  };

  @override
  void initState() {
    super.initState();
    _calculateQuantities();
    _loadSavedLanguage(); // Load saved language on initialization
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    setState(() {
      selectedLanguage = savedLanguage;
    });
  }

  void _calculateQuantities() {
    _itemQuantities = {};
    for (var item in widget.cart) {
      _itemQuantities.update(item, (value) => value + 1, ifAbsent: () => 1);
      _specialNotes.putIfAbsent(item, () => '');
    }
  }

  void _updateQuantity(item.Item item, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        final currentQuantity = _itemQuantities[item] ?? 0;
        final difference = newQuantity - currentQuantity;

        if (difference > 0) {
          for (int i = 0; i < difference; i++) {
            widget.cart.add(item);
          }
        } else {
          for (int i = 0; i < -difference; i++) {
            widget.cart.remove(item);
          }
        }

        _itemQuantities[item] = newQuantity;
      } else {
        _removeItem(item);
      }
    });
  }

  void _removeItem(item.Item itemToRemove) {
    setState(() {
      widget.cart.removeWhere((item) => item.id == itemToRemove.id);
      _calculateQuantities();
      _specialNotes.remove(itemToRemove);
    });
  }

  void _updateSpecialNote(item.Item item, String note) {
    setState(() {
      _specialNotes[item] = note;
    });
  }

  double get _total {
    return _itemQuantities.entries.fold(
      0,
      (sum, entry) => sum + (entry.key.price * entry.value),
    );
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting || widget.cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final orderItems = _itemQuantities.entries.map((entry) {
        return {
          'item_id': entry.key.id,
          'name': entry.key.name,
          'quantity': entry.value,
          'special_note': _specialNotes[entry.key] ?? '',
          'price': entry.key.price,
        };
      }).toList();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TableNumberScreen(
            orderItems: orderItems,
            onClearCart: widget.onClearCart,
          ),
        ),
      );
    } catch (e) {
      final lang = localization[selectedLanguage]!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lang['order_error']!}${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  TextStyle getTextStyle({bool isSubtitle = false, bool isGray = false}) {
    return TextStyle(
      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
      fontSize: isSubtitle ? 14 : 16,
      color: isGray
          ? Theme.of(context).textTheme.bodyMedium!.color
          : isSubtitle
              ? Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7)
              : Theme.of(context).textTheme.bodyLarge!.color,
      fontWeight: isSubtitle ? FontWeight.w400 : FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = localization[selectedLanguage]!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Color definitions
    final Color primaryColor = isDarkMode
        ? Colors.deepPurple[600]!
        : Colors.deepPurple;
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final emptyCartColor = isDarkMode
        ? Colors.deepPurple[200]
        : Colors.deepPurple.shade200;
    final priceColor = isDarkMode
        ? Colors.deepPurple[300]
        : Colors.deepPurple.shade400;
    final quantityBgColor = isDarkMode
        ? Colors.grey[700]
        : Colors.deepPurple.shade50;
    final Color quantityBorderColor = isDarkMode
        ? Colors.grey[600]!
        : Colors.deepPurple.shade200;
    final noteFieldColor = isDarkMode
        ? Colors.grey[700]
        : Colors.deepPurple.shade50;
    final noteFieldBorderColor = isDarkMode
        ? Colors.grey[500]
        : Colors.deepPurple.shade400;
    final noteTextColor = isDarkMode
        ? Colors.white
        : Colors.deepPurple.shade900;
    final totalBgColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                lang['your_cart']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                isDarkMode
                    ? Colors.deepPurple.shade500
                    : Colors.deepPurple.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: emptyCartColor,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          lang['cart_empty']!,
                          style: TextStyle(
                            fontSize: 20,
                            color: emptyCartColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      Text(
                        lang['summary']!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._itemQuantities.entries.map((entry) {
                        final item = entry.key;
                        final quantity = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: cardColor,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (item.imagePath != null &&
                                        item.imagePath!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          ApiService.getImageUrl(
                                            item.imagePath,
                                          ),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.deepPurple.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.fastfood,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.white70,
                                          size: 40,
                                        ),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: textColor,
                                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: priceColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: quantityBgColor,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: quantityBorderColor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove,
                                              size: 22,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.deepPurple,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _updateQuantity(
                                              item,
                                              quantity - 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              quantity.toString(),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.deepPurple,
                                                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add,
                                              size: 22,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.deepPurple,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _updateQuantity(
                                              item,
                                              quantity + 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  onChanged: (value) =>
                                      _updateSpecialNote(item, value),
                                  decoration: InputDecoration(
                                    hintText: lang['special_note'],
                                    hintStyle: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 15,
                                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                    ),
                                    filled: true,
                                    fillColor: noteFieldColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color:
                                            noteFieldBorderColor ??
                                            Colors
                                                .deepPurple
                                                .shade400, // Fallback
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: noteTextColor,
                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
          if (widget.cart.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
              decoration: BoxDecoration(
                color: totalBgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang['total']!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: textColor,
                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: priceColor,
                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _isSubmitting ? null : _submitOrder,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              lang['submit_order']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white,
                                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                              ),
                            ),
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
