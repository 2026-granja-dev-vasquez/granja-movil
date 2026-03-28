import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/models/user_model.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<UserModel>> getUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => UserModel.fromJson(item)).toList();
    }
    throw Exception('Error al cargar usuarios');
  }

  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users'),
      headers: await _getHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Error al crear usuario');
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/users/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Error al actualizar usuario');
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/users/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al eliminar usuario');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al cambiar contraseña');
    }
  }
}
