import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class ApiService {
  // static const String baseUrl = 'http://192.168.108.113:8000/api';
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static String? _token;

  static Future<UserModel?> register(String name, String email, String password, String confirmPassword) async {
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
        body: {
          'email': email,
          'password': password,
        },
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
}
