import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/cash_model.dart';

class CashService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<CashBoxModel?> getCurrentBox() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cash/current'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      if (response.body == 'null' || response.body.isEmpty) return null;
      return CashBoxModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<CashBoxModel> openBox(String name, double openingBalance) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/cash/open'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'opening_balance': openingBalance,
      }),
    );

    if (response.statusCode == 200) {
      return CashBoxModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Error al abrir caja');
  }

  Future<CashBoxModel> closeBox() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/cash/close'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return CashBoxModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al cerrar caja');
  }

  Future<CashTransactionModel> addTransaction(String type, double amount, String category, String description, DateTime? date) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/cash/transactions'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'type': type,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date?.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return CashTransactionModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Error al registrar movimiento');
  }

  Future<List<CashBoxModel>> getHistory() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cash/history'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['data'];
      return data.map((item) => CashBoxModel.fromJson(item)).toList();
    }
    throw Exception('Error al obtener historial');
  }

  Future<CashBoxModel> getBoxDetails(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cash/history/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return CashBoxModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al obtener detalle de caja');
  }

  Future<CashBoxModel> updateBox(int id, String name) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/cash/history/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      return CashBoxModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar nombre de caja');
  }

  Future<void> voidTransaction(int id, String reason) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/cash/transactions/$id/void'),
      headers: await _getHeaders(),
      body: jsonEncode({'void_reason': reason}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Error al anular transacción');
    }
  }
}
