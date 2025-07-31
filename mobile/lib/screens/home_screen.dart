import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../models/item_model.dart' as item;
import '../models/category_model.dart' as category;
import '../models/restaurant_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  final List<String> filterOptions = [
    'Today',
    'This Week',
    'This Month',
    'Custom Date',
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurantInfo();
    _loadData();
  }

  Future<void> _loadRestaurantInfo() async {
    try {
      final fetchedRestaurant = await ApiService.getRestaurant(1);
      setState(() {
        restaurant = fetchedRestaurant;
      });
    } catch (e) {
      debugPrint('Error loading restaurant info: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getItems(),
        ApiService.getCategories(),
        ApiService.getOrders(),
      ]);

      final items = results[0] as List<item.Item>;
      final categories = results[1] as List<category.Category>;
      final orders = results[2] as List<dynamic>;

      final filteredOrders = _filterOrdersByDate(orders);

      final itemMap = {for (var item in items) item.id.toString(): item};

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
        topItems = sortedItems
            .take(5)
            .map(
              (e) => {
                'name': e.key,
                'count': e.value,
                'image': itemData[e.key]?.imagePath,
                'item': itemData[e.key],
              },
            )
            .toList();
        isLoading = false;
      });
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
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (restaurant?.profile != null && restaurant!.profile!.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(
                  ApiService.getImageUrl(restaurant!.profile!),
                ),
                radius: 18,
              ),
            const SizedBox(width: 10),
            Text(
              restaurant?.restaurantName ?? 'Home',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),

        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner
                  Container(
                    width: double.infinity,
                    height: 160,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/home/banner.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withOpacity(0.4),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.centerLeft,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome, Admin 👋",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Here's an overview of today's activity",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Date Filter
                  Row(
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (selectedFilter == 'Custom Date' && customDate != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Chip(
                            label: Text(
                              DateFormat('MMM d, yyyy').format(customDate!),
                            ),
                            onDeleted: () {
                              setState(() {
                                selectedFilter = 'Today';
                                customDate = null;
                              });
                              _loadData();
                            },
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Summary Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SummaryCard(
                        title: "Total Menu Items",
                        value: totalItems.toString(),
                        icon: Icons.restaurant_menu,
                      ),
                      SummaryCard(
                        title: "Total Categories",
                        value: totalCategories.toString(),
                        icon: Icons.category,
                      ),
                      SummaryCard(
                        title: "Orders (${selectedFilter.toLowerCase()})",
                        value: totalOrders.toString(),
                        icon: Icons.receipt_long,
                      ),
                      SummaryCard(
                        title: "Top Item",
                        value: topItem.isNotEmpty ? topItem : "No data",
                        icon: Icons.star,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Top Items List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Top 5 Ordered Items",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        selectedFilter.toLowerCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (topItems.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No orders found for selected period"),
                      ),
                    )
                  else
                    Column(
                      children: topItems
                          .map(
                            (item) => TopItemTile(
                              name: item['name'],
                              count: item['count'],
                              image: item['image'],
                              itemData: item['item'],
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: Colors.deepPurple),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopItemTile extends StatelessWidget {
  final String name;
  final int count;
  final String? image;
  final item.Item? itemData;

  const TopItemTile({
    super.key,
    required this.name,
    required this.count,
    this.image,
    this.itemData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: image != null && image!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiService.getImageUrl(image),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.fastfood, color: Colors.deepPurple),
                ),
              )
            : const Icon(Icons.fastfood, color: Colors.deepPurple),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          "$count orders",
          style: const TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.deepPurple),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
