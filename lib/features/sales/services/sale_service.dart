import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/sale_model.dart';

class SaleService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<List<SaleModel>> getSales() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/sales');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SaleModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar ventas');
  }

  Future<SaleModel> createSale(SaleModel sale) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/sales');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(sale.toJson()),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      // El backend devuelve { success: true, message: ..., sale: ... }
      return SaleModel.fromJson(decoded['sale']);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error al registrar venta');
    }
  }

  Future<SaleModel> getSaleDetails(int id) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/sales/$id');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return SaleModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener detalles de la venta');
  }
}
