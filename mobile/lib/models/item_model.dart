import 'category_model.dart';

class Item {
  final int id;
  final int categoryId;
  final String name;
  final String? imagePath; // <- add this
  final String? description;
  final double price;
  final Category? category;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    this.imagePath,
    this.description,
    required this.price,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      imagePath: json['image_path'], // <- match backend key
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
    );
  }

  Item copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? imagePath,
    String? description,
    double? price,
    Category? category,
  }) {
    return Item(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category_id': categoryId,
      'image_path': imagePath, // <- match backend key
    };
  }
}
