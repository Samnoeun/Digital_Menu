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
    var itemsJson = json['items'] as List<dynamic>? ?? [];
    List<Item> itemsList = itemsJson.map((e) => Item.fromJson(e)).toList();

    return Category(
      id: json['id'],
      name: json['name'],
      items: itemsList,
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
