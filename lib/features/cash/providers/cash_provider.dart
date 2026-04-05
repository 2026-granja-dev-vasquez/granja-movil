import 'package:flutter/material.dart';
import '../models/cash_model.dart';
import '../services/cash_service.dart';

class CashProvider with ChangeNotifier {
  final CashService _service = CashService();

  CashBoxModel? _activeBox;
  List<CashBoxModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  CashBoxModel? get activeBox => _activeBox;
  List<CashBoxModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await fetchActiveBox();
  }

  Future<void> fetchActiveBox() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeBox = await _service.getCurrentBox();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _service.getHistory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBoxDetails(int id) async {
    // Check if we already have transactions for this box in history
    final index = _history.indexWhere((box) => box.id == id);
    if (index != -1 && _history[index].transactions.isNotEmpty) {
      return; // Already loaded
    }

    try {
      final details = await _service.getBoxDetails(id);
      if (index != -1) {
        _history[index] = details;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> openBox(String name, double openingBalance) async {
    _isLoading = true;
    notifyListeners();
    try {
      _activeBox = await _service.openBox(name, openingBalance);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> closeBox() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.closeBox();
      _activeBox = null;
      _errorMessage = null;
      await fetchHistory(); // Refresh history
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(String type, double amount, String category, String description, DateTime? date) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addTransaction(type, amount, category, description, date);
      await fetchActiveBox(); // Refresh to see updated totals and new transaction
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCashBoxName(int id, String newName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedBox = await _service.updateBox(id, newName);
      
      // Si es la caja activa, actualizarla
      if (_activeBox?.id == id) {
        _activeBox = updatedBox;
      }

      // Actualizar en el historial si existe
      final index = _history.indexWhere((box) => box.id == id);
      if (index != -1) {
        _history[index] = updatedBox;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> voidTransaction(int id, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.voidTransaction(id, reason);
      // Actualizar la caja actual o el historial para reflejar los cambios
      if (_activeBox != null) {
        await fetchActiveBox();
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
