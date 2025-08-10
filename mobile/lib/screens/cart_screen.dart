import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _calculateQuantities();
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
        // Calculate how many items to add/remove
        final currentQuantity = _itemQuantities[item] ?? 0;
        final difference = newQuantity - currentQuantity;

        if (difference > 0) {
          // Add more items
          for (int i = 0; i < difference; i++) {
            widget.cart.add(item);
          }
        } else {
          // Remove items
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        titleSpacing: 0,
        // Remove backgroundColor property because flexibleSpace will handle it
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
              const Text(
                'Your Card',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
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
          Expanded(
            child: widget.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.deepPurple.shade200,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Cart is empty',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.deepPurple.shade300,
                            fontWeight: FontWeight.w500,
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
                        'Summary',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
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
                                          color: Colors.deepPurple.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fastfood,
                                          color: Colors.white70,
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Colors.deepPurple.shade400,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.deepPurple.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 22,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            color: Colors.deepPurple,
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
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepPurple,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add,
                                              size: 22,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            color: Colors.deepPurple,
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
                                    hintText:
                                        'Special note (e.g. No chilli...)',
                                    hintStyle: TextStyle(
                                      color: Colors.deepPurple.shade200,
                                      fontSize: 15,
                                    ),
                                    filled: true,
                                    fillColor: Colors.deepPurple.shade50,
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
                                        color: Colors.deepPurple.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.deepPurple.shade900,
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
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                        'Total:',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.deepPurple,
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
                        backgroundColor: Colors.deepPurple,
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
                          : const Text(
                              'SUBMIT ORDER',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
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
