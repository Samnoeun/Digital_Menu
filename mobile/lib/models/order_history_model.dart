class OrderHistory {
  final int id;
  final int tableNumber;
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
}

class OrderItemHistory {
  final int itemId;
  final int quantity;
  final String specialNote;
  final String itemName;
  // final String itemCategory;

  OrderItemHistory({
    required this.itemId,
    required this.quantity,
    required this.specialNote,
    required this.itemName,
    // required this.itemCategory,
  });
}