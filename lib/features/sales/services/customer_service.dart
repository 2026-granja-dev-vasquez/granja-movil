import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/customer_model.dart';

class CustomerService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<List<CustomerModel>> getCustomers() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/customers');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CustomerModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar clientes');
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/customers');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(customer.toJson()),
    );

    if (response.statusCode == 201) {
      return CustomerModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al crear cliente');
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/customers/${customer.id}');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(customer.toJson()),
    );

    if (response.statusCode == 200) {
      return CustomerModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al actualizar cliente');
  }

  Future<void> deleteCustomer(int id) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/customers/$id');

    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar cliente');
    }
  }
}
