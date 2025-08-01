import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services.dart';
import '../../models/order_model.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

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
            loadedOrders.add(Order.fromJson(orderData));
          } catch (e) {
            debugPrint('Error parsing order: $e');
          }
        }
      }

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
        _expandedOrders.clear();
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
      
      if (newStatus == 'completed') {
        await ApiService.deleteOrder(order.id);
        if (!mounted) return;
        setState(() {
          _orders.removeWhere((o) => o.id == order.id);
          _expandedOrders.remove(order.id);
        });
      } else {
        if (!mounted) return;
        setState(() {
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
        });
      }
    } catch (e) {
      debugPrint('Failed to update status: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
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
            TextButton(
              onPressed: _loadOrders,
              child: const Text('Retry'),
            ),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expandedOrders[order.id] = !(_expandedOrders[order.id] ?? false);
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${order.tableNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, hh:mm a').format(order.createdAt),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    backgroundColor: statusColor.withOpacity(0.2),
                    label: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${_calculateTotal(order.items).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_expandedOrders[order.id] == true) ...[
                const SizedBox(height: 12),
                ..._buildOrderItemsList(order.items),
                const SizedBox(height: 12),
                _buildStatusButton(order),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOrderItemsList(List<OrderItem> items) {
    return items.map((item) => Padding(
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
    )).toList();
  }

  Widget _buildStatusButton(Order order) {
    final nextStatus = _getNextStatus(order.status);
    if (nextStatus == null) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: _getStatusColor(nextStatus).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => _updateOrderStatus(order, nextStatus),
        child: Text(
          'Mark as ${nextStatus.toUpperCase()}',
          style: TextStyle(
            color: _getStatusColor(nextStatus),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _filterStatus,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'all',
            child: Text('All Orders'),
          ),
          DropdownMenuItem(
            value: 'pending',
            child: Text('Pending'),
          ),
          DropdownMenuItem(
            value: 'preparing',
            child: Text('Preparing'),
          ),
          DropdownMenuItem(
            value: 'ready',
            child: Text('Ready'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _filterStatus = value!;
          });
        },
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