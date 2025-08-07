import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/api_services.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddCategoryScreen({Key? key, this.category}) : super(key: key);

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      if (widget.category == null) {
        // ✅ CREATE new category
        await ApiService.createCategory(_nameController.text);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Category added successfully')));
      } else {
        // ✅ UPDATE existing category
        await ApiService.updateCategory(
          widget.category!.id,
          _nameController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category updated successfully')),
        );
      }

      Navigator.pop(context, true); // Signal success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          action: e.toString().contains('restaurant')
              ? SnackBarAction(
                  label: 'Create Restaurant',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/create-restaurant'),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF3E5F5),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left:2, right: 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Color(0xFF6A1B9A),
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 0),
              Text(
                widget.category == null ? 'Add Category' : 'Edit Category',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.category == null
                              ? 'Add Category'
                              : 'Update Category',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
