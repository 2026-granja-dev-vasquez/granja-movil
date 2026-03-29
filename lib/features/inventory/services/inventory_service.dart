import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<List<InventoryModel>> getInventory() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/inventory');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InventoryModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar inventario');
  }

  Future<void> adjustStock(int productSizeId, String type, int quantity, String? reason) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/inventory/adjust');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_size_id': productSizeId,
        'type': type,
        'quantity': quantity,
        'reason': reason,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error al ajustar inventario');
    }
  }
}
