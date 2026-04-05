import 'package:flutter/material.dart';
import '../models/cash_model.dart';
import '../services/cash_service.dart';

class CashProvider with ChangeNotifier {
  final CashService _service = CashService();

  CashBoxModel? _activeBox;
  List<CashBoxModel> _history = [];
  List<ExpenseCategoryModel> _expenseCategories = [];
  bool _isLoading = false;
  String? _errorMessage;

  CashBoxModel? get activeBox => _activeBox;
  List<CashBoxModel> get history => _history;
  List<ExpenseCategoryModel> get expenseCategories => _expenseCategories;
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
    final index = _history.indexWhere((box) => box.id == id);
    if (index != -1 && _history[index].transactions.isNotEmpty) return;
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
      await fetchHistory();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(String type, double amount, String category,
      String description, DateTime? date) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.addTransaction(type, amount, category, description, date);
      await fetchActiveBox();
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
      if (_activeBox?.id == id) _activeBox = updatedBox;
      final index = _history.indexWhere((box) => box.id == id);
      if (index != -1) _history[index] = updatedBox;
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
      if (_activeBox != null) await fetchActiveBox();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Rubros de Egresos ────────────────────────────────────────────────────

  Future<void> fetchExpenseCategories() async {
    try {
      _expenseCategories = await _service.getExpenseCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createExpenseCategory(String name) async {
    try {
      final newCat = await _service.createExpenseCategory(name);
      _expenseCategories.add(newCat);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpenseCategory(int id) async {
    try {
      await _service.deleteExpenseCategory(id);
      _expenseCategories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameExpenseCategory(int id, String newName) async {
    try {
      final updated = await _service.renameExpenseCategory(id, newName);
      final index = _expenseCategories.indexWhere((c) => c.id == id);
      if (index != -1) {
        _expenseCategories[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransactionCategory(int txId, String category) async {
    try {
      await _service.updateTransactionCategory(txId, category);
      if (_activeBox != null) await fetchActiveBox();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
