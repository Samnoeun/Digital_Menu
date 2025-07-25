class Category {
  final int id;
  final String name;
  final List<Item> items;

  Category({
    required this.id,
    required this.name,
    required this.items,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => Item.fromJson(itemJson))
          .toList(),
    );
  }
}

class Item {
  final int id;
  final String name;
  final String imagePath;
  final int categoryId;

  Item({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.categoryId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      imagePath: json['image_path'],
      categoryId: json['category_id'],
    );
  }
}
