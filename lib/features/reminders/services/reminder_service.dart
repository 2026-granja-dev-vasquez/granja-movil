import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_service.dart';
import '../models/reminder_model.dart';
import 'package:intl/intl.dart';

class ReminderService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ReminderModel>> getActiveReminders() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reminders'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ReminderModel.fromJson(item)).toList();
    }
    throw Exception('Error al cargar recordatorios pendientes');
  }

  Future<List<ReminderModel>> getHistory(DateTime from, DateTime to) async {
    final fromStr = DateFormat('yyyy-MM-dd').format(from);
    final toStr = DateFormat('yyyy-MM-dd').format(to);
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/reminders/history?from_date=$fromStr&to_date=$toStr'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ReminderModel.fromJson(item)).toList();
    }
    throw Exception('Error al cargar el historial de tareas');
  }

  Future<ReminderModel> createReminder(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reminders'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return ReminderModel.fromJson(jsonDecode(response.body));
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Error al crear recordatorio');
  }

  Future<String> markAsDone(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/reminders/$id/done'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Tarea completada';
    }
    throw Exception(data['message'] ?? 'Error al marcar como hecho');
  }
}
