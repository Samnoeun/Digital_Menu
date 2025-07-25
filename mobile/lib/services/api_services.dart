import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.108.122:8000/api';
  static String? _token;

  static Future<Map<String, dynamic>> register(String name, String email, String password, String confirmPassword) async {
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
      
      if (response.statusCode == 201 && data['success'] == true) {
        _token = data['token'];
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'errors': data['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'errors': {},
      };
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': email,
          'password': password,
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['token'];
        return {
          'success': true,
          'message': data['message'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'errors': data['errors'] ?? {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
        'errors': {},
      };
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
}
