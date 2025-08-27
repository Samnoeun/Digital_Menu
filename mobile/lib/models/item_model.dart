import 'category_model.dart';

class Item {
  final int id;
  final int categoryId;
  final String name;
  final String? imagePath;
  final String? description;
  final double price;
  final Category? category;
  final String? imageUrl;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    this.imagePath,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      imagePath: json['image_path'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      imageUrl: json['image_url'],
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
}