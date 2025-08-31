import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../models/order_history_model.dart';
import '../../models/category_model.dart' as category;
import '../../models/item_model.dart' as item;
import '../../services/api_services.dart';
import '../../screens/ReportOrderHistory/download_order_history_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryScreen extends StatefulWidget {
  final List<OrderHistory> orders;
  final String currentFilter;

  const OrderHistoryScreen({
    Key? key,
    required this.orders,
    this.currentFilter = 'All',
  }) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with TickerProviderStateMixin {
  String _currentFilter = 'All';
  DateTime? customDate;
  DateTimeRange? customRange;
  bool isLoading = true;
  bool isDownloading = false;
  String? errorMessage;
  String selectedLanguage = 'English'; // Add language state

  int totalItems = 0;
  int totalCategories = 0;
  int totalOrders = 0;
  List<OrderHistory> orders = [];
  List<OrderHistory> filteredOrders = [];

  // Add localization map
  final Map<String, Map<String, String>> localization = {
    'English': {
      'order_history': 'Order History',
      'filter_orders': 'Filter Orders',
      'all': 'All',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'custom_date': 'Custom Date',
      'custom_range': 'Custom Range',
      'selected': 'Selected',
      'range': 'Range',
      'loading_orders': 'Loading your orders...',
      'no_orders': 'No Orders Found',
      'no_orders_filter': 'No orders match your current filter criteria',
      'order_items': 'Order Items',
      'price': 'Price',
      'select_format': 'Select Format',
      'excel': 'Excel',
      'pdf': 'PDF',
      'download': 'Download',
      'table': 'Table',
      'items': 'items',
      'try_again': 'Try Again',
      'something_wrong': 'Oops! Something went wrong',
    },
    'Khmer': {
      'order_history': 'ប្រវត្តិការកម្មង់',
      'filter_orders': 'តម្រងការកម្មង់',
      'all': 'ទាំងអស់',
      'today': 'ថ្ងៃនេះ',
      'this_week': 'សប្តាហ៍នេះ',
      'this_month': 'ខែនេះ',
      'custom_date': 'កាលបរិច្ឆេទផ្ទាល់',
      'custom_range': 'ជួរដែលបានកំណត់',
      'selected': 'បានជ្រើសរើស',
      'range': 'ជួរ',
      'loading_orders': 'កំពុងដំណើរការការកម្មង់របស់អ្នក...',
      'no_orders': 'រកមិនឃើញការកម្មង់',
      'no_orders_filter': 'គ្មានការកម្មង់ដែលត្រូវគ្នានឹងលក្ខណៈវិនិច្ឆ័យតម្រងបច្ចុប្បន្នរបស់អ្នកទេ',
      'order_items': 'ទំនិញកម្មង់',
      'price': 'តម្លៃ',
      'select_format': 'ជ្រើសរើសទ្រង់ទ្រាយ',
      'excel': 'Excel',
      'pdf': 'PDF',
      'download': 'ទាញយក',
      'table': 'តុ',
      'items': 'ទំនិញ',
      'try_again': 'ព្យាយាមម្តងទៀត',
      'something_wrong': 'មានអ្វីមួយមិនត្រឹមត្រូវ',
    },
  };

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.currentFilter;
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
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _loadSavedLanguage(); // Load saved language
    _loadOrderHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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

  void _updateFilter(String newFilter) {
    setState(() {
      _currentFilter = newFilter;
      filteredOrders = _filterOrdersByDate(orders);
    });
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
        ApiService.getOrderHistory(),
      ]);

      final items = itemsAndCategories[0] as List<item.Item>;
      final categories = itemsAndCategories[1] as List<category.Category>;
      final orderHistoryData = itemsAndCategories[2] as List<dynamic>;

      // Create a map of item IDs to prices
      final itemPriceMap = Map.fromEntries(
        items.map((item) => MapEntry(item.id, item.price ?? 0.0)),
      );

      final orderHistory = orderHistoryData.map((json) => _parseOrderHistory(json, itemPriceMap)).toList();

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

  OrderHistory _parseOrderHistory(dynamic json, Map<int, double> itemPriceMap) {
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
      orderItems: _parseOrderItems(json['order_items'], itemPriceMap),
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

  List<OrderItemHistory> _parseOrderItems(dynamic itemsData, Map<int, double> itemPriceMap) {
    if (itemsData is! List<dynamic>) return [];

    return itemsData.map((itemJson) {
      if (itemJson is! Map<String, dynamic>) {
        return OrderItemHistory(
          itemId: 0,
          quantity: 0,
          specialNote: '',
          itemName: 'Invalid Item',
          price: 0.0,
        );
      }

      return OrderItemHistory(
        itemId: itemJson['item_id'] ?? 0,
        quantity: itemJson['quantity'] ?? 0,
        specialNote: itemJson['special_note'] ?? '',
        itemName: _getItemName(itemJson),
        price: (itemJson['price'] is num) ? itemJson['price'].toDouble() : (itemPriceMap[itemJson['item_id']] ?? 0.0),
      );
    }).toList();
  }

  String _getItemName(Map<String, dynamic> itemJson) {
    if (itemJson['item'] is Map<String, dynamic>) {
      return itemJson['item']['name'] ?? 'Unknown Item';
    }
    return itemJson['item_name'] ?? 'Unknown Item';
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
        _currentFilter = 'Custom Date';
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
        _currentFilter = 'Custom Range';
        filteredOrders = _filterOrdersByDate(orders);
      });
    }
  }

  List<OrderHistory> _filterOrdersByDate(List<OrderHistory> orders) {
    if (orders.isEmpty) return [];

    final now = DateTime.now();
    switch (_currentFilter) {
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

  Future<Map<String, String>> _getItemDetails(String itemId) async {
    try {
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
    final lang = localization[selectedLanguage]!; // Get translations for current language

    final scaffoldBgColor = isDarkMode ? Colors.grey[900] : Colors.grey[50];
    final infoCardColor = isDarkMode ? Colors.blue[900] : Colors.blue.shade50;
    final infoBorderColor = isDarkMode ? Colors.blue[800]! : Colors.blue.shade100;
    final infoTextColor = isDarkMode ? Colors.blue[100] : Colors.blue.shade800;

    final cardColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade100;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final primaryColor = isDarkMode ? Colors.deepPurple[600]! : Colors.deepPurple;
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
                isDarkMode ? Colors.deepPurple[800]! : Colors.deepPurple.shade700,
                isDarkMode ? Colors.deepPurple[600]! : Colors.deepPurple.shade500,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lang['order_history']!, // Translated title
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: isDownloading
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Icon(Icons.download, color: Colors.white, size: 24),
                    onPressed: isDownloading || isLoading || filteredOrders.isEmpty
                        ? null
                        : () => _showDownloadOptions(context),
                    tooltip: lang['download']!, // Translated tooltip
                  ),
                ],
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
                        lang['loading_orders']!, // Translated text
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                              color: isDarkMode ? Colors.red[900]!.withOpacity(0.3) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              color: isDarkMode ? Colors.red[300]! : const Color(0xFFEF4444),
                              size: 38,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            lang['something_wrong']!, // Translated text
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                              fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                              lang['try_again']!, // Translated text
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                              ),
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
                              color: isDarkMode ? cardColor : Colors.white,
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
                                      lang['filter_orders']!, // Translated text
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Column(
                                      children: [
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildFilterChip(
                                                lang['all']!, // Translated text
                                                Icons.list_alt,
                                                isDarkMode,
                                                primaryColor,
                                                textColor,
                                              ),
                                              const SizedBox(width: 8),
                                              _buildFilterChip(
                                                lang['today']!, // Translated text
                                                Icons.today,
                                                isDarkMode,
                                                primaryColor,
                                                textColor,
                                              ),
                                              const SizedBox(width: 8),
                                              _buildFilterChip(
                                                lang['this_week']!, // Translated text
                                                Icons.date_range,
                                                isDarkMode,
                                                primaryColor,
                                                textColor,
                                              ),
                                              const SizedBox(width: 8),
                                              _buildFilterChip(
                                                lang['this_month']!, // Translated text
                                                Icons.calendar_month,
                                                isDarkMode,
                                                primaryColor,
                                                textColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildFilterChip(
                                                lang['custom_date']!, // Translated text
                                                Icons.event,
                                                isDarkMode,
                                                primaryColor,
                                                textColor,
                                                onTap: () => _selectCustomDate(context),
                                                isFullWidth: true,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildFilterChip(
                                                lang['custom_range']!, // Translated text
                                                Icons.date_range_outlined,
                                                isDarkMode,
                                                primaryColor,
                                                textColor,
                                                onTap: () => _pickCustomRange(context),
                                                isFullWidth: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (_currentFilter == 'Custom Date' && customDate != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: primaryColor.withOpacity(0.2),
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
                                                  '${lang['selected']!}: ${DateFormat('MMM dd, yyyy').format(customDate!)}', // Translated prefix
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                                  ),
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      customDate = null;
                                                      _currentFilter = 'All';
                                                      filteredOrders = _filterOrdersByDate(orders);
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
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
                                        if (_currentFilter == 'Custom Range' && customRange != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: primaryColor.withOpacity(0.2),
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
                                                    '${lang['range']!}: ${DateFormat('MMM dd').format(customRange!.start)} - ${DateFormat('MMM dd, yyyy').format(customRange!.end)}', // Translated prefix
                                                    style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      customRange = null;
                                                      _currentFilter = 'All';
                                                      filteredOrders = _filterOrdersByDate(orders);
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
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
                          filteredOrders.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 50),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
                                        currencyFormat,
                                        lang, // Pass translations
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
                                          color: isDarkMode ? Colors.grey[700]! : const Color(0xFFF1F5F9),
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
                                        lang['no_orders']!, // Translated text
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        lang['no_orders_filter']!, // Translated text
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryTextColor,
                                          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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

  void _showDownloadOptions(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final lang = localization[selectedLanguage]!; // Get translations for current language

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang['select_format']!, // Translated text
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormatOption(context, lang['excel']!, Icons.table_chart, 'xlsx'), // Translated text
              _buildFormatOption(context, lang['pdf']!, Icons.picture_as_pdf, 'pdf'), // Translated text
             
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormatOption(BuildContext context, String title, IconData icon, String format) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.deepPurple[600]! : Colors.deepPurple;

    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _downloadReport(format);
      },
    );
  }

  void _downloadReport(String format) {
    final ordersToDownload = filteredOrders;
    if (ordersToDownload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No orders available for download'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      isDownloading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    DownloadOrderHistoryService.generateOrderHistoryReport(
      ordersToDownload,
      _currentFilter,
      format,
    ).then((file) {
      Navigator.pop(context);
      setState(() {
        isDownloading = false;
      });

      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded successfully to ${file.path}'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      Navigator.pop(context);
      setState(() {
        isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading report: $error'),
          duration: Duration(seconds: 3),
        ),
      );
    });
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
    final isSelected = _currentFilter == label;
    return GestureDetector(
      onTap: onTap ?? () {
        setState(() {
          _currentFilter = label;
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
          color: isSelected ? null : isDarkMode ? Colors.grey[700] : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : isDarkMode ? Colors.grey[600]! : const Color(0xFFE2E8F0),
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
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : isDarkMode ? Colors.grey[300] : const Color(0xFF64748B),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : isDarkMode ? Colors.grey[300] : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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
    NumberFormat currencyFormat,
    Map<String, String> lang, // Add translations parameter
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
        ),
        title: Row(
          children: [
            Text(
              '${lang['table']!} ${order.tableNumber}', // Translated prefix
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textColor,
                letterSpacing: -0.3,
                fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(order.status).withOpacity(0.8),
                    _getStatusColor(order.status),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(order.status).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: secondaryTextColor.withOpacity(0.8),
                ),
                SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: primaryColor.withOpacity(0.7),
                ),
                SizedBox(width: 4),
                Text(
                  '${order.orderItems.length} ${lang['items']!}', // Translated suffix
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : const Color(0xFFEAEAEA),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.restaurant, size: 14, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      lang['order_items']!, // Translated text
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textColor,
                        letterSpacing: -0.2,
                        fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ...order.orderItems.map((orderItem) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : const Color(0xFFEAEAEA),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderItem.itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: textColor,
                                  letterSpacing: -0.1,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                '${lang['price']!}: ${currencyFormat.format(orderItem.price)}', // Translated prefix
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
                                ),
                              ),
                              if (orderItem.specialNote.isNotEmpty) ...[
                                SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.amber[900] : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.amber[800]! : const Color(0xFFD97706).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.note_alt_outlined,
                                        size: 10,
                                        color: isDarkMode ? Colors.amber[100]! : const Color(0xFF92400E),
                                      ),
                                      SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          orderItem.specialNote,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDarkMode ? Colors.amber[100]! : const Color(0xFF92400E),
                                            fontWeight: FontWeight.w600,
                                            fontFamily: selectedLanguage == 'Khmer' ? 'NotoSansKhmer' : null,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [successColor, successColor.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: successColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            'x${orderItem.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
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