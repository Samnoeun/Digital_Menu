import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services.dart';
import '../../models/order_model.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all';
  Map<int, bool> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getOrders();

      if (!mounted) return;

      final List<Order> loadedOrders = [];
      if (response is List) {
        for (var orderData in response) {
          try {
            if (orderData is Map<String, dynamic>) {
              if (orderData['order_items'] != null) {
                orderData['items'] = orderData['order_items'].map((item) {
                  return {
                    'id': item['id'],
                    'item_id': item['item_id'],
                    'name': item['item']['name'],
                    'price': double.parse(item['item']['price']),
                    'quantity': item['quantity'],
                    'special_note': item['special_note'],
                  };
                }).toList();
              }
              loadedOrders.add(Order.fromJson(orderData));
            }
          } catch (e) {
            debugPrint('Error parsing order: $e');
          }
        }
      }

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
        for (var order in _orders) {
          _expandedOrders[order.id] = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  double _calculateTotal(List<OrderItem> items) {
    return items.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await ApiService.updateOrderStatus(order.id, newStatus);

      if (!mounted) return;

      setState(() {
        if (newStatus == 'completed') {
          _orders.removeWhere((o) => o.id == order.id);
          _expandedOrders.remove(order.id);
        } else {
          _orders = _orders.map((o) {
            if (o.id == order.id) {
              return Order(
                id: o.id,
                tableNumber: o.tableNumber,
                status: newStatus,
                createdAt: o.createdAt,
                items: o.items,
              );
            }
            return o;
          }).toList();
        }
      });
    } catch (e) {
      debugPrint('Failed to update status: ${e.toString()}');
      // Consider showing an error message to the user
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0, // Aligns content to the edge
        title: Padding(
          padding: const EdgeInsets.only(left: 2, right: 0),
          child: Row(
            mainAxisSize:
                MainAxisSize.min, // Keeps the icon and text tightly grouped
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              const Text(
                'Orders',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
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
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadOrders, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterDropdown(),
        Expanded(
          child: _filteredOrders.isEmpty
              ? const Center(child: Text('No orders found'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
  final statusColor = _getStatusColor(order.status);
  final expanded = _expandedOrders[order.id] ?? false;
  final time = DateFormat('MMM d · h:mm a').format(order.createdAt.toLocal());
  final totalStr = _calculateTotal(order.items).toStringAsFixed(2);

  String statusLabel(String s) {
    final t = s.trim();
    if (t.isEmpty) return 'Unknown';
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  IconData statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'preparing':
        return Icons.local_fire_department;
      case 'ready':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info_outline;
    }
  }


  Widget countBadge(int count, {Color? bg, Color? fg}) {
    final theme = Theme.of(context);
    final background = bg ?? theme.colorScheme.primary.withOpacity(0.08);
    final foreground = fg ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  return Semantics(
  label:
      'Order for table ${order.tableNumber}, ${order.items.length} items, status ${order.status}',
  child: Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: Container(
       decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade50,
              Colors.white,
              Colors.deepPurple.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  Theme.of(context).cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.restaurant, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Title and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${order.tableNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Theme.of(context).hintColor),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.status == 'pending'
                        ? Colors.amber.shade100
                        : statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(

                      color: order.status == 'pending'
                          ? Colors.amber.shade400.withOpacity(0.5)
                          : statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon(order.status),
                        size: 14,
                        color: order.status == 'pending'
                            ? Colors.orange
                            : statusColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        statusLabel(order.status),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: order.status == 'pending'
                                  ? Colors.orange
                                  : statusColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Total row
                Row(
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 6),
                    countBadge(
                      order.items.length,
                      bg: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      fg: Theme.of(context).colorScheme.primary,
                    ),
                    const Spacer(),
                    Text(
                      '\$$totalStr',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Items toggler
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _expandedOrders[order.id] = !expanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                       
                        Text('Items',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 4),
                        countBadge(order.items.length),
                        const Spacer(),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: const Icon(Icons.keyboard_arrow_down, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),


                // Animated items list
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      children: [
                        ..._buildOrderItemsList(order.items),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  crossFadeState: expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                  sizeCurve: Curves.easeOut,
                ),

                const SizedBox(height: 4),
                _buildStatusButton(order),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

}

  List<Widget> _buildOrderItemsList(List<OrderItem> items) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('${item.quantity}x', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 14)),
                      if (item.specialNote.isNotEmpty)
                        Text(
                          'Note: ${item.specialNote}',
                          style: TextStyle(
                            fontSize: 12,

                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

Widget _buildStatusButton(Order order) {
  final nextStatus = _getNextStatus(order.status);
  if (nextStatus == null) return const SizedBox();

  return SizedBox(
    width: double.infinity,
    child: TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: Color.fromARGB(255, 224, 215, 233),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _updateOrderStatus(order, nextStatus),
      child: Text(
        'Mark as ${nextStatus.toUpperCase()}',
        style: const TextStyle(
          color: Colors.black, 
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}


  Widget _buildFilterDropdown() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white, // White background for dropdown popup
        ),
        child: DropdownButtonFormField<String>(
          value: _filterStatus,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          dropdownColor: Colors.white, // White dropdown popup background
          iconEnabledColor:
              Colors.deepPurple.shade700, // Icon color to contrast
          style: TextStyle(
            color: Colors.deepPurple.shade700, // Text color for dropdown items
            fontWeight: FontWeight.w500,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Orders')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
            DropdownMenuItem(value: 'ready', child: Text('Ready')),
          ],
          onChanged: (value) {
            setState(() {
              _filterStatus = value!;
            });
          },
        ),
      ),
    );
  }

  List<Order> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  String? _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'preparing';
      case 'preparing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return null;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
