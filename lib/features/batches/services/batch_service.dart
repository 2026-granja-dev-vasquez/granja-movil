import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';

class BatchService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async => await _storage.read(key: 'auth_token');

  Future<List<Map<String, dynamic>>> getBatches() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + '/batches'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Error al cargar lotes');
  }

  Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + '/batches'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al crear lote');
  }

  Future<void> registerMortality(int batchId, int quantity, String date, String? reason) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/batches/$batchId/mortality'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'quantity': quantity,
        'date': date,
        'reason': reason,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al registrar mortalidad');
    }
  }
}
