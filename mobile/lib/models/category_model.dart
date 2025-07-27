// class Category {
//   final int id;
//   final String name;
//   final List<Item> items;

//   Category({
//     required this.id,
//     required this.name,
//     required this.items,
//   });

//   factory Category.fromJson(Map<String, dynamic> json) {
//     return Category(
//       id: json['id'],
//       name: json['name'],
//       items: (json['items'] as List<dynamic>)
//           .map((itemJson) => Item.fromJson(itemJson))
//           .toList(),
//     );
//   }
// }

// class Item {
//   final int id;
//   final String name;
//   final String imagePath;
//   final int categoryId;

//   Item({
//     required this.id,
//     required this.name,
//     required this.imagePath,
//     required this.categoryId,
//   });

//   factory Item.fromJson(Map<String, dynamic> json) {
//     return Item(
//       id: json['id'],
//       name: json['name'],
//       imagePath: json['image_path'],
//       categoryId: json['category_id'],
//     );
//   }
// }


class Category {
  final int id;
  final String name;
  final List<Item> items;

  Category({required this.id, required this.name, required this.items});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0, // Default to 0 if null
      name: json['name'] as String? ?? 'Unnamed', // Default to 'Unnamed' if null
      items: (json['items'] as List<dynamic>?)?.map((itemJson) => Item.fromJson(itemJson)).toList() ?? [],
    );
  }
}

class Item {
  final int id;
  final int categoryId;
  final String name;
  final String imagePath;
  final String description;
  final String price;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.price,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unnamed Item',
      imagePath: json['image_path'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as String? ?? '0.00',
    );
  }
}
