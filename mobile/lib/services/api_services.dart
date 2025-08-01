import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/category_model.dart' as category;
import '../models/item_model.dart' as item;
import '../models/order_model.dart';
import '../models/setting_model.dart';
import '../models/restaurant_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.108.93:8000/api'; // Update with your preferred base URL

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
        final token = data['token'];
        if (token != null) await saveAuthToken(token);
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
        final token = data['token'];
        if (token != null) await saveAuthToken(token);
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

  // static Future<UserModel?> getUser() async {
  //   try {
  //     final token = await getAuthToken();
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/me'),
  //       headers: {
  //         'Accept': 'application/json',
  //         if (token != null) 'Authorization': 'Bearer $token',
  //       },
  //     );

  //     final data = json.decode(response.body);

  //     if (response.statusCode == 200) {
  //       return UserModel.fromJson(data);
  //     } else {
  //       throw Exception('Unauthorized');
  //     }
  //   } catch (e) {
  //     throw Exception('Error: $e');
  //   }
  // }
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
    return (jsonData['data'] as List).map((json) => category.Category.fromJson(json)).toList();
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

  // Item Services
// Item Services
static Future<List<item.Item>> getItems() async {
  final token = await getAuthToken();
  if (token == null) {
    throw Exception('Please login first');
  }

  final response = await http.get(
    Uri.parse('$baseUrl/items'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
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
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
    ));
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

  // Order Services
  static Future<List<dynamic>> getOrders() async {
  final token = await getAuthToken();
  if (token == null) throw Exception('Please login first');

  final response = await http.get(
    Uri.parse('$baseUrl/orders'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
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

  // Setting Services
  static Future<Map<String, dynamic>?> getSetting(int id) async {
    final token = await getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/settings/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['data'] ?? jsonData;
    } else {
      throw Exception('Failed to load setting');
    }
  }

  static Future<void> createSetting({
    required String restaurantName,
    required String address,
    File? logoFile,
    String? currency,
    String? language,
    bool? darkMode,
  }) async {
    final token = await getAuthToken();

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/settings'));

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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

  static Future<void> updateSetting({
    required int id,
    required String restaurantName,
    required String address,
    File? logoFile,
    String? currency,
    String? language,
    bool? darkMode,
  }) async {
    final token = await getAuthToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/settings/$id?_method=PUT'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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

  static Future<void> deleteSetting(int id) async {
    final token = await getAuthToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/settings/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete setting');
    }
  }

  // Restaurant Services
  static Future<void> createRestaurant({
    required String restaurantName,
    required String address,
    File? profileImage,
  }) async {
    final token = await getAuthToken();

    var uri = Uri.parse('$baseUrl/restaurants');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields['restaurant_name'] = restaurantName;
    request.fields['address'] = address;
    if (profileImage != null)
      request.files.add(
        await http.MultipartFile.fromPath('profile', profileImage.path),
      );
    final response = await request.send();
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(await response.stream.bytesToString());
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
}) async {
  final token = await getAuthToken();
  
  // Create multipart request
  var request = http.MultipartRequest(
    'POST', 
    Uri.parse('$baseUrl/restaurants/$id?_method=PUT')
  );

  // Add headers
  request.headers.addAll({
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  });

  // Add fields
  request.fields['restaurant_name'] = restaurantName;
  request.fields['address'] = address;

  // Add image if exists
  if (profileImage != null) {
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile', 
        profileImage.path,
        filename: 'restaurant_profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
  }

  // Send request
  final response = await request.send();
  final responseString = await response.stream.bytesToString();

  if (response.statusCode != 200) {
    throw Exception('Failed to update restaurant: $responseString');
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
  
}
