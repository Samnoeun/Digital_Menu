// In your OrderHistory model
class OrderHistory {
  final int id;
  final String tableNumber;
  final String status;
  final DateTime createdAt;
  final List<OrderItemHistory> orderItems;

  OrderHistory({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.createdAt,
    required this.orderItems,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      tableNumber: json['table_number']?.toString() ?? 'Unknown',
      status: json['status']?.toString() ?? 'completed',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      orderItems: (json['order_items'] as List<dynamic>?)
          ?.map((item) => OrderItemHistory.fromJson(item))
          .toList() ?? [],
    );
  }
}

// In your OrderItemHistory model
class OrderItemHistory {
  final int itemId;
  final int quantity;
  final String specialNote;
  final String itemName;
  final String categoryName;

  OrderItemHistory({
    required this.itemId,
    required this.quantity,
    required this.specialNote,
    required this.itemName,
    required this.categoryName,
  });

  factory OrderItemHistory.fromJson(Map<String, dynamic> json) {
    return OrderItemHistory(
      itemId: json['item_id'] is int ? json['item_id'] : int.parse(json['item_id'].toString()),
      quantity: json['quantity'] is int ? json['quantity'] : int.parse(json['quantity'].toString()),
      specialNote: json['special_note']?.toString() ?? '',
      itemName: json['item'] != null 
          ? (json['item']['name']?.toString() ?? 'Unknown Item')
          : 'Unknown Item',
      categoryName: json['item'] != null && json['item']['category'] != null
          ? (json['item']['category']?.toString() ?? 'No category')
          : 'No category',
    );
  }
}