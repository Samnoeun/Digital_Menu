import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../models/category_model.dart';
import '../models/setting_model.dart';
import '../services/api_services.dart';

class MenuPreviewScreen extends StatefulWidget {
  const MenuPreviewScreen({super.key});

  @override
  State<MenuPreviewScreen> createState() => _MenuPreviewScreenState();
}

class _MenuPreviewScreenState extends State<MenuPreviewScreen> {
  SettingModel? setting;
  List<CategoryModel> categories = [];
  Map<int, List<ItemModel>> itemsByCategory = {};
  String searchQuery = '';
  int? selectedCategoryId;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchedSetting = await ApiService.fetchSettings();
      final fetchedCategories = await ApiService.fetchCategories();

      for (var category in fetchedCategories) {
        final items = await ApiService.fetchItemsByCategory(category.id);
        itemsByCategory[category.id] = items;
      }

      setState(() {
        setting = fetchedSetting;
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  List<ItemModel> _filteredItems(int categoryId) {
    final items = itemsByCategory[categoryId] ?? [];
    return items
        .where((item) => item.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (setting?.logo != null)
              CircleAvatar(
                backgroundImage: NetworkImage(setting!.logo ?? ''),
                radius: 18,
              ),
            const SizedBox(width: 8),
            Text(setting?.restaurantName ?? 'Loading...'),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    // 🛒 Show cart screen
                  },
                ),
                // TODO: Show cart item count badge
              ],
            )
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 🔍 Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🧩 Filter by Category
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategoryId == category.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                selectedCategoryId =
                                    isSelected ? null : category.id;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🍔 Items by Category
                  Expanded(
                    child: ListView(
                      children: categories
                          .where((cat) => selectedCategoryId == null || cat.id == selectedCategoryId)
                          .map((cat) {
                        final items = _filteredItems(cat.id);
                        if (items.isEmpty) return const SizedBox();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...items.map((item) => Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: item.imagePath != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              item.imagePath!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.fastfood),
                                    title: Text(item.name),
                                    subtitle: Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        // 🛒 Add to cart logic
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
