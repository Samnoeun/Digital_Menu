import 'package:flutter/material.dart';
import 'add_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<CategoryItem> categories = [
    CategoryItem(id: 1, name: 'Main Dishes', icon: Icons.fastfood),
    CategoryItem(id: 2, name: 'Beverages', icon: Icons.local_drink),
    CategoryItem(id: 3, name: 'Desserts', icon: Icons.cake),
  ];

  void _addCategory(CategoryItem category) {
    setState(() {
      categories.add(category);
    });
  }

  void _editCategory(int index, CategoryItem updatedCategory) {
    setState(() {
      categories[index] = updatedCategory;
    });
  }

  void _deleteCategory(int index) {
    setState(() {
      categories.removeAt(index);
    });
  }

  void _showCategoryOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.blue),
                title: const Text('View'),
                onTap: () {
                  Navigator.pop(context);
                  _viewCategory(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editCategoryDialog(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewCategory(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Category Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(categories[index].icon, size: 40, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  Text(
                    categories[index].name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('ID: ${categories[index].id}'),
              Text('Created: ${DateTime.now().toString().split(' ')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _editCategoryDialog(int index) {
    final TextEditingController nameController = TextEditingController(text: categories[index].name);
    IconData selectedIcon = categories[index].icon;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Icon:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Icons.fastfood,
                      Icons.local_drink,
                      Icons.cake,
                      Icons.local_pizza,
                      Icons.coffee,
                      Icons.icecream,
                    ].map((icon) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedIcon == icon ? Colors.deepPurple : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: selectedIcon == icon ? Colors.deepPurple : Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _editCategory(
                        index,
                        CategoryItem(
                          id: categories[index].id,
                          name: nameController.text,
                          icon: selectedIcon,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${categories[index].name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _deleteCategory(index);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category deleted successfully')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        // Remove back arrow for main page
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
          );
          if (result != null) {
            _addCategory(result);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: categories.isEmpty
          ? const Center(
              child: Text(
                'No categories yet.\nTap + to add a category.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      categories[index].icon,
                      color: Colors.deepPurple,
                      size: 30,
                    ),
                    title: Text(
                      categories[index].name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showCategoryOptions(context, index),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CategoryItem {
  final int id;
  final String name;
  final IconData icon;

  CategoryItem({
    required this.id,
    required this.name,
    required this.icon,
  });
}
