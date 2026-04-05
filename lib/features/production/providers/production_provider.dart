import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/production_model.dart';
import '../models/inventory_model.dart';
import '../services/production_service.dart';

enum StatRange { week, month, comparative }
enum StatType { batch, production }

class ProductionProvider with ChangeNotifier {
  final ProductionService _service = ProductionService();
  
  // Paso 1: Recolectas por Lote (Historial Filtrado)
  List<BatchCollectionModel> _batchCollections = [];
  // Paso 2: Clasificación de Inventario (Historial Filtrado)
  List<ProductionModel> _sortedProductions = [];
  
  // Lista de Reportes Diarios para Comparación
  List<DailySummaryReport> _dailyReports = [];
  List<DailyBatchSummary> _batchSummaries = [];
  
  // Inventario Actual (Stock Neto)
  List<InventoryModel> _inventoryStatus = [];

  // Datos del día seleccionado (Para el balance/banner)
  List<BatchCollectionModel> _dailyBatchCollections = [];
  List<ProductionModel> _dailySortedProductions = [];
  int _pendingFromYesterday = 0;

  // PASO 0: Huevos en mesa de ayer
  List<TableEggModel> _tableEggs = [];
  List<TableEggModel> get tableEggs => _tableEggs;

  bool _isLoading = false;
  String? _errorMessage;

  // Filtros de estadísticas
  StatRange _selectedStatRange = StatRange.week;
  StatType _selectedStatType = StatType.production;
  
