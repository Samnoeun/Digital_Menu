// lib/models/report_item_model.dart

class ReportItem {
  final int itemId;
  final String itemName;
  final String categoryName;
  final int totalSold;

  ReportItem({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.totalSold,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      itemId: json['item_id'] ?? 0,
      itemName: json['item_name'] ?? 'Unknown',
      categoryName: json['category_name'] ?? 'No Category',
      totalSold: json['total_sold'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'category_name': categoryName,
      'total_sold': totalSold,
    };
  }
}
