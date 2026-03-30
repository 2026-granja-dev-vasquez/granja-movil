import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/production_model.dart';
import '../models/inventory_model.dart';

class DailySummaryReport {
  final DateTime date;
  final List<ConsolidationModel> report;
  final int totalDamaged;
  final int totalPending;

  DailySummaryReport({
    required this.date,
    required this.report,
    required this.totalDamaged,
    required this.totalPending,
  });

  factory DailySummaryReport.fromJson(Map<String, dynamic> json) {
    final List<dynamic> reportData = json['report'];
    return DailySummaryReport(
      date: DateTime.parse(json['date']),
      report: reportData.map((item) => ConsolidationModel.fromJson(item)).toList(),
      totalDamaged: json['total_damaged'] ?? 0,
      totalPending: json['total_pending'] ?? 0,
    );
  }
}

class DailyBatchSummary {
  final DateTime date;
  final List<BatchSummaryItem> report;

  DailyBatchSummary({
    required this.date,
    required this.report,
  });

  factory DailyBatchSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> reportData = json['report'];
    return DailyBatchSummary(
      date: DateTime.parse(json['date']),
      report: reportData.map((item) => BatchSummaryItem.fromJson(item)).toList(),
    );
  }
}

class BatchSummaryItem {
  final int batchId;
  final String batchName;
  final int totalUnits;
  final int cartons;
  final int leftoverUnits;
  final String formatted;

  BatchSummaryItem({
    required this.batchId,
    required this.batchName,
    required this.totalUnits,
    required this.cartons,
    required this.leftoverUnits,
    required this.formatted,
  });

  factory BatchSummaryItem.fromJson(Map<String, dynamic> json) {
    return BatchSummaryItem(
      batchId: json['batch_id'],
      batchName: json['batch_name'],
      totalUnits: json['total_units'],
      cartons: json['cartons'],
      leftoverUnits: json['leftover_units'],
      formatted: json['formatted'],
    );
  }
}

class ProductionService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async => await _storage.read(key: 'auth_token');

  // --- PASO 1: RECOLECTAS POR LOTE ---
  Future<List<BatchCollectionModel>> getBatchCollections({String? date, String? startDate}) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/daily-collections').replace(queryParameters: {
      if (date != null) 'date': date,
      if (startDate != null) 'start_date': startDate,
    });

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => BatchCollectionModel.fromJson(item)).toList();
    }
    throw Exception('Error al cargar recolectas');
  }

  Future<void> createBatchCollection(BatchCollectionModel model) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/daily-collections'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode != 201) throw Exception('Error al registrar recolecta');
  }

  // --- PASO 2: CLASIFICACIÓN DE INVENTARIO ---
  Future<List<ProductionModel>> getSortedProductions({String? date, String? startDate}) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/productions').replace(queryParameters: {
      if (date != null) 'date': date,
      if (startDate != null) 'start_date': startDate,
    });

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ProductionModel.fromJson(item)).toList();
    }
    throw Exception('Error al cargar clasificaciones');
  }

  Future<void> createSortedProduction(ProductionModel model) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/productions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode != 201) throw Exception('Error al clasificar producción');
  }

  Future<void> deleteSortedProduction(int id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/productions/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) throw Exception('Error al eliminar registro');
  }

  Future<int> getPendingBalance(String date) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/productions/pending-balance').replace(queryParameters: {
      'date': date,
    });

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['pending_from_yesterday'] ?? 0;
    }
    throw Exception('Error al cargar saldo pendiente');
  }

  Future<List<DailySummaryReport>> getInventorySummary({String? date, String? startDate, String? endDate}) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/productions/summary').replace(queryParameters: {
      if (date != null) 'date': date,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DailySummaryReport.fromJson(item)).toList();
    }
    throw Exception('Error al cargar reporte de producción');
  }

  Future<List<DailyBatchSummary>> getBatchSummary({String? date, String? startDate, String? endDate}) async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/daily-collections/summary').replace(queryParameters: {
      if (date != null) 'date': date,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => DailyBatchSummary.fromJson(item)).toList();
    }
    throw Exception('Error al cargar reporte de galeras');
  }

  Future<List<InventoryModel>> getInventoryStatus() async {
    final token = await _getToken();
    final url = Uri.parse('${ApiConstants.baseUrl}/inventory');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => InventoryModel.fromJson(item)).toList();
    }
    throw Exception('Error al cargar inventario actual');
  }
}
