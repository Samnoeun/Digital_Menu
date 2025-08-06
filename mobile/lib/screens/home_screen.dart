import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String? restaurantName;
  Restaurant? restaurant;
  String? restaurantProfile;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _loadRestaurantInfo();
    _loadData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.deepPurple,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    _animationController.reset();

    try {
      final results = await Future.wait([
        ApiService.getItems(),
        ApiService.getCategories(),
        ApiService.getOrders(),
      ]);
      final items = results[0] as List<item.Item>;
      final categories = results[1] as List<category.Category>;
      final orders = results[2] as List<dynamic>;

      final categoryMap = {for (var cat in categories) cat.id: cat};
      final filteredOrders = _filterOrdersByDate(orders);

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

      setState(() {
        totalItems = items.length;
        totalCategories = categories.length;
        totalOrders = filteredOrders.length;
        topItem = sortedItems.isNotEmpty ? sortedItems.first.key : "No orders";
        topItems = sortedItems.take(5).map((e) {
          final item = itemData[e.key]!;
          return {
            'name': item.name,
            'count': e.value,
            'image': item.imagePath,
            'item': item,
            'category': item.category?.name ?? 'No category',
          };
        }).toList();
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        topItem = "Error loading data";
        topItems = [];
        isLoading = false;
      });
      debugPrint('Error loading home data: $e');
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
              primary: Colors.deepPurple,
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 75,
            collapsedHeight: 75, // Add this to maintain consistent height
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.deepPurple,
            flexibleSpace: Container( // Remove FlexibleSpaceBar and use Container directly
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple,
                    Color(0xFF7B1FA2),
                    Color(0xFF4A148C),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: restaurant == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
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
                                  backgroundColor: Colors.white,
                                  backgroundImage: restaurant!.profile != null
                                      ? NetworkImage(ApiService.getImageUrl(restaurant!.profile!))
                                      : null,
                                  child: restaurant!.profile == null
                                      ? const Icon(Icons.restaurant, size: 28, color: Colors.deepPurple)
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
                                    restaurant!.restaurantName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Dashboard Overview',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
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
                                icon: const Icon(Icons.refresh, color: Colors.white),
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
                            _buildWelcomeBanner(),
                            const SizedBox(height: 24),
                            _buildDateFilter(),
                            const SizedBox(height: 24),
                            _buildSummaryCards(),
                            const SizedBox(height: 32),
                            _buildTopItemsSection(),
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
        color: Colors.grey[300],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
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
            color: Colors.grey[300],
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
            color: Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple,
            Color(0xFF7B1FA2),
            Color(0xFF4A148C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.1),
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
                color: Colors.white.withOpacity(0.05),
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
                      "Welcome, ${restaurant?.restaurantName ?? 'Admin'}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                const Text(
                  "Here's your restaurant's performance overview",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
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
              items: filterOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
                labelText: 'Filter by',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: Colors.deepPurple,
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

  Widget _buildSummaryCards() {
    final cards = [
      {
        'title': 'Total Items',
        'value': totalItems.toString(),
        'icon': Icons.restaurant_menu,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Total Categories',
        'value': totalCategories.toString(),
        'icon': Icons.category,
        'color': const Color(0xFF7B1FA2),
      },
      {
        'title': 'Orders (${selectedFilter.toLowerCase()})',
        'value': totalOrders.toString(),
        'icon': Icons.receipt_long,
        'color': const Color(0xFF4A148C),
      },
      {
        'title': 'Top Item',
        'value': topItem.isNotEmpty ? topItem : "No data",
        'icon': Icons.star,
        'color': const Color(0xFF6A1B9A),
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
                  backgroundColor: Colors.white,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildTopItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "🏆 Top 5 Ordered Items",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                selectedFilter.toLowerCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w600,
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
              color: Colors.white,
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
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  "No orders found for selected period",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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

  const ModernSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 56) / 2;
    
    return Container(
      width: cardWidth,
      height: 110,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? Colors.deepPurple).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding( // Remove Stack and Positioned circle, use Padding directly
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.deepPurple).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? Colors.deepPurple),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
                color: iconColor ?? Colors.deepPurple,
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

  const ModernTopItemTile({
    super.key,
    required this.name,
    required this.count,
    required this.categoryName,
    required this.rank,
    this.image,
    this.itemData,
  });

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
      Colors.deepPurple, // Default
      Colors.deepPurple, // Default
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: image != null && image!.isNotEmpty
                            ? Image.network(
                                ApiService.getImageUrl(image!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.fastfood, color: Colors.grey[400]),
                              )
                            : Icon(Icons.fastfood, color: Colors.grey[400]),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D2D2D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w500,
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
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      'orders',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 12,
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
