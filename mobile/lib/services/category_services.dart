import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';

class CategoryService {
  static const String baseUrl = 'http://192.168.108.122:8000/api';

  static Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'];
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  static Future<void> createCategory(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create category');
    }
  }

  static Future<void> updateCategory(int id, String name) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update category');
    }
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }
}
