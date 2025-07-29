import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      _itemQuantities.update(
        item,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      _specialNotes.putIfAbsent(item, () => '');
    }
  }

  void _updateQuantity(item.Item item, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        _itemQuantities[item] = newQuantity;
      } else {
        _removeItem(item);
      }
    });
  }

  void _removeItem(item.Item itemToRemove) {
    setState(() {
      widget.onDelete(itemToRemove);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._itemQuantities.entries.map((entry) {
                        final item = entry.key;
                        final quantity = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '${item.price.toStringAsFixed(2)} \$',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () => _updateQuantity(item, quantity - 1),
                                        ),
                                        Text(quantity.toString()),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => _updateQuantity(item, quantity + 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  onChanged: (value) => _updateSpecialNote(item, value),
                                  decoration: const InputDecoration(
                                    hintText: 'Special instructions (e.g., less sugar)',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  maxLines: 2,
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_total.toStringAsFixed(2)} \$',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      onPressed: _isSubmitting ? null : _submitOrder,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SUBMIT ORDER',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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