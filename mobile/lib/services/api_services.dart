import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/category_model.dart' as category;
import '../models/item_model.dart' as item;
import '../models/setting_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.108.122:8000/api';

  static String? _token;

  static Future<UserModel?> register(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Accept': 'application/json'},
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        return UserModel.fromJson(data['user']);
      } else {
        throw data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        return UserModel.fromJson(data['user']);
      } else {
        throw data['message'] ?? 'Login failed';
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        _token = null;
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<UserModel?> getUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return UserModel.fromJson(data);
      } else {
        throw Exception('Unauthorized');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Category service
  static Future<List<category.Category>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['data'] == null) {
        return []; // Return empty list if data is null
      }
      final List data = jsonData['data'];
      return data.map((json) => category.Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
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
    final response = await http.delete(Uri.parse('$baseUrl/categories/$id'));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }

  // Itemservice
  static Future<List<item.Item>> getItems() async {
    final response = await http.get(Uri.parse('$baseUrl/items'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return (jsonData['data'] as List)
          .map((itemJson) => item.Item.fromJson(itemJson))
          .toList();
    } else {
      throw Exception('Failed to load items');
    }
  }

  static Future<void> createItem({
    required String name,
    String? description,
    required double price,
    int? categoryId,
    String? imagePath,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/items'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'description': description,
        'price': price,
        if (categoryId != null) 'category_id': categoryId,
        if (imagePath != null) 'image_path': imagePath,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create item');
    }
  }

  static Future<void> updateItem(
    int id, {
    required String name,
    String? description,
    required double price,
    int? categoryId,
    String? imagePath,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/items/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'description': description,
        'price': price,
        if (categoryId != null) 'category_id': categoryId,
        if (imagePath != null) 'image_path': imagePath,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }

  static Future<void> deleteItem(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/items/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }

  // Settings service
  // Get a specific setting by ID
  static Future<Map<String, dynamic>?> getSetting(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/$id'),
      headers: {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data'] ?? jsonData;
    } else {
      throw Exception('Failed to load setting');
    }
  }

  // Create setting with multipart/form-data (for logo upload)
  static Future<void> createSetting({
    required String restaurantName,
    required String address,
    File? logoFile,
    String? currency,
    String? language,
    bool? darkMode,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/settings'));

    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });

    request.fields['restaurant_name'] = restaurantName;
    request.fields['address'] = address;

    if (currency != null) request.fields['currency'] = currency;
    if (language != null) request.fields['language'] = language;
    if (darkMode != null) request.fields['dark_mode'] = darkMode ? '1' : '0';

    if (logoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('logo', logoFile.path),
      );
    }

    final response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to create setting: $respStr');
    }
  }

  // Update setting with multipart/form-data (logo optional)
  static Future<void> updateSetting({
    required int id,
    required String restaurantName,
    required String address,
    File? logoFile,
    String? currency,
    String? language,
    bool? darkMode,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/settings/$id?_method=PUT'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });

    request.fields['restaurant_name'] = restaurantName;
    request.fields['address'] = address;

    if (currency != null) request.fields['currency'] = currency;
    if (language != null) request.fields['language'] = language;
    if (darkMode != null) request.fields['dark_mode'] = darkMode ? '1' : '0';

    if (logoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('logo', logoFile.path),
      );
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to update setting: $respStr');
    }
  }

  // Delete setting by ID
  static Future<void> deleteSetting(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/settings/$id'),
      headers: {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete setting');
    }
  }
}