  // Fechas específicas para comparativa
  DateTime _compareDate1 = DateTime.now();
  DateTime _compareDate2 = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);

  StatRange get selectedStatRange => _selectedStatRange;
  StatType get selectedStatType => _selectedStatType;
  DateTime get compareDate1 => _compareDate1;
  DateTime get compareDate2 => _compareDate2;

  void setCompareDates(DateTime d1, DateTime d2) {
    _compareDate1 = d1;
    _compareDate2 = d2;
    _updateChartData();
  }

  void setStatRange(StatRange range) {
    _selectedStatRange = range;
    _updateChartData();
  }

  void setStatType(StatType type) {
    _selectedStatType = type;
    notifyListeners();
  }

  void _updateChartData() async {
    final now = DateTime.now();
    if (_selectedStatRange == StatRange.week) {
      await fetchSummaryReport(now.subtract(const Duration(days: 7)), now);
    } else if (_selectedStatRange == StatRange.month) {
      await fetchSummaryReport(DateTime(now.year, now.month, 1), now);
    } else if (_selectedStatRange == StatRange.comparative) {
      // Cargamos el rango que cubra ambos meses para tener los datos en memoria
      final start = _compareDate1.isBefore(_compareDate2) ? _compareDate1 : _compareDate2;
      final end = _compareDate1.isAfter(_compareDate2) ? _compareDate1 : _compareDate2;
      
      // Asegurar que cubrimos el mes completo del "end"
      final lastDayOfEnd = DateTime(end.year, end.month + 1, 0);
      await fetchSummaryReport(DateTime(start.year, start.month, 1), lastDayOfEnd);
    }
  }


  List<BatchCollectionModel> get batchCollections => _batchCollections;
  List<ProductionModel> get sortedProductions => _sortedProductions;
  List<DailySummaryReport> get dailyReports => _dailyReports;
  List<DailyBatchSummary> get batchSummaries => _batchSummaries;
  List<InventoryModel> get inventoryStatus => _inventoryStatus;
  List<ProductionModel> get dailySortedProductions => _dailySortedProductions;
  List<BatchCollectionModel> get dailyBatchCollections => _dailyBatchCollections;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingFromYesterday => _pendingFromYesterday;
  int get totalTableUnits => _tableEggs.fold(0, (s, e) => s + e.quantity);

  // Datos para Gráficas (Adaptativo con Desglose)
  List<Map<String, dynamic>> get adaptiveChartData {
    final source = _selectedStatType == StatType.batch ? _batchSummaries : _dailyReports;
    final sorted = List<dynamic>.from(source)..sort((a, b) => a.date.compareTo(b.date));

    if (_selectedStatRange == StatRange.month) {
      return _getWeeklyGroupedData(sorted);
    }
    
    // Vista diaria con desglose
    return sorted.map((day) {
      Map<String, int> breakdown = {};
      int total = 0;

      if (day is DailyBatchSummary) {
        for (var item in day.report) {
          breakdown[item.batchName] = item.cartons;
          total += item.cartons;
        }
      } else if (day is DailySummaryReport) {
        for (var item in day.report) {
          breakdown[item.productSize] = item.cartons;
          total += item.cartons;
        }
      }

      return {
        'date': day.date,
        'total': total,
        'breakdown': breakdown,
      };
    }).toList();
  }

  // Identificar todas las categorías presentes en el periodo actual
  List<String> get activeCategories {
    final Set<String> categories = {};
    for (var day in adaptiveChartData) {
      final breakdown = day['breakdown'] as Map<String, int>;
      categories.addAll(breakdown.keys);
    }
    return categories.toList()..sort();
  }

  List<Map<String, dynamic>> _getWeeklyGroupedData(List<dynamic> sorted) {
    Map<int, Map<String, dynamic>> grouped = {};
    
    for (var day in sorted) {
      final weekNum = (day.date.day / 7).ceil();
      final month = day.date.month;
      final key = month * 10 + weekNum;

      Map<String, int> breakdown = {};
      int total = 0;

      if (day is DailyBatchSummary) {
        for (var item in day.report) {
          breakdown[item.batchName] = item.cartons;
          total += item.cartons;
        }
      } else if (day is DailySummaryReport) {
        for (var item in day.report) {
          breakdown[item.productSize] = item.cartons;
          total += item.cartons;
        }
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'label': "Sem. $weekNum",
          'total': 0,
          'breakdown': <String, int>{},
          'date': day.date,
        };
      }
      
      grouped[key]!['total'] += total;
      final currentBreakdown = grouped[key]!['breakdown'] as Map<String, int>;
      breakdown.forEach((category, value) {
        currentBreakdown[category] = (currentBreakdown[category] ?? 0) + value;
      });
    }
    
    return grouped.values.toList();
  }

  // Comparativa de Meses Seleccionados
  Map<String, dynamic> get customMonthlyComparison {
    int total1 = 0;
    int total2 = 0;

    final source = _selectedStatType == StatType.batch ? _batchSummaries : _dailyReports;

    for (var day in source) {
      int cartons = 0;
      DateTime date;
      if (day is DailyBatchSummary) {
        cartons = day.report.fold(0, (sum, item) => sum + item.cartons);
        date = day.date;
      } else if (day is DailySummaryReport) {
        cartons = day.report.fold(0, (sum, item) => sum + item.cartons);
        date = day.date;
      } else continue;

      if (date.month == _compareDate1.month && date.year == _compareDate1.year) {
        total1 += cartons;
      } else if (date.month == _compareDate2.month && date.year == _compareDate2.year) {
        total2 += cartons;
      }
    }

    return {
      'total1': total1,
      'total2': total2,
      'month1': DateFormat('MMMM', 'es').format(_compareDate1),
      'month2': DateFormat('MMMM', 'es').format(_compareDate2),
    };
  }
  
  set pendingFromYesterday(int value) {
    _pendingFromYesterday = value;
    notifyListeners();
  }

  // Cálculos de balance (Basados en hoy o el día seleccionado)
  int get totalRawCount => _dailyBatchCollections.where((c) => c.type == 'collection').fold(0, (sum, item) => sum + item.quantity);
  int get totalRawAdjustments => _dailyBatchCollections.where((c) => c.type != 'collection').fold(0, (sum, item) => sum + item.quantity);
  
  // Lo clasificado segregado
  int get sortedHarvestUnits => _dailySortedProductions.where((p) => p.origin == 'harvest').fold(0, (sum, item) => sum + item.usefulQuantity + item.damagedQuantity);
  int get sortedRemnantUnits => _dailySortedProductions.where((p) => p.origin == 'remnant').fold(0, (sum, item) => sum + item.usefulQuantity + item.damagedQuantity);
  
  int get totalSortedCount => sortedHarvestUnits + sortedRemnantUnits;
  int get totalDailyDamaged => _dailySortedProductions.fold(0, (sum, item) => sum + item.damagedQuantity);
  
  // El remanente que había al inicio (suma de lo que dice la mesa)
  // Al ser persistente, este es el origen de verdad para el cálculo de "Ayer"
  int get totalInitialTableRemnants => totalTableUnits;
  
  // Produccion de hoy = exactamente lo recolectado hoy (los de ayer ya estan en HISTORICO/AYER)
  int get netTodayHarvest => totalRawCount;

  // POR CLASIFICAR = Ayer (mesa) + Hoy (cosecha) + Ajustes - Ya clasificado
  // Se usa totalInitialTableRemnants (lo que el usuario ve en pantalla) para consistencia
  int get pendingEggs => (totalInitialTableRemnants + totalRawCount + totalRawAdjustments) - totalSortedCount;

  // Carga inicial: HOY + Historial (3d/7d)
  Future<void> fetchDailyData({String? date}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final threeDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 3)));
      final sevenDaysAgo = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)));

      // Carga en paralelo para mejorar el rendimiento (Fácil y rápido)
      final results = await Future.wait([
        _service.getBatchCollections(date: targetDate),
        _service.getSortedProductions(date: targetDate),
        _service.getPendingBalance(targetDate),
        _service.getBatchCollections(startDate: threeDaysAgo),
        _service.getSortedProductions(startDate: sevenDaysAgo),
        _service.getInventorySummary(startDate: threeDaysAgo, endDate: targetDate),
        _service.getBatchSummary(startDate: threeDaysAgo, endDate: targetDate),
        _service.getInventoryStatus(),
        _service.getTableEggs(date: targetDate),   // <-- huevos en mesa
      ]);

      _dailyBatchCollections  = results[0] as List<BatchCollectionModel>;
      _dailySortedProductions = results[1] as List<ProductionModel>;
      _pendingFromYesterday   = results[2] as int;
      _batchCollections  = results[3] as List<BatchCollectionModel>;
      _sortedProductions = results[4] as List<ProductionModel>;
      _dailyReports      = results[5] as List<DailySummaryReport>;
      _batchSummaries    = results[6] as List<DailyBatchSummary>;
      _inventoryStatus   = results[7] as List<InventoryModel>;
      _tableEggs         = results[8] as List<TableEggModel>;
      
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
    _inventoryStatus = await _service.getInventoryStatus();
    
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
      _inventoryStatus = await _service.getInventoryStatus();
      
      _dailyReports = await _service.getInventorySummary(date: dateStr);
      _batchSummaries = await _service.getBatchSummary(date: dateStr);
      _inventoryStatus = await _service.getInventoryStatus();
      
      _batchCollections = await _service.getBatchCollections(date: dateStr);
      _sortedProductions = await _service.getSortedProductions(date: dateStr);
      
      _dailyBatchCollections = List<BatchCollectionModel>.from(_batchCollections);
      _dailySortedProductions = List<ProductionModel>.from(_sortedProductions);

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
    return await addMultipleSortedProductions([model], date: DateFormat('yyyy-MM-dd').format(model.date));
  }

  Future<bool> addMultipleSortedProductions(List<ProductionModel> models, {String? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      for (var model in models) {
        if (model.productSizeId == null) {
          await _service.createSortedProduction(model);
          continue;
        }

        // --- Lógica inteligente de repartición (Remanente vs Cosecha) ---
        int totalToAdd = model.usefulQuantity;
        int currentRemnant = tableEggsForSize(model.productSizeId!);

        if (currentRemnant > 0 && totalToAdd > 0) {
          int remainingOnTable = tableEggsRemainingForSize(model.productSizeId!);
          int useFromRemnant = totalToAdd > remainingOnTable ? remainingOnTable : totalToAdd;
          int remainingForHarvest = totalToAdd - useFromRemnant;

          // 1. Guardar porción de remanente
          if (useFromRemnant > 0) {
            await _service.createSortedProduction(ProductionModel(
              productSizeId: model.productSizeId,
              usefulQuantity: useFromRemnant,
              damagedQuantity: model.damagedQuantity,
              date: model.date,
              origin: 'remnant',
            ));

            // Ya NO borramos ni reducimos la mesa. 
            // Se queda como el historial de lo que se encontró en la mañana.
          }

          // 2. Guardar porción de cosecha nueva
          if (remainingForHarvest > 0) {
            await _service.createSortedProduction(ProductionModel(
              productSizeId: model.productSizeId,
              usefulQuantity: remainingForHarvest,
              damagedQuantity: 0,
              date: model.date,
              origin: 'harvest',
            ));
          }
        } else {
          await _service.createSortedProduction(model);
        }
      }
      await fetchDailyData(date: date);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSortedProduction(ProductionModel model, {String? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateSortedProduction(model);
      await fetchDailyData(date: date);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBatchCollection(int id, {String? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteBatchCollection(id);
      await fetchDailyData(date: date);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSortedProduction(int id, {String? date}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteSortedProduction(id);
      await fetchDailyData(date: date);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets the running historical balance so that pending_from_yesterday
  /// on [date] equals [targetPending]. Refreshes all daily data afterwards.
  Future<bool> resetBalance({required String date, required int targetPending}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.resetBalance(date: date, targetPending: targetPending);
      await fetchDailyData(date: date);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Huevos en Mesa ---

  int tableEggsForSize(int sizeId) =>
      _tableEggs.where((e) => e.productSizeId == sizeId).fold(0, (s, e) => s + e.quantity);

  Future<bool> saveTableEgg(TableEggModel model) async {
    _isLoading = true;
    notifyListeners();
    try {
      final saved = await _service.saveTableEgg(model);
      // replace or add in local list
      _tableEggs.removeWhere((e) => e.productSizeId == saved.productSizeId);
      _tableEggs.add(saved);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTableEgg(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteTableEgg(id);
      _tableEggs.removeWhere((e) => e.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> clearTableEggs(String date) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteTableEggsByDate(date);
      _tableEggs.clear();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Huevos que QUEDAN en mesa (Total inicial - Lo ya clasificado hoy)
  int tableEggsRemainingForSize(int sizeId) {
    int initial = tableEggsForSize(sizeId);
    int alreadySorted = _dailySortedProductions
        .where((p) => p.productSizeId == sizeId && p.origin == 'remnant')
        .fold(0, (s, p) => s + p.usefulQuantity);
    
    int remaining = initial - alreadySorted;
    return remaining > 0 ? remaining : 0;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
