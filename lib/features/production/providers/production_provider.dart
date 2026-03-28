import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/production_model.dart';
import '../services/production_service.dart';

class ProductionProvider with ChangeNotifier {
  final ProductionService _service = ProductionService();
  
  // Paso 1: Recolectas por Lote (Historial Filtrado)
  List<BatchCollectionModel> _batchCollections = [];
  // Paso 2: Clasificación de Inventario (Historial Filtrado)
  List<ProductionModel> _sortedProductions = [];
  
  // Lista de Reportes Diarios para Comparación
  List<DailySummaryReport> _dailyReports = [];
  List<DailyBatchSummary> _batchSummaries = [];

  // Datos del día seleccionado (Para el balance/banner)
  List<BatchCollectionModel> _dailyBatchCollections = [];
  List<ProductionModel> _dailySortedProductions = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<BatchCollectionModel> get batchCollections => _batchCollections;
  List<ProductionModel> get sortedProductions => _sortedProductions;
  List<DailySummaryReport> get dailyReports => _dailyReports;
  List<DailyBatchSummary> get batchSummaries => _batchSummaries;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cálculos de balance (Basados en hoy o el día seleccionado)
  int get totalRawCount => _dailyBatchCollections.fold(0, (sum, item) => sum + item.quantity);
  int get totalSortedCount => _dailySortedProductions.fold(0, (sum, item) => sum + item.usefulQuantity + item.damagedQuantity);
  int get totalDailyDamaged => _dailySortedProductions.fold(0, (sum, item) => sum + item.damagedQuantity);
  int get pendingEggs => totalRawCount - totalSortedCount;

  // Carga inicial: HOY + Historial (3d/7d)
  Future<void> fetchDailyData({String? date}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // 1. Balance del día
      _dailyBatchCollections = await _service.getBatchCollections(date: targetDate);
      _dailySortedProductions = await _service.getSortedProductions(date: targetDate);

      // 2. Historial con filtros
      final threeDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 3)));
      final sevenDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)));
      
      _batchCollections = await _service.getBatchCollections(startDate: threeDaysAgo);
      _sortedProductions = await _service.getSortedProductions(startDate: sevenDaysAgo);

      // 3. Reporte de Producción: ÚLTIMOS 3 DÍAS por defecto para comparativa
      _dailyReports = await _service.getInventorySummary(startDate: threeDaysAgo, endDate: targetDate);
      _batchSummaries = await _service.getBatchSummary(startDate: threeDaysAgo, endDate: targetDate);
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REPORTE POR RANGO: Cargar producción de un periodo para comparar
  Future<void> fetchSummaryReport(DateTime start, DateTime end) async {
    _isLoading = true;
    notifyListeners();
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      
      _dailyReports = await _service.getInventorySummary(startDate: startStr, endDate: endStr);
      _batchSummaries = await _service.getBatchSummary(startDate: startStr, endDate: endStr);
      
      // Sincronizar otros listados
      _batchCollections = await _service.getBatchCollections(startDate: startStr);
      _sortedProductions = await _service.getSortedProductions(startDate: startStr);
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSpecificDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      _dailyReports = await _service.getInventorySummary(date: dateStr);
      _batchSummaries = await _service.getBatchSummary(date: dateStr);
      
      _batchCollections = await _service.getBatchCollections(date: dateStr);
      _sortedProductions = await _service.getSortedProductions(date: dateStr);
      
      _dailyBatchCollections = _batchCollections;
      _dailySortedProductions = _sortedProductions;

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBatchCollection(BatchCollectionModel model) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createBatchCollection(model);
      await fetchDailyData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSortedProduction(ProductionModel model) async {
    return await addMultipleSortedProductions([model]);
  }

  Future<bool> addMultipleSortedProductions(List<ProductionModel> models) async {
    _isLoading = true;
    notifyListeners();
    try {
      for (var model in models) {
        await _service.createSortedProduction(model);
      }
      await fetchDailyData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
