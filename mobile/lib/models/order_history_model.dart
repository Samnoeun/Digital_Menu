class OrderHistory {
  final int id;
  final int tableNumber;   // ✅ change to int
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
      id: json['id'],
      tableNumber: json['table_number'] is String
          ? int.tryParse(json['table_number']) ?? 0
          : json['table_number'],   // ✅ handles both int and string
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      orderItems: (json['order_items'] as List<dynamic>)
          .map((item) => OrderItemHistory.fromJson(item))
          .toList(),
    );
  }
}

class OrderItemHistory {
  final int itemId;
  final int quantity;
  final String specialNote;

  OrderItemHistory({
    required this.itemId,
    required this.quantity,
    required this.specialNote,
  });

  factory OrderItemHistory.fromJson(Map<String, dynamic> json) {
    return OrderItemHistory(
      itemId: json['item_id'],
      quantity: json['quantity'],
      specialNote: json['special_note'] ?? '',
    );
  }
}
