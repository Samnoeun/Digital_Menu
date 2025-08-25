import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../models/order_history_model.dart';
import '../../models/category_model.dart' as category;
import '../../models/item_model.dart' as item;
import '../../services/api_services.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

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

      final itemsAndCategories = await Future.wait([
        ApiService.getItems(),
        ApiService.getCategories(),
        ApiService.getOrderHistory(), // This returns List<dynamic> (raw data)
      ]);

      final items = itemsAndCategories[0] as List<item.Item>;
      final categories = itemsAndCategories[1] as List<category.Category>;
      final orderHistoryData = itemsAndCategories[2] as List<dynamic>;

      // Convert raw data to OrderHistory objects using helper function
      final orderHistory = orderHistoryData
          .map((json) => _parseOrderHistory(json))
          .toList();

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

  // Add these helper functions to your _OrderHistoryScreenState class
  OrderHistory _parseOrderHistory(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return OrderHistory(
        id: 0,
        tableNumber: 0,
        status: 'unknown',
        createdAt: DateTime.now(),
        orderItems: [],
      );
    }

    return OrderHistory(
      id: json['id'] ?? 0,
      tableNumber: _parseTableNumber(json['table_number']),
      status: json['status'] ?? 'completed',
      createdAt: _parseDateTime(json['created_at'] ?? json['completed_at']),
      orderItems: _parseOrderItems(json['order_items']),
    );
  }

  int _parseTableNumber(dynamic tableNumber) {
    if (tableNumber is int) return tableNumber;
    if (tableNumber is String) return int.tryParse(tableNumber) ?? 0;
    return 0;
  }

  DateTime _parseDateTime(dynamic dateString) {
    try {
      if (dateString is String) return DateTime.parse(dateString);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  List<OrderItemHistory> _parseOrderItems(dynamic itemsData) {
    if (itemsData is! List<dynamic>) return [];

    return itemsData.map((itemJson) {
      if (itemJson is! Map<String, dynamic>) {
        return OrderItemHistory(
          itemId: 0,
          quantity: 0,
          specialNote: '',
          itemName: 'Invalid Item',
          // itemCategory: 'No category',
        );
      }

      return OrderItemHistory(
        itemId: itemJson['item_id'] ?? 0,
        quantity: itemJson['quantity'] ?? 0,
        specialNote: itemJson['special_note'] ?? '',
        itemName: _getItemName(itemJson),
        // itemCategory: _getItemCategory(itemJson),
      );
    }).toList();
  }

  String _getItemName(Map<String, dynamic> itemJson) {
    if (itemJson['item'] is Map<String, dynamic>) {
      return itemJson['item']['name'] ?? 'Unknown Item';
    }
    return 'Unknown Item';
  }

  String _getItemCategory(Map<String, dynamic> itemJson) {
    if (itemJson['item'] is Map<String, dynamic>) {
      final itemData = itemJson['item'];
      if (itemData['category'] is Map<String, dynamic>) {
        return itemData['category']['name'] ?? 'No category';
      }
      return itemData['category_name'] ?? 'No category';
    }
    return 'No category';
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            dialogBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
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
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            dialogBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
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

  List<OrderHistory> _filterOrdersByDate(List<OrderHistory> orders) {
    if (orders.isEmpty) return [];

    final now = DateTime.now();
    switch (selectedFilter) {
      case 'Today':
        return orders.where((order) {
          final date = order.createdAt;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
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
            return (date.isAfter(
                      customRange!.start.subtract(const Duration(days: 1)),
                    ) ||
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    switch (status.toLowerCase()) {
      case 'completed':
        return isDarkMode ? Colors.green[600]! : Colors.green;
      case 'pending':
        return isDarkMode ? Colors.orange[600]! : Colors.orange;
      case 'cancelled':
        return isDarkMode ? Colors.red[600]! : Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // Color definitions
    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];

    final infoCardColor = isDarkMode ? Colors.blue[900] : Colors.blue.shade50;
    final Color infoBorderColor = isDarkMode
        ? Colors.blue[800]!
        : Colors.blue.shade100;
    final infoTextColor = isDarkMode ? Colors.blue[100] : Colors.blue.shade800;

    // Color definitions with null assertion operator
    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;
    final primaryColor = isDarkMode
        ? Colors.deepPurple[600]!
        : Colors.deepPurple;
    final successColor = isDarkMode ? Colors.green[600]! : Colors.green;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDarkMode
                    ? Colors.deepPurple[800]!
                    : Colors.deepPurple.shade700,
                isDarkMode
                    ? Colors.deepPurple[600]!
                    : Colors.deepPurple.shade500,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 24, 20),
              child: Align(
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
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: isLoading
            ? SizedBox(
                height: 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading your orders...',
                        style: TextStyle(
                          color: secondaryTextColor,
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
                          color: isDarkMode
                              ? Colors.red[900]!.withOpacity(0.3)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: isDarkMode
                              ? Colors.red[300]!
                              : const Color(0xFFEF4444),
                          size: 38,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadOrderHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
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
                          color: isDarkMode
                              ? cardColor
                              : Colors.white, // ✅ White in light mode
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
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.filter_list,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Filter Orders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
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
                                          _buildFilterChip(
                                            'All',
                                            Icons.list_alt,
                                            isDarkMode,
                                            primaryColor,
                                            textColor,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(
                                            'Today',
                                            Icons.today,
                                            isDarkMode,
                                            primaryColor,
                                            textColor,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(
                                            'This Week',
                                            Icons.date_range,
                                            isDarkMode,
                                            primaryColor,
                                            textColor,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildFilterChip(
                                            'This Month',
                                            Icons.calendar_month,
                                            isDarkMode,
                                            primaryColor,
                                            textColor,
                                          ),
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
                                            isDarkMode,
                                            primaryColor,
                                            textColor,
                                            onTap: () =>
                                                _selectCustomDate(context),
                                            isFullWidth: true,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildFilterChip(
                                            'Custom Range',
                                            Icons.date_range_outlined,
                                            isDarkMode,
                                            primaryColor,
                                            textColor,
                                            onTap: () =>
                                                _pickCustomRange(context),
                                            isFullWidth: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (selectedFilter == 'Custom Date' &&
                                        customDate != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: primaryColor.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Selected: ${DateFormat('MMM dd, yyyy').format(customDate!)}',
                                              style: TextStyle(
                                                color: primaryColor,
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
                                                  filteredOrders =
                                                      _filterOrdersByDate(
                                                        orders,
                                                      );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (selectedFilter == 'Custom Range' &&
                                        customRange != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: primaryColor.withOpacity(
                                              0.2,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.date_range,
                                              size: 16,
                                              color: primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Range: ${DateFormat('MMM dd').format(customRange!.start)} - ${DateFormat('MMM dd, yyyy').format(customRange!.end)}',
                                                style: TextStyle(
                                                  color: primaryColor,
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
                                                  filteredOrders =
                                                      _filterOrdersByDate(
                                                        orders,
                                                      );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: primaryColor,
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

                      SizedBox(height: 20),

                      // Then fix the ListView.builder:
                      filteredOrders.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(
                                bottom: 50,
                              ), // Add bottom padding
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                                  return _buildOrderCard(
                                    order,
                                    index,
                                    isDarkMode,
                                    cardColor,
                                    textColor,
                                    secondaryTextColor,
                                    primaryColor,
                                    successColor,
                                  );
                                },
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: cardColor,
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
                                      color: isDarkMode
                                          ? Colors.grey[700]!
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.inbox_outlined,
                                      size: 38,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Orders Found',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No orders match your current filter criteria',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryTextColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    IconData icon,
    bool isDarkMode,
    Color primaryColor,
    Color textColor, {
    VoidCallback? onTap,
    bool isFullWidth = false,
  }) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap:
          onTap ??
          () {
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
              ? LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isDarkMode
              ? Colors.grey[700]
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDarkMode
                ? Colors.grey[600]!
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: isFullWidth
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : isDarkMode
                  ? Colors.grey[300]
                  : const Color(0xFF64748B),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.grey[300]
                      : const Color(0xFF64748B),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? Colors.grey[800]! : Colors.white,
              bgColor.withOpacity(isDarkMode ? 0.5 : 0.3),
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
          border: Border.all(color: color.withOpacity(0.1), width: 1),
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
            SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6),
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

  Widget _buildOrderCard(
    OrderHistory order,
    int index,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
    Color successColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Colors.grey[800]!, Colors.grey[900]!]
              : [Colors.white, const Color(0xFFFAFBFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
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
        border: Border.all(color: primaryColor.withOpacity(0.08), width: 1),
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
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                  const Color(0xFFEC4899),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
          ),
          title: Row(
            children: [
              Text(
                'Table ${order.tableNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                  style: TextStyle(
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
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: secondaryTextColor.withOpacity(0.8),
                  ),
                  SizedBox(width: 6),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(order.createdAt),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: primaryColor.withOpacity(0.7),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${order.orderItems.length} items',
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.8),
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
                  colors: isDarkMode
                      ? [Colors.grey[700]!, Colors.grey[800]!]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFF1F5F9).withOpacity(0.5),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.05),
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
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Order Items',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Replace the FutureBuilder with direct access to item details
                  ...order.orderItems.map((orderItem) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [Colors.grey[700]!, Colors.grey[800]!]
                              : [
                                  Colors.white,
                                  const Color(0xFFF8FAFC).withOpacity(0.8),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.05),
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
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderItem
                                      .itemName, // Use the item name directly
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: textColor,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                SizedBox(height: 4),

                                if (orderItem.specialNote.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDarkMode
                                            ? [
                                                Colors.amber[800]!,
                                                Colors.amber[900]!,
                                              ]
                                            : [
                                                const Color(0xFFFEF3C7),
                                                const Color(
                                                  0xFFFDE68A,
                                                ).withOpacity(0.7),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFD97706,
                                        ).withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.note_alt_outlined,
                                          size: 12,
                                          color: isDarkMode
                                              ? Colors.amber[100]!
                                              : const Color(0xFF92400E),
                                        ),
                                        SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            orderItem.specialNote,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDarkMode
                                                  ? Colors.amber[100]!
                                                  : const Color(0xFF92400E),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  successColor,
                                  successColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: successColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'x${orderItem.quantity}',
                              style: TextStyle(
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
