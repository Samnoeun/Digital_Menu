import 'package:flutter/material.dart';
import 'category_list_screen.dart';

// This screen now simply redirects to the category list screen.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Immediately push the CategoryListScreen and remove this screen from the stack
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CategoryListScreen()),
      );
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
