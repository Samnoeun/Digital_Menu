import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/api_services.dart';
import '../models/item_model.dart' as item;
import '../models/category_model.dart' as category;
import '../models/order_history_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> 
    with TickerProviderStateMixin {
  String selectedFilter = 'All';
  DateTime? customDate;
  DateTimeRange? customRange;
  bool isLoading = true;
  String? errorMessage;

  int totalItems = 0;
  int totalCategories = 0;
  int totalOrders = 0;
  List<OrderHistory> orders = [];
  List<OrderHistory> filteredOrders = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800)
    );
    _slideController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut)
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), 
      end: Offset.zero
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _loadOrderHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('Loading order history from: ${ApiService.baseUrl}/order-history');
      
      final testResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/order-history'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Raw API response status: ${testResponse.statusCode}');
      print('Raw API response body: ${testResponse.body}');

      final itemsAndCategories = await Future.wait([
        ApiService.getItems(),
        ApiService.getCategories(),
        ApiService.getOrderHistory(),
      ]);

      final items = itemsAndCategories[0] as List<item.Item>;
      final categories = itemsAndCategories[1] as List<category.Category>;
      final orderHistory = itemsAndCategories[2] as List<OrderHistory>;
      
      setState(() {
        totalItems = items.length;
        totalCategories = categories.length;
        totalOrders = orderHistory.length;
        orders = orderHistory;
        filteredOrders = _filterOrdersByDate(orderHistory);
        isLoading = false;
      });
      
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Detailed error: $e');
      setState(() {
        errorMessage = 'Failed to load order history: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  List<OrderHistory> _filterOrdersByDate(List<OrderHistory> orders) {
    if (orders.isEmpty) return [];
    
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'Today':
        return orders.where((order) {
          final date = order.createdAt;
          return date.year == now.year && date.month == now.month && date.day == now.day;
        }).toList();
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return orders.where((order) {
          final date = order.createdAt;
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 date.isBefore(now.add(const Duration(days: 1)));
        }).toList();
      case 'This Month':
        return orders.where((order) {
          final date = order.createdAt;
          return date.year == now.year && date.month == now.month;
        }).toList();
      case 'Custom Date':
        if (customDate != null) {
          return orders.where((order) {
            final date = order.createdAt;
            return date.year == customDate!.year &&
                   date.month == customDate!.month &&
                   date.day == customDate!.day;
          }).toList();
        }
        return orders;
      case 'Custom Range':
        if (customRange != null) {
          return orders.where((order) {
            final date = order.createdAt;
            return (date.isAfter(customRange!.start.subtract(const Duration(days: 1))) ||
                    date.isAtSameMomentAs(customRange!.start)) &&
                   (date.isBefore(customRange!.end.add(const Duration(days: 1))) ||
                    date.isAtSameMomentAs(customRange!.end));
          }).toList();
        }
        return orders;
      default:
        return orders;
    }
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        customDate = picked;
        selectedFilter = 'Custom Date';
        filteredOrders = _filterOrdersByDate(orders);
      });
    }
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        customRange = picked;
        selectedFilter = 'Custom Range';
        filteredOrders = _filterOrdersByDate(orders);
      });
    }
  }

  Future<Map<String, String>> _getItemDetails(String itemId) async {
    try {
      // This should be implemented to fetch item details from your API
      // For now, returning a placeholder
      return {'name': 'Item $itemId', 'category': 'Unknown'};
    } catch (e) {
      return {'name': 'Unknown Item', 'category': 'No category'};
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
appBar: AppBar(
  toolbarHeight: 70,
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.deepPurple.shade700,
          Colors.deepPurple.shade500,
        ],
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 20, 24, 20),
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Order History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
    onPressed: () => Navigator.pop(context),
    constraints: const BoxConstraints(),
    padding: EdgeInsets.zero,
  ),
  backgroundColor: Colors.transparent,
  elevation: 0,
),
      body: SingleChildScrollView(
        child: isLoading
            ? const SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading your orders...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : errorMessage != null
                ? Container(
                    height: 250,
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oops! Something went wrong',
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadOrderHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.filter_list,
                                        color: Color(0xFF6366F1),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Filter Orders',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Column(
                                      children: [
                                        // First row - main filters
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildFilterChip('All', Icons.list_alt),
                                              const SizedBox(width: 8),
                                              _buildFilterChip('Today', Icons.today),
                                              const SizedBox(width: 8),
                                              _buildFilterChip('This Week', Icons.date_range),
                                              const SizedBox(width: 8),
                                              _buildFilterChip('This Month', Icons.calendar_month),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Second row - custom filters
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildFilterChip(
                                                'Custom Date', 
                                                Icons.event, 
                                                onTap: () => _selectCustomDate(context),
                                                isFullWidth: true,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildFilterChip(
                                                'Custom Range', 
                                                Icons.date_range_outlined, 
                                                onTap: () => _pickCustomRange(context),
                                                isFullWidth: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selectedFilter == 'Custom Date' && customDate != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Color(0xFF6366F1),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Selected: ${DateFormat('MMM dd, yyyy').format(customDate!)}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF6366F1),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      customDate = null;
                                                      selectedFilter = 'All';
                                                      filteredOrders = _filterOrdersByDate(orders);
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 14,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (selectedFilter == 'Custom Range' && customRange != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.date_range,
                                                  size: 16,
                                                  color: Color(0xFF6366F1),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Range: ${DateFormat('MMM dd').format(customRange!.start)} - ${DateFormat('MMM dd, yyyy').format(customRange!.end)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF6366F1),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      customRange = null;
                                                      selectedFilter = 'All';
                                                      filteredOrders = _filterOrdersByDate(orders);
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      size: 14,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Summary Cards
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                _buildSummaryCard(
                                  'Total Items',
                                  totalItems.toString(),
                                  Icons.inventory_2,
                                  const Color(0xFFFF6B6B),
                                  const Color(0xFFFFF5F5),
                                ),
                                const SizedBox(width: 8),
                                _buildSummaryCard(
                                  'Categories',
                                  totalCategories.toString(),
                                  Icons.category,
                                  const Color(0xFF4ECDC4),
                                  const Color(0xFFF0FDFA),
                                ),
                                const SizedBox(width: 8),
                                _buildSummaryCard(
                                  'Orders',
                                  totalOrders.toString(),
                                  Icons.receipt_long,
                                  const Color(0xFF45B7D1),
                                  const Color(0xFFF0F9FF),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Orders List
                          filteredOrders.isNotEmpty
                              ? ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  itemCount: filteredOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = filteredOrders[index];
                                    return _buildOrderCard(order, index);
                                  },
                                )
                              : Container(
                                  margin: const EdgeInsets.all(20),
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.inbox_outlined,
                                          size: 38,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No Orders Found',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No orders match your current filter criteria',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                          
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {VoidCallback? onTap, bool isFullWidth = false}) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: onTap ?? () {
        setState(() {
          selectedFilter = label;
          filteredOrders = _filterOrdersByDate(orders);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              bgColor.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFF1E293B),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderHistory order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFAFBFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(24),
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          leading: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
          ),
          title: Row(
            children: [
              Text(
                'Table ${order.tableNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(order.status).withOpacity(0.8),
                      _getStatusColor(order.status),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(order.status).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: const Color(0xFF64748B).withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: const Color(0xFF6366F1).withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${order.orderItems.length} items',
                    style: TextStyle(
                      color: const Color(0xFF6366F1).withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9).withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...order.orderItems.map((orderItem) {
                    return FutureBuilder<Map<String, String>>(
                      future: _getItemDetails(orderItem.itemId.toString()),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF6366F1).withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Loading item...',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final itemDetails = snapshot.data ?? {'name': 'Unknown Item', 'category': 'No category'};
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                const Color(0xFFF8FAFC).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getCategoryColor(itemDetails['category']!).withOpacity(0.8),
                                      _getCategoryColor(itemDetails['category']!),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getCategoryColor(itemDetails['category']!).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getCategoryIcon(itemDetails['category']!),
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemDetails['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(itemDetails['category']!).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getCategoryColor(itemDetails['category']!).withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        itemDetails['category']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getCategoryColor(itemDetails['category']!),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (orderItem.specialNote.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFFEF3C7),
                                              const Color(0xFFFDE68A).withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFD97706).withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.note_alt_outlined,
                                              size: 12,
                                              color: const Color(0xFF92400E),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                orderItem.specialNote,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF92400E),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'x${orderItem.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'appetizer':
      case 'appetizers':
        return const Color(0xFFFF6B6B);
      case 'main course':
      case 'main':
        return const Color(0xFF4ECDC4);
      case 'dessert':
      case 'desserts':
        return const Color(0xFFFFE66D);
      case 'beverage':
      case 'beverages':
      case 'drinks':
        return const Color(0xFF45B7D1);
      case 'salad':
      case 'salads':
        return const Color(0xFF96CEB4);
      case 'soup':
      case 'soups':
        return const Color(0xFFFF8A80);
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'appetizer':
      case 'appetizers':
        return Icons.restaurant;
      case 'main course':
      case 'main':
        return Icons.dinner_dining;
      case 'dessert':
      case 'desserts':
        return Icons.cake;
      case 'beverage':
      case 'beverages':
      case 'drinks':
        return Icons.local_drink;
      case 'salad':
      case 'salads':
        return Icons.eco;
      case 'soup':
      case 'soups':
        return Icons.soup_kitchen;
      default:
        return Icons.fastfood;
    }
  }
}