import '../models/menu_item.dart';
class OrderItemHistory {
  final int itemId;
  final int quantity;
  final String? specialNote;
  final MenuItem item;

  OrderItemHistory({
    required this.itemId,
    required this.quantity,
    this.specialNote,
    required this.item,
  });

  factory OrderItemHistory.fromJson(Map<String, dynamic> json) {
    return OrderItemHistory(
      itemId: json['item_id'],
      quantity: json['quantity'],
      specialNote: json['special_note'],
      item: MenuItem.fromJson(json['item']), // Make sure MenuItem.fromJson exists
    );
  }
}
