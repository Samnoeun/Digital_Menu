import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services.dart';
import '../../models/order_model.dart';

class OrderScreen extends StatefulWidget {
  final Function(bool)? onThemeToggle;
  const OrderScreen({Key? key, this.onThemeToggle}) : super(key: key);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            'Orders',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
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
        actions: widget.onThemeToggle != null
            ? [
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    widget.onThemeToggle!(isDarkMode);
                  },
                ),
              ]
            : [],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadOrders,
              child: Text('Retry', style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _filteredOrders;
    return Column(
      children: [
        _buildFilterDropdown(theme),
        Expanded(
          child: filteredOrders.isEmpty
              ? Center(child: Text('No orders found', style: theme.textTheme.bodyMedium))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order, theme);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme) {
    final statusColor = _getStatusColor(order.status, theme);
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg ?? theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: fg ?? theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Semantics(
      label: 'Order for table ${order.tableNumber}, ${order.items.length} items, status ${order.status}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 2,
        shadowColor: statusColor.withOpacity(0.19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      child: Icon(
                        Icons.restaurant,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table ${order.tableNumber}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.status.toLowerCase() == 'pending'
                            ? (theme.brightness == Brightness.dark
                                ? Colors.orange.withOpacity(0.3)
                                : const Color.fromARGB(255, 246, 222, 152))
                            : statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            statusIcon(order.status),
                            size: 14,
                            color: order.status.toLowerCase() == 'pending'
                                ? Colors.orange
                                : statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel(order.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: order.status.toLowerCase() == 'pending'
                                  ? Colors.orange
                                  : statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        countBadge(order.items.length),
                        const Spacer(),
                        Text(
                          '\$$totalStr',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _expandedOrders[order.id] = !expanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text('Items', style: theme.textTheme.bodyMedium),
                            const SizedBox(width: 4),
                            countBadge(order.items.length),
                            const Spacer(),
                            AnimatedRotation(
                              turns: expanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            ..._buildOrderItemsList(order.items, theme),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                    _buildStatusButton(order, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrderItemsList(List<OrderItem> items, ThemeData theme) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('${item.quantity}x', style: theme.textTheme.bodySmall),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: theme.textTheme.bodySmall),
                      if (item.specialNote.isNotEmpty)
                        Text(
                          'Note: ${item.specialNote}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildStatusButton(Order order, ThemeData theme) {
    final nextStatus = _getNextStatus(order.status);
    if (nextStatus == null) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: theme.colorScheme.surfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _updateOrderStatus(order, nextStatus),
        child: Text(
          'Mark as ${nextStatus.toUpperCase()}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(ThemeData theme) {
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
        data: theme.copyWith(
          canvasColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        ),
        child: DropdownButtonFormField<String>(
          value: _filterStatus,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
          ),
          dropdownColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
          iconEnabledColor: theme.brightness == Brightness.dark ? Colors.white : Colors.deepPurple.shade700,
          style: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.deepPurple.shade700,
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

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return theme.colorScheme.primary;
      case 'ready':
        return Colors.green;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.6);
    }
  }
}