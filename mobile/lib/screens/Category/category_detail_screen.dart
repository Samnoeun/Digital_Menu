import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category_model.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final XFile? pickedImage = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Pick from Gallery'),
            onTap: () async {
              final file = await _picker.pickImage(source: ImageSource.gallery);
              Navigator.pop(context, file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Photo'),
            onTap: () async {
              final file = await _picker.pickImage(source: ImageSource.camera);
              Navigator.pop(context, file);
            },
          ),
        ],
      ),
    );

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _showEditDialog(BuildContext context, dynamic item) {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description ?? '');
    final priceController = TextEditingController(text: item.price.toString());
    final formKey = GlobalKey<FormState>();
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : item.imagePath != null && item.imagePath!.isNotEmpty
                            ? Image.network(
                                item.imagePath!.startsWith('http')
                                    ? item.imagePath!
                                    : 'http://192.168.108.122:8000${item.imagePath}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                              )
                            : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a price' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  item.name = nameController.text;
                  item.description = descriptionController.text;
                  item.price = double.tryParse(priceController.text) ?? 0.0;

                  // ✅ Save the picked image to item
                  if (_selectedImage != null) {
                    final fileName = _selectedImage!.path.split('/').last;
                    item.imagePath = 'http://192.168.108.122:8000/uploads/$fileName';
                  }
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, dynamic item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => widget.category.items.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, dynamic item) {
    final price = double.tryParse(item.price.toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imagePath != null && item.imagePath!.isNotEmpty
              ? Image.network(
                  item.imagePath!.startsWith('http')
                      ? item.imagePath!
                      : 'http://192.168.108.122:8000${item.imagePath}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _errorImage(),
                )
              : _placeholderImage(),
        ),
        title: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.description!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.deepPurple, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') _showEditDialog(context, item);
            if (value == 'delete') _confirmDelete(context, index, item);
          },
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete')],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _errorImage() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No items in this category', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            'Add items to "${widget.category.name}" via the Items screen.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.category.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF3E5F5),
        elevation: 0,
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, index) => _buildItemCard(index, items[index]),
            ),
    );
  }
}
