class Item {
  final int id;
  final int categoryId;
  final String name;
  final String? imagePath;
  final String? description;
  final double price;
  final String? categoryName; // for display

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    this.imagePath,
    this.description,
    required this.price,
    this.categoryName,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      imagePath: json['image_path'],
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      categoryName: json['category']?['name'], // if you eager load category
    );
  }
}