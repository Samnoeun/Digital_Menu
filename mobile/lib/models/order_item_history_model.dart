class OrderItemHistory {
  final int itemId;
  final int quantity;
  final String specialNote;
  final String itemName; // Add this field
  final String itemCategory; // Add this field

  OrderItemHistory({
    required this.itemId,
    required this.quantity,
    required this.specialNote,
    required this.itemName, // Add to constructor
    required this.itemCategory, // Add to constructor
  });

  factory OrderItemHistory.fromJson(Map<String, dynamic> json) {
    return OrderItemHistory(
      itemId: json['item_id'],
      quantity: json['quantity'],
      specialNote: json['special_note'] ?? '',
      itemName: json['item']?['name'] ?? 'Unknown Item', // Extract from nested item object
      itemCategory: json['item']?['category']?['name'] ?? 'No category', // Extract category name
    );
  }
}