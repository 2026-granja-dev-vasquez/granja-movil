import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _service = InventoryService();
  
  List<InventoryModel> _inventory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InventoryModel> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInventory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _inventory = await _service.getInventory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> adjustStock(int productSizeId, String type, int quantity, String? reason) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.adjustStock(productSizeId, type, quantity, reason);
      await fetchInventory(); // Refresh to get latest totals
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
