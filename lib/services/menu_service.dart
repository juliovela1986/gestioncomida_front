// menu_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu.dart';

class MenuService {
  final String apiUrl = 'https://mocki.io/v1/3f9e4d8e-8c6f-4c88-a2a1-123456789abc'; // ejemplo de API mock

  Future<List<Menu>> fetchMenus() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((e) => Menu.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar los menús: ${response.statusCode}');
    }
  }
}