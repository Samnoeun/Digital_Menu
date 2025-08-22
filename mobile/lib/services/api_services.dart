import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/category_model.dart' as category;
import '../models/item_model.dart' as item;
import '../models/restaurant_model.dart';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../models/order_history_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.108.177:8000/api';

  static String? _token;

  // Get stored auth token from SharedPreferences
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  // Save auth token to SharedPreferences and _token variable
  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  // Clear token on logout
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // User Authentication
  static Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'] ?? data['data']['token'];
        if (token != null) await saveAuthToken(token);
        return UserModel.fromJson(data['user'] ?? data['data']['user']);
      } else {
        throw data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      throw 'Registration failed: ${e.toString()}';
    }
  }

  // User Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        // Save the token immediately
        final token = data['token'] as String;
        await saveLoginData(token, email);

        return {'user': UserModel.fromJson(data['user']), 'token': token};
      } else {
        throw data['message'] ?? 'Login failed';
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  // User Logout
  static Future<void> logout() async {
    try {
      final token = await getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await clearAuthToken();
      } else {
        throw Exception('Logout failed');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // User Services
  static Future<UserModel?> getUser() async {
    try {
      final token = await getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception('Unauthorized');
      }
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  // Category Services
  static Future<List<category.Category>> getCategories() async {
    final token = await getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['data'] == null) return [];
      return (jsonData['data'] as List)
          .map((json) => category.Category.fromJson(json))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Please login again');
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }

  static Future<void> createCategory(String name) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 422) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Validation failed');
    } else if (response.statusCode != 201) {
      throw Exception('Failed to create category: ${response.body}');
    }
  }

  static Future<void> updateCategory(int id, String name) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to update category: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<void> deleteCategory(int id) async {
    final token = await getAuthToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // Item Services
  static Future<List<item.Item>> getItems() async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Please login first');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/items'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return (jsonData['data'] as List)
          .map((itemJson) => item.Item.fromJson(itemJson))
          .toList();
    } else if (response.statusCode == 401) {
      await clearAuthToken();
      throw Exception('Session expired. Please login again');
    } else {
      throw Exception('Failed to load items: ${response.body}');
    }
  }

  static Future<void> createItem({
    required String name,
    String? description,
    required double price,
    required int categoryId,
    File? imageFile,
    Uint8List? webImageBytes,
    String? webImageName,
  }) async {
    final token = await getAuthToken();
    if (token == null) {
      throw Exception('Please login first');
    }

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/items'));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['name'] = name;
    request.fields['description'] = description ?? '';
    request.fields['price'] = price.toString();
    request.fields['category_id'] = categoryId.toString();

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    } else if (kIsWeb && webImageBytes != null && webImageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          webImageBytes,
          filename: webImageName,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 201) {
      throw Exception('Failed to create item: $responseBody');
    }
  }

  static Future<void> updateItem(
    int id, {
    required String name,
    String? description,
    required double price,
    required int categoryId,
    File? imageFile,
    Uint8List? webImageBytes,
    String? webImageName,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final uri = Uri.parse('$baseUrl/items/$id?_method=PUT');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['name'] = name
      ..fields['description'] = description ?? ''
      ..fields['price'] = price.toString()
      ..fields['category_id'] = categoryId.toString();

    if (imageFile != null) {
      final fileName = imageFile.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: fileName,
        ),
      );
    } else if (kIsWeb && webImageBytes != null && webImageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          webImageBytes,
          filename: webImageName,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to update item: ${response.statusCode} $responseBody',
      );
    }
  }

  static Future<void> deleteItem(int id) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final response = await http.delete(
      Uri.parse('$baseUrl/items/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete item: ${response.body}');
    }
  }

  // Order Services
  static Future<List<dynamic>> getOrders() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await clearAuthToken();
      throw Exception('Session expired. Please login again');
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String newStatus,
  ) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': newStatus}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      await clearAuthToken();
      throw Exception('Session expired. Please login again');
    } else {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> submitOrder({
    required int tableNumber,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final token = await getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'table_number': tableNumber,
          'items': items
              .map(
                (item) => {
                  'item_id': item['item_id'] ?? item['id'],
                  'quantity': item['quantity'],
                  'special_note': item['special_note'] ?? '',
                },
              )
              .toList(),
        }),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201) {
        return responseBody;
      } else if (response.statusCode == 422) {
        throw Exception(responseBody['message'] ?? 'Validation failed');
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to submit order');
      }
    } catch (e) {
      throw Exception('Failed to submit order: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateOrder(
    int orderId,
    Map<String, dynamic> data,
  ) async {
    final token = await getAuthToken();
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  static Future<void> deleteOrder(int orderId) async {
    final token = await getAuthToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete order');
    }
  }

  // Restaurant Services
  static Future<void> createRestaurant({
    required String restaurantName,
    required String address,
    File? profileImage,
    Uint8List? webImageBytes,
    String? webImageName,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final uri = Uri.parse('$baseUrl/restaurants');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['restaurant_name'] = restaurantName
      ..fields['address'] = address;

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile',
          profileImage.path,
          filename:
              'restaurant_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    } else if (kIsWeb && webImageBytes != null && webImageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile',
          webImageBytes,
          filename: webImageName,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 201) {
      throw Exception('Failed to create restaurant: $responseBody');
    }
  }

  static Future<Map<String, dynamic>> getRestaurantByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/restaurants/user/$userId'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['restaurant'];
    } else {
      throw Exception('Failed to load restaurant');
    }
  }

  static Future<void> updateRestaurant({
    required int id,
    required String restaurantName,
    required String address,
    File? profileImage,
    Uint8List? webImageBytes,
    String? webImageName,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Please login first');

    final uri = Uri.parse('$baseUrl/restaurants/$id?_method=PUT');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['restaurant_name'] = restaurantName
      ..fields['address'] = address;

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile',
          profileImage.path,
          filename:
              'restaurant_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    } else if (kIsWeb && webImageBytes != null && webImageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile',
          webImageBytes,
          filename: webImageName,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Failed to update restaurant: $responseBody');
    }
  }

  static Future<Restaurant> getRestaurant() async {
    try {
      final token = await getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      // First get current user
      final user = await getUser();
      if (user == null) throw Exception('User not found');

      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/user/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['restaurant'] == null) {
          throw Exception('No restaurant found for this user');
        }
        return Restaurant.fromJson(jsonData['restaurant']);
      } else {
        throw Exception('Failed to load restaurant: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getRestaurant: $e');
      rethrow;
    }
  }

  // Image Upload
  // Reusable helper to construct full image URLs
  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    // Case 1: Return with '/storage/profiles/' prefix
    if (!path.startsWith('http') && !path.contains('/')) {
      return '${baseUrl.replaceFirst('/api', '')}/storage/profiles/$path';
    }

    // Case 2: Return with direct path concatenation
    return baseUrl.replaceFirst('/api', '') + path;
  }
