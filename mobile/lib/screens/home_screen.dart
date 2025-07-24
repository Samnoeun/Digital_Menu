import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟣 Banner section
            Container(
              width: double.infinity,
              height: 160,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage("assets/home/banner.png"), // ✅ FIXED
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(
                    0.4,
                  ), // semi-transparent overlay
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
                      "Here’s an overview of today’s activity",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 📊 Summary Cards
            const Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SummaryCard(
                  title: "Total Menu Items",
                  value: "34",
                  icon: Icons.restaurant_menu,
                ),
                SummaryCard(
                  title: "Total Categories",
                  value: "6",
                  icon: Icons.category,
                ),
                SummaryCard(
                  title: "Orders Today",
                  value: "12",
                  icon: Icons.receipt_long,
                ),
                SummaryCard(
                  title: "Top Item",
                  value: "Milk Tea",
                  icon: Icons.star,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 🏆 Top 5 Items
            const Text(
              "Top 5 Items",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),

            const Column(
              children: [
                TopItemTile(name: "Milk Tea", count: 42),
                TopItemTile(name: "Burger", count: 30),
                TopItemTile(name: "Fried Rice", count: 27),
                TopItemTile(name: "Noodle Soup", count: 25),
                TopItemTile(name: "Iced Coffee", count: 23),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 📦 SummaryCard Widget
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

// 🏅 TopItemTile Widget
class TopItemTile extends StatelessWidget {
  final String name;
  final int count;

  const TopItemTile({super.key, required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.fastfood, color: Colors.deepPurple),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          "$count orders",
          style: const TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
