import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../models/report_item_model.dart';

class ReportOrderScreen extends StatefulWidget {
  const ReportOrderScreen({super.key});

  @override
  State<ReportOrderScreen> createState() => _ReportOrderScreenState();
}

class _ReportOrderScreenState extends State<ReportOrderScreen> {
  String filter = 'today';
  DateTimeRange? customRange;
  bool loading = true;
  List<ReportItem> items = [];

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() => loading = true);

    try {
      String url = 'http://your-api.com/api/reports/sales?filter=$filter';

      if (filter == 'custom' && customRange != null) {
        final start = DateFormat('yyyy-MM-dd').format(customRange!.start);
        final end = DateFormat('yyyy-MM-dd').format(customRange!.end);
        url += '&start_date=$start&end_date=$end';
      }

      final response = await Dio().get(
        url,
        options: Options(headers: {'Authorization': 'Bearer YOUR_TOKEN_HERE'}),
      );

      final data = response.data['items'] as List;
      setState(() {
        items = data.map((e) => ReportItem.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint('Error fetching report: $e');
      setState(() => items = []);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        customRange = picked;
        filter = 'custom';
      });
      fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSold = items.fold<int>(0, (sum, e) => sum + e.totalSold);

    return Scaffold(
    appBar: AppBar(
  automaticallyImplyLeading: false, // disable default back button
  backgroundColor: Colors.deepPurple.shade700,
  elevation: 0,
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.deepPurple.shade700,
          Colors.deepPurple.shade500,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
  title: Row(
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      const SizedBox(width: 4),
      const Text(
        "ReportOrder",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),



      body: Column(
        children: [
          // 🔹 Filter Chips
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("Today"),
                  selected: filter == 'today',
                  onSelected: (_) {
                    setState(() => filter = 'today');
                    fetchReport();
                  },
                ),
                FilterChip(
                  label: const Text("This Month"),
                  selected: filter == 'this_month',
                  onSelected: (_) {
                    setState(() => filter = 'this_month');
                    fetchReport();
                  },
                ),
                FilterChip(
                  label: const Text("Custom Range"),
                  selected: filter == 'custom',
                  onSelected: (_) => pickCustomRange(),
                ),
              ],
            ),
          ),

          // 🔹 Summary Cards
          if (!loading && items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _SummaryCard(
                    title: "Items",
                    value: "${items.length}",
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    title: "Total Sold",
                    value: "$totalSold",
                    color: Colors.green,
                  ),
                ],
              ),
            ),

          // 🔹 Loading / Empty / Data
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? const Center(child: Text("No data found 📭"))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo.shade100,
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.indigo,
                            ),
                          ),
                          title: Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Category: ${item.categoryName}"),
                          trailing: Text(
                            "Sold: ${item.totalSold}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
