// models/order_model.dart
import 'package:intl/intl.dart';

class Order {
  final dynamic id;
  final int tableNumber;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: json['id'] ?? 0,
        tableNumber: _parseTableNumber(json),
        status: json['status']?.toString().toLowerCase() ?? 'pending',
        createdAt: _parseDateTime(json['created_at']),
        items: _parseOrderItems(json['items']),
      );
    } catch (e) {
      print('Error parsing order: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  static int _parseTableNumber(Map<String, dynamic> json) {
    final tableNumber = json['table_number'] ?? json['tableNumber'];
    if (tableNumber is int) return tableNumber;
    if (tableNumber is String) return int.tryParse(tableNumber) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  static List<OrderItem> _parseOrderItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) return [];
    
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        return OrderItem.fromJson(item);
      }
      return OrderItem.empty();
    }).toList();
  }
}

class OrderItem {
  final dynamic id;
  final String name;
  final int quantity;
  final double price;
  final String specialNote;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.specialNote,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? json['item_id'],
      name: json['name']?.toString() ?? 'Unknown Item',
      quantity: _parseInt(json['quantity']),
      price: _parseDouble(json['price']),
      specialNote: json['special_note']?.toString() ?? '',
    );
  }

  factory OrderItem.empty() {
    return OrderItem(
      id: 0,
      name: 'Unknown',
      quantity: 0,
      price: 0.0,
      specialNote: '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}