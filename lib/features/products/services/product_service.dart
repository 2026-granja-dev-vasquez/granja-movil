import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';

class ProductService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async => await _storage.read(key: 'auth_token');

  Future<List<Map<String, dynamic>>> getProductSizes() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/product-sizes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Error al cargar tamaños de producto');
  }

  Future<Map<String, dynamic>> updatePrice(int id, double unit, double carton, double box) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/product-sizes/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'unit_price': unit,
        'carton_price': carton,
        'box_price': box,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al actualizar precios');
  }

  Future<Map<String, dynamic>> createSize(String name, double unit, double carton, double box) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/product-sizes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'unit_price': unit,
        'carton_price': carton,
        'box_price': box,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al crear tamaño de producto');
  }
}
