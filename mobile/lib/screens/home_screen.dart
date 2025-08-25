import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../models/item_model.dart' as item;
import '../models/category_model.dart' as category;
import '../models/restaurant_model.dart';
import 'Preview/item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int totalItems = 0;
  int totalCategories = 0;
  int totalOrders = 0;
  String topItem = "Loading...";
  List<Map<String, dynamic>> topItems = [];
  bool isLoading = true;
  String selectedFilter = 'Today';
  DateTime? customDate;
  Restaurant? restaurant;
  String _language = 'English'; // Default language
  bool _isLanguageLoaded = false; // Track if language is loaded

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Localization map for English and Khmer
  final Map<String, Map<String, String>> localization = {
    'English': {
      'dashboard_subtitle': 'Dashboard Overview',
      'welcome_message': 'Welcome, {restaurantName}',
      'performance_overview': "Here's your restaurant's performance overview",
      'filter_by_label': 'Filter by',
      'total_items': 'Total Items',
      'total_categories': 'Total Categories',
      'orders': 'Orders ({filter})',
      'top_item': 'Top Item',
      'top_items_title': 'Top 5 Ordered Items',
      'no_orders_message': 'No orders found for selected period',
      'orders_suffix': 'orders',
      'error_prefix': 'Error:',
      'snackbar_error': 'Error: {error}',
      'network_error': 'Network Error: Unable to connect to the server',
      'api_error': 'API Error: Failed to fetch data',
      'today': 'Today',
      'this_week': 'This Week',
      'this_month': 'This Month',
      'custom_date': 'Custom Date',
      'no_data': 'No data',
      'loading': 'Loading...',
      'no_category': 'No category',
    },
    'Khmer': {
      'dashboard_subtitle': 'ទិដ្ឋភាពទូទៅនៃផ្ទាំងគ្រប់គ្រង',
      'welcome_message': 'សូមស្វាគមន៍, {restaurantName}',
      'performance_overview': 'នេះជាទិដ្ឋភាពនៃការអនុវត្តភោជនីយដ្ឋានរបស់អ្នក',
      'filter_by_label': 'តម្រងតាម',
      'total_items': 'មុខទំនិញសរុប',
      'total_categories': 'ប្រភេទសរុប',
      'orders': 'ការកម្ម៉ង់ ({filter})',
      'top_item': 'មុខទំនិញកំពូល',
      'top_items_title': 'មុខទំនិញកម្ម៉ង់ច្រើនបំផុត ៥',
      'no_orders_message': 'រកមិនឃើញការកម្ម៉ង់សម្រាប់រយៈពេលដែលបានជ្រើសរើសទេ',
      'orders_suffix': 'ការកម្ម៉ង់',
      'error_prefix': 'កំហុស:',
      'snackbar_error': 'កំហុស: {error}',
      'network_error': 'កំហុសបណ្តាញ: មិនអាចភ្ជាប់ទៅសេវាកម្មបានទេ',
      'api_error': 'កំហុស API: បរាជ័យក្នុងការទាញទិន្នន័យ',
      'today': 'ថ្ងៃនេះ',
      'this_week': 'សប្តាហ៍នេះ',
      'this_month': 'ខែនេះ',
      'custom_date': 'កាលបរិច្ឆេទផ្ទាល់ខ្លួន',
      'no_data': 'គ្មានទិន្នន័យ',
      'loading': 'កំពុងផ្ទុក...',
      'no_category': 'គ្មានប្រភេទ',
    },
  };

  final List<String> filterOptions = [
    'Today',
    'This Week',
    'This Month',
    'Custom Date',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSavedLanguage().then((_) {
      if (mounted) {
        setState(() {
          _isLanguageLoaded = true;
        });
        debugPrint('Language loaded: $_language'); // Log language value
        _loadRestaurantInfo();
        _loadData();
      }
    });
  }

  // Load the saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('selectedLanguage');
      if (savedLanguage != null && localization.containsKey(savedLanguage)) {
        setState(() {
          _language = savedLanguage;
        });
      } else {
        setState(() {
          _language = 'English'; // Fallback to English
        });
        if (savedLanguage != null) {
          debugPrint(
            'Invalid language found in SharedPreferences: $savedLanguage',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading language from SharedPreferences: $e');
      setState(() {
        _language = 'English'; // Fallback to English
      });
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final fetchedRestaurant = await ApiService.getRestaurant();
      if (mounted) {
        setState(() {
          restaurant = fetchedRestaurant;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().contains('SocketException')
            ? (localization[_language]?.containsKey('network_error') == true
                  ? localization[_language]!['network_error']!
                  : 'Network Error: Unable to connect to the server')
            : (localization[_language]?.containsKey('snackbar_error') == true
                  ? localization[_language]!['snackbar_error']!.replaceAll(
                      '{error}',
                      e.toString(),
                    )
                  : 'Error: $e');
        debugPrint('Error in _loadRestaurantInfo (language: $_language): $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            backgroundColor: Colors.deepPurple.shade700,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      topItem = localization[_language]?.containsKey('loading') == true
          ? localization[_language]!['loading']!
          : 'Loading...';
    });
    _animationController.reset();

    try {
      final results = await Future.wait([
        ApiService.getItems(),
        ApiService.getCategories(),
        ApiService.getOrders(),
        ApiService.getOrderHistory(),
      ]);
      final items = results[0] as List<item.Item>;
      final categories = results[1] as List<category.Category>;
      final activeOrders = results[2] as List<dynamic>;
      final historicalOrders = results[3] as List<dynamic>;
      
      final allOrders = [...activeOrders, ...historicalOrders];

      final categoryMap = {for (var cat in categories) cat.id: cat};
      final filteredOrders = _filterOrdersByDate(allOrders);

      final itemMap = {
        for (var item in items)
          item.id.toString(): item.copyWith(
            category: categoryMap[item.categoryId],
          ),
      };

      final itemCounts = <String, int>{};
      final itemData = <String, item.Item>{};

      for (var order in filteredOrders) {
        if (order['order_items'] != null) {
          for (var orderItem in order['order_items']) {
            final itemId = orderItem['item_id'].toString();
            final item = itemMap[itemId];
            if (item != null) {
              final quantity = (orderItem['quantity'] as num).toInt();
              itemCounts[item.name] = (itemCounts[item.name] ?? 0) + quantity;
              itemData[item.name] = item;
            }
          }
        }
      }

      final sortedItems = itemCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (mounted) {
        setState(() {
          totalItems = items.length;
          totalCategories = categories.length;
          totalOrders = filteredOrders.length;
          topItem = sortedItems.isNotEmpty
              ? sortedItems.first.key
              : (localization[_language]?.containsKey('no_data') == true
                    ? localization[_language]!['no_data']!
                    : 'No data');
          topItems = sortedItems.take(5).map((e) {
            final item = itemData[e.key]!;
            return {
              'name': item.name,
              'count': e.value,
              'image': item.imagePath,
              'item': item,
              'category':
                  item.category?.name ??
                  (localization[_language]?.containsKey('no_category') == true
                      ? localization[_language]!['no_category']!
                      : 'No category'),
            };
          }).toList();
          isLoading = false;
        });

        _animationController.forward();
      }
    } catch (e) {
      final errorMessage = e.toString().contains('SocketException')
          ? (localization[_language]?.containsKey('network_error') == true
                ? localization[_language]!['network_error']!
                : 'Network Error: Unable to connect to the server')
          : (localization[_language]?.containsKey('error_prefix') == true
                ? '${localization[_language]!['error_prefix']!} $e'
                : 'Error: $e');
      debugPrint('Error in _loadData (language: $_language): $e');
      setState(() {
        topItem = errorMessage;
        topItems = [];
        isLoading = false;
      });
    }
  }

  List<dynamic> _filterOrdersByDate(List<dynamic> orders) {
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'Today':
        return orders.where((order) {
          final orderDate = DateTime.parse(order['created_at']).toLocal();
          return orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day;
        }).toList();
      case 'This Week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return orders.where((order) {
          final orderDate = DateTime.parse(order['created_at']).toLocal();
          return orderDate.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          );
        }).toList();
      case 'This Month':
        return orders.where((order) {
          final orderDate = DateTime.parse(order['created_at']).toLocal();
          return orderDate.year == now.year && orderDate.month == now.month;
        }).toList();
      case 'Custom Date':
        if (customDate != null) {
          return orders.where((order) {
            final orderDate = DateTime.parse(order['created_at']).toLocal();
            return orderDate.year == customDate!.year &&
                orderDate.month == customDate!.month &&
                orderDate.day == customDate!.day;
          }).toList();
        }
        return orders;
      default:
        return orders;
    }
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.deepPurple.shade700,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.white,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              labelLarge: TextStyle(
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != customDate) {
      setState(() {
        customDate = picked;
        selectedFilter = 'Custom Date';
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Show a loading indicator until language is loaded
    if (!_isLanguageLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 75,
            collapsedHeight: 75,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.deepPurple.shade700,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: restaurant == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Row(
                          children: [
                            Hero(
                              tag: 'restaurant_avatar',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: isDarkMode
                                      ? const Color.fromARGB(255, 246, 246, 246)
                                      : Colors.white,
                                  backgroundImage: restaurant!.profile != null
                                      ? NetworkImage(
                                          ApiService.getImageUrl(
                                            restaurant!.profile!,
                                          ),
                                        )
                                      : null,
                                  child: restaurant!.profile == null
                                      ? Icon(
                                          Icons.restaurant,
                                          size: 28,
                                          color: Colors.deepPurple.shade700,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localization[_language]?.containsKey(
                                              'welcome_message',
                                            ) ==
                                            true
                                        ? localization[_language]!['welcome_message']!
                                              .replaceAll(
                                                '{restaurantName}',
                                                restaurant?.restaurantName ??
                                                    'Admin',
                                              )
                                        : 'Welcome, Admin',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: _language == 'Khmer'
                                          ? 'NotoSansKhmer'
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    localization[_language]?.containsKey(
                                              'dashboard_subtitle',
                                            ) ==
                                            true
                                        ? localization[_language]!['dashboard_subtitle']!
                                        : 'Dashboard Overview',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontFamily: _language == 'Khmer'
                                          ? 'NotoSansKhmer'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _loadRestaurantInfo();
                                  _loadData();
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? _buildLoadingState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeBanner(theme),
                            const SizedBox(height: 24),
                            _buildDateFilter(theme),
                            const SizedBox(height: 24),
                            _buildSummaryCards(theme),
                            const SizedBox(height: 32),
                            _buildTopItemsSection(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildShimmerBanner(),
          const SizedBox(height: 24),
          _buildShimmerCards(),
          const SizedBox(height: 32),
          _buildShimmerList(),
        ],
      ),
    );
  }

  Widget _buildShimmerBanner() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[300],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildShimmerCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(4, (index) {
        return Container(
          width: MediaQuery.of(context).size.width / 2 - 28,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildShimmerList() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade700.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDarkMode ? 0.03 : 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      localization[_language]?.containsKey('welcome_message') ==
                              true
                          ? localization[_language]!['welcome_message']!
                                .replaceAll(
                                  '{restaurantName}',
                                  restaurant?.restaurantName ?? 'Admin',
                                )
                          : 'Welcome, Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: _language == 'Khmer'
                            ? 'NotoSansKhmer'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TweenAnimationBuilder(
                      duration: const Duration(seconds: 2),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.4 * value),
                          child: const Text(
                            "👋",
                            style: TextStyle(fontSize: 20),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  localization[_language]?.containsKey(
                            'performance_overview',
                          ) ==
                          true
                      ? localization[_language]!['performance_overview']!
                      : "Here's your restaurant's performance overview",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final translatedFilterOptions = [
      localization[_language]?.containsKey('today') == true
          ? localization[_language]!['today']!
          : 'Today',
      localization[_language]?.containsKey('this_week') == true
          ? localization[_language]!['this_week']!
          : 'This Week',
      localization[_language]?.containsKey('this_month') == true
          ? localization[_language]!['this_month']!
          : 'This Month',
      localization[_language]?.containsKey('custom_date') == true
          ? localization[_language]!['custom_date']!
          : 'Custom Date',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              items: filterOptions.asMap().entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: filterOptions[entry.key],
                  child: Text(
                    translatedFilterOptions[entry.key],
                    style: TextStyle(
                      fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue == 'Custom Date') {
                  _selectCustomDate(context);
                } else {
                  setState(() {
                    selectedFilter = newValue!;
                    customDate = null;
                  });
                  _loadData();
                }
              },
              decoration: InputDecoration(
                labelText:
                    localization[_language]?.containsKey('filter_by_label') ==
                        true
                    ? localization[_language]!['filter_by_label']!
                    : 'Filter by',
                labelStyle: TextStyle(
                  color: const Color.fromARGB(255, 162, 122, 255),
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
              iconEnabledColor: isDarkMode
                  ? Colors.white
                  : Colors.deepPurple.shade700,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.deepPurple.shade700,
                fontWeight: FontWeight.w500,
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
          ),
          if (selectedFilter == 'Custom Date' && customDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Chip(
                  label: Text(
                    DateFormat('MMM d, yyyy').format(customDate!),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                    ),
                  ),
                  backgroundColor: Colors.deepPurple.shade700,
                  deleteIconColor: Colors.white,
                  onDeleted: () {
                    setState(() {
                      selectedFilter = 'Today';
                      customDate = null;
                    });
                    _loadData();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final cards = [
      {
        'title': localization[_language]?.containsKey('total_items') == true
            ? localization[_language]!['total_items']!
            : 'Total Items',
        'value': totalItems.toString(),
        'icon': Icons.restaurant_menu,
        'color': const Color.fromARGB(255, 151, 106, 255),
      },
      {
        'title':
            localization[_language]?.containsKey('total_categories') == true
            ? localization[_language]!['total_categories']!
            : 'Total Categories',
        'value': totalCategories.toString(),
        'icon': Icons.category,
        'color': const Color.fromARGB(255, 151, 106, 255),
      },
      {
        'title': localization[_language]?.containsKey('orders') == true
            ? localization[_language]!['orders']!.replaceAll(
                '{filter}',
                localization[_language]?.containsKey(
                          selectedFilter.toLowerCase(),
                        ) ==
                        true
                    ? localization[_language]![selectedFilter.toLowerCase()]!
                          .toLowerCase()
                    : selectedFilter.toLowerCase(),
              )
            : 'Orders ($selectedFilter)',
        'value': totalOrders.toString(),
        'icon': Icons.receipt_long,
        'color': const Color.fromARGB(255, 151, 106, 255),
      },
      {
        'title': localization[_language]?.containsKey('top_item') == true
            ? localization[_language]!['top_item']!
            : 'Top Item',
        'value': topItem.isNotEmpty
            ? topItem
            : (localization[_language]?.containsKey('no_data') == true
                  ? localization[_language]!['no_data']!
                  : 'No data'),
        'icon': Icons.star,
        'color': const Color.fromARGB(255, 151, 106, 255),
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;

        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 600 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: ModernSummaryCard(
                  title: card['title'] as String,
                  value: card['value'] as String,
                  icon: card['icon'] as IconData,
                  iconColor: card['color'] as Color,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  language: _language,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildTopItemsSection(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "🏆 ${localization[_language]?.containsKey('top_items_title') == true ? localization[_language]!['top_items_title']! : 'Top 5 Ordered Items'}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 131, 78, 255),
                fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 138, 88, 255).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                localization[_language]?.containsKey(
                          selectedFilter.toLowerCase(),
                        ) ==
                        true
                    ? localization[_language]![selectedFilter.toLowerCase()]!
                          .toLowerCase()
                    : selectedFilter.toLowerCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 133, 81, 255),
                  fontWeight: FontWeight.w600,
                  fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  localization[_language]?.containsKey('no_orders_message') ==
                          true
                      ? localization[_language]!['no_orders_message']!
                      : 'No orders found for selected period',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontFamily: _language == 'Khmer' ? 'NotoSansKhmer' : null,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: topItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 800 + (index * 100)),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(50 * (1 - value), 0),
                    child: Opacity(
                      opacity: value,
                      child: ModernTopItemTile(
                        name: item['name'],
                        count: item['count'],
                        image: item['image'],
                        itemData: item['item'],
                        categoryName: item['category'],
                        rank: index + 1,
                        language: _language,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }
}

class ModernSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? language;

  const ModernSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 56) / 2;

    return Container(
      width: cardWidth,
      height: 110,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? Colors.deepPurple.shade700).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.deepPurple.shade700).withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? Colors.deepPurple.shade700,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontFamily: language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor ?? Colors.deepPurple.shade700,
                fontFamily: language == 'Khmer' ? 'NotoSansKhmer' : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ModernTopItemTile extends StatelessWidget {
  final String name;
  final int count;
  final String? image;
  final item.Item? itemData;
  final String categoryName;
  final int rank;
  final String? language;

  const ModernTopItemTile({
    super.key,
    required this.name,
    required this.count,
    required this.categoryName,
    required this.rank,
    this.image,
    this.itemData,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
      Colors.deepPurple.shade700, // Default
      Colors.deepPurple.shade700, // Default
    ];

    // Localization map for ModernTopItemTile
    final Map<String, Map<String, String>> localization = {
      'English': {'orders_suffix': 'orders'},
      'Khmer': {'orders_suffix': 'ការកម្ម៉ង់'},
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (itemData != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ItemDetailBottomSheet(item: itemData!),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: image != null && image!.isNotEmpty
                            ? Image.network(
                                ApiService.getImageUrl(image!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.fastfood,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                              )
                            : Icon(
                                Icons.fastfood,
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rankColors[rank - 1],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: language == 'Khmer'
                                  ? 'NotoSansKhmer'
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF2D2D2D),
                          fontFamily: language == 'Khmer'
                              ? 'NotoSansKhmer'
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            126,
                            74,
                            248,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color.fromARGB(255, 126, 71, 255),
                            fontWeight: FontWeight.w500,
                            fontFamily: language == 'Khmer'
                                ? 'NotoSansKhmer'
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 119, 65, 246),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        fontFamily: language == 'Khmer'
                            ? 'NotoSansKhmer'
                            : null,
                      ),
                    ),
                    Text(
                      localization[language ?? 'English']?.containsKey(
                                'orders_suffix',
                              ) ==
                              true
                          ? localization[language ??
                                'English']!['orders_suffix']!
                          : 'orders',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 129, 75, 255),
                        fontSize: 12,
                        fontFamily: language == 'Khmer'
                            ? 'NotoSansKhmer'
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
