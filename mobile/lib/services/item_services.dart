import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item_model.dart';

class ItemService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<List<Item>> getItems() async {
    final response = await http.get(Uri.parse('$baseUrl/items'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items');
    }
  }
}