//   static String getImageUrl(String? path) {
//   if (path == null || path.isEmpty) return '';

//   // If path is already a full URL
//   if (path.startsWith('http')) return path;

//   // Make sure it starts with slash
//   if (!path.startsWith('/')) path = '/$path';

//   // Use /storage/ for web access
//   return '${baseUrl.replaceFirst('/api', '')}/storage$path';
// }


  static Future<void> saveLoginData(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_email', email);
  }

  static Future<Map<String, String>?> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('user_email');

    if (token != null && email != null) {
      return {'token': token, 'email': email};
    }
    return null;
  }

  static Future<void> clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password/email'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'Failed to send reset password email');
    }
  }
/// Fetch all order history from API
  static Future<List<OrderHistory>> getOrderHistory() async {
    try {
      final token = await getAuthToken();
      if (token == null) throw Exception('Please login first');

      final response = await http.get(
        Uri.parse('$baseUrl/order-history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is! Map<String, dynamic> || !jsonResponse.containsKey('data')) {
          throw Exception('Invalid API response format');
        }

        final data = jsonResponse['data'] as List<dynamic>;
        return data.map((e) => OrderHistory.fromJson(e)).toList();
      } else if (response.statusCode == 401) {
        await clearAuthToken();
        throw Exception('Session expired. Please login again');
      } else {
        throw Exception('Failed to load order history: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getOrderHistory: $e');
      rethrow;
    }
  }

}
