class ItemModel {
  final int id;
  final String name;
  final String? imagePath;
  final String? description;
  final double price;
  final int categoryId;

  ItemModel({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.price,
    required this.categoryId,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      imagePath: json['image_path'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      categoryId: json['category_id'],
    );
  }
}
